

                .include ../os/sio_defs.asm
                .include ../os/ports.asm


sioa_data       .equ sio0_base+sio_port_a
sioa_command    .equ sioa_data+sio_cfg

siob_data       .equ sio0_base+sio_port_b
siob_command    .equ siob_data+sio_cfg

blue            .equ 1
green           .equ 2

stbufa_size     .equ 64
stbufb_size     .equ 64
srbufa_size     .equ 256
srbufb_size     .equ 256

srbufa_emptyish .equ 16
srbufb_emptyish .equ 16
srbufa_fullish  .equ srbufa_size - 16
srbufb_fullish  .equ srbufb_size - 16

isr_txrdyb      .equ $8000
isr_txstatb     .equ $8002
isr_rxrdyb      .equ $8004
isr_rxerrb      .equ $8006
isr_txrdya      .equ $8008
isr_txstata     .equ $800a
isr_rxrdya      .equ $800c
isr_rxerra      .equ $800e

led_state       .equ $8010

stcnta          .equ $8040
stcntb          .equ $8041
srcnta          .equ $8042
srcntb          .equ $8043
stina           .equ $8044
stouta          .equ $8046
stinb           .equ $8048
stoutb          .equ $804a
srina           .equ $804c
srouta          .equ $804e
srinb           .equ $8050
sroutb          .equ $8052
sstata          .equ $8054
sstatb          .equ $8055
serra           .equ $8056
serrb           .equ $8057          

stbufa          .equ $8080
stbufb          .equ $80c0
srbufa          .equ $8100
srbufb          .equ $8200

                .org 0

                ld sp,0
                ld a,high isr_txrdyb
                ld i,a
                im 2

                ; initialize interrupt vector
                ld hl,siob_txrdy
                ld (isr_txrdyb),hl
                ld hl,siob_txstat
                ld (isr_txstatb),hl
                ld hl,siob_rxrdy
                ld (isr_rxrdyb),hl
                ld hl,siob_rxerr
                ld (isr_rxerrb),hl
                ld hl,sioa_txrdy
                ld (isr_txrdya),hl
                ld hl,sioa_txstat
                ld (isr_txstata),hl
                ld hl,sioa_rxrdy
                ld (isr_rxrdya),hl
                ld hl,sioa_rxerr
                ld (isr_rxerra),hl

                ; initialize port A buffers
                xor a
                ld (stcnta),a
                ld (srcnta),a
                ld (sstata),a
                ld (serra),a
                ld hl,stbufa
                ld (stina),hl
                ld (stouta),hl
                ld hl,srbufa
                ld (srina),hl
                ld (srouta),hl

                ; initialize port B buffers
                xor a
                ld (stcntb),a
                ld (srcntb),a
                ld (sstatb),a
                ld (serrb),a
                ld hl,stbufb
                ld (stinb),hl
                ld (stoutb),hl
                ld hl,srbufb
                ld (srinb),hl
                ld (sroutb),hl

                ; reset port A
                ld a,sio_channel_reset
                out (sioa_command),a
                nop
                nop

                ; reset port B
                ld a,sio_channel_reset
                out (siob_command),a
                nop
                nop

                ; select port B WR2
                ld a,sio_reg2
                out (siob_command),a

                ; port B WR2: set interrupt vector
                xor a
                out (siob_command),a

                ; select port B WR1
                ld a,sio_reg1
                out (siob_command),a

                ; port B WR1: vary interrupt vector by status
                ld a,sio_vector_by_status
                out (siob_command),a

                ; select port A WR4, reset external/status interrupt
                ld a,sio_reg4+sio_reset_ext_stat_int
                out (sioa_command),a

                ; port A WR4: async mode, divisor 64, 1 stop bit, no parity
                ld a,sio_clock_x64+sio_stop_1bit+sio_parity_none
                out (sioa_command),a

                ; select port A WR3
                ld a,sio_reg3
                out (sioa_command),a

                ; port A WR3: receiver enable, auto enables, receive 8 bits/char
                ld a,sio_rx_enable+sio_rx_auto_enables+sio_rx_8bits
                out (sioa_command),a

                ; select port A WR5
                ld a,sio_reg5
                out (sioa_command),a

                ; port A WR5: tranmitter enable, transmit 8 bits/char, assert DTR and RTS
                ld a,sio_tx_enable+sio_tx_8bits+sio_dtr+sio_rts
                out (sioa_command),a

                ; select port A WR1 and reset external/status interrupt (again)
                ld a,sio_reg1+sio_reset_ext_stat_int
                out (sioa_command),a

                ; port A WR1: enable interupt on all received characters (ignoring parity),
                ; enable tx interrupt
                ld a,sio_rx_int_all+sio_tx_int_enable+sio_vector_by_status
                out (sioa_command),a

                ei

                xor a
                ld (led_state),a
                out (gpio_port),a
