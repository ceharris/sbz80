
L7_PORT		defl $20
L7_ENABLE	defl $40

		macro l7x4_digit
		and 0xf			; mask off upper nibble
		ld c,a			; save value to display
		ld a,b			; get the digit number
		and 0x3			; range [0..3]
		rlca			; move digit number to bits 4..5
		rlca
		rlca
		rlca
		or c			; merge in value to display
		out (L7_PORT),a		; write digit value to controller
		or L7_ENABLE	
		out ($20),a		; latch the new digit value
		endm

		macro l7x4_out
		ld a,l			; get LSB of value
		ld b,0			; address digit 0
		l7x4_digit
		ld a,l			; get LSB of value
		rrca			; swap nibbles
		rrca
		rrca
		rrca
		ld b,1			; address digit 1
		l7x4_digit
		ld a,h			; get MSB of value
		ld b,2			; address digit 2
		l7x4_digit
		ld a,h			; get MSB of value
		rrca			; swap nibbles
		rrca
		rrca
		rrca
		ld b,3			; address digit 3
		l7x4_digit
		endm
		