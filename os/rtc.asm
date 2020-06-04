	;---------------------------------------------------------------
	; Real Time Clock support
	;
	; The SBZ80 is equipped with a Benchmark BQ4845 real time clock
	; peripheral. The BQ4845 provides a real time source counting
	; and storing seconds, minutes, hours, days, months, years in
	; BCD format. A 3V lithium battery provides power to keep time
	; even when the system power supply is disconnected, and the
	; BQ4845 provides additional capability to sustain power to
	; external SRAM which might be used as a future enhancement to
	; the SBZ80 system.
	;
	; The BQ4845 is I/O addressable on the SBZ80 and includes
	; 16 registers which are all read/write. The upper four bits
	; of the I/O address are configured using a 4-position switch
	; pack on the module. The upper four I/O address lines and the
	; switch positions are connected to a comparator to drive the
	; chip select input of the BQ4845.
	;
	; The BQ4845 includes support for generating interrupts for
	; several different conditions. Connecting this to the Z80
	; interrupt input requires some additional supporting logic,
	; as the BQ4845 provides no means to output a vector onto the
	; bus when the interrupt is acknowledged by the CPU. For this
	; reason, the interrupt output of the BQ4845 is connected to
	; PA7 of the mainboard PIO. The active low interrupt output is
	; open drain, therefore PA7 is tied to +5V through a 10K ohm
	; resistor. Port A of the PIO is then configured such that it
	; signals an interrupt to the CPU and provides the apppropriate
	; vector whenever the BQ4845 signals an interrupt.


		name rtc

		extern setisr
		extern rtcph
		extern rtcah

		include isr.asm
		include ports.asm
		include pio_defs.asm
		include rtc_defs.asm

iso_date_delim	equ '-'
iso_separator	equ 'T'
iso_time_delim	equ ':'

century_digit1	equ '2'
century_digit2  equ '0'

rtc_isr_vec	equ isr_pio_port_a


		cseg

dowtab		db 'Sun',0
		db 'Mon',0
		db 'Tue',0
		db 'Wed',0
		db 'Thu',0
		db 'Fri',0
		db 'Sat',0

montab		db 'Jan',0
		db 'Feb',0
		db 'Mar',0
		db 'Apr',0
		db 'May',0
		db 'Jun',0
		db 'Jul',0
		db 'Aug',0
		db 'Sep',0
		db 'Oct',0
		db 'Nov',0
		db 'Dec',0

	;---------------------------------------------------------------
	; rtcini:
	; Initialize the RTC subsystem.
	;
rtcini::
		; set default handler for RTC interrupts
		ld hl,rtc_nop_handler
		ld (rtcph),hl
		ld (rtcah),hl

		; set twenty-four hour mode, enable DST,
		; and start the oscillator

		ld a,rtc_24hr_m|rtc_dse_m|rtc_run_m
		out (rtc_port_ctl),a

		ret

	;---------------------------------------------------------------
	; SVC: rtcpt
	; Schedule a periodic callback.
	;
	; On entry:
	;	C = rate (0 to 15)
	;	HL = callback routine
	;
	; On return:
	;	AF, HL destroyed
	;	all other registers preserved
	;
rtcpt::
		push bc
		ld b,c			; save the rate

		; set handler address
		ld (rtcph),hl

		; set the interrupt service routine
		ld c,rtc_isr_vec
		ld hl,rtcisr
		call setisr

		; set the period in the rate register
		ld a,b			; recover the rate
		and 0xf			; rate is only 4 bits
		ld c,a			; preserve rate
		in a,(rtc_port_rate)
		and 0xf0		; clear rate bits
		or c			; set new rate bits
		out (rtc_port_rate),a

		; enable periodic interrupt
		in a,(rtc_port_ei)
		set rtc_pie,a
		out (rtc_port_ei),a

		pop bc
		ret

	;---------------------------------------------------------------
	; SVC: rtcalm
	; Schedule an alarm.
	;
	; On entry:
	;	B = day of month
	;	C = hour
	;	D = minute
	;	E = second
	;	HL = callback routine
	;
	; On return:
	;	AF, HL destroyed
	;	all other registers preserved
	;
