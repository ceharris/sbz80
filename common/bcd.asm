
		include "machine.h.asm"
		include "bcd.h.asm"

NUM_BCD_DIGITS	defl	10
BCD_BUFFER_SIZE	defl	NUM_BCD_DIGITS / 2
ACD_BUFFER_SIZE	defl	NUM_BCD_DIGITS + 2 	; +2 for sign and NUL

FLAG_ZERO	defl	0
FLAG_CARRY	defl	1


		section	CODE_USER


bcd_uint16:
		push	ix
		call	bcd_clear
		ld	ix,bit_values
		ld	b,16
bcd_uint16_10:
		rrc	l			; copy LSB to carry flag
		rl	c			; save carry flag in C
		rlc	l			; restore L
		rr	c			; set carry to LSB from L
		rr	h
		rr	l			; next bit into carry
		push	hl
		jp	nc,bcd_uint16_20
		call	bcd_copy_bit_value
		ld	hl,bcd_addend
		call	bcd_add			; add bit value to sum
		jp	bcd_uint16_30
bcd_uint16_20:
		call	bcd_skip_bit_value
bcd_uint16_30:
		pop	hl
		djnz	bcd_uint16_10
		pop	ix
		ret


bcd_uint32:
		push	ix
		call	bcd_clear
		ld	ix,bit_values
		ld	b,32
bcd_uint32_10:
		rrc	l			; copy LSB to carry flag
		rl	c			; save carry flag in C
		rlc	l			; restore L
		rr	c			; set carry to LSB from L
		rr	d
		rr	e
		rr	h
		rr	l			; next bit into carry
		push	de
		push	hl
		jp	nc,bcd_uint32_20
		call	bcd_copy_bit_value
		ld	hl,bcd_addend
		call	bcd_add			; add bit value to sum
		jp	bcd_uint32_30
bcd_uint32_20:
		call	bcd_skip_bit_value
bcd_uint32_30:
		pop	hl
		pop	de
		djnz	bcd_uint32_10
		pop	ix
		ret

bcd_copy_bit_value:
		push	bc
		ld	hl,bcd_addend
		ld	b,BCD_BUFFER_SIZE
bcd_copy_bit_value_10:
		ld	a,(ix)
		inc	ix
		ld	(hl),a
		inc	hl
		or	a
		jp	z,bcd_copy_bit_value_20
		djnz	bcd_copy_bit_value_10
bcd_copy_bit_value_20:
		pop	bc
		ret


bcd_skip_bit_value:
		push	bc
		ld	b,BCD_BUFFER_SIZE
bcd_skip_bit_value_10:
		ld	a,(ix)
		inc	ix
		or	a
		jp	z,bcd_skip_bit_value_20
		djnz	bcd_skip_bit_value_10
bcd_skip_bit_value_20:
		pop	bc
		ret


bcd2acd:
		push	bc
		push	de
		ld	de,bcd_accum
		ld	hl,acd_buffer + ACD_BUFFER_SIZE - 1
		ld	(hl),0			; null terminator
		ld	b,BCD_BUFFER_SIZE
bcd2acd_10:
		ld	a,(de)			; get BCD digit pair
		inc	de	
		ld 	c,a			; save digit pair
		and	0xf			; isolate low digit
		add	'0'			; convert to ASCII
		dec	hl
		ld	(hl),a			; ASCII digit to buffer
		ld	a,c			; recover digit pair
		; isolate upper digit
		rra
		rra
		rra
		rra
		and	0xf	
		add	'0'			; convert to ASCII
		dec	hl
		ld	(hl),a			; ASCII digit to buffer
		djnz	bcd2acd_10		
bcd2acd_20:
		ld	a,(hl)
		or	a			; end of string?
		jp	z,bcd2acd_25
		cp	'0'
		jp	nz,bcd2acd_30		; go if leading digit isn't zero
		inc	hl			; skip leading zero
		jp	bcd2acd_20
bcd2acd_25:
		dec	hl
		ld	(hl),'0'
bcd2acd_30:
		pop	de
		pop	bc
		ret

		

	;--------------------------------------------------------------
	; bcd_add:
	; Performs a BCD addition: bcd_accum = bcd_accum + (HL)
	; On entry:
	;    	HL -> addend
	;
	; On return:
	;    	HL -> addend + 1
	;	A = bcd_flags
	;
bcd_add:
		push	bc
		push	de
		ld	de,bcd_accum
bcd_add_next:	
		ld	b,BCD_BUFFER_SIZE
		or	a		; clear carry
