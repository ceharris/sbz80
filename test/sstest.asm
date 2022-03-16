
MOSI	        .equ low $80
SCLK            .equ $40

MODE_REG        .equ $00
IO_REG          .equ $10
SPI_CS_REG      .equ $f0

RAM_TOP         .equ $e000
ROM_TOP         .equ $10000

		.aseg
		.org RAM_TOP

                jp bootstrap
bootstrap:
                xor a
                out (MODE_REG),a
                ld sp,RAM_TOP

		ld a,0
                out (IO_REG),a
		out (SPI_CS_REG),a

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

		xor a
		scf
segnext:
		rra
		jr c,segdone
		ld h,$01
		ld l,a
		ld b,8
segdigit:
		call spi
		inc h
		djnz segdigit

		ld de,$4000
		call delay
		jr segnext
segdone:
		ld b,8
		ld h,$01
		ld l,0
blank:
		call spi
		inc h
		djnz blank

		ld bc,0
		ld de,0
loop:
		call ssdisp32
		ld a,e
		add 1
		ld e,a
		ld a,d
		adc 0
		ld d,a
		ld a,c
		adc 0
		ld c,a
		ld a,b
		adc 0
		ld b,a

		jp loop

delay:
		push af
delay10:
		dec de
		ld a,d
		or e
		jr nz,delay10
		pop af
		ret

ssdisp32:
		push de
		push hl
		ld h,d					; save input D
		call binhex				; DE = hex for input E
		ld a,1					; digit to display
		call ssout				; display lower nibble of input E
		ld e,d	
		ld a,2					; digit to display
		call ssout				; display upper nibble of input E

		ld e,h					; restore input D
		call binhex				; DE = hex for D
		ld a,3					; digit to display
		call ssout				; display lower nibble of input D
		ld e,d	
		ld a,4					; digit to display
		call ssout				; display upper nibble of input D

		ld e,c
		call binhex				; DE = hex for input C
		ld a,5					; digit to display
		call ssout				; display lower nibble of input C
		ld e,d
		ld a,6					; digit to display
		call ssout				; display upper nibble of input C

		ld e,b
		call binhex				; DE = hex for input B
		ld a,7					; digit to display
		call ssout				; display lower niblle of input B
		ld e,d
		ld a,8					; digit to display
		call ssout				; display upper nibble of input B
		pop hl
		pop de
		ret

;----------------------------------------------------------------------
; ssout:
; Outputs a bit pattern to a digit of the 7-segment LED display module
;
; On entry:
;	A = digit address 1-8 (right to left)
;   E = bit pattern for the digit
;
; On return:
;	AF destroyed
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
;	D = pattern for upper four bits of input E
; 	E = pattern for lower four bits of input E
;	AF destroyed
;
binhex:
		push hl
		ld d,e					; save E

		; convert lower nibble
		ld a,e					
		and $0f	
		ld hl,digits			; point to digit patterns
		add l					; add nibble value to table LSB
		ld l,a					; ... and save it
		ld a,h					; get table MSB
		adc 0					; include any carry out of the LSB
		ld h,a					; ... and save it
		ld e,(hl)				; fetch the bit pattern

		; convert upper nibble
		ld a,d			
		rrca
		rrca
		rrca
		rrca
		and $0f

		ld hl,digits			; point to digit patterns
		add l					; add nibble value to table LSB
		ld l,a					; ... and save it
		ld a,h					; get table MSB
		adc 0					; include any carry out of the LSB
		ld h,a					; ... and save it
		ld d,(hl)
		pop hl
		ret

digits:
		db $7e		; 0 - 01111110
		db $30		; 1 - 00110000
		db $6d		; 2 - 01101101
		db $79		; 3 - 01111001
		db $33		; 4 - 00110011
		db $5b		; 5 - 01011011
		db $5f		; 6 - 01011111
		db $70		; 7 - 01110000
		db $7F		; 8 - 01111111
		db $7B		; 9 - 01111011
		db $77		; A - 01110111
		db $1F		; b - 00011111
		db $4E		; C - 01001110
		db $3D		; d - 00111101
		db $4F		; E - 01001111
		db $47		; F - 01000111


;----------------------------------------------------------------------
; spi:
; Sends a 16-bit value out to the display module using SPI
;
; On entry:
;	 HL = value to send
;
spi:
		push af
		push bc
		ld a,$0f
                out (SPI_CS_REG),a

                xor a
		ld b,8
spi10:
		rlc h
		jp nc,spi20
		or low MOSI
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
		or low MOSI
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

                xor a
                out (SPI_CS_REG),a
		pop bc
		pop af
		ret

                .org ROM_TOP-1
                nop
                .end