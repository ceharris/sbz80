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

m_adc		db 3,"ADC"
m_add		db 3,"ADD"
m_and		db 3,"AND"
m_bit		db 3,"BIT"
m_call		db 4,"CALL"
m_ccf		db 3,"CCF"
m_cp		db 2,"CP"
m_cpd		db 3,"CPD"
m_cpdr		db 4,"CPDR"
m_cpi		db 3,"CPI"
m_cpir		db 4,"CPIR"
m_cpl		db 3,"CPL"
m_daa		db 3,"DAA"
m_dec		db 3,"DEC"
m_di		db 2,"DI"
m_djnz		db 4,"DJNZ"
m_ei		db 2,"EI"
m_ex		db 2,"EX"
m_exx		db 3,"EXX"
m_halt		db 4,"HALT"
m_im		db 2,"IM"
m_in		db 2,"IN"
m_inc		db 3,"INC"
m_ind		db 3,"IND"
m_indr		db 4,"INDR"
m_ini		db 3,"INI"
m_inir		db 4,"INIR"
m_jp		db 2,"JP"
m_jr		db 2,"JR"
m_ld		db 2,"LD"
m_ldd		db 3,"LDD"
m_lddr		db 4,"LDDR"
m_ldi		db 3,"LDI"
m_ldir		db 4,"LDIR"
m_neg		db 3,"NEG"
m_nop		db 3,"NOP"
m_or		db 2,"OR"
m_out		db 3,"OUT"
m_outd		db 4,"OUTD"
m_otdr		db 4,"OTDR"
m_outi		db 4,"OUTI"
m_otir		db 4,"OTIR"
m_pop		db 3,"POP"
m_push		db 4,"PUSH"
m_res		db 3,"RES"
m_ret		db 3,"RET"
m_reti		db 4,"RETI"
m_retn		db 4,"RETN"
m_rl		db 2,"RL"
m_rla		db 3,"RLA"
m_rlc		db 3,"RLC"
m_rld		db 3,"RLD"
m_rlca		db 4,"RLCA"
m_rst		db 3,"RST"
m_rr		db 2,"RR"
m_rra		db 3,"RRA"
m_rrc		db 3,"RRC"
m_rrd		db 3,"RRD"
m_rrca		db 4,"RRCA"
m_sbc		db 3,"SBC"
m_scf		db 3,"SCF"
m_set		db 3,"SET"
m_sla		db 3,"SLA"
m_sll		db 3,"SLL"
m_sra		db 3,"SRA"
m_srl		db 3,"SRL"
m_sub		db 3,"SUB"
m_xor		db 3,"XOR"

m_table:
		dw m_adc
		dw m_add
		dw m_and
		dw m_bit
		dw m_call
		dw m_ccf
		dw m_cp
		dw m_cpd
		dw m_cpdr
		dw m_cpi
		dw m_cpir
		dw m_cpl
		dw m_daa
		dw m_dec
		dw m_di
		dw m_djnz
		dw m_ei
		dw m_ex
		dw m_exx
		dw m_halt
		dw m_im
		dw m_in
		dw m_inc
		dw m_ind
		dw m_indr
		dw m_ini
		dw m_inir
		dw m_jp
		dw m_jr
		dw m_ld
		dw m_ldd
		dw m_lddr
		dw m_ldi
		dw m_ldir
		dw m_neg
		dw m_nop
		dw m_or
		dw m_out
		dw m_outd
		dw m_otdr
		dw m_outi
		dw m_otir
		dw m_pop
		dw m_push
		dw m_res
		dw m_ret
		dw m_reti
		dw m_retn
		dw m_rl
		dw m_rla
		dw m_rlc
		dw m_rld
		dw m_rlca
		dw m_rst
		dw m_rr
		dw m_rra
		dw m_rrc
		dw m_rrd
		dw m_rrca
		dw m_sbc
		dw m_scf
		dw m_set
		dw m_sla
		dw m_sll
		dw m_sra
		dw m_srl
		dw m_sub
		dw m_xor
m_table_end:
m_table_size	equ m_table_end - m_table
num_mnemonics	equ m_table_size / 2
