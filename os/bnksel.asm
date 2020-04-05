		name bnksel
		include ports.asm
bank_mask       equ 	0xfc		; lower 2 bits are bank selection

	;--------------------------------------------------------------
	; SVC: bnksel
	; Selects a 32K	memory bank to reside at address 0x8000.
	; The system supports 4 switchable 32K banks. When switching
	; banks, it is important to properly account for the PC and SP 
	; registers, otherwise the system may crash. Attempts to select 
	; an invalid bank number are ignored and NZ status is returned.
	; 
        ; On entry:
	;	C = the bank number (0-3) to place at address 0x8000
	; On return:
	;	Z flag is set if a bank was selected
	;

		cseg
bnksel::
		ld a,c
		cp 4			; clear carry flag if out of range
		jr nc,banksel10

		ld a,(sys_cfg_reg)
		and bank_mask		; clear bank selection
		or c			; set bank selection bits
		ld (sys_cfg_reg),a	; store configuration register
		out (sys_cfg_port),a	; set configuration register
		xor a			; set zero flag
		ret
banksel10:
		or a			; clear zero flag
		ret		


		dseg
vars:
sys_cfg_reg     ds 1                    ; system config register contents

align		ds (align - vars) % 2 	; pad for alignment
 
