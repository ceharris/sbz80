
	;-------------------------------------------------------------
	; optest:
	; A macro that produces a test case for an instruction and
	; its operands. The resulting code disassembles the given
	; instruction and compares it to the expected disassembly.
	; If the actual disassembly matches the expected disassembly,
	; execution continues at the next address following the macro
	; expansion. Otherwise, the r is halted; HL points at
	; the expected and DE points at the actual and execution continues
	; at the fail label.
	;
	; Parameters:
	; 	a_op	the instruction to test
	;	a_exp	string containing the expected disassembly
	; 
optest		macro a_op,a_exp
		local op,exp,done

                ld (iy+st_dasm_level),0
                ld (iy+st_dasm_preg),reg_HL
                ld ix,dbuf+st_dasm_inst

		ld hl,op
		call dasm
                ld de,cbuf
		call i2str	
		ld hl,exp
		call validate
		jr z,done

		jp fail

op:		`a_op`
exp:		db `a_exp`,0
done:
		endm

