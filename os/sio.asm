
        ;---------------------------------------------------------------
        ; Serial I/O Support
        ;
        ; The system includes the standard Z80 SIO peripheral, which
        ; provides two fully independent serial interfaces. The SIO
        ; supports a asynchronous and synchronous modes with a variety
        ; of different protocols. However, this module provides support
        ; only for common asynchronous modes, with a single bit
        ; rate for both the tranmsit and receive directions.
        ;
        ; Each port may be configured for 5, 6, 7, or 8 bits, with
        ; 1, 1 1/2, or 2 stop bits, and parity none, even, or odd.
        ;
        ; Transmit and receive bit rates are derived from the system
        ; clock, operating at either 3.6864 MHz or 7.3728 MHz.
        ;
        ; Port A clock input is provided directly by the system clock.
        ; This provides a bit rate of either 115,200 or 230,400 using
        ; only the clock divider in the SIO channel. Configuration
        ; switch SW1 is used to select between the two possible speeds.
        ; Selection of the divisor is based on SW1 and SW2 (which
        ; provides the system clock speed).
        ;
        ;  SW1   Serial Clock  Divisor  Port A Bit Rate
        ;  ---   ------------  -------  ---------------
        ;  OFF     1.8432 MHz       32      57,600 bps
        ;  ON      1.8432 MHz       16     115,200 bps
        ;  OFF     3.6864 MHz       32     115,200 bps
        ;  ON      3.6864 MHz       16     230,400 bps
        ;
        ; Port B clock input is provided by the zero count output of
        ; a CTC channel operated in counter mode, and triggered by the
        ; serial clock. This allows the clock rate to vary based on
        ; the time constant for the channel. The following common bit
        ; rates are supported, based on the serial clock in use.
        ;
        ;            Port B Bit Rate    Port B Bit Rate
	;      TC   3.6864 MHz Clock   1.8432 MHz Clock
        ;      --   ----------------   ----------------
        ;       1       115,200 bps        57,600 bps
        ;       2        57,600 bps        28,800 bps
        ;       3        38,400 bps        19,200 bps
        ;       6        19,200 bps        9,600 bps
        ;      12         9,600 bps        4,800 bps
        ;      24         4,800 bps        2,400 bps
        ;      48         2,400 bps        1,200 bps
        ;      96         1,200 bps          600 bps
        ;
        ; To derive these rates, the SIO clock divisor is set to 16.
        ;
        ; SIO port A is a TTL serial interface which is terminated
        ; using an FTDI-type USB cable adapter. SIO port B is configured
        ; as a standard EIA/TIA 232 interface, on a 9-pin male D shell.
        ;---------------------------------------------------------------

                .name sio

                .extern isrtab
                .extern gpin
                .extern sacfg
                .extern sawr5
                .extern sarr0
                .extern sarr1
                .extern satxc
                .extern sarxc
                .extern satxh
                .extern satxt
                .extern sarxh
                .extern sarxt
                .extern sbcfg
                .extern sbwr5
                .extern sbrr0
                .extern sbrr1
                .extern sbtxc
                .extern sbrxc
                .extern sbtxh
                .extern sbtxt
                .extern sbrxh
                .extern sbrxt

                .include memory.asm
                .include ports.asm
                .include isr.asm
                .include ctc_defs.asm
                .include sio_defs.asm

sio_a_data      .equ sio0_base+sio_port_a
sio_a_command   .equ sio0_base+sio_port_a+sio_cfg
sio_b_data      .equ sio0_base+sio_port_b
sio_b_command   .equ sio0_base+sio_port_b+sio_cfg

sio_rx_emptyish .equ 32
sio_rx_fullish  .equ sio_rx_size - sio_rx_emptyish

sio_ctc_ch      .equ ctc0_ch0
sio_ctc_ctrl    .equ ctc_di+ctc_counter+ctc_falling+ctc_tc+ctc_ctrl


        ;---------------------------------------------------------------
        ; Time constants for the CTC channel used for port B
        ;
