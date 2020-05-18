	;--------------------------------------------------------------
	; Mainboard CTC Support
	;
	; The mainboard is equipped with two Z80 CTC units, providing
	; a total of 8 programmable timer/counter channels. Three of
	; the channels are unassigned and available for programming as
	; timers or for hardware interfacing.
	;	
	; Eight contiguous I/O ports are assigned to the mainboard CTC
	; channels; CTC-A channels 0-3 and CTC-B channels 0-3 are 
	; assigned in order.
	;
	; The standard Z80 interrupt priority chain is implemented for 
	; each of the CTC units. CTC-A is the highest priority device in 
	; the chain attached to the Z80 and CTC-B is at a lower priority
	; The CTC prioritizes channel interrupt events in channel order, 
	; therefore the interrupt priority of the channels corresponds 
	; to the order in which the channels are assigned to I/O ports, 
	; with CTC-A channel 0 having the highest priority and CTC-B channel
	; 3 having the lowest priority.
	; 
	; Channel Asignments
	; ------------------
	; CTC-A channel 0: timer tick
	; CTC-A channel 1: (reserved for future SIO)
	; CTC-A channel 2: (reserved for future SIO)
	; CTC-A channel 3: delay service function
	; CTC-B channel 0: (unassigned)
	; CTC-B channel 1: (unassigned)
	; CTC-B channel 2: (unassigned)
	; CTC-B channel 3: keyboard scan and debounce
	; 

		include isr.asm
		include ports.asm
		include ctc_defs.asm

		cseg

	;--------------------------------------------------------------
	; ctcini:
	; Initializes the mainboard CTC units
	;

ctcini::
		; set all channels as externally triggered counters,
		; with per-channel interrupts disabled

		ld a,ctc_default
		out (ctc_ch0),a
		out (ctc_ch1),a
		out (ctc_ch2),a
		out (ctc_ch3),a
		out (ctc_ch4),a
		out (ctc_ch5),a
		out (ctc_ch6),a
		out (ctc_ch7),a

		; set CTC base interrupt vector for CTC-A
		; other channels used fixed offset from this base
		ld a,2*isr_ctc_ch0
		out (ctc_ch0),a

		; set CTC base interrupt vector for CTC-B
		; other channels used fixed offset from this base
		ld a,2*isr_ctc_ch4
		out (ctc_ch4),a

		ret

		end

