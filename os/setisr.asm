		name setisr
		
	;--------------------------------------------------------------
	; setisr
	; Sets the interrupt service routine address for a mode 2
	; interrupt vector. This routine assumes that the vector table
	; has been initialized and that the I register contains the
	; page address of the table.
	;
	; On entry:
	;	C = the interrupt vector to set (0-127)
	;	HL = service routine address
	; On return
	;	all registers except AF preserved

setisr::
		push de			; preserve caller's DE
		ex de,hl		; put ISR address into DE

		; point HL to vector slot
		ld a,i			; page address of vector table
		ld h,a
		ld a,c			; get vector number
		or a			; clear carry
		rla			; multiply by 2
		ld l,a			; HL -> vector slot
	
		; set ISR address in vector table
		ld (hl),e		; ISR address LSB
		inc hl
		ld (hl),d		; ISR address MSB
		ex de,hl		; put ISR address back in DE
		
		pop de			; restore caller's DE
		ret

		end
