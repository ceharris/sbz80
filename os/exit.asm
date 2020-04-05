		name exit

	;--------------------------------------------------------------
	; SVC: exit
	; Halts the CPU.
	; If an interrupt occurs the system restarts
	;
		cseg
exit::
		halt
		jp 0

		end
