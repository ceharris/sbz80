	;---------------------------------------------------------------
	; Unsigned integer multiplication and division
	;---------------------------------------------------------------
		name muldiv

	;---------------------------------------------------------------
	; SVC: m32x8
	; Multiplies a 16 bit unsigned value by an 8 bit unsigned value.
	;
	; On entry:
	;	HL = multiplicand
	;	C = multiplier
	; On return:
	;	HL = product
	;	C = multiplier
	;	B = zero
	;	
m16x8::
		push de
		ld e,l
		ld d,h

		ld a,c
		ld l,0
		ld b,8
m16x8_10:
		add hl,hl
		add a,a
		jr nc,m16x8_20
		add hl,de
m16x8_20:
		djnz m16x8_10

		pop de
		ret

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

	;---------------------------------------------------------------
	; SVC: d32x16
	; Divides a 32-bit unsigned value by 16-bit unsigned value.
	;
	; On entry:
	;	DEHL=dividend
	;	BC=divisor
	; On return:
	;	DEHL=quotient
	;	BC=remainder
	;	AF destroyed
	;
d32x16::
		push ix

                ; exchange registers such that
                ; ACIX = dividend, DE = divisor
                ld a,l
                ld ixl,a
                ld a,h
                ld ixh,a
                ld a,c                  ; preserve divisor bits 0-7
                ld c,e                  ; C = dividend bits 16-23
                ld e,a                  ; E = divisor bits 0-7
                ld a,d                  ; A = dividend bits 24-31
                ld d,b                  ; D = divisor bits 8-15

		; do the division
		ld hl,0
		ld b,32
d32x16_10:
		add ix,ix
		rl c
		rla
		adc hl,hl
		jr c,d32x16_20
		sbc hl,de
		jr nc,d32x16_30
		add hl,de
		djnz d32x16_10
		jr d32x16_40
d32x16_20:
		or a
		sbc hl,de
d32x16_30:
		inc ixl
		djnz d32x16_10
d32x16_40:
		; exchange registers such that
		; DEHL=quotient, BC=remainder
		ld e,c
		ld d,a
		ld c,l
		ld b,h
		ld a,ixl
		ld l,a
		ld a,ixh
		ld h,a

		pop ix
		ret

	;---------------------------------------------------------------
	; SVC: d16x8
	; Divides a 16-bit unsigned value by an 8-bit unsigned value.
	;
	; On entry:
	;	HL = dividend
	;	C = divisor
	; On return
	;	A = remainder
	;	HL = quotient
	; 	B = zero
	;
d16x8::
		ld b,16
		xor a
d16x8_10:
		add hl,hl
		rla
		cp c
		jr c,d16x8_20
		inc l
		sub c
d16x8_20:
		djnz d16x8_10
		ret
	
		end
