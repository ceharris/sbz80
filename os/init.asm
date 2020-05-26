		name init

		extern ctcini
		extern pioini
		extern rtcini
		extern tkinit
		extern kiinit
		extern doinit
		extern kiraw
		extern demo

		extern vectab
		extern cknsec
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
		include ctc_defs.asm

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

		call ctcini
		call pioini
		call rtcini

		call initcfg
		call initvec
		call initrst

		call tkinit
		call doinit
		call kiinit
		im 2
		ei

		call demo
		halt

	;--------------------------------------------------------------
	; Load the system configuration from the keyboard register.
	;
initcfg:
		; fetch config from keyboard register via PIO
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
		ld hl,125			; 125 nsec period for 8 MHz
		or a
		jr z,initcfg10			; go if 8 Mhz
		ld b,a
		add hl,hl			; 250 nsec period for 4 MHz
		dec b
		jr z,initcfg10			; go if 4 Mhz
		add hl,hl			; 500 nsec period for 2 Mhz
		dec b
		jr z,initcfg10			; go if 2 MHz
		add hl,hl			; 1000 nsec period for 1 MHz
initcfg10:
		; store clock period
		ld de,cknsec
		ex de,hl
		ld (hl),e
		inc hl
		ld (hl),d

		; select default configuration (bank 0)
		xor a
		out (sys_cfg_port),a

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

