		name init

		extern demo
		extern kiraw
		extern tkinit	
		extern kiinit
		extern doinit
		extern vectab
		extern ckusec
		extern syscfg
		extern vrst10
		extern vrst18
		extern vrst20
		extern vrst38
		extern noprst
		extern nopisr

		include memory.asm
		include isr.asm
		include ports.asm
		include ctc.asm

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

		call initcfg
		call initvec
		call initrst
		call initctc

		call tkinit
		call doinit
		call kiinit
		im 2
		ei

		call demo
		halt

	;--------------------------------------------------------------
	; Load the system configuration from the system PIO.
	;
initcfg:
		; fetch config from PIO
		call kiraw
		ld a,h				; get high order bits
		rrca				; config bits
		rrca				;   are in the 
		rrca				;   uppermost
		rrca				;   nibble
		and 0xf				; just the config bits
		ld (syscfg),a			; store them
		
		; determine clock period in microseconds
		and 0x3				; just the clock speed bits
		ld b,a
		ld a,3
		sub b				; A  = 3 - clock speed bits
		ld hl,125			; 125 usec period for 8 MHz
		or a
		jr z,initcfg10			; go if 8 Mhz
		ld b,a
		add hl,hl			; 250 usec period for 4 MHz
		dec b
		jr z,initcfg10			; go if 4 Mhz
		add hl,hl			; 500 usec period for 2 Mhz
		dec b
		jr z,initcfg10			; go if 2 MHz
		add hl,hl			; 1000 usec period for 1 MHz
initcfg10:
		; store clock period
		ld de,ckusec
		ex de,hl
		ld (hl),e
		inc hl
		ld (hl),d
		
		ret

	;--------------------------------------------------------------
	; initctc:
	; Initializes the Z80 CTC on the mainboard
	;
initctc:
		; set all channels as externally triggered counters,
		; with per-channel interrupts disabled

ctc_chx_cfg	equ ctc_counter|ctc_trigger|ctc_reset|ctc_ctrl

		ld a,ctc_chx_cfg
		out (ctc_ch0),a
		out (ctc_ch1),a
		out (ctc_ch2),a
		out (ctc_ch3),a

		; set CTC base interrupt vector
		; other channels used fixed offset from this base
		ld a,isr_ctc_ch0
		out (ctc_ch0),a

		ret

	;--------------------------------------------------------------
	; initvec:
	; Initializes the mode 2 interrupt vector table
	;
initvec:
                ; set the mode 2 interrupt vector table page address
                ld a,high(vectab)
                ld i,a

		ld l,0
		ld h,a
		ld de,nopisr

		; set default ISR for mode 2 interrupt vectors
		ld b,im2_table_size / 2
initvec10:
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		djnz initvec10
		ret

	;--------------------------------------------------------------
	; initrst:
	; Initializes the user-programmable restart vectors.
	;
initrst:
		ld hl,noprst
		ld (vrst10),hl
		ld (vrst18),hl
		ld (vrst20),hl
		ld (vrst38),hl
		ret

		end

