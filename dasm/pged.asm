		;--------------------------
		; Extension Page ED 
		;--------------------------
dasm_page_ed:
		ld a,(hl)			; get next opcode
		inc hl

		; divide into sections
		rla
		jr c,dasm_ped_s23
		rla
		jp nc,dasm_ped_unsup
		jr dasm_ped_s1
dasm_ped_s23:
		rla
		jp nc,dasm_ped_s2
		jp dasm_ped_unsup

		;-------------------
		; Page ED Section 1
		;-------------------
dasm_ped_s1:
		; preserve row bits and rotate them out
		ld c,a
		rla
		rla
		rla		

		; split into columns
		rla
		jr c,dasm_ped_s1_c47
		rla
		jr c,dasm_ped_s1_c23
		rla
		jr nc,dasm_ped_s1_c0
		jr dasm_ped_s1_c1
dasm_ped_s1_c23:
		rla
		jp nc,dasm_ped_s1_c2
		jp dasm_ped_s1_c3
dasm_ped_s1_c47:
		rla
		jr c,dasm_ped_s1_c67
		rla
		jp nc,dasm_ped_s1_c4
		jp dasm_ped_s1_c5
dasm_ped_s1_c67:
		rla
		jp nc,dasm_ped_s1_c6
		jp dasm_ped_s1_c7

dasm_ped_s2:
		; preserve row bits and rotate them out
		ld c,a
		rla
		rla
		rla		

		; split into columns
		rla
		jp c,dasm_ped_unsup
		rla
		jr c,dasm_ped_s2_c23
		rla
		jp nc,dasm_ped_s2_c0
		jp dasm_ped_s2_c1
dasm_ped_s2_c23:
		rla
		jp nc,dasm_ped_s2_c2
		jp dasm_ped_s2_c3

		;----------------------------
		; Page ED Section 1 Column 0
		;----------------------------
		; IN r,(C)
		;----------------------------
dasm_ped_s1_c0:
		ld (ix+st_inst_opcode),op_IN
		ld (ix+st_inst_argc),2

		ld a,c				; recover register bits
		
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		; get register puts into lowest 3 bits of A
		rlca
		rlca
		rlca
		and 0x7

		; not legal to use indirect
		cp reg_indirect		
		jp z,dasm_ped_unsup
		
		call mkarg_register_r

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct

		ld a,reg_C
		call mkarg_register
		set arg_indirect,(ix+st_arg_flags)
		
		jp dasm_page0_done

		;----------------------------
		; Page ED Section 1 Column 1
		;----------------------------
		; OUT (C),r
		;----------------------------
dasm_ped_s1_c1:
		ld (ix+st_inst_opcode),op_OUT
		ld (ix+st_inst_argc),2
		
		ld a,c				; recover register bits
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		ld c,a				; save register bits
		ld a,reg_C
		call mkarg_register
		set arg_indirect,(ix+st_arg_flags)

		ld a,c				; recover register bits

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct

		; get register puts into lowest 3 bits of A
		rlca
		rlca
		rlca
		and 0x7

		; not legal to use indirect
		cp reg_indirect		
		jp z,dasm_ped_unsup
		
		call mkarg_register_r

		jp dasm_page0_done

		;----------------------------
		; Page ED Section 1 Column 2
		;----------------------------
		; ADC HL,ss; SBC HL,ss
		;----------------------------
dasm_ped_s1_c2:
		ld a,c				; recover row and register bits
		and 0x20			; even or odd row?
		ld a,c
		jr nz,dasm_ped_s1_c2_10

		ld (ix+st_inst_opcode),op_SBC	; ---- SBC ----
		jr dasm_ped_s1_c2_20

dasm_ped_s1_c2_10:
		ld (ix+st_inst_opcode),op_ADC	; ---- ADC ----

