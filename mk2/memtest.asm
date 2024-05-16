		section	CODE
		org	$0

mmu_ctrl_reg	defl	$e0
mmu_page_reg	defl	$f0

entry:
		xor	a
		out	(mmu_page_reg),a
		ld	hl,0
		ld	de,$8000
		ld	bc,end - entry
		ldir
		ld	a,1
		out	(mmu_ctrl_reg),a
		ld	sp,$2000
test:
		ld	a,$10
test_05:
		ld	b,a
		out	(mmu_page_reg),a
		ld	hl,$2000
test_10:
		push	hl
		ld	l,h
		ld	h,b
		call	print
		pop	hl
		ld	a,$55
		ld	(hl),a
		cp	(hl)
		jp	z,test_20
		halt
test_20:
		xor	$ff
		ld	(hl),a
		cp	(hl)
		jp	z,test_30
		halt
test_30:
;		call	delay
		inc	hl
		ld	a,h
		or	a
		jp	nz,test_10

		ld	a,b
		add	a,$10
		jp	nc,test_05
		jp	test

print:
		push	bc
		push	hl
		ld	a,l
		ld	b,0
		call	digit
		ld	a,l
		rrca
		rrca
		rrca
		rrca
		ld	b,1
		call	digit
		ld	a,h
		ld	b,2
		call	digit
		ld	a,h
		rrca
		rrca
		rrca
		rrca
		ld	b,3
		call	digit
		pop	hl
		pop	bc
		ret
digit:
		and	0xf
		ld	c,a
		ld	a,b
		and	0x3
		rlca
		rlca
		rlca
		rlca
		or	c
		out	($a0),a
		or	$40
		out	($a0),a
		ret

delay:
		push	bc
		push	de
		ld	b,1
delay_10:
		ld	de,$100
delay_20:
		dec	de
		ld	a,d
		or	e
		jr	nz,delay_20
		djnz	delay_10

		pop	de
		pop	bc
		ret

end:

