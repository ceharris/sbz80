        ;---------------------------------------------------------------
        ; Tick Counter
        ;
        ; The tick counter provides a measure of elapsed time that is
        ; based on a periodic interrupts from ctc0 channel 3. The choice
        ; of channel 3 is based on the fact that due to package
        ; constraints of the CTC component, channel 3 has no zero count
        ; output (ZC/TC pin) that could be used for timing another
        ; hardware device.
        ;
        ; Based on a system clock of 3.6864 MHz, ctc0 channel 3 can be
        ; configured to use the timer mode with the prescaler set to
        ; 256 and the time constant set to 144 to arrive at a timer
        ; frequency of 100 Hz.
        ;
        ;       period  = TC * pre_scaler / clock rate
        ;               = 144 * 256 / 3.6864 MHz
        ;               = 10,000 microseconds
        ;               = 10 milliseconds
        ;       frequency = 1 / period = 1 / 0.01 seconds = 100 Hz
        ;
        ; This choice of time constant isn't ideal, however, because it 
        ; doesn't allow the same firmware to be used with a 7.3728 MHz (2x) 
        ; clock while requiring only a configuration change via a switch.
        ; If we double the time constant, the result will not fit in the
        ; 8-bit register of the CTC. We therefore instead choose 72 as
        ; the time constant with a 3.6864 MHz clock, resulting in a timer
        ; frequency of 200 Hz. When the clock speed is doubled, we
        ; also double the time constant to 144, to arrive at the same 
        ; timer frequency.
        ;
        ; We divide the timer frequency by 2 using a flag that
        ; is complemented at each timer interrupt, incrementing the 
        ; 32-bit tkcnt variable in system memory  each time the flag
        ; is set to zero (at every other interrupt). This allows the 
        ; tick counter to reflect the desired 100 Hz tick frequency.
        ;---------------------------------------------------------------

                .name tk

                .extern gpin
                .extern isrtab
                .extern tkcnt
                .extern tkflag

                .extern d32x8

                .include memory.asm
                .include ports.asm
                .include isr.asm
                .include ctc_defs.asm

tk_ctc_ctrl     .equ ctc_ei+ctc_timer+ctc_pre256+ctc_falling+ctc_tc+ctc_ctrl

tk_ctc_tc       .equ 72                ; time constant (pre-scale=256)
tk_ctc_ch	.equ ctc0_ch3
tk_ctc_isr	.equ isr_ctc0_ch3

tk_5ms_flag     .equ $1

                .cseg

        ;---------------------------------------------------------------
        ; tkinit:
        ; Initializes the tick counter and sets up ctc0 channel 3.
        ;
tkinit::
                ; zero out the flag and the counter
                xor a
                ld (tkflag),a
                ld hl,tkcnt
                ld b,4
tkinit_10:
                ld (hl),a
                inc hl
                djnz tkinit_10

                ; Set interrupt vector
                ld hl,isrtab+tk_ctc_isr
                ld (hl),low(tkisr)
                inc hl
                ld (hl),high(tkisr)

                ld c,tk_ctc_tc          ; time constant for "normal" clock
                ld a,(gpin)             ; get config switch positions        
                rla                     ; put "turbo" switch into carry
                jr c,tkinit_20          ; "normal" when switch is set to 1
                rl c                    ; double time constant for "turbo"
tkinit_20:
                ; configure CTC channel
                ld a,tk_ctc_ctrl
                out (tk_ctc_ch),a       ; output control word
                ld a,c
                out (tk_ctc_ch),a       ; output time constant

                ret

        ;---------------------------------------------------------------
        ; tkisr:
        ; Tick count interrupt service routine.
        ;
        ; This ISR increments the 32-bit `tkcnt` variable defined in
        ; memory.asm each time that ctc0 channel 3 interrupts the CPU.
        ;
tkisr::
                ei
                push af
                push hl

                ; use a 1 flag to divide timer frequency by 2
                ld a,(tkflag)
                xor tk_5ms_flag
                ld (tkflag),a
                ; skip counter update at every other interrupt
                and tk_5ms_flag
                jr nz,tkisr_10             

                ld hl,tkcnt                     ; HL -> 32-bit counter

                inc (hl)                        ; increment 1st byte
                jr nz,tkisr_10                  ; go if no ripple

                inc hl                          ; ripple into 2nd byte
                inc (hl)                        ; increment it
                jr nz,tkisr_10                  ; go if no ripple

                inc hl                          ; ripple into 3rd byte
                inc (hl)                        ; increment it
                jr nz,tkisr_10                  ; go if no ripple

                inc hl                          ; ripple into 4th byte
                inc (hl)                        ; increment it
tkisr_10:
                pop hl
                pop af
                reti

        ;---------------------------------------------------------------
        ; tkrd16:
        ; Reads the least significant 16 bits of the tick counter. This
        ; function is useful for relatively short interval measurement.
        ;
        ; On return:
        ;       HL = least significant 16 bits of the tick counter
        ;
tkrd16::
                push de
                ld hl,tkcnt
                di
                ld e,(hl)
                inc hl
                ld d,(hl)
                ei
                ex de,hl
                pop de
                ret

        ;---------------------------------------------------------------
        ; tkrd32:
        ; Reads the 32-bit tick counter.
        ;
        ; On return:
        ;       DEHL = 32-bit tick counter
        ;
tkrd32::
                push bc
                ld hl,tkcnt
                di
                ld c,(hl)
                inc hl
                ld b,(hl)
                inc hl
                ld e,(hl)
                inc hl
                ld d,(hl)
                ei
                ld l,c
                ld h,b
                pop bc
                ret

        ;---------------------------------------------------------------
        ; tkrdut:
        ; Converts the tick count into a system uptime in a caller-
        ; provided buffer.
        ;
        ; On entry:
        ;       IY = caller's 6-byte buffer for the result
        ;
        ; On return:
        ;       AF is destroyed
        ;
        ;       Caller's buffer is updated with system uptime as follows:
        ;       buf+0 = days (2 bytes, unsigned integer)
        ;       buf+2 = hours (1 byte, 0..23)
        ;       buf+3 = minutes (1 byte, 0..59)
        ;       buf+4 = seconds (1 byte, 0..59)
        ;       buf+5 = hundreds (1 byte, 0..99)
        ;
tkrdut::
                push bc
                push de
                push hl

                ; load DEHL with the 32-bit counter
                ld hl,tkcnt
                di
                ld c,(hl)
                inc hl
                ld b,(hl)
                inc hl
                ld e,(hl)
                inc hl
                ld d,(hl)
                ei
                ld l,c
                ld h,b

                ; divide hundreths by 100 to get seconds with
                ; hundredths as the remainder
                ld c,100
                call d32x8              ; DEHL is now seconds
                ld (iy+5),a             ; store hundredths

                ; divide seconds by 60 to get minutes with
                ; seconds as the remainder
                ld c,60
                call d32x8              ; DEHL is now minutes
                ld (iy+4),a             ; store seconds

                ; divide minutes by 60 to get hours with
                ; minutes as the remainder
                call d32x8              ; DEHL is now hours
                ld (iy+3),a             ; store minutes

                ; divide hours by 24 to get days with
                ; hours as the remainder
                ld c,24
                call d32x8              ; HL is now days
                ld (iy+2),a             ; store hours

                ; store days
                ld (iy+0),l
                ld (iy+1),h

                pop hl
                pop de
                pop bc
                ret


                .end
