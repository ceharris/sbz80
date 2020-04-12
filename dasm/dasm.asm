
; Bit positions for argument flags
arg_register	equ 0
arg_immediate	equ 1
arg_extended	equ 2
arg_indirect	equ 3
arg_indexed	equ 4
arg_flag	equ 5	
arg_implicit	equ 6
arg_disp	equ 7

; Masks for argument flags
mask_register	equ 1<<arg_register
mask_immediate	equ 1<<arg_immediate
mask_extended	equ 1<<arg_extended
mask_indirect	equ 1<<arg_indirect
mask_indexed	equ 1<<arg_indexed
mask_flag	equ 1<<arg_flag
mask_implicit	equ 1<<arg_implicit
mask_disp	equ 1<<arg_disp

; Argument structure displacements and size
st_arg_flags	equ 0
st_arg_v	equ 1
st_arg_disp	equ 3
st_arg_size	equ st_arg_disp + 1

; Decoded instruction structure displacements and size
st_inst_len	equ 0
st_inst_flags	equ 1
st_inst_opcode	equ 2
st_inst_argc	equ 3
st_inst_argx	equ 4
st_inst_argy	equ st_inst_argx + st_arg_size
st_inst_size	equ st_inst_argy + st_arg_size

; Disassembler state structure displacements and size
st_dasm_level	equ 0
st_dasm_preg	equ 1
st_dasm_flags	equ 2
st_dasm_inst	equ 4
st_dasm_usize	equ st_dasm_inst + st_inst_size
st_dasm_size	equ st_dasm_usize + (16 - st_dasm_usize % 16)

		cseg
demo:
		ld iy,dbuf
		ld (iy+st_dasm_level),0		
		ld (iy+st_dasm_preg),reg_HL
		ld (iy+st_dasm_flags),0

		ld ix,dbuf+st_dasm_inst

		ld hl,test
		ld de,cbuf

demo10:
		call dasm_page0
		call inst_to_string

		ld a,(hl)
		or a
		jr nz,demo10

		halt

	; On entry:
	;	IX -> instruction decode structure
	;	IY -> disassembler state structure
	;	HL -> memory location to disassemble
	;
dasm_page0:
		push ix
		push bc

		ld a,(hl)			; fetch opcode
		inc hl

		or a				; clear carry
		rla
		jr c,dasm_page0_upper		; upper half of page 0

		rla
		jr nc,dasm_p0_s0		; opcodes 0x00-0x3f
		jp dasm_p0_s1			; opcodes 0x40-0x7f

dasm_page0_upper:
		rla
		jp nc,dasm_p0_s2		; opcodes 0x80-0xbf
		jr dasm_p0_s3			; opcodes 0xc0-0xff

dasm_p0_s0:
		; save middle 3 bits, then rotate them out
		ld c,a				
		rla				
		rla
		rla
	
		; now split into columns
		rla
		jr nc,dasm_p0_s0_c03
		jr dasm_p0_s0_c47
dasm_p0_s0_c03:
		rla
		jr nc,dasm_p0_s0_c01
		jr dasm_p0_s0_c23
dasm_p0_s0_c47:
		rla
		jp nc,dasm_p0_s0_c45
		jr dasm_p0_s0_c67
dasm_p0_s0_c01:
		rla
		jr nc,dasm_p0_s0_c0
		jr dasm_p0_s0_c1
dasm_p0_s0_c23:
		rla
		jr nc,dasm_p0_s0_c2
		jr dasm_p0_s0_c3
dasm_p0_s0_c67:
		rla
		jp nc,dasm_p0_s0_c6
		jp dasm_p0_s0_c7

dasm_p0_s3:
		halt
		halt
		halt

		;----------------
		; Column 0
		;----------------
dasm_p0_s0_c0:
		ld a,c				; recover middle 3 bits
		rla
		jr nc,dasm_p0_s0_c0_r03
		jp dasm_p0_s0_c0_r47
dasm_p0_s0_c0_r03:
		rla
		jr nc,dasm_p0_s0_c0_r01
		jr dasm_p0_s0_c0_r23
dasm_p0_s0_c0_r01:
		rla
		jp c,dasm_p0_s0_c0_r1
		ld a,op_NOP
		jr dasm_page0_noarg
dasm_p0_s0_c0_r23:
		rla
		jp nc,dasm_p0_s0_c0_r2
		jp dasm_p0_s0_c0_r3

		;----------------
		; Column 1
		;----------------
dasm_p0_s0_c1:
		ld a,c				; recover middle 3 bits
		or a				; clear carry

		; rotate 2 register bits into lower positions
		; and remaining opcode bit into carry
		rla
		rla
		rla

		jp nc,dasm_p0_s0_c1_re		; even rows
		jp dasm_p0_s0_c1_ro		; odd rows

		;----------------
		; Column 2
		;----------------
