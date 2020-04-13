; Symbol index values for opcodes
op_ADC		equ 0
op_ADD		equ 1
op_AND		equ 2
op_BIT		equ 3
op_CALL		equ 4
op_CCF		equ 5
op_CP		equ 6
op_CPD		equ 7
op_CPDR		equ 8
op_CPI		equ 9
op_CPIR		equ 10
op_CPL		equ 11
op_DAA		equ 12
op_DEC		equ 13
op_DI		equ 14
op_DJNZ		equ 15
op_EI		equ 16
op_EX		equ 17
op_EXX		equ 18
op_HALT		equ 19
op_IM		equ 20
op_IN		equ 21
op_INC		equ 22
op_IND		equ 23
op_INDR		equ 24
op_INI		equ 25
op_INIR		equ 26
op_JP		equ 27
op_JR		equ 28
op_LD		equ 29
op_LDD		equ 30
op_LDDR		equ 31
op_LDI		equ 32
op_LDIR		equ 33
op_NEG		equ 34
op_NOP		equ 35
op_OR		equ 36
op_OUT		equ 37
op_OUTD		equ 38
op_OTDR		equ 39
op_OUTI		equ 40
op_OTIR		equ 41
op_POP		equ 42
op_PUSH		equ 43
op_RES		equ 44
op_RET		equ 45
op_RETI		equ 46
op_RETN		equ 47
op_RL		equ 48
op_RLA		equ 49
op_RLC		equ 50
op_RLD		equ 51
op_RLCA		equ 52
op_RST		equ 53
op_RR		equ 54
op_RRA		equ 55
op_RRC		equ 56
op_RRD		equ 57
op_RRCA		equ 58
op_SBC		equ 59
op_SCF		equ 60
op_SET		equ 61
op_SLA		equ 62
op_SLL		equ 63
op_SRA		equ 64
op_SRL		equ 65
op_SUB		equ 66
op_XOR		equ 67

; symbol index values for registers
reg_A		equ 0
reg_B		equ 1
reg_C		equ 2
reg_D		equ 3
reg_E		equ 4
reg_H		equ 5
reg_L		equ 6
reg_AF		equ 7
reg_BC		equ 8
reg_DE		equ 9
reg_HL		equ 10
reg_SP		equ 11
reg_IX		equ 12
reg_IY		equ 13
reg_AAF		equ 14
reg_I		equ 15
reg_R		equ 16

; symbol index values for flags
fl_NZ		equ 17
fl_Z		equ 18
fl_NC		equ 19
fl_C		equ 20
fl_PO		equ 21
fl_PE		equ 22 
fl_P		equ 23
fl_M		equ 24

; bit patterns for pointer register 
reg_pointer     equ 2                   ; bit pattern when used as ss/qq
reg_indirect    equ 6                   ; bit pattern when used as register r

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
st_dasm_flags	equ 0
st_dasm_preg	equ 1
st_dasm_inst	equ 2
st_dasm_usize	equ st_dasm_inst + st_inst_size
st_dasm_size	equ st_dasm_usize + (16 - st_dasm_usize % 16)

