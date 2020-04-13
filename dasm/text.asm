		name text
		include defs.asm
	
		cseg
		
	;---------------------------------------------------------------
	; i2str:
	;
	; Converts a decoded instruction to a string representation.
	;
	; On entry:
	;	IX -> instruction structure
	;	DE -> target buffer
	;
	; On return:
	;	DE = DE + length of string representation
	;	all other registers except AF preserved
	;

i2str::
		push bc
		push hl

		; copy opcode symbol
		ld c,(ix+st_inst_opcode)	; get symbol index
		ld hl,m_table			; point to symbol table
		call copy_symbol

		; any arguments?
		ld a,(ix+st_inst_argc)		; get arg count
		or a
		jr z,i2str_done	; done if no args

		; delimit instruction from args with a single space
		ld a,' '
		ld (de),a
		inc de

		; convert first argument to string
		push ix
		ld bc,st_inst_argx
		add ix,bc
		call arg_to_string
		pop ix

		; more than one argument?
		ld a,(ix+st_inst_argc)
		cp 2
		jr c,i2str_done	; done if just one arg

		; delimit first arg from next with a comma
		ld a,','
		ld (de),a
		inc de

		; convert second argument to string
		push ix
		ld bc,st_inst_argy
		add ix,bc
		call arg_to_string
		pop ix

i2str_done:
	
		; null-terminate the string
		xor a
		ld (de),a
		inc de

		pop hl
		pop bc
		ret

	;---------------------------------------------------------------
	; arg_to_string:
	;
	; Converts an instruction argument to a string representation.
	;
	; On entry:
	;	IX -> argument structure
	;	DE -> target buffer
	;
	; On return:
	;	DE = DE + length of argument string
	;	IX, BC, HL preserved
	;

arg_to_string:
		push bc
		push hl		
	
		ld c,(ix+st_arg_flags)	; get argument flags

		ld a,c
		and mask_register	
		jr nz,arg_is_register

		ld a,c
		and mask_immediate
		jr nz,arg_is_immediate

		ld a,c
		and mask_flag
		jr nz,arg_is_flag

		; arg is implicit (single-digit decimal; e.g. BIT 3)
		ld a,(ix+st_arg_v)		; get argument value
		add a,'0'			; convert to ASCII digit
		ld (de),a
		inc de
		jp arg_to_string_done

arg_is_register:
		ld a,c
		and mask_indirect
		jr nz,arg_is_register_indirect	

		; arg is register
		ld c,(ix+st_arg_v)	; get symbol index
		ld hl,s_table		; point to symbol table
		call copy_symbol	; copy register symbol
		jr arg_to_string_done

arg_is_immediate:
		ld a,c
		and mask_extended
		jr nz,arg_is_extended_immediate

		ld a,c
		and mask_indirect
		jr nz,arg_is_indirect_immediate

		ld a,c
		and mask_disp
		jr nz,arg_is_displacement
	
		; arg is 8-bit immediate
		ld c,(ix+st_arg_v)	; get immediate value
		call to_hex8		; convert to ASCII hexadecimal
		jr arg_to_string_done

arg_is_flag:
		ld a,c
		and mask_implicit
		jr nz,arg_is_implicit_flag
	
		; arg is flag
		ld c,(ix+st_arg_v)	; get symbol index
		ld hl,s_table		; point to symbol table
		call copy_symbol

arg_to_string_done:
		pop hl
		pop bc
		ret

arg_is_register_indirect:
		ld a,c
		and mask_indexed
		jr nz,arg_is_indexed_indirect
		
		; arg is register indirect
		ld a,'('
		ld (de),a
		inc de

		ld c,(ix+st_arg_v)	; get symbol index
		ld hl,s_table		; point to symbol table
		call copy_symbol	; copy register symbol

		ld a,')'
		ld (de),a
		inc de
		jr arg_to_string_done

