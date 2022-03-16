
SCLK            .equ $40
MOSI            .equ $80

IO_REG          .equ $10
SPI_ADDR_REG    .equ $f0
SPI_CS          .equ $08
L7_DISP_ADDR    .equ $07

MODE_REG        .equ $00
MODE            .equ $80

RAM_TOP         .equ $e000
ROM_TOP         .equ $10000

MADDR           .equ $100
MLEN            .equ RAM_TOP - MADDR

BLUE            .equ $01
WHITE           .equ $02


tcount          .equ $40
tfail           .equ $43
taddr           .equ $44
tpat:           .equ $46
tact:           .equ $48
tled:           .equ $50


blink           macro cnt
                local bloop,bdelay
                ld b,cnt
                ld c,$02
bloop:
                ld a,c
                xor $03
                ld c,a
                out (IO_REG),a
                ld de,0
bdelay:
                dec de
                ld a,e
                or d
                jp nz,bdelay
                djnz bloop
                endm


                .aseg
                .org RAM_TOP

                jp start
start:
                xor a
                out (MODE_REG),a

                ld sp,RAM_TOP
                ld a,$0
                out (SPI_ADDR_REG),a

                ld a,BLUE
                ld (tled),a
                out (IO_REG),a

                ; test display
                ld hl,$0f01
                call spi
                ld de,0
                call delay

                ; normal display
                ld hl,$0f00
                call spi
                ld de,0
                call delay

                ; clear all digits
                ld b,8
                ld h,1
                ld l,0
ssclear:
                call spi
                inc h
                djnz ssclear

                ; no input decode
                ld hl,$0900
                call spi

                ; max intensity
                ld hl,$0a0f
                call spi

                ; scan all digits
                ld hl,$0b07
                call spi

                ; normal operation
                ld hl,$0c01
                call spi

                ; normal display
                ld hl,$0f00
                call spi

mrst:
                xor a
                ld l,a
                ld h,a
                ld (tcount),hl
                ld (tcount+2),a
                ld (tfail),a
                ld (taddr),hl
                ld (tpat),a
                ld (tact),a

                ld ix,pats              ; IX -> test patterns
                ld de,0                 ; D = number of errors, E = test count
                ld hl,0                 ; last error address
mtest:
                ld a,BLUE
                ld (tled),a
                ld a,(tled)
                out (IO_REG),a

;               in a,(IO_REG)
;               and $10
;               jp nz,mrst

                exx

                ; fill memory with pattern
                ld a,(ix)               ; Fetch the pattern
                ld hl,MADDR             ; HL -> start of RAM
                ld bc,MLEN - 1          ; BC = one less than RAM size
                ld e,l
                ld d,h
                inc de                  ; DE one byte ahead of HL
                ld (hl),a               ; fill first byte
                ldir                    ; fill the rest of RAM

                ld a,WHITE
                ld (tled),a
                out (IO_REG),a

                ; compare memory to pattern
                ld a,(ix)
                ld hl,MADDR             ; HL -> start of RAM
                ld bc,MLEN              ; BC = RAM size

m10:
                cpi                     ; compare next byte
                jp nz,m20               ; failure at (HL - 1)
                jp pe,m10               ; continue comparing

                exx
                jp m30                  ; test passed

m20:
                ex de,hl
                dec de                  ; DE -> last address tested
                ld iyl,e
                ld iyh,d
                exx
                ex de,hl                ; preserve test ID in HL
                ld e,iyl
                ld d,iyh

                ex de,hl                ; HL -> last address tested

                ld (taddr),hl
                ld a,(ix)
                ld (tpat),a
                ld a,(hl)
                ld (tact),a
                ld hl,(tfail)
                inc hl
                ld (tfail),hl

m30:
                ld hl,(tcount)
                inc hl
                ld (tcount),hl
                ld a,l
                or h
                ld a,(tcount+2)
                jp nz,m35
                inc a
                ld (tcount+2),a
m35:
                ld l,h
                ld h,a

                ld c,l
                ld b,h
                ld a,5                  ; start at digit 5
                call ssdisp16           ; display BC = test count

                ld a,(tfail)
                ld c,a
                ld a,(tcount)
                ld b,a
                ld a,1                  ; start at digit 1
                call ssdisp16           ; display BC = failure count
                jp m50

m40:
                ld hl,(taddr)
                ld c,l
                ld b,h
                ld a,5                  ; start at digit 5
                call ssdisp16           ; display BC = failure address

                ld a,(tact)
                ld c,a
                ld a,(tpat)
                ld b,a
                ld a,1
                ld a,5                  ; start at digit 1
                call ssdisp16           ; display BC = expected/actual