rtcalm::
		push bc

		; alarm second
		ld a,e
		out (rtc_port_asec),a

		; alarm minute
		ld a,d
		out (rtc_port_amin),a

		; alarm hour
		ld a,c
		out (rtc_port_ahour),a

		; alarm day-of-month
		ld a,b
		out (rtc_port_adom),a

		; set handler address
		ld (rtcah),hl

		; set the interrupt service routine
		ld c,rtc_isr_vec
		ld hl,rtcisr
		call setisr

		; enable alarm interrupt
		in a,(rtc_port_ei)
		set rtc_aie,a
		out (rtc_port_ei),a

		pop bc
		ret

	;---------------------------------------------------------------
	; SVC: rtcsta
	; Sets the current date and time using an ASCII-coded ISO8601
	; representation.
	;
	; On entry:
	;	HL = pointer to buffer containing ISO8601 date and time
	;
	; On return:
	;	HL points at next byte past end of buffer
	;	AF destroyed
	;	all other registers preserved
	;
rtcsta::
		push bc
		in a,(rtc_port_ctl)
		set rtc_uti,a
		res rtc_run,a
		out (rtc_port_ctl),a

		; skip century
		inc hl
		inc hl

		; year
		call rtc_a2b
		out (rtc_port_year),a

		; month
		call rtc_a2b
		out (rtc_port_month),a

		; day of month
		call rtc_a2b
		out (rtc_port_dom),a

		; day of week can be used in place of usual separator
		ld a,(hl)
		cp iso_separator
		jr z,rtcsta_no_weekday		; no day of week specified

		dec hl				; need two digits
		call rtc_a2b
		and 0xf				; discard first digit
		out (rtc_port_dow),a

rtcsta_no_weekday:
		; hour
		call rtc_a2b
		out (rtc_port_hour),a

		; minute
		call rtc_a2b
		out (rtc_port_min),a

		; sec
		call rtc_a2b
		out (rtc_port_sec),a

		in a,(rtc_port_ctl)
		res rtc_uti,a
		set rtc_run,a
		out (rtc_port_ctl),a

		pop bc
		ret

	;---------------------------------------------------------------
	; SVC: rtcstb
	; Sets the current date and time using the RTC's binary coded
	; decimal representation.
	;
	; On entry:
	;	HL = pointer to buffer
	;	(HL + 0) = seconds (0..59)
	;	(HL + 1) = minutes (0..59)
	;	(HL + 2) = hours (0..23, 81..92)
	;	(HL + 3) = day of month (1..31)
	;	(HL + 4) = day of week (1..7)
	;	(HL + 5) = month (1..12)
	;	(HL + 6) = year (0..99)
	;
	; On return:
	;	HL points at next byte past end of buffer
	;	AF destroyed
	;	all other registers preserved
	;

rtcstb::
		; set RTC UTI bit and stop the clock
		in a,(rtc_port_ctl)
		set rtc_uti,a
		res rtc_run,a
		out (rtc_port_ctl),a

		; set second
		ld a,(hl)
		inc hl
		out (rtc_port_sec),a

		; set minute
		ld a,(hl)
		inc hl
		out (rtc_port_min),a

		; set hour
		ld a,(hl)
		inc hl
		out (rtc_port_hour),a

		; set day-of-month
		ld a,(hl)
		inc hl
		out (rtc_port_dom),a

		; set day-of-week
		ld a,(hl)
		inc hl
		out (rtc_port_dow),a

		; set month
		ld a,(hl)
		inc hl
		out (rtc_port_month),a

		; set year
		ld a,(hl)
		inc hl
		out (rtc_port_year),a

		; reset RTC UTI bit and start the clock
		in a,(rtc_port_ctl)
		res rtc_uti,a
		set rtc_run,a
		out (rtc_port_ctl),a

		ret

	;---------------------------------------------------------------
	; SVC: rtcgta
	; Gets the current date and time as ASCII strings.
	;
	; On entry:
	;	C = format (0=ISO8601, 1=Long Date and Time)
	;	HL = pointer to buffer for formatted time and date
	;
	; On return
	;	AF, BC destroyed
	;	HL is unchanged
	;	no other registers changed
	;

