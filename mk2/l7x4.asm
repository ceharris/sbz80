		include "machine.h.asm"

L7_PORT		equ $A0
L7_ENABLE	equ $40

		public l7x4_out

		section CODE_USER

	;---------------------------------------------------------------
	; l7x4_out:
	; Displays a 16-bit value on the 4-digit LED display.
	;
	; On entry:
	;	HL = value to display
	;
l7x4_out:
		push bc
		push hl
		ld a,l			; get LSB of value
		ld b,0			; address digit 0
		call _l7x4_digit	; display the lower nibble
		ld a,l			; get LSB of value
		rrca			; swap nibbles
		rrca
		rrca
		rrca
		ld b,1			; address digit 1
		call _l7x4_digit	; display the upper nibble
		ld a,h			; get MSB of value
		ld b,2			; address digit 2
		call _l7x4_digit	; display the lower nibble
		ld a,h			; get MSB of value
		rrca			; swap nibbles
		rrca
		rrca
		rrca
		ld b,3			; address digit 3
		call _l7x4_digit	; display the upper nibble
		pop hl
		pop bc
		ret

	;---------------------------------------------------------------
	; _l7x4_digit:
	; Displays a 4-bit value as hexadecimal digit on the display
	; 
	; On entry:
	;	A = 4-bit value to display
	;	B = digit position (0..3, from right to left)
	;
	; On return:
	;	C = 4-bit value that was displayed
_l7x4_digit:
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
		out (L7_PORT),a		; latch the new digit value
		ret
