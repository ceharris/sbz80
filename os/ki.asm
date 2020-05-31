	;--------------------------------------------------------------
	; Keyboard input support
	;
	; The SBZ80 mainboard has a 12-button keyboard that can be
	; used to provide input to programs. The keys are identified
	; as K0 through K11 and are connected to the least significant
	; twelve bits of a 16-bit parallel (broadside) load shift
	; register. The clock, load, and serial output signals of
	; shift register are connected to a few pins the A port of the
	; mainboard PIO unit. This module provides the support needed
	; to read key press and release events and to generate symbol
	; inputs from them.
	;
	; As with any input device made from mechanical switches, the
	; switch inputs must be debounced to eliminate spurious key
	; events produced as the switch contacts are joined and
	; separated. In this module, debounce is accomplished by
	; using a timer channel to drive an interrupt service routine
	; that scans the inputs and folds the new inputs into a simple
	; array-based filter algorithm.  Using this approach all twelve
	; inputs are debounced simultaneously with a period of 8.192
	; milliseconds.
	;
	; The resulting debounced state is used derive a stream of
	; input symbols using a table that translates the key into a
	; corresponding symbol which may a printable character or
	; a function identifier of some kind.
	;
	; Two of the keys are used interpreted as latching modifiers,
	; such that 40 different input symbols can be produced using
	; just 12 keys. When a modifier key is pressed and released,
	; the state of a modifier bit is toggled in memory. The two
	; modifier bits are then interpreted as a modulo-4 integer
	; multiplier to index the input symbol table when interpreting
	; a key press event from one of the non-modifer keys.
	;
	; Input symbols derived from the keyboard are placed into
	; a small ring buffer for subsequent retrieval by a program.
	; Service functions are also provided to set the symbol table
	; to use in interpreting inputs and to flush the ring buffer.
	;--------------------------------------------------------------

		name ki

		include memory.asm
		include isr.asm
		include ports.asm
		include ctc_defs.asm
		include pio_defs.asm

		extern syscfg
		extern kiring
		extern kirhd
		extern kirtl
		extern kiflag
		extern kistab
		extern kisamp
		extern kistat
		extern kiprev
		extern setisr

ki_port		equ 	pio_port_base + pio_port_a
ki_ctc_ch	equ 	ctc_ch7
ki_isr_vec	equ 	isr_ctc_ch7

ki_ctc_cfg	equ 	ctc_ei|ctc_timer|ctc_pre256|ctc_tc|ctc_reset|ctc_ctrl

ki_ser_in	equ 0x8
ki_shift	equ 0x10
ki_clock	equ 0x20

ki_sym_keys	equ 10			; number of symbol keys
ki_mod_mask	equ 0x3			; modifier key mask

	; Flag bit definitions
ki_flag_ibusy	equ 7			; Blocks ISR re-entry
ki_flag_mod_l	equ 1			; Left modifier state
ki_flag_mod_r	equ 0			; Right modifier state

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
		; initialize input ring buffer
		ld hl,kiring		; point to start of ring
		ld (kirhd),hl		; set the head pointer
		ld (kirtl),hl		; set the tail pointer

		; initialize symbol table pointer
		ld hl,0
		ld (kistab),hl

		xor a
		ld (kiflag),a		; zero the flags

		; initialize the samples array
		ld hl,kisamp		; point to index byte
		ld (hl),a		; zero the index byte
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
	; After the debounced keyboard state has been updated, the
	; debounced inputs are scanned to determine whether an input
	; symbol should be placed in an input ring buffer for program
	; consumption via the `kiget` SVC. See the `kisym` routine for
	; details.
	;
	; Because the process of scanning the keyboard and deriving
	; input symbols is pretty lengthy, this routine re-enables
	; interrupts as soon as possible. It uses a flag bit to prevent
	; a subsequent timer interrupt from fully re-entering this routine
	; before a current invocation is completed. In practice, given
	; an interrupt rate of about 10 ms, re-entrant invocations should
	; be fairly rare unless the system is exceptionally busy handling
	; other interrupts.
	;
	; The `kiinit` routine must be called exactly once to initialize
	; timer interrupt with a period of about 10 ms and to set up the
	; other necessary in-memory state.
	;
	; On return:
	;	- all registers preserved
	;	- `kisamp` system variable updated with next raw
	; 	  keyboard sample
	; 	- `kistat` system variable updated with debounced state
	;	  of all keys
	;	- `kiring` and associated pointers updated with any
	;	  input symbols derived from the debounced keyboard state
	;	- interrupts enabled