arg_is_indexed_indirect:
		ld a,'('
		ld (de),a
		inc de

		ld c,(ix+st_arg_v)	; get symbol index
		ld hl,s_table		; point to symbol table
		call copy_symbol	; copy register symbol
		
		ld c,(ix+st_arg_disp)	; get displacement
		call to_displacement	; convert to ASCII displacement
		
		ld a,')'
		ld (de),a
		inc de
		jr arg_to_string_done

arg_is_extended_immediate:
		ld a,c
		and mask_indirect
		jr nz,arg_is_indirect_extended
		
		; arg is 16-bit immediate
		ld c,(ix+st_arg_v)	; get immediate value
		ld b,(ix+st_arg_v+1)
		call to_hex16		; convert to ASCII hexadecimal
		jr arg_to_string_done

arg_is_indirect_extended:
		ld a,'('
		ld (de),a
		inc de
		ld c,(ix+st_arg_v)	; get immediate value
		ld b,(ix+st_arg_v+1)
		call to_hex16		; convert to ASCII hexadecimal
		ld a,')'
		ld (de),a
		inc de
		jr arg_to_string_done

arg_is_indirect_immediate:
		ld a,'('
		ld (de),a
		inc de
		ld c,(ix+st_arg_v)	; get immediate value
		call to_hex8		; convert to ASCII hexadecimal
		ld a,')'
		ld (de),a
		inc de
		jr arg_to_string_done
	
arg_is_displacement:
		ld c,(ix+st_arg_v)	; get displacement value
		call to_displacement
		jr arg_to_string_done

arg_is_implicit_flag:
		ld c,(ix+st_arg_v)	; get implicit value
		call to_hex8		
		jr arg_to_string_done


	;---------------------------------------------------------------
	; to_hex8:
	;
	; Converts an 8-bit value to a two-byte ASCII hexadecimal
	; representation.
	;
	; On entry:
	; 	C = the value to convert
	;	DE -> buffer for hexadecimal representation
	; On return:
	;	DE = DE + 2
	;	BC, HL unchanged
	;

to_hex8:
		push bc
		push hl

		; allocate two bytes on stack
		xor a
		push af			

		ld l,a
		ld h,a
		add hl,sp		; HL -> local buffer

		; add C-style hexadecimal prefix
		ld a,'0'
		ld (de),a
		inc de
		ld a,'x'
		ld (de),a
		inc de		

		ld (hl),c		; store value to convert

		ld b,2			; number of digits
to_hex8_next:
		rld			; copy nibble into A
		and 0xf
		
		cp 10
		jr nc,to_hex8_af
		add a,'0'		; convert 0-9 to ASCII digit
		jr to_hex8_store
to_hex8_af:
		add a,'A' - 10		; convert A-F to ASCII digit
to_hex8_store:
		ld (de),a		; store the hexadecimal digit
		inc de			; next buffer location
		djnz to_hex8_next	; for all digits

		pop af
		pop hl
		pop bc
		ret

	;---------------------------------------------------------------
	; to_hex16:
	;
	; Converts a 16-bit value to a four-byte ASCII hexadecimal
	; representation.
	;
	; On entry:
	; 	BC = the value to convert
	;	DE -> buffer for hexadecimal representation
	; On return:
	;	DE = DE + 2
	;	BC, HL unchanged
	;

to_hex16:
		push bc
		push hl

		; allocate two bytes on stack
		xor a
		push af			

		ld l,a
		ld h,a
		add hl,sp		; HL -> local buffer

		; add C-style hexadecimal prefix
		ld a,'0'
		ld (de),a
		inc de
		ld a,'x'
		ld (de),a
		inc de		

		; store value to convert in big-endian order
		ld (hl),b
		inc hl
		ld (hl),c

		dec hl			; point to first byte to convert

		ld b,4			; number of digits to convert
to_hex16_next:
		rld			; copy nibble into A
		and 0xf
		
		cp 10
		jr nc,to_hex16_af
		add a,'0'		; convert 0-9 to ASCII digit
		jr to_hex16_store