m50:
                inc ix                  ; next pattern

                ld a,e
                and patcnt - 1
                jp nz,mtest             ; go if more patterns

                ld ix,pats              ; start over with first pattern
                jp mtest

pats:
                db $00, $0f, $f0, $ff
                db $11, $1e, $e1, $ee
                db $22, $2d, $d2, $dd
                db $33, $3c, $c3, $cc
                db $44, $4b, $b4, $bb
                db $55, $5a, $a5, $aa
                db $66, $69, $96, $99
                db $77, $78, $87, $88
patend:

patcnt  .equ patend - pats



;----------------------------------------------------------------------
; ssdisp16:
; Displays a 16-bit value on 4 digits of the 7-segment LED display.
;
; On entry:
;               BC = value to display
;
; On return:
;               AF destroyed

ssdisp16:
                push de
                push hl
                ld h,a

                ld e,c
                call binhex
                ld a,h
                call ssout
                inc h

                ld e,d
                ld a,h
                call ssout
                inc h

                ld e,b
                call binhex
                ld a,h
                call ssout
                inc h

                ld e,d
                ld a,h
                call ssout

                pop hl
                pop de
                ret

;----------------------------------------------------------------------
; ssout:
; Outputs a bit pattern to a digit of the 7-segment LED display module
;
; On entry:
;       A = digit address 1-8 (right to left)
;   E = bit pattern for the digit
;
; On return:
;       AF destroyed
;
ssout:
                push hl
                ld h,a
                ld l,e
                call spi
                pop hl
                ret

;----------------------------------------------------------------------
; binhex:
; Converts a 8-bit value to two 8-bit patterns representing hexadecimal
; digits for a 7-segment display
;
; On entry:
;   E = 8-bit input value
;
; On return:
;       D = pattern for upper four bits of input E
;       E = pattern for lower four bits of input E
;       AF destroyed
;
binhex:
                push hl
                ld d,e                                  ; save E

                ; convert lower nibble
                ld a,e
                and $0f
                ld hl,digits                    ; point to digit patterns
                add l                                   ; add nibble value to table LSB
                ld l,a                                  ; ... and save it
                ld a,h                                  ; get table MSB
                adc 0                                   ; include any carry out of the LSB
                ld h,a                                  ; ... and save it
                ld e,(hl)                               ; fetch the bit pattern

                ; convert upper nibble
                ld a,d
                rrca
                rrca
                rrca
                rrca
                and $0f

                ld hl,digits                    ; point to digit patterns
                add l                                   ; add nibble value to table LSB
                ld l,a                                  ; ... and save it
                ld a,h                                  ; get table MSB
                adc 0                                   ; include any carry out of the LSB
                ld h,a                                  ; ... and save it
                ld d,(hl)
                pop hl
                ret

digits:
                db $7e          ; 0 - 01111110
                db $30          ; 1 - 00110000
                db $6d          ; 2 - 01101101
                db $79          ; 3 - 01111001
                db $33          ; 4 - 00110011
                db $5b          ; 5 - 01011011
                db $5f          ; 6 - 01011111
                db $70          ; 7 - 01110000
                db $7F          ; 8 - 01111111
                db $7B          ; 9 - 01111011
                db $77          ; A - 01110111
                db $1F          ; b - 00011111
                db $4E          ; C - 01001110
                db $3D          ; d - 00111101
                db $4F          ; E - 01001111
                db $47          ; F - 01000111

;----------------------------------------------------------------------
; spi:
; Sends a 16-bit value out to the display module using SPI
;
; On entry:
;        HL = value to send
;
spi:
                push af
                push bc

                ld a,low SPI_CS|L7_DISP_ADDR
                out (SPI_ADDR_REG),a

                ld a,(tled)
                and ~SCLK
                out (IO_REG),a

                ld b,8
spi10:
                rlc h
                jp nc,spi20
                or MOSI
                jp spi30
spi20:
                and low ~MOSI
spi30:
                out (IO_REG),a
                or SCLK
                out (IO_REG),a
                and ~SCLK
                out (IO_REG),a
                djnz spi10

                ld b,8
spi40:
                rlc l
                jp nc,spi50
                or MOSI
                jp spi60
spi50:
                and low ~MOSI
spi60:
                out (IO_REG),a
                or SCLK
                out (IO_REG),a
                and ~SCLK
                out (IO_REG),a
                djnz spi40

                ld a,0
                out (SPI_ADDR_REG),a
                ld a,(tled)
                out (IO_REG),a

                pop bc
                pop af
                ret

delay:
                push af
delay10:
                dec de
                ld a,d
                or e
                jr nz,delay10
                pop af
                ret

                .org ROM_TOP-1
                nop


                .end
