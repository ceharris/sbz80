RAM		.equ $4000
ROMSZ	.equ $2000

IOREG	.equ $ff
MODE	.equ $80

CONFIG	.equ $80

		.aseg

		.org $0000

		ld hl,0
		ld de,RAM
		ld bc,ROMSZ
		ldir

		ld a,$80
		out (IOREG),a
		jp init

		.org $0200

init:
		ld sp,0

		; -- zero out low memory
		xor a
		ld l,a
		ld h,a
		ld e,a
		ld d,a
		inc de
		ld bc,init - 1
		ld a,(hl)
		ldir

		; -- initialize restart vector 0
		ld hl,0
		ld (hl),$c3					; JP init
		inc hl
		ld (hl),init & $ff
		inc hl
		ld (hl),(init >> 8) & $ff
		inc hl

		; -- initialize restart vector 8
		ld hl,8
		ld (hl),$c3
		inc hl
		ld (hl),red & $ff
		inc hl
		ld (hl),(red >> 8) & $ff

		ld hl,CONFIG
		ld (hl),$80

loop:		
		ld a,(CONFIG)
		xor $01
		ld (CONFIG),a
		out (IOREG),a

		in a,(IOREG)
		and $10
		jr z,skip
		rst $08

skip:

		ld de,0
delay:
		dec de
		ld a,d
		or e
		jp nz,delay
		jp loop

red:
		ld a,(CONFIG)
		xor $02
		ld (CONFIG),a
		ret

		jp loop




