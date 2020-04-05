		name post

		include memory.asm
		include ports.asm
mem_pattern	equ	0x55

	;--------------------------------------------------------------
	; Power-on Self Tests 
	; This routine runs tests on memory and various other subsystems.
	;
		cseg
post::
		exx

		; initialize system configuration register
		; need this to ensure upper bank zero is selected
		xor a
		out (sys_cfg_port),a			

		; fill memory with pattern
		ld hl,ram_start
		ld bc,ram_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),mem_pattern
                ldir

		; test that memory contains the pattern
                ld hl,ram_start
		ld bc,ram_size
		ld a,mem_pattern
post_mem10:
                cpi
		jp nz,post_fail
		jp pe,post_mem10

		; fill memory with pattern complement
                ld hl,ram_start
		ld bc,ram_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),~mem_pattern
                ldir

		; test that memory contains the pattern complement
                ld hl,ram_start
		ld bc,ram_size
		ld a,~mem_pattern
post_mem20:
                cpi
		jp nz,post_fail
                jp pe,post_mem20

		; fill memory with values that correspond to address LSB
                ld hl,ram_start
		ld bc,ram_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),0
post_mem30:
                ldi
		jp po,post_mem40
		inc (hl)
		jr post_mem30
post_mem40:
		inc (hl)

		; test that memory contains expected address LSBs
                ld hl,ram_start
		ld bc,ram_size
		ld a,0
post_mem50:
                cpi
		jp nz,post_fail
		jp po,post_mem60
		inc a
		jr post_mem50

		; fill memory with zeroes (NOP)
post_mem60:
                ld hl,ram_start
		ld bc,ram_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),0
                ldir
		exx
		jp (hl)			; return to caller

post_fail:
		halt

		end
