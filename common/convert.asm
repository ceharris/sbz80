
	include "../include/convert.h.asm"

;-------------------------------------------------------------
; atou16:
; Convert an ASCII decimal value to a 16-bit unsigned integer.
;
; On entry:
;	DE = pointer to ASCII decimal value; conversion stops
;	     with the first non-digit character encountered
; On return:
;	DE = pointer to terminating character
;	HL = converted value
;
; Credit: Zeda
;	
atou16:
	push bc
	ld hl,0				; zero the result
atou16_10:
	ld a,(de)			; get char from input
	sub $30				; convert ASCII digit to binary
	cp 10 				; is it really a digit?
	jp c,atou16_20			; continue if it's a digit
	pop bc
	ret
atou16_20:
	inc de				; point to next input char

	; Mutltiply result by 10.
	; This takes advantage of the fact that 
	; 10 * x = 5 * 2 * x 
	;	 = (4 + 1) * 2 * x
	;	 = (4 + 1) * x * 2
	;	 = (4*x + x) * 2
	;	 = ((x<<2) + x) << 1
	; HL contains x (the current result)
	ld c,l				; copy x to BC
	ld b,h
	add hl,hl			; HL <<= 1; now HL = 2*x
	add hl,hl			; HL <<= 1; now HL = 4*x
	add hl,bc			; HL += result; now HL = 5*x
	add hl,hl			; HL <<= 1; now HL = 10*x

	; add incoming digit
	add a,l
	ld l,a	
	jr nc,atou16_10
	inc h				; include carry from the add
	jr atou16_10


;---------------------------------------------------------------
; htou16:
; Convert an ASCII hexadecimal value to a 16-bit unsigned integer.
;
; On entry:
;	DE = pointer to the value to convert; conversion stops
;	     with the first non-hexadecimal character
; On return:
;	DE = pointer to terminating character
;	HL = converted value
;
htou16:
	ld hl,0				; zero the result
htou16_10:
	ld a,(de)			; get next char to convert
	sub '0'				; convert digit to binary
	cp 9 + 1			; is it in range for a digit?
	jr c,htou16_20			; go if digit
	and 0xdf			; clear bit 5 to convert case
	sub 7				; translate 'A'..'F' to 10..15
	cp 10				; check lower bound
	ret c				; go if some char before 'A'
	cp 15 + 1			; check upper bound
	ret nc				; go if some char after 'F'
htou16_20:
	inc de				; point to next char
	add hl,hl			; HL <<= 1
	add hl,hl			; HL <<= 1
	add hl,hl			; HL <<= 1
	add hl,hl			; HL <<= 1
	or l				; A=bits 0..3, L=bits 4..7
	ld l,a
	jr htou16_10

;---------------------------------------------------------------
; qtou16:
; Convert an ASCII octal value to a 16-bit unsigned integer.
;
; On entry:
;	DE = pointer to the value to convert; conversion stops
;	     with the first non-octal character
; On return:
;	DE = pointer to terminating character
;	HL = converted value
;
qtou16:
	ld hl,0				; zero the result
qtou16_10:
	ld a,(de)			; get next char to convert
	sub '0'				; convert digit to binary
	cp 7 + 1			; in range for an octal digit?
	ret nc				; not an octal digit

	inc de
	add hl,hl			; HL <<= 1
	add hl,hl			; HL <<= 1
	add hl,hl			; HL <<= 1
	or l				; A=bits 0..2, L=bits=3..7
	ld l,a
	jr qtou16_10


	;---------------------------------------------------------------
	; btou16:
	; Convert an ASCII binary value to a 16-bit unsigned integer.
	;
	; On entry:
	;	DE = pointer to the value to convert; conversion stops
	;	     with the first character that isn't '0' or '1'
	; On return:
	;	DE = pointer to terminating character
	;	HL = converted value
	;
btou16:
		ld hl,0			; zero the result
btou16_10:
		ld a,(de)		; get next char to convert
		sub '0'			; convert digit to binary
		cp 1 + 1		; in range for a binary digit?
		ret nc			; not a binary digit

		inc de
		add hl,hl		; HL <<= 1
		or l			; A=bit 0, L=bits 1..7
		ld l,a
		jr btou16_10

;-------------------------------------------------------------
; u16toa:
; Converts an unsigned integer value to an ASCII decimal string.
;
; On entry:
;	DE = the value to convert
;	HL = pointer to a buffer at least 6 bytes 
;
; On return:
;	buffer at HL contains the null-terminated sequence of 
; 	ASCII decimal digits
;	
; Credit: Zeda
;	
u16toa:
	push af
	push bc
	push de
	ex de,hl

	ld bc,-10000
	ld a,'0' - 1
u16toa_10:
	inc a
	add hl,bc
	jr c,u16toa_10
	ld (de),a
	inc de

	ld bc,1000
	ld a,'9' + 1
u16toa_20:
	dec a
	add hl,bc
	jr nc,u16toa_20
	ld (de),a
	inc de

	ld bc,-100
	ld a,'0' - 1
u16toa_30:
	inc a
	add hl,bc
	jr c,u16toa_30
	ld (de),a
	inc de

	ld a,l
	ld h,'9' + 1
u16toa_40:
	dec h
	add a,10
	jr nc,u16toa_40
	add a,'0'
	ex de,hl
	ld (hl),d
	inc hl
	ld (hl),a
	inc hl
	ld (hl),0

	ld c,-6
	add hl,bc
	ld a,'0'
u16toa_50:
	inc hl
	cp (hl)
	jr z,u16toa_50

	ld a,(hl)
	or a
	jr nz,u16toa_60
	dec hl
u16toa_60:
	pop de
	pop bc
	pop af
	ret