dasm_p0_s0_c2:
		ld a,c				; recover middle 3 bits
		rla
		jr nc,dasm_p0_s0_c2_r03
		jr dasm_p0_s0_c2_r47
dasm_p0_s0_c2_r03:
		rla
		jr nc,dasm_p0_s0_c2_r01
		jr dasm_p0_s0_c2_r23
dasm_p0_s0_c2_r47:
		rla
		jr nc,dasm_p0_s0_c2_r45
		jr dasm_p0_s0_c2_r67
dasm_p0_s0_c2_r01:
		rla
		jp nc,dasm_p0_s0_c2_r0
		jp dasm_p0_s0_c2_r1
dasm_p0_s0_c2_r23:
		rla
		jp nc,dasm_p0_s0_c2_r2
		jp dasm_p0_s0_c2_r3
dasm_p0_s0_c2_r45:
		rla
		jp nc,dasm_p0_s0_c2_r4
		jp dasm_p0_s0_c2_r5
dasm_p0_s0_c2_r67:
		rla
		jp nc,dasm_p0_s0_c2_r6
		jp dasm_p0_s0_c2_r7
		
		;----------------
		; Column 3
		;----------------
dasm_p0_s0_c3:
		ld a,c				; recover middle 3 bits
		or a				; clear carry

		; rotate 2 register bits into lower positions
		; and remaining opcode bit into carry
		rla
		rla
		rla

		jp nc,dasm_p0_s0_c3_re		; even rows
		jp dasm_p0_s0_c3_ro		; odd rows

		;----------------
		; Column 7
		;----------------
dasm_p0_s0_c7:
		ld a,c				; recover middle 3 bits
		rla
		jr nc,dasm_p0_s0_c7_r03
		jr dasm_p0_s0_c7_r47
dasm_p0_s0_c7_r03:
		rla
		jr nc,dasm_p0_s0_c7_r01
		jr dasm_p0_s0_c7_r23
dasm_p0_s0_c7_r47:
		rla
		jr nc,dasm_p0_s0_c7_r45
		jr dasm_p0_s0_c7_r67
dasm_p0_s0_c7_r01:
		rla
		ld a,op_RLCA
		jr nc,dasm_page0_noarg
		ld a,op_RRCA
		jr dasm_page0_noarg
dasm_p0_s0_c7_r23:
		rla
		ld a,op_RLA
		jr nc,dasm_page0_noarg
		ld a,op_RRA
		jr dasm_page0_noarg
dasm_p0_s0_c7_r45:
		rla
		ld a,op_DAA
		jr nc,dasm_page0_noarg
		ld a,op_CPL
		jr dasm_page0_noarg
dasm_p0_s0_c7_r67:
		rla
		ld a,op_SCF
		jr nc,dasm_page0_noarg
		ld a,op_CCF

dasm_page0_noarg:
		ld (ix+st_inst_opcode),a	; mnemomic symbol index
		ld (ix+st_inst_argc),0		; no arguments
		jp dasm_page0_done

		;----------------
		; EX AF,AF'
		;----------------
dasm_p0_s0_c0_r1:
		ld (ix+st_inst_opcode),op_EX
		ld (ix+st_inst_argc),2		; two arguments
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld c,0				; no displacement
		ld a,reg_AF			; register symbol index
		call mkarg_register		; configure register arg
		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld c,0				; no displacement
		ld a,reg_AAF			; register symbol index
		call mkarg_register		; configure register arg
		jp dasm_page0_done

		;----------------
		; DJNZ disp
		;----------------
dasm_p0_s0_c0_r2:
		ld a,op_DJNZ			; mnenmonic symbol index
		jr dasm_p0_s0_c0_r3jr

		;----------------
		; JR disp
		;----------------
dasm_p0_s0_c0_r3:
		ld a,op_JR			; mnenmonic symbol index
dasm_p0_s0_c0_r3jr:
		ld (ix+st_inst_opcode),a
		ld (ix+st_inst_argc),1		; one argument
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld c,(hl)			; fetch displacement
		inc hl
		call mkarg_relative_addr	; configure relative addr arg
		jp dasm_page0_done

		;----------------
		; JR fl,disp
		;----------------
dasm_p0_s0_c0_r47:
		ld (ix+st_inst_opcode),op_JR
		ld (ix+st_inst_argc),2		; two arguments

		; rotate flag bits into lower positions and isolate
		rlca				
		rlca
		and 0x3				
		
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		call mkarg_flag			; configure flag arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld c,(hl)			; fetch displacement
		inc hl
		call mkarg_relative_addr	; configure relative addr arg
		jp dasm_page0_done

		;----------------
		; LD ss,N
		;----------------
