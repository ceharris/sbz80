	;--------------------------------------------------------------
	; Keyboard input support
	;
		name ki

		include memory.asm
		include isr.asm
		include ports.asm
		include ctc_defs.asm
		include pio_defs.asm

		extern syscfg
		extern kisamp
		extern kistat
		extern setisr

ki_port		equ 	pio_port_base + pio_port_a
ki_ctc_ch	equ 	ctc_ch4
ki_isr_vec	equ 	isr_ctc_ch4

ki_ctc_cfg	equ 	ctc_ei|ctc_timer|ctc_pre256|ctc_tc|ctc_reset|ctc_ctrl

ki_ser_in	equ 0x8
ki_shift	equ 0x10
ki_clock	equ 0x20

		cseg

		; Time Constants by clock rate for 8.192 msec scan period
tc_tab		db	32		; 1 MHz
		db	64		; 2 MHz
		db	128		; 4 MHz
		db	0		; 8 MHz

	;---------------------------------------------------------------
	; kiinit:
	; Initialize system variables used for keyboard input support.
	;

kiinit::
		; initialize the samples array
		ld hl,kisamp		; point to index byte
		xor a			; zero it
		ld (hl),a
		ld b,2*(ki_samples + 1)	; plus 1 for status word
		dec a			; now A is all ones
kiinit10:
		inc hl
		ld (hl),a
		djnz kiinit10

		ld hl,kidbnc		; address of keyboard ISR
		ld c,ki_isr_vec		; interrupt vector number
		call setisr		; set ISR vector

		ld a,ki_ctc_cfg
		out (ki_ctc_ch),a	; configure our channel

		ld a,(syscfg)
		and 0x3			; get clock speed from config

		; point HL to TC table entry for clock speed
		ld hl,tc_tab		; point to start of TC table
		add a,l
		ld l,a			; LSB of table entry
		adc a,l			; propagate the carry
		sub l			; remove bias of L
		ld h,a			; MSB of table entry

		; set TC for our channel
		ld a,(hl)		; fetch TC for clock speed
		out (ki_ctc_ch),a	; set TC

		ret

	;---------------------------------------------------------------
	; SVC: kiptr
	; Gets a pointer to the 2-byte (debounced) keyboard status
	; buffer. The keyboard status is continually updated so long as
	; interrupts are enabled. A program can obtain this pointer and
	; scan the keyboard by observing changes to the state of the
	; corresponding 2-byte buffer.
	;
	; On return:
	;	HL -> keyboard status buffer
	;
	;	(HL + 0) bit 0 = K0
	;	(HL + 0) bit 1 = K1
	;	...
	;	(HL + 0) bit 7 = K7
	; 	(HL + 1) bit 0 = K8
	;	...
	;	(HL + 1) bit 3 = K11
	;
	;	(HL + 1) bits 4-7 are hardwired system config flags

kiptr::
		ld hl,kistat
		ret

	;---------------------------------------------------------------
	; SVC: kiread
	; Reads (debounced) state of the keyboard. For programs that
	; need to continuously scan the keyboard, it is more efficient
	; to obtain a pointer to the keyboard status buffer using
	; the @kiptr service.
	;
	; On return:
	;	HL = keyboard state as individual bits, where any key that
	;	     is currently pressed is represented as a zero.
	;
	;	     L bit 0 = K0
	;	     L bit 1 = K1
	;	     ...
	;            L bit 7 = K7
	;	     H bit 0 = K8
	;            ...
	;	     H bit 3 = K11
	;
	;            H bits 4-7 are hardwired system configuration flags