to_hex16_af:
		add a,'A' - 10		; convert A-F to ASCII digit
to_hex16_store:
		ld (de),a		; store the hexadecimal digit
		inc de			; next buffer location

		ld a,b
		cp 3
		jr nz,to_hex16_same_byte
		inc hl			; next byte

to_hex16_same_byte:
		djnz to_hex16_next	; for all digits

		pop af
		pop hl
		pop bc
		ret

	;---------------------------------------------------------------
	; to_displacement:
	;
	; Convert an 8-bit signed displacement to ASCII decimal with
	; a leading sign.
	;
	; On entry:
	;	C = displacement
	;	DE -> buffer for ASCII decimal representation
	; On return:
	;	DE = DE + length of ASCII decimal representation
	;	BC, HL unchanged	
	;

to_displacement:
		ld a,c			; load displacement to convert 
		or a
		ret z			; zero is a special case
		
		and 0x80		; test sign bit
		jr nz,to_disp_neg

		ld a,'+'		
		jr to_disp_conv
to_disp_neg:	
		ld a,c
		neg
		ld c,a
		ld a,'-'
to_disp_conv:
		ld (de),a

		; divide displacement by 100
		ld a,c			; displacement is the dividend
		ld c,100
		call div88
		or a
		jr z,to_disp_lt100	; don't include leading zero
		
		inc de
		add a,'0'		; convert quotient to ASCII decimal
		ld (de),a	
		
		; divide displacement by 10
to_disp_lt100:
		ld a,c			; dividend is the prior remainder
		ld c,10
		call div88
		or a
		jr nz,to_disp_ge10
		ld a,(de)
		cp '0'
		jr c,to_disp_lt10	; don't include leading zero
		xor a			; it's not a leading zero
to_disp_ge10:
		inc de			
		add a,'0'		; convert quotient to ASCII decimal
		ld (de),a	
	
		; convert final remainder
to_disp_lt10:
		ld a,c
		inc de			
		add a,'0'
		ld (de),a
		inc de

		ret

	;---------------------------------------------------------------
	; div88:
	;
	; Divide a 8-bit unsigned dividend by an unsigned 8-bit divisor.
	;
	; On entry:
	;	A = dividend
	;	C = divisor
	; On return:
	;	A = quotient
	;	C = remainder
	;	B destroyed

div88:
		ld b,0			; initial quotient
div88_next:
		sub c			; divide by subtract
		jr c,div88_stop		; did we go too far?
		inc b			; increment quotient
		jr div88_next		; next trial subtraction
div88_stop:
		add a,c			; undo last trial subtraction
		ld c,a			; put remainder in C
		ld a,b			; put quotient in A
		ret
		

	;---------------------------------------------------------------
	; copy_symbol:
	;
	; Copies a symbol (mnemonic, operand, etc) from a symbol
	; table to buffer.
	;
	; On entry:
	;	C = symbol index
	;	HL = pointer to symbol table
	;	DE = destination buffer for symbol
	; On return:
	;	DE = destination buffer address + symbol length
	; 	BC, HL unchanged
	;

copy_symbol:
		push bc
		push hl

		; use symbol index to get table entry
		ld a,c			; symbol index to A
		sla a			; table entries are words
		add a,l			; offset the LSB
		ld l,a			; put LSB back to L
		adc h			; offset the MSB
		sub l			; better than zeroing A first
		ld h,a			; put MSB back to H
		
		; retrieve pointer to symbol string from table
		ld a,(hl)
		inc hl
		ld h,(hl)
		ld l,a

		; copy the symbol string
		ld c,(hl)		; string length is first byte
		xor a
		ld b,a			; BC = string length
		inc hl			; HL = start of symbol
		ldir			; copy the string

copy_symbol20:
		pop hl
		pop bc
		ret

		include mnemonic.asm
		include operand.asm

		end