kidbnc::
		push af
		ld a,(kiflag)
		bit ki_flag_ibusy,a
		jr nz,kidbnc_skip	; don't re-enter

		; prevent re-entry before enabling interrupts
		set ki_flag_ibusy,a
		ld (kiflag),a
		ei

		; preserve the other registers we need
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
		jr c,kidbnc_no_wrap	; go if below ring size
		xor a			; reset to start of ring
kidbnc_no_wrap:
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
kidbnc_lower_keys:
		or (hl)
		inc hl
		djnz kidbnc_lower_keys
		ld e,a			; E = debounced keys

		; debounce keys K8-K11
		xor a
		ld b,ki_samples
kidbnc_upper_keys:
		or (hl)
		inc hl
		djnz kidbnc_upper_keys
		ld d,a			; D = debounced keys

		; save previous state and new state
		ld hl,(kistat)
		ld (kiprev),hl
		ld (kistat),de

		; scan for input only if debounced keyboard state changed
		or a
		sbc hl,de
		jr z,kidbnc_done

		; scan for input only if a symbol table is specified
		ld hl,(kistab)
		ld a,h
		or l
		jr z,kidbnc_done

		call kimod		; update modifier state
		call z,kisym		; check symbol input if no mod changed

kidbnc_done:
		; restore registers we used
		pop hl
		pop de
		pop bc

		; clear the busy flag before returning
		di
		ld a,(kiflag)
		res ki_flag_ibusy,a
		ld (kiflag),a
kidbnc_skip:
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

	;---------------------------------------------------------------
	; kimod:
	; Updates the current modifier key state.
	;
	; Modifier keys behave as toggles in the sense that a modifier
	; bit is set on or off by pressing and releasing a modifier key,
	; and remains in that state until the same modifier key is
	; pressed and released again.
	;
	; Modifier state is always cleared after a symbol is input.
	;
	; On entry:
	;	DE = debounced keyboard state
	;
	; On return:
	;	AF and C destroyed
	;	NZ indicates that modifier state was changed
	;
kimod:
		ld a,d			; get modifier bits
		srl a			; move into least
		srl a			;   significant bits
		and ki_mod_mask		; just the modifier bits

		; is either modifier key currently pressed?
		cp ki_mod_mask
		ret z			; no modifier key pressed

		cpl			; invert state (1=key down)
		ld c,a
		ld a,(kiflag)		; fetch keyboard flags
		xor c			; toggle modifier bits
		ld (kiflag),a		; store keyboard flags
		or 1			; set NZ to indicate modifier change
		ret

	;---------------------------------------------------------------
	; rinc:
	; Macro that does a modulo-N increment on the low order byte of
	; ring pointer, where N is the ring size.
	;
	; Parameters:
	;	s = source register for low order byte
	;	t = target register for incremented low order byte
	;
	; On return:
	;	t = (s + 1) mod ring_size
	;	AF destroyed
	;
rinc		macro t,s
		local rinc_no_wrap,rinc_end
		ld a,s
		cp low(kiring + ki_ring_size - 1)
		jr nz,rinc_no_wrap
		ld t,low(kiring)
		jr rinc_end
rinc_no_wrap:
		inc t
rinc_end:
		endm

	;---------------------------------------------------------------
	; kisym:
	; Scans the debounced keyboard state for the next input symbol.
	; If an input symbol is available, it is stored in the keyboard
	; ring buffer.
	;
	; This routine will only accept an symbol key as an input if
	; no other symbol key is pressed at the same time. Modifier keys
	; may be pressed (or latched) and will be used in selecting the
	; appropriate symbol from the currently selected symbol table.
	;
	; On entry:
	;	DE = debounced keyboard state
	;
	; On return:
	;	contents of all general purpose registers destroyed
	;	NZ indicates a symbol was input, Z indicates no input
	;
