        ;---------------------------------------------------------------
        ; Keyboard Input Module
        ; 
        ; The keyboard hardward interface is compatible with a PS/2 
        ; keyboard. The interface consists of a shift register and
        ; supporting logic to read 8-bit keyboard scan codes and
        ; status codes. The shift register is connected to pio0 port A
        ; operating in PIO mode 1. Each time that a valid keyboard
        ; input is received, the contents of the shift register are
        ; strobed into the PIO port, and a CPU interrupt is signaled.
        ;
        ; This module provides the interrupt service routine that 
        ; reads keyboard inputs and translates scan codes and status
        ; bytes into ASCII control/character codes. Additionally, it 
        ; maintains a bit set that reflects the state of each key,
        ; providing the means for a user program to use sophisticated
        ; key press to function mappings.
        ;---------------------------------------------------------------

                .name ki

                .include memory.asm
                .include ports.asm
                .include isr.asm
                .include pio_defs.asm

ki_port         .equ pio0_base+pio_port_a
ki_port_isr     .equ isr_pio0_a

kb_ok           .equ $aa
kb_extended     .equ $e0
kb_release      .equ $f0
kb_err          .equ $fc
kb_resend       .equ $fe

kb_shift_l      .equ $12
kb_shift_r      .equ $59
kb_ctrl_l       .equ $14
kb_opt_l        .equ $11

kb_e_ctrl_r     .equ $14
kb_e_opt_r      .equ $11
kb_e_cmd_l      .equ $1f
kb_e_cmd_r      .equ $27

        ; Definitions for kiflag
f_extended      .equ $01
f_release       .equ $02

        ; Definitions for kimod
m_shift_l       .equ $01
m_shift_r       .equ $02
m_shift         .equ m_shift_l|m_shift_r
m_ctrl_l        .equ $04
m_ctrl_r        .equ $08
m_ctrl          .equ m_ctrl_l|m_ctrl_r
m_opt_l         .equ $10
m_opt_r         .equ $20
m_opt           .equ m_opt_l|m_opt_r
m_cmd_l         .equ $40
m_cmd_r         .equ $80
m_cmd           .equ m_cmd_l|m_cmd_r

                .cseg

        ;---------------------------------------------------------------
        ; kiinit:
        ; Initialize the keyboard interface.
        ;
kiinit::
                ; initialize ring buffer
                ld hl,kiring
                ld (kihead),hl
                ld (kitail),hl

                ; initialize flags and BAT code
                xor a
                ld (kiflag),a
                ld (kimod),a
                ld (kibat),a

                ; Set interrupt vector
                ld hl,isrtab+ki_port_isr
                ld (hl),low(kiisr)
                inc hl
                ld (hl),high(kiisr)

                ; enable PIO 0 port A interrupts
                ld a,pio_ictl_ei+pio_ictl_word
                out (ki_port+pio_cfg),a

                ; priming read
                in a,(ki_port)
                ret


        ;---------------------------------------------------------------
        ; Keyboard interrupt service routine
        ;
kiisr:
                ei
                push af
                push bc
                push hl

                in a,(ki_port)          ; read the input
                ld b,a                  ; save it

                cp kb_ok                ; is it the OK BAT code?
                jp z,kiisr_80
                cp kb_err               ; is is the ERROR BAT code?
                jp z,kiisr_80
                cp kb_resend            ; is it a resend request?
                jp z,kiisr_90

                cp kb_extended          ; extended scan code next?
                jr nz,kiisr_10          ; go if not extended
                ld a,(kiflag)
                or f_extended
                ld (kiflag),a
                jp kiisr_90
kiisr_10:
                cp kb_release           ; key release next?
                jr nz,kiisr_20          ; go if not key release
                ld a,(kiflag)
                or f_release
                ld (kiflag),a
                jp kiisr_90
