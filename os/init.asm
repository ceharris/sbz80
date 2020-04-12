		name init

		extern inivec 
		extern demo
		extern vectab

		include memory.asm

	;--------------------------------------------------------------
	; System reset handler
	;
	; This routine resets the user-assignable restart vector handlers,
	; sets up a stack in low writable memory and passes control to the
	; user program.
	;
		cseg
init::
		; stack grows down from start of umem
		ld sp,umem_start	

		; set the mode 2 interrupt vector table page address
		ld a,high(vectab)
		ld i,a

		call inivec
		call demo
		jp 0

		end
