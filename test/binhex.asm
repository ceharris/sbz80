
		aseg

		org 0
		ld sp,0
		jp start

		org 0x10
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
		db $3B		; d - 00111101
		db $27		; E - 00100111
		db $47		; F - 01000111


		org 0x100
start:
		ld e,$7f
		call binhex

binhex:
		push hl
		ld d,e
		ld a,e
		and $0f
		ld hl,digits
		add l
		ld l,a
		ld a,h
		adc 0
		ld h,a
		ld e,(hl)

		ld a,d
		rrca
		rrca
		rrca
		rrca
		and $0f
		ld hl,digits
		add l
		ld l,a
		ld a,h
		adc 0
		ld h,a
		ld d,(hl)
		pop hl
		ret