kiisr_20:
                ld a,(kiflag)
                ld c,a
                and f_release           ; is it a key release?
                jr z,kiisr_30

                ; clear the release flag
                ld a,c
                and ~f_release
                ld (kiflag),a
                ld c,a

                and f_extended          ; releasing an extended key?
                jr nz,kiisr_rel_ext

                ; check for release of non-extended modifier
                ld a,b                  ; recover scan code
                ld c,~m_shift_l        
                cp kb_shift_l           ; is it left shift?
                jr z,kiisr_rel_mod
                ld c,~m_shift_r 
                cp kb_shift_r           ; is it right shift?
                jr z,kiisr_rel_mod
                ld c,~m_ctrl_l
                cp kb_ctrl_l            ; is it left ctrl?
                jr z,kiisr_rel_mod
                ld c,~m_opt_l
                cp kb_opt_l             ; is it left option/alt?
                jr z,kiisr_rel_mod
                jp kiisr_90             ; ignore other key release

kiisr_rel_ext:
                ; clear the extended flag
                ld a,c
                and ~f_extended
                ld (kiflag),a

                ; check for release of extended modifier
                ld a,b
                ld c,~m_ctrl_r
                cp kb_e_ctrl_r          ; is it right control?
                jr z,kiisr_rel_mod
                ld c,~m_ctrl_r
                cp kb_e_opt_r           ; is it right option/alt?
                jr z,kiisr_rel_mod
                ld c,~m_cmd_l
                cp kb_e_cmd_l           ; is it left command?
                jr z,kiisr_rel_mod
                ld c,low ~m_cmd_r
                cp kb_e_cmd_r           ; is it right command?
                jr z,kiisr_rel_mod
                jp kiisr_90             ; ignore other key release

kiisr_rel_mod:
                ; clear modifier bit
                ld a,(kimod)
                and c
                ld (kimod),a
                jp kiisr_90

kiisr_30:
                ld a,c
                and f_extended          ; pressing an extended key?
                jr nz,kiisr_ext

                ld a,b                  ; recover scan code
                ld c,m_shift_l        
                cp kb_shift_l           ; is it left shift?
                jr z,kiisr_mod
                ld c,m_shift_r 
                cp kb_shift_r           ; is it right shift?
                jr z,kiisr_mod
                ld c,m_ctrl_l
                cp kb_ctrl_l            ; is it left ctrl?
                jr z,kiisr_mod
                ld c,m_opt_l
                cp kb_opt_l             ; is it left option/alt?
                jr z,kiisr_mod

                ; translate normal key code
                ld a,(kimod)            ; get modifiers
                ld c,a                  ; preserve 'em
                ld hl,xlt_no_mod
                or a                    ; any modifier?
                jr z,kiisr_40
                ld hl,xlt_shift_mod
                and m_shift             ; shift modifier?
                jr nz,kiisr_40
                ld a,c
                ld hl,xlt_ctrl_mod
                and m_ctrl              ; ctrl modifier?
                jr nz,kiisr_40
                jr kiisr_90             ; ignore when other modifier

kiisr_ext:
                ld a,c
                and ~f_extended         ; clear the extended flag
                ld (kiflag),a

                ; check for press of extended modifier
                ld a,b
                ld c,m_ctrl_r
                cp kb_e_ctrl_r          ; is it right control?
                jr z,kiisr_mod
                ld c,m_ctrl_r
                cp kb_e_opt_r           ; is it right option/alt?
                jr z,kiisr_mod
                ld c,m_cmd_l
                cp kb_e_cmd_l           ; is it left command?
                jr z,kiisr_mod
                ld c,m_cmd_r
                cp kb_e_cmd_r           ; is it right command?
                jr z,kiisr_mod
                jr kiisr_90             ; ignore other extended key press

kiisr_mod:
                ; set modifier bit
                ld a,(kimod)
                or c
                ld (kimod),a
                jr kiisr_90

kiisr_40:
                ; point HL to the translated code
                ld a,l
                add b
                ld l,a
                ld a,h
                adc 0
                ld h,a

                ; get the tranlated code
                ld a,(hl)
                or a
                jr z,kiisr_90           ; ignore if undefined translation
                ld b,a                  ; save translated input

                ld hl,(kitail)          ; HL -> input ring tail
                ld c,l                  ; save LSB
                inc l                   ; next position
                ld a,l
                and kiring_size-1       ; do we need to wrap?
                jr nz,kiisr_70          ; nope...
                ld l,low(kiring)        ; wrap to the beginning
