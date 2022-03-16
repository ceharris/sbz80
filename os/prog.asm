                .name prog

                .include memory.asm
                .include svcid.asm
                .include ports.asm
                .include adc.asm
                .include pio_defs.asm

adc_port        .equ adc0_ch2
blink_loops     .equ $100

uptime          .equ $4000
last_secs       .equ $4008
last_adc        .equ $4009
loop_cnt        .equ $400a
blinker         .equ $400c

kb_buf          .equ $4010
kb_cnt          .equ $401c
kb_size         .equ kb_cnt-kb_buf

                .cseg
prog::

                ld c,$4                 ; display on
                ld a,@lcctl
                rst $28

                ld iy,uptime

                ld hl,blink_loops
                ld (loop_cnt),hl
                xor a
                ld (kb_cnt),a

                ld (blinker),a

                dec a
                ld (last_secs),a
                ld (last_adc),a

loop:
                ld hl,(loop_cnt)
                dec hl
                ld (loop_cnt),hl
                ld a,l
                or h
                call z,blink

                call kb_read

                ld a,@tkrd32
                rst $28

                ld c,01010000b
                ld b,10000111b
                ld a,@l7pd32
                rst $28

                in a,(adc_port)
                ld c,a
                ld de,100
                ld a,@mm16x8
                rst $28
                ld a,(last_adc)
                cp h
                jr z,no_adc_change                
                
                ld a,h
                ld (last_adc),a
                ld bc,$0100
                ld a,@lcgoto
                rst $28

                ld l,h
                ld h,0
                ld a,@lcpd16
                rst $28

                ld c,'%'
                ld a,@lcputc
                rst $28

                ld c,' '
                ld a,@lcputc
                rst $28

no_adc_change:
                ld a,@tkrdut
                rst $28

                ld a,(last_secs)
                cp (iy+4)
                jp z,loop

                ld a,(iy+4)
                ld (last_secs),a

                ld bc,0
                ld a,@lcgoto
                rst $28

                ld l,(iy+0)
                ld h,(iy+1)
                ld a,@lcpd16
                rst $28

                ld hl,days
                ld a,@lcputs
                rst $28

                ld h,0
                ld l,(iy+2)
                ld a,l
                cp 10
                jp nc,nopad_hh
                ld c,'0'
                ld a,@lcputc
                rst $28
nopad_hh:
                ld a,@lcpd16
                rst $28

                ld c,':'
                ld a,@lcputc
                rst $28

                ld h,0
                ld l,(iy+3)
                ld a,l
                cp 10
                jp nc,nopad_mm
                ld c,'0'
                ld a,@lcputc
                rst $28
nopad_mm:
                ld a,@lcpd16
                rst $28

                ld c,':'
                ld a,@lcputc
                rst $28

                ld h,0
                ld l,(iy+4)
                ld a,l
                cp 10
                jp nc,nopad_ss
                ld c,'0'
                ld a,@lcputc
                rst $28
nopad_ss:
                ld a,@lcpd16
                rst $28

                ifdef BROKEN
                ; divide time by 100 to get seconds and hundredths
                ld c,100
                ld a,@md32x8
                rst $28

                ; display hundredths in a two-digit zero-padded field
                ; in digits 1..0
                push hl
                ld l,a
                ld c,00000000b
                ld b,00000001b
                ld a,@l7pd8
                rst $28
                pop hl

                ; divide time by 60 to get minutes and seconds
                ld c,60
                ld a,@md32x8
                rst $28

                ; display seconds in a two-digit zero-padded field
                ; with trailing decimal point in digits 3..2
                push hl
                ld l,a
                ld c,00010010b
                ld b,10000011b
                ld a,@l7pd8
                rst $28
                pop hl

                ; divide time by 60 to get hours and minutes
                ld c,60
                ld a,@md32x8
                rst $28

                ; display minutes in a two-digit zero-padded field
                ; with trailing decimal point in digits 5..4
                push hl
                ld l,a
                ld c,00100100b
                ld b,10000101b
                ld a,@l7pd8
                rst $28
                pop hl

                ; divide time by 24 to get days and hours
                ld c,24
                ld a,@md32x8
                rst $28

                ; display hours in a two-digit space-padded field
                ; with trailing decimal point in digits 7..6
                push hl
                ld l,a
                ld c,01110110b
                ld b,10000111b
                ld a,@l7pd8
                rst $28
                pop hl

                endif

                jp loop 

delay:
                dec de
                ld a,e
                or d
                jp nz,delay
                ret

kb_read:
                ld a,@kiread
                rst $28
                ret z
                ld c,a

                cp $1b
                jp nz,kb_read_05

                xor a
                ld (kb_cnt),a
                ld a,@lccls
                rst $28
                ret

kb_read_05:
                cp $20
                ret c

                ld a,(kb_cnt)
                cp kb_size
                jp z,kb_read_10
                inc a
                ld (kb_cnt),a
                ld hl,kb_buf-1
                add a,l
                ld l,a
                jp kb_read_20
kb_read_10:
                ld a,c
                ld bc,kb_size-1
                ld de,kb_buf
                ld hl,kb_buf+1
                ldir
                dec hl
                ld c,a
kb_read_20:
                ld (hl),c
kb_read_30:
                ld bc,$0104
                ld a,@lcgoto
                rst $28

                ld hl,kb_buf
                ld a,(kb_cnt)
                ld b,a
kb_read_40:
                ld a,(hl)
                jr c,kb_read_50
                ld c,a
                ld a,@lcputc
                rst $28
kb_read_50:
                inc hl
                djnz kb_read_40

                jp kb_read

blink:          
                ld a,(blinker)
                xor $1
                ld (blinker),a
                out (pio1_base+pio_port_a),a
                out (pio1_base+pio_port_b),a
                ld hl,blink_loops
                ld (loop_cnt),hl
                ret

days:           db "d ",0
