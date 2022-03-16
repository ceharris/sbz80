
		.aseg

		.org $0000

IOREG	.equ $10

		ld c,$02

loop:
		ld a,c
		xor $03
		ld c,a
		out (IOREG),a
		ld de,0
delay:
		dec de
		ld a,e
		or d
		jp nz,delay

		jp loop