sio_tc_table:
                db 96                   ;   1,200 bps / 600 bps
                db 48                   ;   2,400 bps / 1,200 bps
                db 24                   ;   4,800 bps / 2,400 bps
                db 12                   ;   9,600 bps / 4,800 bps
                db 6                    ;  19,200 bps / 9,600 bps
                db 3                    ;  38,400 bps / 19,200 bps
                db 2                    ;  57,600 bps / 28,800 bps
                db 1                    ; 115,200 bps / 57,600 bps


        ;---------------------------------------------------------------
        ; sioini:
        ; Initializes the SIO module.
        ;
sioini::
                ; initialize interrupt vectors
                ld hl,sio_a_txrdy
                ld (isrtab+isr_sio0_a_txrdy),hl
                ld hl,sio_a_status
                ld (isrtab+isr_sio0_a_status),hl
                ld hl,sio_a_rxrdy
                ld (isrtab+isr_sio0_a_rxrdy),hl
                ld hl,sio_a_error
                ld (isrtab+isr_sio0_a_error),hl
                ld hl,sio_b_txrdy
                ld (isrtab+isr_sio0_b_txrdy),hl
                ld hl,sio_b_status
                ld (isrtab+isr_sio0_b_status),hl
                ld hl,sio_b_rxrdy
                ld (isrtab+isr_sio0_b_rxrdy),hl
                ld hl,sio_b_error
                ld (isrtab+isr_sio0_b_error),hl

                ; initialize port A configuration
                xor a
                ld (sacfg),a
                ld (sawr5),a
                ld (sarr0),a
                ld (sarr1),a
                ld (satxc),a
                ld (sarxc),a
                ld hl,satxbf
                ld (satxh),hl
                ld (satxt),hl
                ld hl,sarxbf
                ld (sarxh),hl
                ld (sarxt),hl

                ; mark port B as unconfigured
                xor a
                ld (sbcfg),a

                ; reset ports A and B
                ld a,sio_channel_reset
                out (sio_a_command),a
                out (sio_b_command),a
                nop
                nop

                ; select port B WR2
                ld a,sio_reg2
                out (sio_b_command),a

                ; port B WR2: set interrupt vector
                ld a,isrtab+isr_sio0_b_txrdy
                out (sio_b_command),a

                ; select port B WR1
                ld a,sio_reg1
                out (sio_b_command),a

                ; port B WR1: vary interrupt vector by status
                ld a,sio_vector_by_status
                out (sio_b_command),a

                ; determine port A clock divisor based on config switches
                ld c,sio_clock_x32
                ld a,(gpin)
                cpl
                and $40
                jr z,sioini_10          ; SW1=OFF => divisor 32
                ld c,sio_clock_x16	; SW1=ON  => divisor 16
sioini_10:
                ld a,(sio_rx_8bits>>2)+sio_stop_1bit+sio_parity_none
                or c                    ; include clock divisor bits

                ; initialize port A
                ld (sacfg),a
                ld c,sio_a_command
                call sio_init_port      ; initialize the port
                ld (sawr5),a            ; store the WR5 config mask

                ret


        ;---------------------------------------------------------------
        ; sbinit:
        ; Initializes serial port B.
        ;
        ; On entry:
        ;       B = speed
        ;         0 = 1,200 bps
        ;         1 = 2,400 bps
        ;         2 = 4,800 bps
        ;         3 = 9,600 bps
        ;         4 = 19,200 bps
        ;         5 = 38,400 bps
        ;         6 = 57,600 bps
        ;         7 = 115,200 bps
        ;       C = configuration
        ;         D7..D6 - don't care
        ;         D5..D4 - bits per character (5=00b, 7=01b, 6=10b, 8=11b)
        ;         D3..D2 - stop bits (1=01b, 1.5=10b, 2=11b)
        ;         D1..D0 - parity (None=00b, Even=01b, Odd=11b)
        ;       DE = pointer to 256-byte receive buffer
        ;       HL = pointer to 256-byte transmit buffer
        ;
        ; On return:
        ;       AF destroyed
        ;
