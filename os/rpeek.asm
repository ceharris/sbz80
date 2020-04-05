		name rpeek

	;----------------------------------------------------------
	; rpeek:
	; Store all current machine registers in memory to allow
	; them to be examined for debugging.
	;
		cseg
rpeek::
		push bc 		; preserve caller's BC

		; store general purpose registers
		ld (reg_bc),bc
		ld (reg_de),de
		ld (reg_hl),hl

		; store index registers
		ld (reg_ix),ix
		ld (reg_iy),iy

		; store accumulator and flags
		push af
		pop bc
		ld (reg_af),bc

		; store alternate general purpose registers
		exx
		ld (areg_bc),bc
		ld (areg_de),de
		ld (areg_hl),hl
		exx

		; store alternate accumulator and flags
		ex af,af'
		push af
		pop bc
		ld (areg_af),bc
		ex af,af'

		pop bc			; restore caller's BC

		; store I and R registers
		push af
		ld a,r
		ld (reg_r),a
		ld a,i
		ld (reg_i),a
		pop af		

		; store stack pointer
		ld (reg_sp),sp		; store SP
		push hl
		ld hl,(reg_sp)		; get SP into HL
		inc hl			; adjust for return address on stack
		inc hl
		ld (reg_sp),hl		; store adjusted SP
		pop hl

		; store program counter
		ex (sp),hl		; ret addr at top of stack is PC
		ld (reg_pc),hl		; store PC
		ex (sp),hl		; put back the return address

		ret

	;----------------------------------------------------------
	; SVC rpcpy:
	; Copies registers stored by rpeek into a user provided buffer
	;
	; On entry:
	;	HL = destination buffer

		cseg
rpcpy::
		push hl
		push de
		push bc
		ld e,l
		ld d,h
		ld hl,regs
		ld bc,regs_size
		ldir
		pop bc
		pop de
		pop hl	
		ret		

        ; Storage for peeked register contents
		dseg
regs:
reg_af          ds 2
reg_bc          ds 2
reg_de          ds 2
reg_hl          ds 2
areg_af         ds 2
areg_bc         ds 2
areg_de         ds 2
areg_hl         ds 2
reg_ix          ds 2
reg_iy          ds 2
reg_i           ds 1
reg_r           ds 1
reg_sp          ds 2
reg_pc          ds 2
regs_end:

regs_size	equ regs_end - regs		; size of register buf

		end