kiread::
		ld hl,(kistat)
		ret

	;---------------------------------------------------------------
	; kidbnc:
	; Debounce the keyboard
	;
	; This routine is intended to be invoked periodically from a
	; timer interrupt with a period of about 10 ms. Each time it
	; is called, it reads the (raw) keyboard inputs and stores it
	; as a sample in a ring buffer. The routine then scans the
	; buffer to determine which keys have been active (low) for at
	; least as long as t*N, where t is the sample period and N is
	; the number of samples.
	;
	; The `kiinit` routine must be called exactly once to initialize
	; timer interrupt with a period of about 10 ms. Each time it
	; is called, it reads the (raw) keyboard inputs and stores it
	; as a sample in a ring buffer. The routine then scans the
	; buffer to determine which keys have been active (low) for at
	; least as long as t*N, where t is the sample period and N is
	; the number of samples.
	;
	; The `kiinit` routine must be called exactly once to initialize
	; the system variables `kisamp` and `kistat` before invoking
	; this routine
	;
	; On return:
	;	- all registers preserved
	;	- `kisamp` system variable updated with next raw
	; 	  keyboard sample
	; 	- `kistat` system variable updated with debounced state
	;	   of all keys
	;

kidbnc::
		; preserve all registers we use
		push af
		push bc
		push de
		push hl

		; get fresh keyboard input sample into DE
		call kiraw
		ld e,l
		ld d,h

		; point HL to position for current sample
		ld hl,kisamp
		ld a,(hl)		; fetch sample index
		ld c,a			; save current index
		inc a			; next sample index
		cp ki_samples		; at ring size?
		jr c,kidbnc10		; go if below ring size
		xor a			; reset to start of ring
kidbnc10:
		ld (hl),a		; store next sample index
		inc hl			; point to start of samples

		; set HL to address for LSB of current sample
		ld a,c			; recover current sample index
		add a,l
		ld l,a
		adc a,h
		sub l
		ld h,a			; HL -> storage for LSB of sample
		ld (hl),e		; store it

		; now get address for MSB of current sample
		ld a,ki_samples
		add a,l
		ld l,a
		adc a,h
		sub l
		ld h,a			; HL -> storage for MSB of sample
		ld (hl),d		; store it

		; point to samples
		ld hl,kisamp
		inc hl			; skip index byte

		; debounce keys K0-K7
		xor a
		ld b,ki_samples
kidbnc20:
		or (hl)
		inc hl
		djnz kidbnc20
		ld e,a			; E = debounced keys

		; debounce keys K8-K11
		xor a
		ld b,ki_samples
kidbnc30:
		or (hl)
		inc hl
		djnz kidbnc30
		ld d,a			; D = debounced keys

		; store debounced key bits (HL -> kistat)
		ld (hl),e
		inc hl
		ld (hl),d

		; restore all registers we used
		pop hl
		pop de
		pop bc
		pop af
		ei
		reti

	;---------------------------------------------------------------
	; kiraw:
	; Performs a raw read of the 16-bit shift register which provides
	; the keyboard input bits. This function must be called from a
	; debounce routine in order to get stable keyboard inputs.
	;
	; On return:
	;	HL contains the 16-bit word from the shift register
	;	AF destroyed
	;
kiraw::
		push bc


		; toggle SH/LD# from high to low to load the shift register
		in a,(ki_port)
		or low(ki_shift & not(ki_clock))
		out (ki_port),a			; SH/LD#=1 CLK=0
		and low(not(ki_shift))
		out (ki_port),a			; SH/LD#=0 CLK=0
		or ki_shift
		out (ki_port),a			; SH/LD#=1 CLK=0

		ld b,16				; load 16 bits
kiraw10:
		; make room for next bit
		sla l
		rl h

		; read next bit and set in result word if not zero
		in a,(ki_port)
		and ki_ser_in
		or a			; is the input bit a one?
		jr z,kiraw20
		set 0,l
kiraw20:
		; pulse clock line to shift next bit into input
		in a,(ki_port)
		or ki_clock
		out (ki_port),a 	; CLK=1
		and low(not(ki_clock))
		out (ki_port),a		; CLK=0

		djnz kiraw10

		pop bc
		ret

		end