dasm_p0_s0_c1_re:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		and 0x3				; mask all but register bits
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		call mkarg_register_ss		; configure register ss arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld c,(hl)			; get LSB of immediate arg
		inc hl
		ld b,(hl)			; get MSB of immediate arg
		inc hl
		call mkarg_absolute_addr
		jp dasm_page0_done

		;----------------
		; ADD HL,ss
		;----------------
dasm_p0_s0_c1_ro:
		ld (ix+st_inst_opcode),op_ADD
		ld (ix+st_inst_argc),2		; two arguments

		; do second argument first to use register bits
		and 0x3				; mask all but register bits
		ld bc,st_inst_argx + st_arg_size
		add ix,bc			; point to arg y struct
		call mkarg_register_ss		; configure register ss arg

		ld bc,-st_arg_size
		add ix,bc			; point to arg x struc
		ld a,(iy+st_dasm_preg)		; get pointer register symbol
		call mkarg_register		; configure register arg
		jp dasm_page0_done

		;----------------
		; LD (BC),A
		;----------------
dasm_p0_s0_c2_r0:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld a,reg_BC
		call mkarg_register		; configure register arg
		set arg_indirect,(ix+st_arg_flags)

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld a,reg_A
		call mkarg_register		; configure register arg
		jp dasm_page0_done

		;----------------
		; LD A,(BC)
		;----------------
dasm_p0_s0_c2_r1:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld a,reg_A
		call mkarg_register		; configure register arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld a,reg_BC
		call mkarg_register		; configure register arg
		set arg_indirect,(ix+st_arg_flags)

		jp dasm_page0_done

		;----------------
		; LD (DE),A
		;----------------
dasm_p0_s0_c2_r2:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld a,reg_DE
		call mkarg_register		; configure register arg
		set arg_indirect,(ix+st_arg_flags)

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld a,reg_A
		call mkarg_register		; configure register arg
		jp dasm_page0_done

		;----------------
		; LD A,(DE)
		;----------------
dasm_p0_s0_c2_r3:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld a,reg_A
		call mkarg_register		; configure register arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld a,reg_DE
		call mkarg_register		; configure register arg
		set arg_indirect,(ix+st_arg_flags)

		jp dasm_page0_done

		;----------------
		; LD (N),HL
		;----------------
dasm_p0_s0_c2_r4:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld c,(hl)			; load LSB of address
		inc hl
		ld b,(hl)			; load MSB of address
		inc hl
		call mkarg_indirect_addr	; configure indirect arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld a,(iy+st_dasm_preg)		; pointer register symbol
		call mkarg_register		; configure register arg
		jp dasm_page0_done

		;----------------
		; LD HL,(N)
		;----------------
dasm_p0_s0_c2_r5:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld a,(iy+st_dasm_preg)		; pointer register symbol
		call mkarg_register		; configure register arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld c,(hl)			; load LSB of address
		inc hl
		ld b,(hl)			; load MSB of address
		inc hl
		call mkarg_indirect_addr	; configure indirect arg

		jp dasm_page0_done

		;----------------
		; LD (N),A
		;----------------
dasm_p0_s0_c2_r6:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld c,(hl)			; load LSB of address
		inc hl
		ld b,(hl)			; load MSB of address
		inc hl
		call mkarg_indirect_addr	; configure indirect arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld a,reg_A
		call mkarg_register		; configure register arg
		jp dasm_page0_done

		;----------------
		; LD A,(N)
		;----------------
dasm_p0_s0_c2_r7:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		; two arguments

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct
		ld a,reg_A
		call mkarg_register		; configure register arg

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld c,(hl)			; load LSB of address
		inc hl
		ld b,(hl)			; load MSB of address
		inc hl
		call mkarg_indirect_addr	; configure indirect arg
		jp dasm_page0_done

		;----------------
		; INC ss
		;----------------
dasm_p0_s0_c3_re:
		ld (ix+st_inst_opcode),op_INC
		ld (ix+st_inst_argc),1		; one argument

		and 0x3				; mask all but register bits
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struc
		call mkarg_register_ss		; configure register ss arg
		jp dasm_page0_done

		;----------------
		; DEC ss
		;----------------
dasm_p0_s0_c3_ro:
		ld (ix+st_inst_opcode),op_DEC
		ld (ix+st_inst_argc),1		; one argument

		and 0x3				; mask all but register bits
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struc
		call mkarg_register_ss		; configure register ss arg
		jp dasm_page0_done

		;----------------
		; INC r, DEC r
		;----------------
dasm_p0_s0_c45:
		rla				; get column into carry
		jr c,dasm_p0_s0_c45_10
		ld (ix+st_inst_opcode),op_INC
		jr dasm_p0_s0_c45_20