bcd_add_10:
		; add next BCD digit pair
		ld	a,(de)
		adc	(hl)
		daa
		ld	(de),a
		inc	de
		rl	c		; save carry flag in C

		; if digit pair is 00 it's the end of the addend
		ld	a,(hl)		; recover addend digit pair
		inc	hl		; move on in case we jump
		or	a
		jp	z,bcd_add_20	; go if pair is 0
		rr	c		; restore carry
		djnz	bcd_add_10	; stop at buffer size limit
		jp	bcd_add_40	; we're done
bcd_add_20:
		dec	b		; count pair with zero upper digit
		rr	c		; restore carry
		jp	nc,bcd_add_40	; we're done if there's no carry
bcd_add_30:
		; propagate the carry up through bcd_accum
		ld	a,(de)
		adc	0
		daa
		ld	(de),a
		inc	de
		djnz	bcd_add_30
bcd_add_40:	
		; put carry flag into the appropriate bit of C
		rept	FLAG_CARRY + 1
		rl	c
		endr

		; check for zero result
		xor	a
		ex	de,hl
		ld	b,BCD_BUFFER_SIZE
bcd_add_50:
		dec	hl
		or	(hl)
		djnz	bcd_add_50
		ex	de,hl
		or	a		; any non-zero bits?
		ld	a,c
		jp	nz,bcd_add_60	; some non-zero bits
		or	1<<FLAG_ZERO
bcd_add_60:
		ld	(bcd_flags),a		
		pop	de
		pop	bc
		ret


	;-------------------------------------------------------------
	; bcd_clear:
	; Clears the BCD accumulator register and flags.
	;
bcd_clear:
		push	bc
		push	hl
		ld	hl,bcd_flags
		ld	b,BCD_BUFFER_SIZE+1
bcd_clear_10:
		ld	(hl),0
		inc	hl
		djnz	bcd_clear_10
		pop	hl
		pop	bc
		ret

		section RODATA
bit_values:
		db	0x01,0x00			; bit 0 = 1
		db	0x02,0x00			; bit 1 = 2
		db	0x04,0x00			; bit 2 = 4
		db	0x08,0x00			; bit 3 = 8
		db	0x16,0x00			; bit 4 = 16
		db	0x32,0x00			; bit 5 = 32
		db	0x64,0x00			; bit 6 = 64
		db	0x28,0x01,0x00			; bit 7 = 128
		db	0x56,0x02,0x00			; bit 8 = 256
		db	0x12,0x05,0x00			; bit 9 = 512
		db	0x24,0x10,0x00			; bit 10 = 1,024
		db	0x48,0x20,0x00			; bit 11 = 2,048
		db	0x96,0x40,0x00			; bit 12 = 4,096
		db	0x92,0x81,0x00			; bit 13 = 8,192
		db	0x84,0x63,0x01,0x00		; bit 14 = 16,384
		db	0x68,0x27,0x03,0x00		; bit 15 = 32,768
		db	0x36,0x55,0x06,0x00		; bit 16 = 65,536
		db	0x72,0x10,0x13,0x00		; bit 17 = 131,072
		db	0x44,0x21,0x26,0x00		; bit 18 = 262,144
		db	0x88,0x42,0x52,0x00		; bit 19 = 524,288
		db	0x76,0x85,0x04,0x01,0x00	; bit 20 = 1,048,576
		db	0x52,0x71,0x09,0x02,0x00	; bit 21 = 2,097,152
		db	0x04,0x43,0x19,0x04,0x00	; bit 22 = 4,194,304
		db	0x08,0x86,0x38,0x08,0x00	; bit 23 = 8,388,608
		db	0x16,0x72,0x77,0x16,0x00	; bit 24 = 16,777,216
		db	0x32,0x44,0x55,0x33,0x00	; bit 25 = 33,554,432
		db	0x64,0x88,0x10,0x67,0x00	; bit 26 = 67,108,864
		db	0x28,0x77,0x21,0x34,0x01	; bit 27 = 134,217,728
		db	0x56,0x54,0x43,0x68,0x02	; bit 28 = 268,435,456
		db	0x12,0x09,0x87,0x36,0x05	; bit 29 = 536,870,912
		db	0x24,0x18,0x74,0x73,0x10	; bit 30 = 1,073,741,824
		db	0x48,0x36,0x48,0x47,0x21	; bit 31 = 2,147,483,648

		section	BSS
bcd_flags:	ds	1
bcd_accum:	ds	BCD_BUFFER_SIZE
bcd_addend:	ds	BCD_BUFFER_SIZE
acd_buffer:	ds	NUM_BCD_DIGITS + 2