loop:
next:
                call sioa_getc
                jp nc,next
                ld c,a
                call sioa_putc
                jp loop

sioa_puts:
                ld a,(hl)
                or a
                ret z
                ld c,a
                call sioa_putc
                inc hl
                jp sioa_puts

sioa_tx:
                in a,(sioa_command)
                and sio_tx_buffer_empty
                jp z,sioa_tx

                ld a,c
                out (sioa_data),a
                ret


        ;---------------------------------------------------------------
        ; SIO port A Transmiter Status ISR
        ;
sioa_txstat:
                ei
                push af

                ; read RR0 for status bits
                in a,(sioa_command) 
                ld (sstata),a
                ; reset interrupt latch

                ld a,sio_reset_ext_stat_int
                out (sioa_command),a

                pop af
                reti

        ;---------------------------------------------------------------
        ; SIO port A Transmitter Ready ISR
        ;
sioa_txrdy:
                ei
                push af

                ld a,(stcnta)           ; get num chars waiting
                or a
                jr z,sioa_txrdy_reset

                push hl
                ld hl,(stouta)          ; get ring head pointer
                ld a,(hl)               ; get char to transmit
                out (sioa_data),a       ; transmit it

                inc l                   ; update the head pointer
                ld a,stbufa_size-1      ; load buffer size (n^2)-1
                and l                   ; wrap if needed
                or low stbufa           ; offset to base
                ld l,a
                ld (stouta),hl          ; put new ring head pointer

                ld hl,stcnta
                dec (hl)                ; atomically decrement num waiting
                pop hl

                jr nz,sioa_txrdy_end    ; go if ring not empty

sioa_txrdy_reset:

                ld a,sio_reset_tx_int   ; command to reset tx ready interrupt
                out (sioa_command),a    ; write command to WR0

                ; turn off blue LED
                ld a,(led_state)
                and ~blue
                ld (led_state),a
                out (gpio_port),a

sioa_txrdy_end:
                pop af
                reti


        ;---------------------------------------------------------------
        ; SIO port A Receiver Ready ISR
        ;
sioa_rxrdy:
                ei
                push af
                push hl

sioa_rxrdy_get:
                in a,(sioa_data)        ; get the received char
                ld l,a                  ; preserve it

                ld a,(srcnta)           ; get num chars waiting
                cp srbufa_size-1        ; is there room for another
                jr nc,sioa_rxrdy_check  ; nope...

                ld a,l                  ; recover received char
                ld hl,(srina)           ; get ring tail pointer
                ld (hl),a               ; put received char in buf
                inc l                   ; increment pointer (rolls over)
                ld (srina),hl           ; put ring tail pointer
                ld hl,srcnta
                inc (hl)                ; atomically update waiting count

                ld a,(srcnta)           ; get new waiting count
                cp srbufa_fullish       ; is getting kinda full?
                jp nz,sioa_rxrdy_check  ; nope

                ; clear RTS as buffer nears full
                ld a,sio_reg5
                out (sioa_command),a    ; select WR5
                ld a,sio_dtr+sio_tx_8bits+sio_tx_enable
                out (sioa_command),a    ; write WR5

sioa_rxrdy_check:
                ; turn on green LED
                ld a,(led_state)
                or green
                ld (led_state),a
                out (gpio_port),a

                ; check to see if more availble to read
                in a,(sioa_command)     ; read RR0
                rrca
                jr c,sioa_rxrdy_get     ; go if received char available

                pop hl
                pop af
                reti


        ;---------------------------------------------------------------
        ; SIO port A Receiver Error ISR
        ;
