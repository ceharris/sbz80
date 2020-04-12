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
		; page 0, section 2
		ld b,b
		ld b,c
		ld b,d
		ld b,e
		ld b,h
		ld b,l
		ld b,(hl)
		ld b,a
		ld c,b
		ld c,c
		ld c,d
		ld c,e
		ld c,h
		ld c,l
		ld c,(hl)
		ld c,a
		ld d,b
		ld d,c
		ld d,d
		ld d,e
		ld d,h
		ld d,l
		ld d,(hl)
		ld d,a
		ld e,b
		ld e,c
		ld e,d
		ld e,e
		ld e,h
		ld e,l
		ld e,(hl)
		ld e,a
		ld h,b
		ld h,c
		ld h,d
		ld h,e
		ld h,h
		ld h,l
		ld h,(hl)
		ld h,a
		ld l,b
		ld l,c
		ld l,d
		ld l,e
		ld l,h
		ld l,l
		ld l,(hl)
		ld l,a
		ld (hl),b
		ld (hl),c
		ld (hl),d
		ld (hl),e
		ld (hl),h
		ld (hl),l
		halt
		ld (hl),a
		ld a,b
		ld a,c
		ld a,d
		ld a,e
		ld a,h
		ld a,l
		ld a,(hl)
		ld a,a

		nop
