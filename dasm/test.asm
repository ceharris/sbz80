test:
		; page 0, section 0, column 0
		nop
		ex af,af'
		djnz test
		jr test
		jr c,test
		; page 0, section 0, column 1
		ld bc,0xbbbb
		add hl,bc
		ld de,0xdddd
		add hl,de
		ld hl,0xaaaa
		add hl,hl
		ld sp,0xffff
		add hl,sp
		; page 0, section 0, column 2
		ld (bc),a
		ld a,(bc)
		ld (de),a
		ld a,(de)
		ld (0x5555),hl
		ld hl,(0xaaaa)
		ld (0x5555),a
		ld a,(0xaaaa)
		; page 0, section 0, column 3
		inc bc
		dec bc
		inc de
		dec de
		inc hl
		dec hl
		inc sp
		dec sp
		; page 0, section 1, column 4
		inc b
		inc c
		inc d
		inc e
		inc h
		inc l
		inc (hl)
		inc a
		; page 0, section 1, column 5
		dec b
		dec c
		dec d
		dec e
		dec h
		dec l
		dec (hl)
		dec a
		; page 0, section 1, column 6
		ld b,0xbb
		ld c,0xcc
		ld d,0xdd
		ld e,0xee
		ld h,0x44
		ld l,0x11
		ld (hl),0x66
		ld a,0xaa
		; page 0, section 1, column 7
		rlca
		rrca
		rla
		rra
		daa
		cpl
		scf
		ccf

		nop