sbinit::
                push bc
                push hl

                ; Initialize control structure
                xor a
                ld (sbrr0),a
                ld (sbrr1),a
                ld (sbtxc),a
                ld (sbrxc),a
                ld (sbtxh),hl
                ld (sbtxt),hl
                ex de,hl
                ld (sbrxh),hl
                ld (sbrxt),hl
                ex de,hl

                ld a,(gpin)
                cpl
                and $80
                ld a,c
                jr nz,sbinit_turbo

                ; set clock divisor to 16 for 3.6864 MHz system clock
                and $3f
                or $40
                jr sbinit_port

                ; set clock divisor to 32 for 7.3728 MHz system clock
sbinit_turbo:
                and $3f
                or $80

                ; initialize port B hardware
sbinit_port:
                ld (sbcfg),a
                ld c,sio_b_command
                call sio_init_port
                ld (sbwr5),a

                ; get CTC time constant for the speed
                ld hl,sio_tc_table
                ld c,b
                ld b,0
                add hl,bc

                ; configure CTC channel to drive tx/rx clock
                ld a,sio_ctc_ctrl
                out (sio_ctc_ch),a      ; send control word
                ld a,(hl)
                out (sio_ctc_ch),a      ; send time constant

                pop hl
                pop bc
                ret


        ;---------------------------------------------------------------
        ; saputc:
        ; Sends a character out via SIO port A.
        ;
        ; On entry:
        ;       C = character to send
        ;       HL destroyed
        ;
saputc::
                di
                ld a,(satxc)            ; get num chars waiting
                or a                    ; is the buffer empty?
                jr nz,saputc_ring       ; nope -- go add to ring

                in a,(sio_a_command)    ; get register R0
                and sio_tx_buffer_empty ; can we transmit now?
                jr z,saputc_ring        ; nope -- go add to ring

                ld a,c                  ; get char to transmit
                out (sio_a_data),a      ; transmit it
                ei
                ret

saputc_again:
                ei
saputc_ring:
                ld a,(satxc)            ; get num chars waiting
                cp sio_a_tx_size-1
                jr nc,saputc_again      ; buffer full, keep trying

                ld hl,satxc
                di
                inc (hl)                ; increment num waiting
                ld hl,(satxt)           ; get tail pointer
                ld (hl),c               ; put character into buffer
                ei

                inc l                   ; increment pointer
                ld a,sio_a_tx_size-1    ; load buffer size (n^2)-1
                and l                   ; wrap if needed
                or low satxbf           ; offset to base
                ld l,a
                ld (satxt),hl           ; store new tail pointer

                ret

        ;---------------------------------------------------------------
        ; sagetc:
        ; Gets a character received from SIO port A.
        ;
        ; On return:
        ;       if C flag set, A contains a received character
        ;       HL destroyed
        ;
sagetc::
                ld a,(sarxc)            ; get num chars waiting
                or a
                jp nz,sagetc_cont
                ret

sagetc_cont:
                cp sio_rx_emptyish      ; is the buffer kinda empty?
                jp nz,sagetc_get

                ; assert RTS as buffer nears empty
                ld a,sio_reg5
                out (sio_a_command),a   ; select WR5
                ld a,(sawr5)            ; get WR5 mask
                or sio_rts              ; set RTS
                out (sio_a_command),a   ; write WR5

sagetc_get:
                ld hl,(sarxh)           ; get ring head pointer
                ld a,(hl)               ; get the received char
                inc l                   ; update the head (rolls over)
                ld (sarxh),hl           ; put the ring head pointer

                ld hl,sarxc
                dec (hl)                ; atomically update waiting count

                scf                     ; indicate char received
                ret


        ;---------------------------------------------------------------
        ; sapoll:
        ; Tests whether port A has received characters available.
        ;
        ; On return:
        ;       A = number of characters waiting
        ;       Z flag reflects count
        ;