rtcgta::
		push hl

		; set UTI bit
		in a,(rtc_port_ctl)
		set rtc_uti,a
		out (rtc_port_ctl),a

		; which output type
		ld a,c
		or a
		jr nz,rtcgta_long		; go if long format requested

		;-------------------------------
		; ISO-8601 format
		;-------------------------------

		; fixed century digits
		ld (hl),century_digit1
		inc hl
		ld (hl),century_digit2
		inc hl

		; year
		in a,(rtc_port_year)		; fetch year
		call rtc_b2a			; convert to ASCII decimal

		; month
		in a,(rtc_port_month)		; fetch month
		call rtc_b2a			; convert to ASCII decimal

		; day-of-month
		in a,(rtc_port_dom)		; fetch day-of-month
		call rtc_b2a			; convert to ASCII decimal

		; ISO8601 date/time separator
		ld (hl),iso_separator		; append separator
		inc hl

		; hour
		in a,(rtc_port_hour)		; fetch hour
		call rtc_b2a			; convert to ASCII decimal

		; minute
		in a,(rtc_port_min)		; fetch minute
		call rtc_b2a			; convert to ASCII decimal

		; second
		in a,(rtc_port_sec)		; fetch second
		call rtc_b2a			; convert to ASCII decimal

		ld (hl),0			; append null terminator

		; clear UTI bit
		in a,(rtc_port_ctl)
		res rtc_uti,a
		out (rtc_port_ctl),a

		pop hl
		ret

		;-------------------------------
		; Long US locale format
		;-------------------------------
rtcgta_long:
		push de

		; set UTI bit
		in a,(rtc_port_ctl)
		set rtc_uti,a
		out (rtc_port_ctl),a

		; is the day of the week specified?
		in a,(rtc_port_dow)		; fetch day-of week
		or a
		jr z,rtcgta_long20

		; day of week abbreviation
		ld de,dowtab
		call rtc_lkup			; look up and append
		ld (hl),' '			; add a space
		inc hl

rtcgta_long20:
		; month abbreviation
		in a,(rtc_port_month)		; fetch month
		ld de,montab
		call rtc_lkup			; look up and append
		ld (hl),' '			; add a space
		inc hl

		; day of month
		in a,(rtc_port_dom)		; fetch day-of-month
		call rtc_b2a			; convert to ASCII decimal
		ld (hl),','			; add a comma
		inc hl
		ld (hl),' '			; add a space
		inc hl

		; fixed century digits
		ld (hl),century_digit1
		inc hl
		ld (hl),century_digit2
		inc hl

		; year
		in a,(rtc_port_year)		; fetch year
		call rtc_b2a			; convert to ASCII decimal
		ld (hl),0			; null terminator for date
		inc hl

		; hour
		in a,(rtc_port_hour)		; fetch hour
		call rtc_b2a			; convert to ASCII decimal
		ld (hl),iso_time_delim		; add delimiter
		inc hl

		; minute
		in a,(rtc_port_min)		; fetch minute
		call rtc_b2a			; convert to ASCII decimal
		ld (hl),iso_time_delim		; add delimiter
		inc hl

		; second
		in a,(rtc_port_sec)		; fetch second
		call rtc_b2a			; convert to ASCII decimal
		ld (hl),0			; add null terminator

		; clear UTI bit
		in a,(rtc_port_ctl)
		res rtc_uti,a
		out (rtc_port_ctl),a

		pop de
		pop hl

		ret

	;---------------------------------------------------------------
	; SVC: rtcgtb
	; Gets the current date and time in the RTC's native
	; binary-coded decimal format.
	;
	; On entry:
	;	HL = pointer to seven byte buffer to receive date/time
	;
	; On return:
	;	HL = HL + 7
	; 	(HL-7) = second
	;	(HL-6) = minute
	; 	(HL-5) = hour
	;	(HL-4) = day-of-month
	;	(HL-3) = day-of-week
	;	(HL-2) = month
	;	(HL-1) = year
	;
