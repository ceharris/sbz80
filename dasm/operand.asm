s_reg_A		db 1,"A"
s_reg_B		db 1,"B"
s_reg_C		db 1,"C"
s_reg_D		db 1,"D"
s_reg_E		db 1,"E"
s_reg_H		db 1,"H"
s_reg_L		db 1,"L"
s_reg_AF	db 2,"AF"
s_reg_BC	db 2,"BC"
s_reg_DE	db 2,"DE" 
s_reg_HL	db 2,"HL"
s_reg_SP	db 2,"SP"
s_reg_IX	db 2,"IX"
s_reg_IY	db 2,"IY"
s_reg_AAF	db 3,"AF'"
s_reg_I		db 1,"I"
s_reg_R		db 1,"R"
s_fl_NZ		db 2,"NZ"
s_fl_Z		db 1,"Z"
s_fl_NC		db 2,"NC"
s_fl_C		db 1,"C"
s_fl_PO		db 2,"PO"
s_fl_PE		db 2,"PE"
s_fl_P		db 1,"P"
s_fl_M		db 1,"M"

s_table:
		dw s_reg_A
		dw s_reg_B
		dw s_reg_C
		dw s_reg_D
		dw s_reg_E
		dw s_reg_H
		dw s_reg_L
		dw s_reg_AF
		dw s_reg_BC
		dw s_reg_DE
		dw s_reg_HL
		dw s_reg_SP
		dw s_reg_IX
		dw s_reg_IY
		dw s_reg_AAF
		dw s_reg_I
		dw s_reg_R
		dw s_fl_NZ
		dw s_fl_Z
		dw s_fl_NC
		dw s_fl_C
		dw s_fl_PO
		dw s_fl_PE
		dw s_fl_P
		dw s_fl_M
s_table_end:
s_table_size	equ s_table_end - s_table
num_operands	equ s_table_size / 2

reg_r_table::
		db reg_B
		db reg_C
		db reg_D
		db reg_E
		db reg_H
		db reg_L
		db reg_HL
		db reg_A

reg_ss_table::
		db reg_BC
		db reg_DE
		db reg_HL
		db reg_SP

reg_qq_table::
		db reg_BC
		db reg_DE
		db reg_HL
		db reg_AF

flag_table::
		db fl_NZ
		db fl_Z
		db fl_NC
		db fl_C
		db fl_PO
		db fl_PE
		db fl_P
		db fl_M
