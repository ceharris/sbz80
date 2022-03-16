
SCLK	.equ $40
MOSI	.equ $20
SCS		.equ $10

IOREG	.equ $f0

MODREG	.equ $ff
MODE 	.equ $01

RAM		.equ $4000
ROMSZ	.equ $2000

MADDR	.equ $400
MLEN	.equ $10000 - MADDR

PDATA	.equ $d0
PCTRL	.equ $d2
PMODE	.equ $4f
PINTR	.equ $87


KB_OK 	.equ $aa
KB_ERR	.equ $fc

BLUE	.equ $1
LED		.equ $2
KBLEN	.equ 16
TLED	.equ $4000
INPTR	.equ $4002
KBHEAD	.equ $4008
KBTAIL	.equ $400a
KBCNT	.equ $400c
KBBAT   .equ $400d
KBFLAGS .equ $400e

KBBUF	.equ $4010

VECTAB	.equ $4100

INBUF	.equ $8000

DLYCNT	.equ 0

		.aseg
		.org 0

		ld sp,0
		ld a,high(VECTAB)
		ld i,a
		im 2

		ld a,SCS|BLUE
		ld (TLED),a
		out (IOREG),a
		ld de,0
		call delay

		ld a,(TLED)
		xor BLUE
		ld (TLED),a
		out (IOREG),a
		call delay

		ld a,(TLED)
		xor BLUE
		ld (TLED),a
		out (IOREG),a
		call delay

		ld a,(TLED)
		xor BLUE
		ld (TLED),a
		out (IOREG),a
		call delay

		ld a,(TLED)
		xor BLUE
		ld (TLED),a
		out (IOREG),a
		call delay

		ld a,(TLED)
		xor BLUE
		ld (TLED),a
		out (IOREG),a

		; test display
		ld hl,$0f01
		call spi
		ld de,DLYCNT
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

		ld bc,0
		ld a,1
		call ssdisp16

		ld bc,0
		ld a,5
		call ssdisp16

		ld de,kbisr
		ld hl,VECTAB
		ld (hl),e
		inc hl
		ld (hl),d

		ld hl,KBBUF
		ld (KBHEAD),hl
		ld (KBTAIL),hl

		xor a
		out (PCTRL),a					; set vector to zero
		ld a,PMODE
		out (PCTRL),a					; set mode 1 (input)
		ld a,PINTR
		out (PCTRL),a					; enable interrupt

		ld hl,INBUF
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl

		xor a
		ld (INPTR),hl
		ld (KBCNT),a
		ld (KBBAT),a
		in a,(PDATA)

		ei

		xor a
		ld d,a
		ld e,a
		ld h,a
		ld l,a
show:
		ld a,(KBCNT)
		ld b,a
		ld c,e
		ld a,5
		call ssdisp16

		ld b,h
		ld c,l
		ld a,1
		call ssdisp16

loop:
		call kbread
		jp z,loop
		ld d,e
		ld e,h
		ld h,l
		ld l,a
		jp show

kbisr:
		ei
		push af
		push bc
		push hl

		in a,(PDATA)
		ld b,a

		cp KB_OK
		jp z,kbisr20
		cp KB_ERR
		jp z,kbisr20

		ld a,(KBCNT)
		inc a
		ld (KBCNT),a

		ld hl,(KBTAIL)
		ld c,l
		inc l
		ld a,l
		and KBLEN-1
		jp nz,kbisr10
		ld l,low(KBBUF)
kbisr10:
		ld a,(KBHEAD)
		cp l
		jp z,kbisr30
		
		ld (KBTAIL),hl
		ld l,c
		ld (hl),b
		jp kbisr30

kbisr20:
		ld (KBBAT),a
kbisr30:
		pop hl
		pop bc
		pop af
		reti		

kbread:
		push bc
		push hl
		ld hl,(KBHEAD)
		ld a,(KBTAIL)
		cp l
		jp z,kbread20

		ld c,(hl)
		inc l
		ld a,l
		and KBLEN-1
		jp nz,kbread10
		ld l,low(KBBUF)
kbread10:
		ld (KBHEAD),hl
		or 1
		ld a,c

kbread20:
		pop hl
		pop bc
		ret


;----------------------------------------------------------------------
; ssdisp16:
; Displays a 16-bit value on 4 digits of the 7-segment LED display.
;
; On entry:
;       A = digit position from 1..8 (right to left)
;		BC = value to display
;
; On return:
;		AF destroyed

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
		ld a,(TLED)
		and ~SCS
		out (IOREG),a

		ld b,8
spi10:
		rlc h
		jp nc,spi20
		or MOSI
		jp spi30
spi20:
		and ~MOSI
spi30:
		out (IOREG),a
		or SCLK
		out (IOREG),a
		and ~SCLK
		out (IOREG),a
		djnz spi10

		ld b,8
spi40:
		rlc l
		jp nc,spi50
		or MOSI
		jp spi60
spi50:
		and ~MOSI
spi60:
		out (IOREG),a
		or SCLK
		out (IOREG),a
		and ~SCLK
		out (IOREG),a
		djnz spi40

		ld a,(TLED)
		or SCS
		out (IOREG),a

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



		.end