dasm_ped_s1_c2_20:
		ld (ix+st_inst_argc),2				

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		ld c,a				; save register bits
		ld a,reg_HL
		call mkarg_register

		ld a,c				; recover register bits

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct

		; rotate register bits into lowest 2 bits of A
		rlca
		rlca
		and 0x3
		call mkarg_register_ss
		
		jp dasm_page0_done

		;----------------------------
		; Page ED Section 1 Column 3
		;----------------------------
		; LD (nn),ss; LD ss,(nn)
		;----------------------------
dasm_ped_s1_c3:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2

		ld a,c				; recover row and register bits
		and 0x20			; even or odd row?
		ld a,c
		jr nz,dasm_ped_s1_c3_10

		;------------
		; LD (nn),ss
		;------------
		
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		
		; fetch indirect address
		ld c,(hl)
		inc hl
		ld b,(hl)
		inc hl
		call mkarg_indirect_addr

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct

		; rotate register bits into lowest 2 bits of A
		rlca
		rlca
		and 0x3
		call mkarg_register_ss

		jp dasm_page0_done

		;------------
		; LD ss,(nn)
		;------------
dasm_ped_s1_c3_10:

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		
		; rotate register bits into lowest 2 bits of A
		rlca
		rlca
		and 0x3
		call mkarg_register_ss

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct

		; fetch indirect address
		ld c,(hl)
		inc hl
		ld b,(hl)
		inc hl
		call mkarg_indirect_addr

		jp dasm_page0_done

		;----------------------------
		; Page ED Section 1 Column 4
		;----------------------------
		; NEG
		;----------------------------
dasm_ped_s1_c4:
		ld a,c				; recover row bits
		and 0xe0			; mask off non-row bits
		jp nz,dasm_ped_unsup		; only row 0 is defined
		
		ld a,op_NEG			; ---- NEG ----
		jp dasm_page0_noarg
	
		;----------------------------
		; Page ED Section 1 Column 5
		;----------------------------
		; RETN, RETI
		;----------------------------
dasm_ped_s1_c5:
		ld a,c				; recover row bits
		rla
		jp c,dasm_ped_unsup		; rows 4-7 not defined
		rla
		jp c,dasm_ped_unsup		; rows 2-3 not defined
		rla
		ld a,op_RETN			; ---- RETN ----
		jp nc,dasm_page0_noarg
		ld a,op_RETI			; ---- RETI ----
		jp dasm_page0_noarg

		;----------------------------
		; Page ED Section 1 Column 6
		;----------------------------
		; IM m
		;----------------------------
dasm_ped_s1_c6:
		ld a,c				; recover row bits
		rla
		jp c,dasm_ped_unsup		; rows 4-7 not defined
		rla
		jr c,dasm_ped_s1_c6_r23
		rla
		jp c,dasm_ped_unsup		; row 1 not defined
		xor a				; clear row bits
		jr dasm_ped_s1_c6_10		
dasm_ped_s1_c6_r23:
		; rotate remaining row bit into lowest bit of A
		rlca
		and 0x1
		inc a				; mode = row + 1

		;--------
		; IM m
		;--------
dasm_ped_s1_c6_10:
		ld (ix+st_inst_opcode),op_IM
		ld (ix+st_inst_argc),1
	
		ld bc,st_inst_argx
		add ix,bc
		call mkarg_implicit_literal

		jp dasm_page0_done

		;--------------------------------
		; Page ED Section 1 Column 7
		;--------------------------------
		; LD I,A; LD R,A; LD A,I; LD A,R
		; RRD; RLD
		;--------------------------------
dasm_ped_s1_c7:
		ld a,c				; recover row bits
		rla
		jr c,dasm_ped_s1_c7_r47
		rla
		jr c,dasm_ped_s1_c7_r23
		rla
		ld a,reg_I
		jr nc,dasm_ped_s1_c7_10
		ld a,reg_R
		jr dasm_ped_s1_c7_10
dasm_ped_s1_c7_r23:
		rla
		ld a,reg_I
		jr nc,dasm_ped_s1_c7_20
		ld a,reg_R
		jr dasm_ped_s1_c7_20
