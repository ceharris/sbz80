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
		; page CB section 0 row 0
		rlc b
		rlc c
		rlc d
		rlc h
		rlc l
		rlc (hl)
		rlc a
		; page CB section 0 row 1
		rrc b
		rrc c
		rrc d
		rrc h
		rrc l
		rrc (hl)
		rrc a
		; page CB section 0 row 2
		rl b
		rl c
		rl d
		rl h
		rl l
		rl (hl)
		rl a
		; page CB section 0 row 3
		rr b
		rr c
		rr d
		rr h
		rr l
		rr (hl)
		rr a
		; page CB section 0 row 4
		sla b
		sla c
		sla d
		sla h
		sla l
		sla (hl)
		sla a
		; page CB section 0 row 5
		sra b
		sra c
		sra d
		sra h
		sra l
		sra (hl)
		sra a
		; page CB section 0 row 6
		sll b
		sll c
		sll d
		sll h
		sll l
		sll (hl)
		sll a
		; page CB section 0 row 7
		srl b
		srl c
		srl d
		srl h
		srl l
		srl (hl)
		srl a
		; page CB section 1 row 0
		bit 0,b
		bit 0,c
		bit 0,d
		bit 0,e
		bit 0,h
		bit 0,l
		bit 0,(hl)
		bit 0,a
		; page CB section 1 row 1
		bit 1,b
		bit 1,c
		bit 1,d
		bit 1,e
		bit 1,h
		bit 1,l
		bit 1,(hl)
		bit 1,a
		; page CB section 1 row 2
		bit 2,b
		bit 2,c
		bit 2,d
		bit 2,e
		bit 2,h
		bit 2,l
		bit 2,(hl)
		bit 2,a
		; page CB section 1 row 3
		bit 3,b
		bit 3,c
		bit 3,d
		bit 3,e
		bit 3,h
		bit 3,l
		bit 3,(hl)
		bit 3,a
		; page CB section 1 row 4
		bit 4,b
		bit 4,c
		bit 4,d
		bit 4,e
		bit 4,h
		bit 4,l
		bit 4,(hl)
		bit 4,a
		; page CB section 1 row 5
		bit 5,b
		bit 5,c
		bit 5,d
		bit 5,e
		bit 5,h
		bit 5,l
		bit 5,(hl)
		bit 5,a
		; page CB section 1 row 6
		bit 6,b
		bit 6,c
		bit 6,d
		bit 6,e
		bit 6,h
		bit 6,l
		bit 6,(hl)
		bit 6,a
		; page CB section 1 row 7
		bit 7,b
		bit 7,c
		bit 7,d
		bit 7,e
		bit 7,h
		bit 7,l
		bit 7,(hl)
		bit 7,a
		; page CB section 2 row 0
		res 0,b
		res 0,c
		res 0,d
		res 0,e
		res 0,h
		res 0,l
		res 0,(hl)
		res 0,a
		; page CB section 2 row 1
		res 1,b
		res 1,c
		res 1,d
		res 1,e
		res 1,h
		res 1,l
		res 1,(hl)
		res 1,a
		; page CB section 2 row 2
		res 2,b
		res 2,c
		res 2,d
		res 2,e
		res 2,h
		res 2,l
		res 2,(hl)
		res 2,a
		; page CB section 2 row 3
		res 3,b
		res 3,c
		res 3,d
		res 3,e
		res 3,h
		res 3,l
		res 3,(hl)
		res 3,a
		; page CB section 2 row 4
		res 4,b
		res 4,c
		res 4,d
		res 4,e
		res 4,h
		res 4,l
		res 4,(hl)
		res 4,a
		; page CB section 2 row 5
		res 5,b
		res 5,c
		res 5,d
		res 5,e
		res 5,h
		res 5,l
		res 5,(hl)
		res 5,a
		; page CB section 2 row 6
		res 6,b
		res 6,c
		res 6,d
		res 6,e
		res 6,h
		res 6,l
		res 6,(hl)
		res 6,a
		; page CB section 2 row 7
		res 7,b
		res 7,c
		res 7,d
		res 7,e
		res 7,h
		res 7,l
		res 7,(hl)
		res 7,a
		; page CB section 3 row 0
		set 0,b
		set 0,c
		set 0,d
		set 0,e
		set 0,h
		set 0,l
		set 0,(hl)
		set 0,a
		; page CB section 3 row 1
		set 1,b
		set 1,c
		set 1,d
		set 1,e
		set 1,h
		set 1,l
		set 1,(hl)
		set 1,a
		; page CB section 3 row 2
		set 2,b
		set 2,c
		set 2,d
		set 2,e
		set 2,h
		set 2,l
		set 2,(hl)
		set 2,a
		; page CB section 3 row 3
		set 3,b
		set 3,c
		set 3,d
		set 3,e
		set 3,h
		set 3,l
		set 3,(hl)
		set 3,a
		; page CB section 3 row 4
		set 4,b
		set 4,c
		set 4,d
		set 4,e
		set 4,h
		set 4,l
		set 4,(hl)
		set 4,a
		; page CB section 3 row 5
		set 5,b
		set 5,c
		set 5,d
		set 5,e
		set 5,h
		set 5,l
		set 5,(hl)
		set 5,a
		; page CB section 3 row 6
		set 6,b
		set 6,c
		set 6,d
		set 6,e
		set 6,h
		set 6,l
		set 6,(hl)
		set 6,a
		; page CB section 3 row 7
		set 7,b
		set 7,c
		set 7,d
		set 7,e
		set 7,h
		set 7,l
		set 7,(hl)
		set 7,a
		; page DD section 0
		add ix,bc
		add ix,de
		add ix,ix
		add ix,sp
		ld ix,0xaaaa
		ld (0xbbbb),ix
		ld ix,(0xcccc)
		inc ix
		dec ix
		inc (ix+1)	
		dec (ix-1)	
		ld (ix+2),0x55
		; page DD section 1 
		ld b,(ix+0)
		ld c,(ix+1)
		ld d,(ix+2)
		ld e,(ix+3)
		ld h,(ix+4)
		ld l,(ix+5)
		ld a,(ix+7)
		ld (ix+0),b
		ld (ix+1),c
		ld (ix+2),d
		ld (ix+3),e
		ld (ix+4),h
		ld (ix+5),l
		ld (ix+7),a
		; page DD section 2
		add a,(ix)
		adc a,(ix+1)	
		sub (ix-1)
		sbc a,(ix-2)
		and (ix+10)
		xor (ix+11)
		or (ix+12)
		cp (ix+13)
		; page DD section 3
		pop ix
		jp (ix)
		ld sp,ix
		ex (sp),ix
		push ix
		; page FD section 0
		add iy,bc
		add iy,de
		add iy,iy
		add iy,sp
		ld iy,0xaaaa
		ld (0xbbbb),iy
		ld iy,(0xcccc)
		inc iy
		dec iy
		inc (iy+1)	
		dec (iy-1)	
		ld (iy+2),0x55
		; page FD section 1 
		ld b,(iy+0)
		ld c,(iy+1)
		ld d,(iy+2)
		ld e,(iy+3)
		ld h,(iy+4)
		ld l,(iy+5)
		ld a,(iy+7)
		ld (iy+0),b
		ld (iy+1),c
		ld (iy+2),d
		ld (iy+3),e
		ld (iy+4),h
		ld (iy+5),l
		ld (iy+7),a
		; page FD section 2
		add a,(iy)
		adc a,(iy+1)	
		sub (iy-1)
		sbc a,(iy-2)
		and (iy+10)
		xor (iy+11)
		or (iy+12)
		cp (iy+13)
		; page FD section 3
		pop iy
		jp (iy)
		ld sp,iy
		ex (sp),iy
		push iy

		nop