kisym:
		; check for available space in ring buffer
		ld hl,(kirtl)
		rinc l,l
		ld a,(kirhd)
		cp l
		ret z			; don't scan if ring buffer full

		ex de,hl		; HL = debounced keyboard state

		; find first pressed symbol key
		ld c,0			; symbol table "column"
		ld b,ki_sym_keys	; number of symbol keys
kisym_find_first:
		srl h			; shift all key bits right
		rr l
		jr nc,kisym_key_down	; go if found a key pressed
		inc c			; next symbol table "column"
		djnz kisym_find_first	; loop for all 10 symbol keys
		xor a			; indicate no key pressed
		ret
kisym_key_down:
		; check for more than one symbol key pressed
		dec b			; account for pressed key found
		jr z,kisym_check_mod	; no more symbol bits
		xor a			; zero to assume no key pressed
kisym_find_next:
		srl h			; shift all key bits right
		rr l
		ret nc			; return A=0 to mean no key pressed
		djnz kisym_find_next	; loop for remaining symbol keys

		; check for modifier bits
kisym_check_mod:
		ld a,(kiflag)		; fetch keyboard flags
		and ki_mod_mask		; mask off bits that aren't modifiers
		ld b,a			; will use them as a counter
		or a			; set Z if no modifier bits set

		ld hl,(kistab)		; fetch symbol table pointer
		jr z,kisym_no_mod	; go if no modifiers

		; compute table row pointer in HL
		ld de,10		; multiply by 10 for modifier combos
kisym_row_mult:
		add hl,de
		djnz kisym_row_mult

kisym_no_mod:
		; add column index to table row pointer
		ld a,l
		add a,c
		ld l,a
		adc a,h
		sub l
		ld h,a

		; clear used modifier state
		ld a,(kiflag)
		and ~ki_mod_mask	; clear modifier bits
		ld (kiflag),a

kisym_store_symbol:
		ld a,(hl)		; fetch the selected symbol
		or a
		ret z			; go if undefined symbol for key
		ld hl,(kirtl)		; fetch tail pointer
		ld (hl),a		; put symbol into the ring
		rinc l,l
		ld (kirtl),hl
		ret

	;---------------------------------------------------------------
	; SVC: kiptr
	; Gets a pointer to the 2-byte (debounced) keyboard status
	; buffer. The keyboard status is continually updated as long as
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
	; SVC: kiget
	; Gets the next input symbol entered on the keyboard.
	;
	; As input symbols are scanned from the debounced keyboard
	; signals, they are placed into a small ring buffer and retained
	; until retrieved by this method.
	;
	; On return:
	;	NZ => A contains the next input symbol
	;	Z => no input symbol was available
	;
kiget::
		push hl
		ld hl,(kirhd)		; fetch head pointer
		ld a,(kirtl)		; fetch tail pointer LSB (same MSB)
		cp l
		jr z,kiget_done		; buffer empty if pointers equal
		rinc a,l		; increment head pointer
		ld (kirhd),a		; store head pointer
		ld a,(hl)		; fetch the stored symbol
		or a			; clear zero flag
kiget_done:
		pop hl
		ret

	;---------------------------------------------------------------
	; SVC: kiflus
	; Flushes the ring buffer used to hold symbol input such that
	; any input waiting in the buffer is discarded.
	;
	; On return:
	;	AF destroyed
	;
kiflus::
		push hl

		; Move head up to current tail.
		; It's important that we change only the head pointer
		; since interrupts might be enabled.

		ld hl,(kirtl)		; fetch tail pointer
		ld (kirhd),hl		; store as head pointer
		pop hl
		ret

	;---------------------------------------------------------------
	; SVC: kictab
	; Changes the keyboard symbol table.
	;
	; Subsequent input symbols scanned from the keyboard will use
	; the specified symbol table. Inputs already scanned and placed
	; in the input queue not unchanged.
	;
	; On entry:
	;	HL = pointer to 40-byte symbol table
	;
	; On return:
	;	all registers preserved
	;
kictab::
		ld (kistab),hl
		ret

		end