rtcgtb::
		; set UTI bit
		in a,(rtc_port_ctl)
		set rtc_uti,a
		out (rtc_port_ctl),a

		; get second
		in a,(rtc_port_sec)
		ld (hl),a
		inc hl

		; get minute
		in a,(rtc_port_min)
		ld (hl),a
		inc hl

		; get hour
		in a,(rtc_port_hour)
		ld (hl),a
		inc hl

		; get day-of-month
		in a,(rtc_port_dom)
		ld (hl),a
		inc hl

		; get day-of-week
		in a,(rtc_port_dow)
		ld (hl),a
		inc hl

		; get month
		in a,(rtc_port_month)
		ld (hl),a
		inc hl

		; get year
		in a,(rtc_port_year)
		ld (hl),a
		inc hl

		; clear UTI bit
		in a,(rtc_port_ctl)
		res rtc_uti,a
		out (rtc_port_ctl),a

		ret

	;---------------------------------------------------------------
	; rtc_lkup:
	; Performs a table lookup for a month or day-of-week
	; abbreviation.
	;
	; On entry:
	;	A = month (1..12) or day-of-week (1..7)
	;	DE = pointer to table of abbreviations
	;	HL = pointer to buffer to receive the abbreviation string
	;
	; On return:
	;	AF destroyed
	;	DE = table entry + 3
	; 	HL = HL + 3
	;
rtc_lkup:
		dec a			; RTC month and day is one-based
		rlca			; multiply by 4 for
		rlca			;     4-byte table entries

		; point DE to the selected table entry
		add a,e
		ld e,a
		adc a,d
		sub e
		ld d,a

		; copy string to target buffer
		ld b,3			; length of abbreviations
rtc_lkup10:
		ld a,(de)
		ld (hl),a
		inc de
		inc hl
		djnz rtc_lkup10
		ret

	;---------------------------------------------------------------
	; rtc_a2b:
	; Converts two digits of ASCII decimal into a packed pair of
	; BCD digits.
	;
	; On entry:
	;	HL = pointer to two digits of ASCII decimal
	;
	; On return:
	;	A = corresponding pair of packed BCD digits
	; 	HL = entry HL + 2
	;	C destroyed
	;
rtc_a2b:
		ld a,(hl)
		inc hl
		sub '0'
		and 0xf
		rlca
		rlca
		rlca
		rlca
		ld c,a
		ld a,(hl)
		inc hl
		sub '0'
		and 0xf
		add a,c
		ret

	;---------------------------------------------------------------
	; rtc_b2a:
	; Converts a packed BCD digit pair into two digits of ASCII
	; decimal.
	;
	; On entry:
	;	A = BCD digit pair to convert
	; 	HL = pointer to buffer for ASCII digits
	; On return:
	;	HL = HL + 2
rtc_b2a:
		ld (hl),a
		rld
		and 0xf
		add a,'0'
		ld c,a
		rld
		and 0xf
		add a,'0'
		ld (hl),c
		inc hl
		ld (hl),a
		inc hl
		ret

	;---------------------------------------------------------------
	; rtcisr:
	; Real time clock interrupt handler.
	;
rtcisr::
		push af
		push hl

                in a,(sys_cfg_port)
                xor 1
                out (sys_cfg_port),a

		in a,(rtc_port_flags)

		; dispatch periodic interrupt
		bit rtc_pf,a
		jr z,rtcisr10
		ld hl,rtcisr10
		push hl
	 	ld hl,(rtcph)
		jp (hl)
rtcisr10:
		; dispatch alarm interrupt
		bit rtc_af,a
		jr z,rtcisr20
		ld hl,rtcisr20
		push hl
		ld hl,(rtcah)
		jp (hl)
rtcisr20:
		pop hl
		pop af
		ei
		reti

rtc_nop_handler:
		ret

		end