dasm_ped_s1_c7_r47:
		rla
		jp c,dasm_ped_unsup		; rows 6-7 not defined
		rla
		ld a,op_RRD			; ---- RRD ----
		jp nc,dasm_page0_noarg
		ld a,op_RLD			; ---- RLD ----
		jp dasm_page0_noarg

		;----------------
		; LD I,A; LD R,A
		;----------------
dasm_ped_s1_c7_10:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		
		call mkarg_register

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
	
		ld a,reg_A
		call mkarg_register

		jp dasm_page0_done

		;----------------
		; LD A,I; LD A,R
		;----------------
dasm_ped_s1_c7_20:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		ld c,a				; save source register
		ld a,reg_A
		call mkarg_register
		ld a,c				; recover source register

		ld bc,st_arg_size
		add ix,bc

		call mkarg_register

		jp dasm_page0_done
		
		;----------------------------
		; Page ED Section 3 Column 0
		;----------------------------
		; LDI, LDD, LDIR, LDDR
		;----------------------------
dasm_ped_s2_c0:
		ld a,c				; recover row bits
		rla
		jr nc,dasm_ped_unsup		; rows 0-3 undefined
		rla
		jr c,dasm_ped_s2_c0_r67
		rla
		ld a,op_LDI			; ---- LDI ----
		jp nc,dasm_page0_noarg
		ld a,op_LDD			; ---- LDD ----
		jp dasm_page0_noarg
dasm_ped_s2_c0_r67:
		rla
		ld a,op_LDIR			; ---- LDIR ----
		jp nc,dasm_page0_noarg
		ld a,op_LDDR			; ---- LDDR ----
		jp dasm_page0_noarg
		
		;----------------------------
		; Page ED Section 2 Column 1
		;----------------------------
		; CPI, CPD, CPIR, CPDR
		;----------------------------
dasm_ped_s2_c1:
		ld a,c				; recover row bits
		rla
		jr nc,dasm_ped_unsup		; rows 0-3 undefined
		rla
		jr c,dasm_ped_s2_c1_r67
		rla
		ld a,op_CPI			; ---- CPI ----
		jp nc,dasm_page0_noarg
		ld a,op_CPD			; ---- CPD ----
		jp dasm_page0_noarg
dasm_ped_s2_c1_r67:
		rla
		ld a,op_CPIR			; ---- CPIR ----
		jp nc,dasm_page0_noarg
		ld a,op_CPDR			; ---- CPDR ----
		jp dasm_page0_noarg

		;----------------------------
		; Page ED Section 2 Column 2
		;----------------------------
		; INI, IND, INIR, INDR
		;----------------------------
dasm_ped_s2_c2:
		ld a,c				; recover row bits
		rla
		jr nc,dasm_ped_unsup		; rows 0-3 undefined
		rla
		jr c,dasm_ped_s2_c2_r67
		rla
		ld a,op_INI			; ---- INI ----
		jp nc,dasm_page0_noarg
		ld a,op_IND			; ---- IND ----
		jp dasm_page0_noarg
dasm_ped_s2_c2_r67:
		rla
		ld a,op_INIR			; ---- INIR ----
		jp nc,dasm_page0_noarg
		ld a,op_INDR			; ---- INDR ----
		jp dasm_page0_noarg

		;----------------------------
		; Page ED Section 2 Column 3
		;----------------------------
		; OUTI, OUTD, OTIR, OTDR
		;----------------------------
dasm_ped_s2_c3:
		ld a,c				; recover row bits
		rla
		jr nc,dasm_ped_unsup		; rows 0-3 undefined
		rla
		jr c,dasm_ped_s2_c3_r67
		rla
		ld a,op_OUTI			; ---- OUTI ----
		jp nc,dasm_page0_noarg
		ld a,op_OUTD			; ---- OUTD ----
		jp dasm_page0_noarg
dasm_ped_s2_c3_r67:
		rla
		ld a,op_OTIR			; ---- OTIR ----
		jp nc,dasm_page0_noarg
		ld a,op_OTDR			; ---- OTDR ----
		jp dasm_page0_noarg

		;------- TODO handle unrecognized op-code
dasm_ped_unsup:
		halt

