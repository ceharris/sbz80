		name strcpy

	;--------------------------------------------------------------
	; SVC: strcpy
	; Copies a null-terminated string from one location in memory 
        ; to another.
	;
	; On entry:
	;	HL = source string, DE=target location
	; On return:
	;	HL = source string terminator + 1
	;	DE = entry DE + string length (including terminator)

		cseg
strcpy::
		push bc
		xor a
		ld c,a
		ld b,a
		
strcpy10:
		ld a,(hl)
		ldi
		jp po,strcpy20
		or a
		jr nz,strcpy10
strcpy20:
		pop bc
		ret			

		end
