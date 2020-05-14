;------------------------------------------
; Unsigned integer division
;

	;---------------------------------------------------------------
	; SVC: d32x8
	; Divides a 32-bit unsigned value by an 8-bit unsigned value.
	; 
	; On entry:
	;	DEHL is the dividend
	;	C is the divisor
	; On return:
	;	DEHL is the quotient
	;	A is the remainder
	;	C is unchanged
	;	B is zero
	;
d32x8::
		xor a
		ld b,32
d32x8_10:
		add hl,hl
		rl e
		rl d
		rla
		cp c
		jr c,d32x8_20
		sub c
		inc l
d32x8_20:
		djnz d32x8_10
		ret

	;---------------------------------------------------------------
	; SVC: d3210
	; Divides a 32-bit unsigned value by 10.
	; 
	; On entry:
	;	DEHL is the dividend
	;
	; On return:
	;	DEHL is the quotient
	;	A is the remainder
	;	C is unchanged
	;	BC is ten
	;
d3210::
		ld bc,0x0d0a
		xor a
		ex de,hl
		add hl,hl
		rla
		add hl,hl
		rla
		add hl,hl
		rla
d3210_10:
		add hl,hl
		rla
		cp c
		jr c,d3210_20
		sub c
		inc l
d3210_20:
		djnz d3210_10

		ex de,hl
		ld b,16
d3210_30:
		add hl,hl
		rla
		cp c
		jr c,d3210_40
		sub c
		inc l
d3210_40:
		djnz d3210_30
		ret

		end
