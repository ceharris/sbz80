
		name tk
		extern setisr
		extern d32x16
		extern d32x8
		extern d16x8

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

	;---------------------------------------------------------------
	; SVC: tkgets
	; Gets the system elapsed time as a string in the format.
	; '(N*)Nd HH:MM:SS'
	;
	; On entry:
	;	HL = pointer to buffer to receive the string
	;
	; On return:
	;	all registers except AF preserved
	;
tkgets::
		push bc
		push de
		push hl
		push ix

		; blank buffer and null terminate
		ld b,16
tkgets10:
		ld (hl),' '
		inc hl
		djnz tkgets10
		ld (hl),0

		; put HL into IX
		ld a,l
		ld ixl,a
		ld a,h
		ld ixh,a

		; get tick counter into DEHL (units are 500 microseconds)
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

		; shift DEHL right to get milliseconds
		srl d
		rr e
		rr h
		rr l

		; divide DEHL by 1000 to get seconds
		ld bc,1000
		call d32x16

                ; divide DEHL by 60 to get minutes (quotient)
                ; and seconds (remainder)
                ld c,60
		call d32x8

		; convert seconds to decimal and add delimiter
		call tocunit
		dec ix
		ld (ix),':'

		; divide DEHL by 60 to get hours (quotient)
		; and minutes (remainder)
		ld c,60
		call d32x8

		; convert minutes to decimal and add delimiter
		call tocunit
		dec ix
		ld (ix),':'

		; divide DEHL by 24 to get days (quotient)
		; and hours (remainder)
		ld c,24
		call d32x8

		; convert hours to decimal
		call tocunit

		; insert space
		dec ix
		ld (ix),' '

		; insert units indicator
		dec ix
		ld (ix),'d'

tkgets20:
		; divide HL by 10 to get next digit of elapsed days
		ld c,10
		call d16x8

		; convert digit to decimal and prepend to buffer
		add a,'0'
		dec ix
		ld (ix),a

		; is the quotient still non-zero?
		ld a,h
		or l
		jr nz,tkgets20

		pop ix
		pop hl
		pop de
		pop bc
		ret

	;---------------------------------------------------------------
	; tocunit:
	; Converts a binary value to a decimal chrono unit using a table
	; lookup. Binary values in the range 0..59 can be converted.
	;
	; On entry:
	;	A = the value to be converted
	;	IX = successor to the buffer position at which the
	;	digit pair is to be inserted.
	;
	; On return:
	;	IX = buffer position of leading digit of chrono unit
	;	AF destroyed
	;	all other registers preserved
	;
tocunit:
		push hl

		; get pointer to digit pair to display
		rlca			; times two for two digits
		ld hl,chronotab		; point to start of lookup table
		add a,l
		ld l,a			; L = table entry LSB
		adc a,h
		sub l
		ld h,a			; H = table entry MSB

		inc hl			; second digit first
		dec ix
		ld a,(hl)
		ld (ix),a

		dec hl			; now first digit
		dec ix
		ld a,(hl)
		ld (ix),a

		pop hl
		ret

chronotab	db '000102030405060708091011121314'
		db '151617181920212223242526272829'
		db '303132333435363738394041424344'
		db '454647484950515253545556575859'

		end
