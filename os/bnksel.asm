		name bnksel

		include ports.asm

bank_mask       equ 	0xc0		; upper 2 bits are bank selection

	;--------------------------------------------------------------
	; SVC: bnksel
	; Selects a 32K	memory bank to reside at address 0x8000.
	; The system supports 3 switchable 32K banks. When switching
	; banks, it is important to properly account for the PC and SP 
	; registers, otherwise the system may crash. Attempts to select 
	; an invalid bank number are ignored and NZ status is returned.
	; 
        ; On entry:
	;	C = the bank number (0-2) to place at address 0x8000
	; On return:
	;	Z flag is set if a bank was selected
	;	C is destroyed
	;

		cseg
bnksel::
		ld a,c
		cp 3			; clear carry flag if out of range
		jr nc,banksel10
		
		; bank selection is bits 6 and 7
		rrca
		rrca
		ld c,a

		in a,(sys_cfg_port)	; retrieve config register
		and low(not(bank_mask))	; clear bank selection bits
		or c			; set bank selection bits
		out (sys_cfg_port),a	; set configuration register
		xor a			; set zero flag
		ret
banksel10:
		or a			; clear zero flag
		ret		
