		name hex

       	;-------------------------------------------------------------
	; SVC: hex8
	; Converts an 8-bit binary value to ASCII hexadecimal.
	; The hexadecimal representation is written to a caller-
        ; provided buffer.
	;
	; On entry:
	;	C = binary value to convert
	;	HL = pointer to two character buffer 
	; On return
	;	HL = caller's HL + 2
	;	(HL-2) = ASCII hex of C's high-order nibble
	;	(HL-1) = ASCII hex of C's low-order nibble

		cseg
hex8::
		push	bc		; preserve caller's BC
		ld	a,c		; get value to convert

		; rotate upper nibble to lower nibble
		ld	b,4
hex8_10:	
		rra
		djnz	hex8_10	
		and	0xf

		cp	0xa		; is it 0-9 or A-F?
		jr	nc,hex8_20	; go if A-F
		add	a,'0'		; convert to ASCII '0'..'9'
		jr	hex8_30
hex8_20:	
		add	a,'A'-10	; convert to ASCII 'A'..'F'
hex8_30:
		ld	(hl),a		; store upper nibble hex
		inc	hl		; next buffer location

		ld	a,c		; get value to convert
		and	0xf		; mask off upper nibble
		cp	0xa		; is it 0-9 or A-F?
		jr	nc,hex8_40	; go if A-F
		add	a,'0'		; convert to ASCII '0'..'9'
		jr	hex8_50
hex8_40:	
		add	a,'A'-10	; convert to ASCII 'A'..'F'
hex8_50:
		ld	(hl),a		; store lower nibble hex
		inc	hl		; next buffer location
				
		pop	bc
		ret

       	;-------------------------------------------------------------
	; SVC: hex16
	; Converts a 16-bit binary value to ASCII hexadecimal.
	; The hexadecimal representation is written to a caller-
        ; provided buffer.
	;
	; On entry:
	;	BC = binary value to convert
	;	HL = pointer to two character buffer 
	; On return
	;	HL = caller's HL + 2
	;	(HL-2) = ASCII hex of C's high-order nibble
	;	(HL-1) = ASCII hex of C's low-order nibble

hex16::
		push	bc		; preserve caller's BC
		ld	c,b
		call	hex8		; convert most significant byte
		pop	bc		; restore caller's BC
		call	hex8		; convert least significant byte
		ret

		end
