
		section	CODE
		org	$0


mmu_ctrl_reg	defl	$1
mmu_a0		defl	$1
mmu_u1		defl	$2
mmue		defl	$8

		xor	a
		ld	c,a
loop:
		ld	a,c
		xor	mmu_u1
		ld	c,a
		out	(mmu_ctrl_reg),a
		ld	b,2
loop_10:	
		ld	de,0
loop_20:
		dec	de
		ld	a,d
		or	e
		jp	nz, loop_20
		djnz	loop_10
		jp	loop