sioa_rxerr:
                ei
                push af

                ; select RR 1
                ld a,sio_reg1
                out (sioa_command),a

                ; read RR 1 for error bits
                in a,(sioa_command)
                ld (serra),a

                ; reset error latch
                ld a,sio_error_reset
                out (sioa_command),a
                pop af
                reti


        ;---------------------------------------------------------------
        ; SIO port A Put Character
        ;
sioa_putc:
                push hl
                di
                ld a,(stcnta)           ; get num chars waiting
                or a                    ; is the buffer empty?
                jr nz,sioa_putc_ring    ; nope -- go add to ring

                in a,(sioa_command)     ; get register R0
                and sio_tx_buffer_empty ; can we transmit now?
                jr z,sioa_putc_ring     ; nope -- go add to ring

                ld a,c                  ; get char to transmit
                out (sioa_data),a       ; transmit it
                ei
                pop hl
                ret

sioa_putc_again:
                ei
sioa_putc_ring:
                ld a,(stcnta)           ; get num chars waiting
                cp stbufa_size-1
                jr nc,sioa_putc_again   ; buffer full, keep trying

                ld hl,stcnta
                di
                inc (hl)                ; increment num waiting
                ld hl,(stina)           ; get tail pointer
                ld (hl),c               ; put character into buffer
                ei

                inc l                   ; increment pointer
                ld a,stbufa_size-1      ; load buffer size (n^2)-1
                and l                   ; wrap if needed
                or low stbufa           ; offset to base
                ld l,a
                ld (stina),hl           ; store new tail pointer

                ; turn on blue LED
                ld a,(led_state)
                or blue
                ld (led_state),a
                out (gpio_port),a

                pop hl
                ret

        ;---------------------------------------------------------------
        ; SIO port A Get Character
        ;
sioa_getc:
                push hl
                ld a,(srcnta)           ; get num chars waiting
                or a
                jp nz,sioa_getc_cont

                ; turn off green LED
                ld a,(led_state)
                and ~green
                ld (led_state),a
                out (gpio_port),a
                or a

                pop hl
                ret

sioa_getc_cont:
                cp srbufb_emptyish
                jp nz,sioa_getc_get

                ; set RTS as buffer nears empty
                ld a,sio_reg5
                out (sioa_command),a    ; select WR5
                ld a,sio_dtr+sio_tx_8bits+sio_tx_enable+sio_rts
                out (sioa_command),a    ; write WR5

sioa_getc_get:
                ld hl,(srouta)          ; get ring head pointer
                ld a,(hl)               ; get the received char
                inc l                   ; update the tail (rolls over)
                ld (srouta),hl          ; put the ring head pointer

                ld hl,srcnta
                dec (hl)                ; atomically update waiting count

                scf                     ; indicate char received
                pop hl
                ret


        ;---------------------------------------------------------------
        ; SIO port B Transmiter Status ISR
        ;
siob_txstat:
                ei
                push af

                ; read RR0 for status bits
                in a,(siob_command) 
                ld (sstatb),a
                ; reset interrupt latch

                ld a,sio_reset_ext_stat_int
                out (siob_command),a

                pop af
                reti


        ;---------------------------------------------------------------
        ; SIO port B Transmitter Ready ISR
        ;
siob_txrdy:
                ei
                push af
                ld a,(stcntb)           ; get num chars waiting
                or a
                jr z,siob_txrdy_reset

                push hl
                ld hl,(stoutb)          ; get ring head pointer
                ld a,(hl)               ; get char to transmit
                out (siob_data),a       ; transmit it

                inc l                   ; update the head pointer
                ld a,stbufb_size-1      ; load buffer size (n^2)-1
                and l                   ; wrap if needed
                or low stbufb           ; offset to base
                ld l,a
                ld (stoutb),hl          ; put new ring head pointer

                ld hl,stcntb
                dec (hl)                ; atomically decrement num waiting

                pop hl
                jr nz,siob_txrdy_end    ; go if ring not empty

siob_txrdy_reset:
                ld a,sio_reset_tx_int   ; command to reset tx ready interrupt
                out (siob_command),a    ; write command to WR0

siob_txrdy_end:
                pop af
                reti


        ;---------------------------------------------------------------
        ; SIO port B Receiver Ready ISR
        ;
siob_rxrdy:
                ei
                push af
                push hl