sapoll::
                ld a,(sarxc)            ; get num chars waiting
                or a
                ret


        ;---------------------------------------------------------------
        ; saflsh:
        ; Flushes all pending input from port A.
saflsh::
                di
                xor a
                ld (sarxc),a            ; set count to zero
                ld (sarr1),a            ; zero any error flag
                ld hl,(sarxh)           ; make the head and tail equal
                ld (sarxt),hl
                ei
                ret


        ;---------------------------------------------------------------
        ; sbputc:
        ; Sends a character out via SIO port B.
        ;
        ; On entry:
        ;       C = character to send
        ;       HL destroyed
        ;
sbputc::
                di
                ld a,(sbtxc)            ; get num chars waiting
                or a                    ; is the buffer empty?
                jr nz,sbputc_ring       ; nope -- go add to ring

                in a,(sio_b_command)    ; get register R0
                and sio_tx_buffer_empty ; can we transmit now?
                jr z,sbputc_ring        ; nope -- go add to ring

                ld a,c                  ; get char to transmit
                out (sio_b_data),a      ; transmit it
                ei
                ret

sbputc_again:
                ei
sbputc_ring:
                ld a,(sbtxc)            ; get num chars waiting
                cp sio_a_tx_size-1
                jr nc,sbputc_again      ; buffer full, keep trying

                ld hl,sbtxc
                di
                inc (hl)                ; increment num waiting
                ld hl,(sbtxt)           ; get tail pointer
                ld (hl),c               ; put character into buffer
                ei

                inc l                   ; increment pointer (rolls over)
                ld l,a
                ld (sbtxt),hl           ; store new tail pointer
                ret

        ;---------------------------------------------------------------
        ; sbgetc:
        ; Gets a character received from SIO port B.
        ;
        ; On return:
        ;       if C flag set, A contains a received character
        ;       HL destroyed
        ;
sbgetc::
                ld a,(sbrxc)            ; get num chars waiting
                or a
                jp nz,sbgetc_cont
                ret

sbgetc_cont:
                cp sio_rx_emptyish      ; is the buffer kinda empty?
                jp nz,sbgetc_get

                ; assert RTS as buffer nears empty
                ld a,sio_reg5
                out (sio_b_command),a   ; select WR5
                ld a,(sbwr5)            ; get WR5 mask
                or sio_rts              ; set RTS
                out (sio_b_command),a   ; write WR5

sbgetc_get:
                ld hl,(sbrxh)           ; get ring head pointer
                ld a,(hl)               ; get the received char
                inc l                   ; update the tail (rolls over)
                ld (sbrxh),hl           ; put the ring head pointer

                ld hl,sbrxc
                dec (hl)                ; atomically update waiting count

                scf                     ; indicate char received
                ret


        ;---------------------------------------------------------------
        ; sbpoll:
        ; Tests whether port B has received characters available.
        ;
        ; On return:
        ;       A = number of characters waiting
        ;       Z flag reflects count
        ;
sbpoll::
                ld a,(sbrxc)            ; get num chars waiting
                or a
                ret

        ;---------------------------------------------------------------
        ; sbflsh:
        ; Flushes all pending input from port B.
sbflsh::
                di
                xor a
                ld (sbrxc),a            ; set count to zero
                ld (sbrr1),a            ; zero any error flag
                ld hl,(sbrxh)           ; make the head and tail equal
                ld (sbrxt),hl
                ei
                ret


        ;---------------------------------------------------------------
        ; sio_init_port:
        ; Initialize a serial port.
        ;
        ; On entry:
        ;       A = configuration
        ;         D7..D6 - clock divisor (1=00b, 16=01b, 32=10b, 64=11b)
        ;         D5..D4 - bits per character (5=00b, 7=01b, 6=10b, 8=11b)
        ;         D3..D2 - stop bits (1=01b, 1.5=10b, 2=11b)
        ;         D1..D0 - parity (None=00b, Even=01b, Odd=11b)
        ;       C = target SIO command port address
        ;
        ; On return:
        ;       A = WR5 configuration mask
        ;
