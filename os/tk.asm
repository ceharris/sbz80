
		name tk
		extern setisr
		extern tkcnt
		extern tkprd
		extern syscfg

		include ports.asm
		include isr.asm
		include ctc_defs.asm

tk_ctc_ch	equ ctc_ch0
tk_ctc_cfg  	equ ctc_ei|ctc_timer|ctc_pre16|ctc_tc|ctc_reset|ctc_ctrl

clk_speed_mask	equ 0x3

		cseg

		; time constants for configurable clock speeds
tctab		db	125			; 1 MHz clock
		db	250			; 2 MHz	clock
		db	250			; 4 MHz	clock
		db	250			; 8 MHz clock

		; tick periods (in units of 500 usec) for configurable 
		; clock speeds
tktab 		db	4			; 1 MHz clock
		db	4			; 2 MHz clock
		db	2			; 4 MHz clock
		db	1			; 8 MHz clock

	;---------------------------------------------------------------
	; tkinit:
	; Initializes the tick counter. The counter represents the
	; number of 500 usec units that have elapsed since the timer was
	; started. The counter will wrap after 24d 20:31:23.648.
	;	
tkinit::
		; set the 32-bit counter to zero
                xor a
                ld hl,tkcnt
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a

		; put the ISR address into the mode 2 interrupt vector table
		ld hl,tkinc			; address of the ISR
		ld c,isr_ctc_ch0		; interupt vector number
		call setisr			; set vector in table
		
		; set control word for our CTC channel
		ld a,tk_ctc_cfg			
                out (tk_ctc_ch),a
	
		; point HL to time constant table entry
		ld a,(syscfg)			; get system config bits
		and clk_speed_mask		; just the clock speed bits
		ld hl,tctab			; point to first table entry
		add a,l				; add clock speed bits
		ld l,a				; save LSB
		adc a,h				; roll the carry into MSB
		sub l				; remove LSB bias
		ld h,a				; HL -> table entry

		; set TC on our channel
		ld a,(hl)		
		out (tk_ctc_ch),a
		
		; point HL to tick period table entry
		ld a,(syscfg)			; get system config bits
		and clk_speed_mask		; just the clock speed bits
		ld hl,tktab			; point to start of table
		add a,l				; add clock speed bits
		ld l,a				; save LSB
		adc a,h				; roll the carry into MSB
		sub l				; remove LSB bias
		ld h,a				; HL -> table entry
		ld a,(hl)			; retrieve tick period
		ld (tkprd),a			;     and store it

		ret

	;---------------------------------------------------------------
	; tkinc:
	; Interrupt service routine for the CTC channel used for the 
	; timer tick.
	;
tkinc::
                push af
                push hl

		ld a,(tkprd)			; get the tick period
                ld hl,tkcnt                     ; point to byte 0
                add a,(hl)                      ; add period to LSB
		ld (hl),a			; store LSB
                jr nc,tkinc10                   ; go if LSB didn't wrap

		; propagate carry through upper bytes
                inc hl                          ; point to byte 1
                inc (hl)                        ; increment it
                jr nz,tkinc10                   ; go if didn't wrap
                inc hl                          ; point to byte 2
                inc (hl)                        ; increment it
                jr nz,tkinc10                   ; go if didn't wrap
                inc hl                          ; point to byte 3
                inc (hl)                        ; increment it
tkinc10:
                pop hl
                pop af
		ei
                reti

	;---------------------------------------------------------------
	; SVC: tkread
	; Read the current value of the tick counter. The value represents
	; the number of ticks elapsed time the timer was started. Each
	; tick is 500 usec.
	; 
	; On return:
	; 	tick counter returned as a 32-bit value in DEHL
	;	
tkread::
		push bc
		ld hl,tkcnt+3
		di
		ld d,(hl)
		dec hl
		ld e,(hl)
		dec hl
		ld b,(hl)
		dec hl
		ld c,(hl)
		ei
		ld l,c
		ld h,b
		pop bc
		ret		
		
	;---------------------------------------------------------------
	; SVC: tkrdms
	; Reads the current value of the tick counter and converts to 
	; milliseconds.
	; 
	; On return:
	; 	elapsed milliseconds returned as a 32-bit value in DEHL
	;	C flag contains the previous least significant bit which
	;	could be used to round the number of milliseconds if
	;	desired.
	;	
tkrdms::
		call tkread
		srl d
		rr e
		rr h
		rr l
		ret

		end