siob_rxrdy_get:
                in a,(siob_data)        ; get the received char
                ld l,a                  ; preserve it

                ld a,(srcntb)           ; get num chars waiting
                cp srbufb_size-1        ; is there room for another
                jr nc,siob_rxrdy_check  ; nope...

                ld a,l                  ; recover received char
                ld hl,(srinb)           ; get ring tail pointer
                ld (hl),a               ; put received char in buf
                inc l                   ; increment pointer (rolls over)
                ld (srinb),hl           ; put ring tail pointer
                ld hl,srcntb
                inc (hl)                ; atomically update waiting count

                ld a,(srcntb)           ; get new waiting count
                cp srbufb_fullish       ; is getting kinda full?
                jp nz,siob_rxrdy_check  ; nope

                ; clear RTS as buffer nears full
                ld a,sio_reg5
                out (siob_command),a    ; select WR5
                ld a,sio_dtr+sio_tx_8bits+sio_tx_enable
                out (siob_command),a    ; write WR5

siob_rxrdy_check:
                ; check to see if more availble to read
                in a,(siob_command)     ; read RR0
                rrca
                jr c,siob_rxrdy_get     ; go if received char available

                pop hl
                pop af
                reti


        ;---------------------------------------------------------------
        ; SIO port B Receiver Error ISR
        ;
siob_rxerr:
                ei
                push af

                ; select RR 1
                ld a,sio_reg1
                out (siob_command),a

                ; read RR 1 for error bits
                in a,(siob_command)
                ld (serrb),a

                ; reset error latch
                ld a,sio_error_reset
                out (siob_command),a
                pop af
                reti


        ;---------------------------------------------------------------
        ; SIO port B Put Character
        ;
siob_putc:
                push hl
                ld a,(stcntb)           ; get num chars waiting
                or a                    ; is the buffer empty?
                jr nz,siob_putc_ring    ; nope -- go add to ring

                in a,(siob_command)     ; get register R0
                and sio_tx_buffer_empty ; can we transmit now?
                jr z,siob_putc_ring     ; nope -- go add to ring

                ld a,c                  ; get char to transmit
                out (siob_data),a       ; transmit it
                pop hl
                ret

siob_putc_ring:
                ld a,(stcntb)           ; get num chars waiting
                cp stbufb_size-1
                jr nc,siob_putc_ring    ; buffer full, keep trying

                di
                ld hl,stcntb
                inc (hl)                ; increment num waiting
                ld hl,(stinb)           ; get tail pointer
                ld (hl),c               ; put character into buffer
                ei

                inc l                   ; increment pointer
                ld a,stbufb_size-1      ; load buffer size (n^2)-1
                and l                   ; wrap if needed
                or low stbufb           ; offset to base
                ld l,a
                ld (stinb),hl           ; store new tail pointer

                pop hl
                ret

        ;---------------------------------------------------------------
        ; SIO port B Get Character
        ;
siob_getc:
                push hl
                ld a,(srcntb)           ; get num chars waiting
                ld l,a
                or a
                jp z,siob_getc_done

                cp srbufb_emptyish
                jp nz,siob_getc_get

                ; set RTS as buffer nears empty
                ld a,sio_reg5
                out (siob_command),a    ; select WR5
                ld a,sio_dtr+sio_tx_8bits+sio_tx_enable+sio_rts
                out (siob_command),a    ; write WR5

siob_getc_get:
                ld hl,(sroutb)          ; get ring head pointer
                ld a,(hl)               ; get the received char
                inc l                   ; update the tail (rolls over)
                ld (sroutb),hl          ; put the ring head pointer

                ld hl,srcntb
                dec (hl)                ; atomically update waiting count

                scf                     ; indicate char received

siob_getc_done:
                pop hl
                ret

ipsum:
                db "Lorem ipsum dolor sit amet, consectetur adipiscing elit,", $d, $a
                db "sed do eiusmod tempor incididunt ut labore et dolore", $d, $a
                db "magna aliqua. Ut enim ad minim veniam, quis nostrud", $d, $a
                db "exercitation ullamco laboris nisi ut aliquip ex ea", $d, $a
                db "commodo consequat. Duis aute irure dolor in reprehenderit", $d, $a
                db "in voluptate velit esse cillum dolore eu fugiat nulla", $d, $a
                db "pariatur. Excepteur sint occaecat cupidatat non proident,", $d, $a
                db "sunt in culpa qui officia deserunt mollit anim id est laborum.", $d, $a, 0

                .end