dasm_p0_s0_c45_10:
		ld (ix+st_inst_opcode),op_DEC
dasm_p0_s0_c45_20:
		ld (ix+st_inst_argc),1		

		ld a,c				; recover middle 3 bits

		; rotate 3 register bits into lowest positions
		rlca
		rlca
		rlca
		and 0x7				; just the register bits

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct		
		call mkarg_register_r
		jp dasm_page0_done

		;----------------
		; LD r,N
		;----------------
dasm_p0_s0_c6:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2		

		; rotate 3 register bits into lowest positions
		ld a,c				; recover middle 3 bits
		rlca
		rlca
		rlca
		and 0x7				; just the register bits
		
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct		
		call mkarg_register_r
		
		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		ld c,(hl)			; get immediate argument
		inc hl
		call mkarg_immediate
		jp dasm_page0_done		

		;----------------
		; HALT
		;----------------
dasm_p0_s1:
		; is source and dest (HL)?  (A=rrrqqqXX)
		and 0xfc			; discard lowest two bits
		cp 0xd8
		jr nz,dasm_p0_s1_10

		ld (ix+st_inst_opcode),op_HALT
		ld (ix+st_inst_argc),0
		jp dasm_page0_done

		;----------------
		; LD r,q
		;----------------
dasm_p0_s1_10:
		ld (ix+st_inst_opcode),op_LD
		ld (ix+st_inst_argc),2

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct		
		ld c,a				; save register bits

		; get target register into lowest 3 bits
		rlca 
		rlca 
		rlca 
		and 0x7				; just the register bits
		call mkarg_register_r

		ld a,c				; recover register bits
		; move source register into lowest 3 bits
		rra
		rra
		and 0x7				; just the register bits

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct
		call mkarg_register_r
		jp dasm_page0_done

		;---------------------------------------------
		; Section 2: ADD a,r; ADC a,r; SUB r; SBC a,r
		;	     AND r; XOR r; OR r; CP r
		;---------------------------------------------
dasm_p0_s2:
		push hl
		push ix
		pop hl

		; is it SUB r?
		ld c,a				; save row and register bits
		and 0xe0	
		cp 0x40
		jr z,dasm_p0_s2_r2		; handle SUB as special case
		ld a,c				; recover row and register bits

		; now split into rows
		rla
		jr nc,dasm_p0_s2_r03
		jr dasm_p0_s2_r47

dasm_p0_s2_r03:
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct		
		ld c,a				; save row and register bits

		ld a,reg_A			; A is the target register
		call mkarg_register
		ld a,c				; recover row and register bits

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct

		; get source register into lowest 3 bits of A
		ld c,a				; save row bits
		rra
		rra
		rra
		and 0x7
		call mkarg_register_r
		ld a,c				; recover row bits
		
		ld c,2				; argument count
		rla
		jr c,dasm_p0_s2_r3		; just 3; 2 is a special case

		rla		
		ld a,op_ADD			; ---- ADD A,r ----
		jr nc,dasm_p0_s2_done
		ld a,op_ADC			; ---- ADC A,r ----
		jr dasm_p0_s2_done

dasm_p0_s2_r3:
		ld a,op_SBC			; ---- SBC A,r ----
		jr dasm_p0_s2_done

		;----------------
		; SUB r
		;----------------
dasm_p0_s2_r2:
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		; get source register into lowest 3 bits of A
		ld c,a				; save row bits
		rra
		rra
		rra
		and 0x7
		call mkarg_register_r
		ld a,c				; recover row bits
		
		ld c,1				; argument count
		ld a,op_SUB
		jr dasm_p0_s2_done

dasm_p0_s2_r47:
		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		; get source register into lowest 3 bits of A
		ld c,a				; save row bits
		rra
		rra
		rra
		and 0x7
		call mkarg_register_r
		ld a,c				; recover row bits
		
		ld c,1				; argument count
		rla
		jr c,dasm_p0_s2_r67

		rla
		ld a,op_AND			; ---- AND ----
		jr nc,dasm_p0_s2_done
		ld a,op_XOR			; ---- XOR ----
		jr dasm_p0_s2_done
dasm_p0_s2_r67:
		rla
		ld a,op_OR			; ---- OR ----
		jr nc,dasm_p0_s2_done
		ld a,op_CP			; ---- CP ----

dasm_p0_s2_done:
		push hl
		pop ix
		pop hl
		ld (ix+st_inst_opcode),a
		ld (ix+st_inst_argc),c
		jp dasm_page0_done

dasm_page0_done:
		pop bc
		pop ix
		ret

		include mkarg.asm
		include text.asm
		include mnemonic.asm
		include operand.asm

		cseg
		include test.asm

		dseg
dbuf		ds st_dasm_size
cbuf		ds 24

		end