sio_init_port:
                push bc
                ld b,a                  ; save configuration

                ; select SIO WR4
                ld a,sio_reg4
                out (c),a

                ; SIO WR4: async mode with divisor, stop bits, parity
                ld a,b
                and $cf
                out (c),a

                ; select SIO WR3
                ld a,sio_reg3
                out (c),a

                ; get bits per character into D7..D6
                ld a,b
                rlca
                rlca
                and $c0

                ; SIO WR3: receiver enable, auto enables, with bits
                or sio_rx_enable+sio_rx_auto_enables
                out (c),a

                ; select SIO WR5
                ld a,sio_reg5
                out (c),a

                ; get bits per character into D6..D5
                ld a,b
                rlca
                and $60

                ; SIO WR5: tranmitter enable, assert DTR and RTS, specify tx bits
                or sio_tx_enable+sio_dtr+sio_rts
                ld b,a                  ; save WR5 config for return to caller
                out (c),a

                ; select SIO WR1
                ld a,sio_reg1
                out (c),a

                ; SIO WR1: enable interrrupts
                ld a,sio_rx_int_all+sio_tx_int_enable+sio_ext_int_enable+sio_vector_by_status
                out (c),a

                ld a,b                  ; return WR5 config
                pop bc

                ret

        ;---------------------------------------------------------------
        ; ISR: SIO port A transmitter ready
        ;
sio_a_txrdy:
                ei
                push af

                ld a,(satxc)            ; get num chars waiting
                or a
                jr z,sio_a_txrdy_reset

                push hl
                ld hl,(satxh)           ; get ring head pointer
                ld a,(hl)               ; get char to transmit
                out (sio_a_data),a      ; transmit it

                inc l                   ; update the head pointer
                ld a,sio_a_tx_size-1    ; load buffer size (n^2)-1
                and l                   ; wrap if needed
                or low satxbf           ; offset to base
                ld l,a
                ld (satxh),hl           ; put new ring head pointer

                ld hl,satxc
                dec (hl)                ; atomically decrement num waiting
                pop hl

                jr nz,sioa_txrdy_end    ; go if ring not empty

sio_a_txrdy_reset:

                ld a,sio_reset_tx_int   ; command to reset tx ready interrupt
                out (sio_a_command),a   ; write command to WR0

sioa_txrdy_end:
                pop af
                reti


        ;---------------------------------------------------------------
        ; ISR: SIO port A transmitter status change
        ;
sio_a_status:
                ei
                push af

                ; read and store RR0 for status bits
                in a,(sio_a_command)
                ld (sarr0),a

                ; reset interrupt latch
                ld a,sio_reset_ext_stat_int
                out (sio_a_command),a

                pop af
                reti


        ;---------------------------------------------------------------
        ; ISR: SIO port A received character available
        ;
sio_a_rxrdy:
                ei
                push af
                push hl

sio_a_rxrdy_get:
                in a,(sio_a_data)       ; get the received char
                ld l,a                  ; preserve it

                ld a,(sarxc)            ; get num chars waiting
                cp sio_rx_size-1        ; is there room for another
                jr nc,sio_a_rxrdy_check ; nope...

                ld a,l                  ; recover received char
                ld hl,(sarxt)           ; get ring tail pointer
                ld (hl),a               ; put received char in buf
                inc l                   ; increment pointer (rolls over)
                ld (sarxt),hl           ; put ring tail pointer
                ld hl,sarxc
                inc (hl)                ; atomically update waiting count

                ld a,(sarxt)            ; get new waiting count
                cp sio_rx_fullish       ; is getting kinda full?
                jp nz,sio_a_rxrdy_check ; nope

                ; clear RTS as buffer nears full
                ld a,sio_reg5
                out (sio_a_command),a   ; select WR5
                ld a,(sawr5)
                and ~sio_rts
                out (sio_a_command),a   ; write WR5

