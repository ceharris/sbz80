	;---------------------------------------------------------------
	; mkarg_flag:
	;
	; Makes an argument structure for flag `f`.
	;
	; On entry:
	;	IX -> target argument structure
	;	A = flag `f`
	;
	; On return:
	;	argument structure filled in
	;	all registers except AF are preserved
	;

mkarg_flag:
		push bc
		push hl
		
		ld b,a				; save specified flag

		; get flag symbol index from lookup table
		; start by getting offset into flag lookup table
		ld hl,flag_table
		ld a,l				
		add a,b
		ld l,a
		adc a,h
		sub l
		ld h,a				; HL -> entry for flag `f`

		ld a,(hl)			; get symbol index

		ld (ix+st_arg_flags),mask_flag
		ld (ix+st_arg_v),a
		ld (ix+st_arg_v+1),0
		ld (ix+st_arg_disp),0

		pop hl
		pop bc
		ret

	;---------------------------------------------------------------
	; mkarg_register_r:
	;
	; Makes an argument structure for register `r`.
	;
	; On entry:
	;	IX -> target argument structure
	;	IY -> disassembly state structure
	;	A = register `r`
	;	C = displacement
	;
	; On return:
	;	argument structure filled in
	;	all registers except AF are preserved
	;	
mkarg_register_r:
		push bc
		push hl
		
		; is `r` the indirect register?
		cp reg_indirect
		jr nz,mkarg_register_r_10
		
		ld (ix+st_arg_flags),mask_register|mask_indirect
		ld a,(iy+st_dasm_preg)		; get pointer register symbol
		ld (ix+st_arg_v),a

		; set indexed flag and displacement if indexed instruction
		ld a,(iy+st_dasm_flags)
		and mask_indexed
		jr z,mkarg_register_r_20
		set arg_indexed,(ix+st_arg_flags)
		ld (ix+st_arg_disp),c		; save displacement
		jr mkarg_register_r_20

mkarg_register_r_10:
		ld b,a				; save specified register

		; get register symbol index from lookup table
		; start by getting offset into register lookup table
		ld hl,reg_r_table
		ld a,l				
		add a,b
		ld l,a
		adc a,h
		sub l
		ld h,a				; HL -> entry for register `r`

		ld a,(hl)			; get symbol index
		ld (ix+st_arg_flags),mask_register
		ld (ix+st_arg_v),a

mkarg_register_r_20:
		pop hl
		pop bc
		ret		

	;---------------------------------------------------------------
	; mkarg_register_qq:
	;
	; Makes an argument structure for register pair `qq`.
	;
	; On entry:
	;	IX -> target argument structure
	;	IY -> disassembly state structure
	;	A = register `qq`
	;
	; On return:
	;	argument structure filled in
	;	all registers except AF are preserved
	;	
mkarg_register_qq:
		push bc
		push hl
		ld hl,reg_qq_table	
		jr mkarg_register_rr

	;---------------------------------------------------------------
	; mkarg_register_ss:
	;
	; Makes an argument structure for register pair `ss`.
	;
	; On entry:
	;	IX -> target argument structure
	;	IY -> disassembly state structure
	;	A = register `ss`
	;
	; On return:
	;	argument structure filled in
	;	all registers except AF are preserved
	;	
mkarg_register_ss:
		push bc
		push hl
		ld hl,reg_ss_table	

mkarg_register_rr:

		; is `rr` the pointer register?
		cp reg_pointer
		jr nz,mkarg_register_rr_10
		
		ld a,(iy+st_dasm_preg)		; get pointer register symbol
		jr mkarg_register_rr_20	

mkarg_register_rr_10:
		ld b,a				; save specified register
		
		; get register symbol index from lookup table
		; start by getting offset into register lookup table
		ld a,l				
		add a,b
		ld l,a
		adc a,h
		sub l
		ld h,a				; HL -> entry for register `r`
		ld a,(hl)			; get symbol index

mkarg_register_rr_20:
		ld (ix+st_arg_flags),mask_register
		ld (ix+st_arg_v),a
		ld (ix+st_arg_disp),c
		
		pop hl
		pop bc
		ret		
	
	;---------------------------------------------------------------
	; mkarg_register:
	;
	; Makes an argument structure for a register argument using
	; the specified register symbol.
	;
	; On entry:
	;	IX -> target argument structure
	;	A = register symbol
	;	C = displacement
	; On return:
	;	all registers preserved
	;

mkarg_register:
		ld (ix+st_arg_flags),mask_register
		ld (ix+st_arg_v),a
		ld (ix+st_arg_disp),c
		ret

	;---------------------------------------------------------------
	; mkarg_register_indirect:
	;
	; Makes an argument structure for a register indirect argument 
        ; using the specified register symbol.
	;
	; On entry:
	;	IX -> target argument structure
	;	A = register symbol
	;	C = displacement
	; On return:
	;	all registers preserved
	;

mkarg_register_indirect:
		ld (ix+st_arg_flags),mask_register | mask_indirect
		ld (ix+st_arg_v),a
		ld (ix+st_arg_v+1),0
		ld (ix+st_arg_disp),c
		ret

	;---------------------------------------------------------------
	; mkarg_absolute_addr:
	;
	; Makes an argument structure for an absolute (immediate) address.
	; On entry:
	;	BC = address
	; On return:
	;	all registers preserved
	;
mkarg_absolute_addr:
		ld (ix+st_arg_flags),mask_immediate | mask_extended
		ld (ix+st_arg_v),c
		ld (ix+st_arg_v+1),b
		ret

	;---------------------------------------------------------------
	; mkarg_indirect_addr:
	;
	; Makes an argument structure for an indirect address.
	;
	; On entry:
	;	BC = address
	; On return:
	;	all registers preserved
	;
mkarg_indirect_addr:
		ld (ix+st_arg_flags),mask_immediate | mask_extended | mask_indirect
		ld (ix+st_arg_v),c
		ld (ix+st_arg_v+1),b
		ret

	;---------------------------------------------------------------
	; mkarg_relative_addr:
	;
	; Makes an argument structure for an relative address.
	;
	; On entry:
	;	C = displacement
	; On return:
	;	all registers preserved
	; 
mkarg_relative_addr:
		ld (ix+st_arg_flags),mask_immediate | mask_disp
		ld (ix+st_arg_v),c
		ret

	;---------------------------------------------------------------
	; mkarg_immediate:
	;
	; Makes an argument structure for an 8-bit immediate operand
	;
	; On entry:
	;	C = operand
	; On return:
	;	all registers preserved
	; 
mkarg_immediate:
		ld (ix+st_arg_flags),mask_immediate
		ld (ix+st_arg_v),c
		ret

        ;---------------------------------------------------------------
        ; mkarg_implicit_literal:
        ;
        ; Makes an argument structure for an implicit literal operand 
        ; (e.g. for the BIT or IM instructions).
        ;
        ; On entry:
        ;       A = operand
        ; On return:
        ;       all registers preserved
        ;
mkarg_implicit_literal:
                ld (ix+st_arg_flags),mask_implicit
                ld (ix+st_arg_v),a
		ret

        ;---------------------------------------------------------------
        ; mkarg_implicit_address:
        ;
        ; Makes an argument structure for an implicit address operand
        ; (e.g. for the RST instruction).
        ;
        ; On entry:
        ;       A = operand
        ; On return:
        ;       all registers preserved
        ;
mkarg_implicit_address:
                ld (ix+st_arg_flags),mask_implicit | mask_flag
                ld (ix+st_arg_v),a
                ret