;---------------------------------------------------------------
; u16toh:
; Converts a 16-bit value to ASCII hexadecimal.
; 
; On entry:
;	DE is the value to convert
;	HL is a buffer of at least 5 bytes
; On return:
;	buffer at HL contains the null-terminated sequence of
;	ASCII hexadecimal digits
;
u16toh:
	push hl
	ld a,e
	ld e,d
	ld d,a
	call e_to_hex
	ld a,e
	ld e,d
	ld d,a
	call e_to_hex
	ld (hl),0
	pop hl
	ret

;---------------------------------------------------------------
; u8tob:
; Converts an 8-bit value to ASCII hexadecimal.
; 
; On entry:
;	E is the value to convert
;	HL is a buffer of at least 3 bytes
; On return:
;	buffer at HL contains the null-terminated sequence of
;	ASCII hexadecimal digits
;
u8toh:
	push hl
	call e_to_hex
	ld (hl),0
	pop hl
	ret

;---------------------------------------------------------------
; e_to_hex:
; Converts a 8-bit value in E to ASCII hexadecimal in the buffer 
; at HL.
; 
; On entry:
;	E is the value to convert
;	HL is a buffer of at least 2 bytes
; On return:
;	HL = HL on entry + 2
;
e_to_hex:
	ld a,e				; get value to convert
	; move bits[4..7] to bits[0..3]
	rrca	
	rrca
	rrca
	rrca
	and 0xf				; isolate bits[0..3]
	cp 10				; digit or letter?
	jr c,e_to_hex_10		; go if digit
	add 0x27			; prepare to make it letter
e_to_hex_10:
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,e				; get value to convert
	and 0xf				; isolate bits[0..3]
	cp 10				; digit or letter
	jr c,e_to_hex_20		; go if digit
	add 0x27			; prepare to make it a letter
e_to_hex_20:
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position
	ret

;---------------------------------------------------------------
; u16toq:
; Converts a 16-bit value to ASCII octal.
; 
; On entry:
;	E is the value to convert
;	HL is a buffer of at least 7 bytes
; On return:
;	buffer at HL contains the null-terminated sequence
;	of ASCII octal digits
;
u16toq:
	push hl
	ld a,d				; get MSB of value to convert
	rlca				; move bit 7 to bit 1
	and 0x1				; isolate bits 1
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,d				; get MSB of value to convert
	;move bits[4..6] to bits[0..2]
	rlca
	rlca
	rlca
	rlca
	and 0x7				; isolate bits[0..2]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,d				; get MSB of value to convert
	rrca				; move bits[1..3] to bits[0..2]
	and 0x7				; isolate bits[0..2]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,d				; get MSB of value to convert
	rra				; carry = bit 0
	ld a,e				; get LSB of value to convert
	rra				; bit 7 = carry from MSB
	; move bits[5..7] to bits[0..2]
	rlca
	rlca
	rlca
	and 0x7				; isolate bits[0..2]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,e				; get LSB of value to convert
	; move bits[3..5] to bits[0..2]
	rrca
	rrca
	rrca
	and 0x7				; isolate bits[0..2]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,e				; get LSB of value to convert
	and 0x7				; isolate bits[0..2]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position
	ld (hl),0			; add null terminator

	pop hl
	ret

;---------------------------------------------------------------
; u8toq:
; Converts an 8-bit value to ASCII octal.
; 
; On entry:
;	E is the value to convert
;	HL is a buffer of at least 4 bytes
; On return:
;	buffer at HL contains the null-terminated sequence
;	of ASCII octal digits
;
u8toq:
	push hl
	ld a,e				; get value to convert
	; move bits[6..7] to bits[0..1]
	rlca	
	rlca
	and 0x3				; isolate bits[0..1]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,e				; get value to convert
	;move bits[3..5] to bits [0..2]
	rrca
	rrca
	rrca
	and 0x7				; isolate bits[0..2]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position

	ld a,e				; get value to convert
	and 0x7				; isolate bits[0..2]
	add '0'				; convert to ASCII
	ld (hl),a			; put into buffer
	inc hl				; next buffer position
	ld (hl),0			; add null-terminator
	pop hl
	ret

;---------------------------------------------------------------
; u16tob:
; Converts a 16-bit value to ASCII binary.
; 
; On entry:
;	DE is the value to convert
;	HL is a buffer of at least 17 bytes
; On return:
;	buffer at HL contains the null terminated sequence of
;	ASCII binary digits
;
u16tob:
	push bc
	push hl
	ld a,e
	ld e,d
	ld d,a
	call e_to_bin
	ld a,e
	ld e,d
	ld d,a
	call e_to_bin
	ld (hl),0
	pop hl
	pop bc
	ret

;---------------------------------------------------------------
; u8tob:
; Converts an 8-bit value to ASCII binary.
; 
; On entry:
;	E is the value to convert
;	HL is a buffer of at least 9 bytes
; On return:
;	buffer at HL contains the null terminated sequence of
;	ASCII binary digits
;
u8tob:
	push bc
	push hl
	call e_to_bin
	ld (hl),0
	pop hl
	pop bc
	ret

;---------------------------------------------------------------
; e_to_bin:
; Converts a 8-bit value in E to ASCII binary in the buffer at HL.
; 
; On entry:
;	E is the value to convert
;	HL is a buffer of at least 8 bytes
; On return:
;	HL = HL on entry + 8
;	B is zero
;
e_to_bin:
	ld b,8
e_to_bin_10:
	rlc e				; high order bit to carry
	ld a,'0'			; prepare to output a zero
	jr nc,e_to_bin_20		; go if it's a zero
	inc a				; it's a one instead
e_to_bin_20:
	ld (hl),a			; put into buffer
	inc hl				; next buffer position
	djnz e_to_bin_10
	ret


