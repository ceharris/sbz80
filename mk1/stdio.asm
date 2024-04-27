
		include "stdio.h.asm"

ETX		defl 0x3
CTRL_C		defl ETX
EOT		defl 0x4
CTRL_D		defl EOT
BS		defl 0x8
CR		defl 0xd
SPC		defl 0x20
DEL		defl 0x7f

		section CODE_USER

	;---------------------------------------------------------------
	; puts:
	; Writes a null-terminated string to standard output.
	;
	; On entry:
	;	HL = pointer to a null-terminated string
	;
puts:
		push hl
puts_10:
		ld a,(hl)		; get next char to output
		or a			; null terminator?
		jr z,puts_20
		ld c,a
		call putc		; output the char
		inc hl						
		jp puts_10
puts_20:
		pop hl
		ret

	;---------------------------------------------------------------
	; gets:
	; Reads a string from standard input. Characters are read from
	; the input device until a newline (CR) is read or until
	; the maximum size of the buffer has been reached. Even in the
	; case that the buffer is exhausted, the buffer will always
	; contain a null terminator; only B - 1 bytes of the buffer will 
	; be used for input characters
	;
	; On entry:
	;	HL = input buffer
	;	B = maximum size of input buffer
	; On return:
	;	buffer at HL contains the input string
	;	HL = pointer to the null terminator
	;	B = length of unused buffer space
	;	C is the character that terminated input
gets:
		push de

		; save starting buffer address
		ld e,l			
		ld d,h
gets_10:
		dec b			; account for char to be entered
		jp z,gets_30
gets_20:
		call getc		; get a character
		ld c,a			; save it
		cp DEL			; is it the Delete key?
		jp z,gets_90		; delete prev character
		cp BS			; is it the Backspace key?
		jp z,gets_90		; delete prev character
		cp CR			; is it the Return key?
		jp z,gets_30		; terminate the input
		cp CTRL_C		; is it Control-C?
		jp z,gets_30		; terminate the input
		cp CTRL_D		; is it Control-D?
		jp z,gets_30		; terminate the input
		cp SPC			; some other control char?
		jp c,gets_20		; ignore other control chars
		call putc		; echo the character
		ld (hl),c		; store in buffer
		inc hl			; next buffer position
		jp gets_10
gets_30:
		; terminate the string with NUL
		xor a			; NUL = 0
		ld (hl),a		; store in buffer
		pop de
		ret

		; delete the character at the end of the buffer
gets_90:
		; does the buffer contain at least one character?
		push hl			; save buffer pointer
		or a			; clear carry
		sbc hl,de		; compare to initial pointer
		pop hl			; recover buffer pointer
		jp z,gets_20		; nothing to delete
		
		; erase character from terminal using BS - SPC - BS sequence 
		ld c,BS			; back to position of char to erase
		call putc
		ld c,SPC		; replace char at cursor with space
		call putc
		ld c,BS			; back for next input char
		call putc
		
		; adjust buffer count and offset
		inc b			
		dec hl
		jp gets_20