sio_a_rxrdy_check:
                ; check to see if more availble to read
                in a,(sio_a_command)    ; read RR0
                rrca
                jr c,sio_a_rxrdy_get    ; go if received char available

                pop hl
                pop af
                reti


        ;---------------------------------------------------------------
        ; ISR: SIO port A receiver error
        ;
sio_a_error:
                ei
                push af

                ; select RR 1
                ld a,sio_reg1
                out (sio_a_command),a

                ; read RR 1 and store RR 1 for error bits
                in a,(sio_a_command)
                ld (sarr1),a

                ; reset error latch
                ld a,sio_error_reset
                out (sio_a_command),a

                pop af
                reti


        ;---------------------------------------------------------------
        ; ISR: SIO port B transmitter ready
        ;
sio_b_txrdy:
                ei
                push af

                ld a,(sbtxc)            ; get num chars waiting
                or a
                jr z,sio_b_txrdy_reset

                push hl
                ld hl,(sbtxh)           ; get ring head pointer
                ld a,(hl)               ; get char to transmit
                out (sio_b_data),a      ; transmit it
                inc l                   ; update head pointer (rolls over)
                ld (sbtxh),hl           ; put new ring head pointer

                ld hl,sbtxc
                dec (hl)                ; atomically decrement num waiting
                pop hl

                jr nz,sio_b_txrdy_end    ; go if ring not empty

sio_b_txrdy_reset:

                ld a,sio_reset_tx_int   ; command to reset tx ready interrupt
                out (sio_b_command),a   ; write command to WR0

sio_b_txrdy_end:
                pop af
                reti


        ;---------------------------------------------------------------
        ; ISR: SIO port B transmitter status change
        ;
sio_b_status:
                ei
                push af

                ; read and store RR0 for status bits
                in a,(sio_b_command)
                ld (sbrr0),a

                ; reset interrupt latch
                ld a,sio_reset_ext_stat_int
                out (sio_b_command),a

                pop af
                reti


        ;---------------------------------------------------------------
        ; ISR: SIO port B received character available
        ;
sio_b_rxrdy:
                ei
                push af
                push hl

sio_b_rxrdy_get:
                in a,(sio_b_data)       ; get the received char
                ld l,a                  ; preserve it

                ld a,(sbrxc)            ; get num chars waiting
                cp sio_rx_size-1        ; is there room for another
                jr nc,sio_b_rxrdy_check ; nope...

                ld a,l                  ; recover received char
                ld hl,(sbrxt)           ; get ring tail pointer
                ld (hl),a               ; put received char in buf
                inc l                   ; increment pointer (rolls over)
                ld (sbrxt),hl           ; put ring tail pointer
                ld hl,sbrxc
                inc (hl)                ; atomically update waiting count

                ld a,(sbrxt)            ; get new waiting count
                cp sio_rx_fullish       ; is getting kinda full?
                jp nz,sio_b_rxrdy_check ; nope

                ; clear RTS as buffer nears full
                ld a,sio_reg5
                out (sio_b_command),a   ; select WR5
                ld a,(sbwr5)
                and ~sio_rts
                out (sio_b_command),a   ; write WR5

sio_b_rxrdy_check:
                ; check to see if more availble to read
                in a,(sio_b_command)    ; read RR0
                rrca
                jr c,sio_b_rxrdy_get    ; go if received char available

                pop hl
                pop af
                reti


        ;---------------------------------------------------------------
        ; ISR: SIO port B receiver error
        ;
sio_b_error:
                ei
                push af

                ; select RR 1
                ld a,sio_reg1
                out (sio_b_command),a

                ; read RR 1 and store RR 1 for error bits
                in a,(sio_b_command)
                ld (sbrr1),a

                ; reset error latch
                ld a,sio_error_reset
                out (sio_b_command),a

                pop af
                reti


                .end
