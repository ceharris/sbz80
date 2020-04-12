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
		; page 0, section 0, column 4
		inc b
		inc c
		inc d
		inc e
		inc h
		inc l
		inc (hl)
		inc a
		; page 0, section 0, column 5
		dec b
		dec c
		dec d
		dec e
		dec h
		dec l
		dec (hl)
		dec a
		; page 0, section 0, column 6
		ld b,0xbb
		ld c,0xcc
		ld d,0xdd
		ld e,0xee
		ld h,0x44
		ld l,0x11
		ld (hl),0x66
		ld a,0xaa
		; page 0, section 0, column 7
		rlca
		rrca
		rla
		rra
		daa
		cpl
		scf
		ccf
		; page 0, section 1, column 0
		ld b,b
		ld b,c
		ld b,d
		ld b,e
		ld b,h
		ld b,l
		ld b,(hl)
		ld b,a
		; page 0, section 1, column 1
		ld b,b
		ld c,b
		ld c,c
		ld c,d
		ld c,e
		ld c,h
		ld c,l
		ld c,(hl)
		ld c,a
		; page 0, section 1, column 2
		ld d,b
		ld d,c
		ld d,d
		ld d,e
		ld d,h
		ld d,l
		ld d,(hl)
		ld d,a
		; page 0, section 1, column 3
		ld e,b
		ld e,c
		ld e,d
		ld e,e
		ld e,h
		ld e,l
		ld e,(hl)
		ld e,a
		; page 0, section 1, column 4
		ld h,b
		ld h,c
		ld h,d
		ld h,e
		ld h,h
		ld h,l
		ld h,(hl)
		ld h,a
		; page 0, section 1, column 5
		ld l,b
		ld l,c
		ld l,d
		ld l,e
		ld l,h
		ld l,l
		ld l,(hl)
		ld l,a
		; page 0, section 1, column 6
		ld (hl),b
		ld (hl),c
		ld (hl),d
		ld (hl),e
		ld (hl),h
		ld (hl),l
		halt
		ld (hl),a
		; page 0, section 1, column 7
		ld a,b
		ld a,c
		ld a,d
		ld a,e
		ld a,h
		ld a,l
		ld a,(hl)
		ld a,a
		; page 0 section 2 row 0
		add a,b
		add a,c
		add a,d
		add a,e
		add a,h	
		add a,l
		add a,(hl)
		add a,a
		; page 0 section 2 row 1
		adc a,b
		adc a,c
		adc a,d
		adc a,e
		adc a,h	
		adc a,l
		adc a,(hl)
		adc a,a
		; page 0 section 2 row 2
		sub b
		sub c
		sub d
		sub e
		sub h	
		sub l
		sub (hl)
		sub a
		; page 0 section 2 row 3
		sbc a,b
		sbc a,c
		sbc a,d
		sbc a,e
		sbc a,h	
		sbc a,l
		sbc a,(hl)
		sbc a,a
		; page 0 section 2 row 4
		and b
		and c
		and d
		and e
		and h	
		and l
		and (hl)
		and a
		; page 0 section 2 row 5
		xor b
		xor c
		xor d
		xor e
		xor h	
		xor l
		xor (hl)
		xor a
		; page 0 section 2 row 6
		or b
		or c
		or d
		or e
		or h	
		or l
		or (hl)
		or a
		; page 0 section 2 row 7
		cp b
		cp c
		cp d
		cp e
		cp h	
		cp l
		cp (hl)
		cp a
		; page 0 section 3 column 0
		ret nz
		ret z
		ret nc
		ret c
		ret po
		ret pe
		ret p
	 	ret m
		; page 0 section 3 column 1
		pop bc
		ret
		pop de
		exx
		pop hl
		jp (hl)
		pop af
		ld sp,hl
		; page 0 section 3 column 2
		jp nz,0x0
		jp z,0x1111
		jp nc,0x2222
		jp c,0x3333
		jp po,0x4444
		jp pe,0x5555
		jp p,0x6666
	 	jp m,0x7777
		; page 0 section 3 column 3
		jp 0xbeef
		out (0x80),a
		in a,(0x81)
		ex (sp),hl
		ex de,hl
		di
		ei
		; page 0 section 3 column 4
		call nz,0x0
		call z,0x1111
		call nc,0x2222
		call c,0x3333
		call po,0x4444
		call pe,0x5555
		call p,0x6666
	 	call m,0x7777
		; page 0 section 3 column 5
		push bc
		call 0xbeef
		push de
		push hl	
		push af
		; page 0 section 3 column 6
		add a,0
		adc a,1
		sub 2
		sbc a,3
		and 4
		xor 5
		or 6
		cp 7
		; page 0 section 3 column 7
		rst 0x0
		rst 0x8
		rst 0x10
		rst 0x18
		rst 0x20
		rst 0x28
		rst 0x30
		rst 0x38

		nop