kiisr_70:
                ld a,(kihead)           ; get the current head
                cp l                    ; would we overrun?
                jr z,kiisr_90           ; yep...

                ld (kitail),hl          ; save the new tail
                ld l,c                  ; now recover where we were
                ld (hl),b               ; store the input
                jr kiisr_90              

kiisr_80:
                ld (kibat),a            ; store a BAT code
kiisr_90:
                pop hl
                pop bc
                pop af
                reti

        ;---------------------------------------------------------------
        ; kiread:
        ; Reads the next keyboard input event if available
        ;
        ; On return:
        ;       NZ: A = keyboard input event
        ;       Z: no event available
        ;
kiread::
                push bc
                push hl
                ld hl,(kihead)          ; HL -> input ring head
                ld a,(kitail)           ; A = ring tail LSB
                cp l                    ; is the ring empty?
                jr z,kiread_20          ; yep...

                ld c,(hl)               ; get the event at head
                inc l                   ; update head pointer
                ld a,l                   
                and kiring_size-1       ; do we need to wrap?
                jr nz,kiread_10         ; nope...
                ld l,low(kiring)        ; wrap to beginning
kiread_10:
                ld (kihead),hl          ; save new head
                or 1                    ; set NZ
                ld a,c                  ; return event in A

kiread_20:
                pop hl
                pop bc
                ret

xlt_no_mod:
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$09,$60,$00
                db      $00,$00,$00,$00,$00,$71,$31,$00
                db      $00,$00,$7a,$73,$61,$77,$32,$00
                db      $00,$63,$78,$64,$65,$34,$33,$00
                db      $00,$20,$76,$66,$74,$72,$35,$00
                db      $00,$6e,$62,$68,$67,$79,$36,$00
                db      $00,$00,$6d,$6a,$75,$37,$38,$00
                db      $00,$2c,$6b,$69,$6f,$30,$39,$00
                db      $00,$2e,$2f,$6c,$3b,$70,$2d,$00
                db      $00,$00,$27,$00,$5b,$3d,$00,$00
                db      $00,$00,$0d,$5d,$00,$5c,$00,$00
                db      $00,$00,$00,$00,$00,$00,$08,$00
                db      $00,$31,$00,$34,$37,$00,$00,$00
                db      $30,$2e,$32,$35,$36,$38,$1b,$00
                db      $00,$2b,$33,$2d,$2a,$39,$00,$00
xlt_shift_mod:
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$7e,$00
                db      $00,$00,$00,$00,$00,$51,$21,$00
                db      $00,$00,$5a,$53,$41,$57,$40,$00
                db      $00,$43,$58,$44,$45,$24,$23,$00
                db      $00,$00,$56,$46,$54,$52,$25,$00
                db      $00,$4e,$42,$48,$47,$59,$5e,$00
                db      $00,$00,$4d,$4a,$55,$26,$2a,$00
                db      $00,$3c,$4b,$49,$4f,$29,$28,$00
                db      $00,$3e,$3f,$4c,$3a,$50,$5f,$00
                db      $00,$00,$22,$00,$7b,$2b,$00,$00
                db      $00,$00,$00,$7d,$00,$7c,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
xlt_ctrl_mod:
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$11,$00,$00
                db      $00,$00,$1a,$13,$01,$17,$00,$00
                db      $00,$03,$18,$04,$05,$00,$00,$00
                db      $00,$00,$16,$06,$14,$12,$00,$00
                db      $00,$0e,$02,$08,$07,$19,$00,$00
                db      $00,$00,$0d,$0a,$15,$00,$00,$00
                db      $00,$00,$0b,$09,$0f,$00,$00,$00
                db      $00,$00,$00,$0c,$00,$10,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00
                db      $00,$00,$00,$00,$00,$00,$1b,$00
                db      $00,$00,$00,$00,$00,$00,$00,$00

                .end

