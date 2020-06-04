
		name setrtc

		include svc.asm

xy_year		equ 0x100
xy_mon		equ 0x103
xy_day		equ 0x106
xy_weekday	equ 0x109

xy_hour		equ 0x100
xy_min		equ 0x103
xy_sec		equ 0x106
xy_meridian	equ 0x109

date_delim	equ '-'
time_delim	equ ':'

rtc_bcd_size	equ 7

ls_rtc_size	equ rtc_bcd_size
ls_time_size	equ 6			; HHMMSS representation
ls_date_size	equ 6			; YYMMDD representation

ls_rtc_ptr      equ 0
ls_date_ptr     equ ls_rtc_ptr + 2
ls_time_ptr     equ ls_date_ptr + 2
ls_kitab        equ ls_time_ptr + 2
ls_rtc          equ ls_kitab + 2
ls_date         equ ls_rtc + ls_rtc_size
ls_time         equ ls_date + ls_date_size
ls_weekday      equ ls_time + ls_time_size
ls_meridian     equ ls_weekday                  ; stored in MSB of weekday
ls_last         equ ls_meridian + 1
locals_size     equ ls_last + ls_last % 2

rtc_sec		equ 0
rtc_min		equ 1
rtc_hour	equ 2
rtc_day		equ 3
rtc_weekday	equ 4
rtc_month	equ 5
rtc_year	equ 6

	;---------------------------------------------------------------
	; setrtc:
	; A utility program that sets the date and time in the real-time
	; clock module based on user input.
	;
setrtc::
		push ix

		; allocate memory for locals
		ld ix,-locals_size
		add ix,sp
		ld sp,ix

		; get locals pointer into HL
		push ix
		pop hl

		; set up local RTC buffer pointer
		ld bc,ls_rtc
		add hl,bc
		ld (ix + ls_rtc_ptr),l
		ld (ix + ls_rtc_ptr + 1),h

		; set up local ACD time buffer pointer
		ld bc,ls_rtc_size
		add hl,bc
		ld (ix + ls_date_ptr),l
		ld (ix + ls_date_ptr + 1),h

		; set up local ACD date buffer pointer
		ld bc,ls_date_size
		add hl,bc
		ld (ix + ls_time_ptr),l
		ld (ix + ls_time_ptr + 1),h

		; set keyboard symbol table
		ld hl,ktab_rtc
		ld a,@kistab
		rst 0x28

		; save previous table pointer
		ld (ix + ls_kitab),l
		ld (ix + ls_kitab + 1),h

setrtc_again:
		call get_clock
		call get_date
		call get_time
		jr c,setrtc_again

		; point HL to RTC data
		ld l,(ix + ls_rtc_ptr)
		ld h,(ix + ls_rtc_ptr + 1)

		; set date and time in RTC module
		ld a,@rtcstb
		rst 0x28

		; restore previous keyboard symbol table
		ld l,(ix + ls_kitab)
		ld h,(ix + ls_kitab + 1)
		ld a,@kistab
		rst 0x28

		; deallocate memory for locals
		ld ix,locals_size
		add ix,sp
		ld sp,ix

		pop ix
		ret

	;---------------------------------------------------------------
	; get_clock:
	; Gets the current date and time from the RTC hardware and
	; converts it to ACD format for use as default user input.
	;
get_clock:
		ld l,(ix + ls_rtc_ptr)
		ld h,(ix + ls_rtc_ptr + 1)
		ld a,@rtcgtb
		rst 0x28

		; point HL to RTC year
		ld l,(ix + ls_rtc_ptr)
		ld h,(ix + ls_rtc_ptr + 1)
		ld a,rtc_year
		add a,l
		ld l,a
		adc a,h
		sub l
		ld h,a

		; point DE to start of ACD buffer for date
		ld e,(ix + ls_date_ptr)
		ld d,(ix + ls_date_ptr + 1)

		; convert year
		call bcd2acd
		dec hl

		; convert month
		call bcd2acd
		dec hl

		; convert day-of-week
		ld a,(hl)
		cp 1
		jr c,get_clock_reset_weekday
		cp 8
		jr nc,get_clock_reset_weekday
		dec a
		jr get_clock_local_weekday

get_clock_reset_weekday:
		xor a

get_clock_local_weekday:
		ld (ix + ls_weekday),a
		dec hl

		; convert day-of-month
		call bcd2acd
		dec hl

		; point DE to local ACD time buffer
		ld e,(ix + ls_time_ptr)
		ld d,(ix + ls_time_ptr + 1)

                ; set local meridian
                ld c,(ix + ls_meridian)         ; get local meridian
                sla c                           ; discard MSB of C
                ld a,(hl)                       ; get meridian bit from RTC
                rla                             ; rotate PM bit into carry
                rr c                            ; rotate carry into MSB of C
                ld (ix + ls_meridian),c

		; normalize hours BCD
		ld a,(hl)
		and 0x7f
		ld (hl),a

		; convert hour
		call bcd2acd
		dec hl

		; convert minute
		call bcd2acd
		dec hl

		; convert second
		call bcd2acd
		dec hl

		ret

get_date:
		; clear display
		ld a,@doclr
		rst 0x28

		; show prompt
		ld bc,0
		ld a,@dogoto
		rst 0x28
		ld hl,date_prompt
		ld a,@doputs
		rst 0x28

		; point HL to ACD date buffer
		ld l,(ix + ls_date_ptr)
		ld h,(ix + ls_date_ptr + 1)

		; show current date
		ld bc,xy_year
		ld a,@dogoto
		rst 0x28
		call show_date

		; get year
		ld bc,xy_year
		ld a,@dogoto
		rst 0x28
		call get_pair
		jr c,get_date

		; get month
		ld bc,xy_mon
		ld a,@dogoto
		rst 0x28
		call get_pair
		jr c,get_date

		; get day-of-month
		ld bc,xy_sec
		ld a,@dogoto
		rst 0x28
		call get_pair
		jr c,get_date

		; get day-of-week
		call get_weekday
		jr c,get_date

		; convert and validate
		call convert_date
		jr c,get_date

		ret

get_time:
		; clear display
		ld a,@doclr
		rst 0x28

		; show prompt
		ld bc,0
		ld a,@dogoto
		rst 0x28
		ld hl,time_prompt
		ld a,@doputs
		rst 0x28

		; point HL to ACD time buffer
		ld l,(ix + ls_time_ptr)
		ld h,(ix + ls_time_ptr + 1)

		; show current time
		ld bc,xy_hour
		ld a,@dogoto
		rst 0x28
		call show_time

		; get hour
		ld bc,xy_hour
		ld a,@dogoto
		rst 0x28
		call get_pair
		ret c

		; get minute
		ld bc,xy_min
		ld a,@dogoto
		rst 0x28
		call get_pair
		jr c,get_time

		; get second
		ld bc,xy_sec
		ld a,@dogoto
		rst 0x28
		call get_pair
		jr c,get_time

		; get meridian
		call get_meridian
		jr c,get_time

		; convert and validate
		call convert_time
		jr c,get_time

		ret

	;---------------------------------------------------------------
	; show_date:
	; Displays the contents of the given buffer as a delimited date
	; string.
	;
	; On entry:
	; 	HL = pointer to buffer containing ASCII-coded decimal
	;	date to be displayed
	;
show_date:
		push hl
		call show_pair
		ld c,date_delim
		ld a,@doputc
		rst 0x28
		call show_pair
		ld c,date_delim
		ld a,@doputc
		rst 0x28
		call show_pair
		ld c,' '
		ld a,@doputc
		rst 0x28
		call show_weekday
		pop hl
		ret

	;---------------------------------------------------------------
	; show_time:
	; Displays the contents of the given buffer as delimited time
	; string.
	;
	; On entry:
	; 	HL = pointer to buffer containing ASCII-coded decimal
	;	time to be displayed
	;
show_time:
		push hl
		call show_pair
		ld c,time_delim
		ld a,@doputc
		rst 0x28
		call show_pair
		ld c,time_delim
		ld a,@doputc
		rst 0x28
		call show_pair
		ld c,' '
		ld a,@doputc
		rst 0x28
		call show_meridian
		pop hl
		ret

	;---------------------------------------------------------------
	; show_pair:
	; Displays a pair of ASCII decimal digits at the cursor position.
	;
	; On entry:
	;	HL = pointer to the digits to display
	;
	; On return:
	;	HL = HL + 2
	;	display cursor is located at the position following the
	;	second digit
show_pair:
		ld c,(hl)
		inc hl
		ld a,@doputc
		rst 0x28
		ld c,(hl)
		inc hl
		ld a,@doputc
		rst 0x28
		ret

	;---------------------------------------------------------------
	; get_weekday:
	; Gets the weekday (Sun..Sat) from user input.
	;
	; On entry:
	;	(IX + ls_weekday) = default weekday
	;
	; On return:
	;	(IX + ls_weekday) = selected weekday
	;
get_weekday:
		call show_weekday

get_weekday_wait:
		ld a,@kiget
		rst 0x28
		jr z,get_weekday_wait
		cp ksym_enter
		jr z,get_weekday_enter
		cp ksym_clear
		jr z,get_weekday_clear
		cp ksym_dec
		jr z,get_weekday_dec
		cp ksym_inc
		jr nz,get_weekday_wait

		ld a,(ix + ls_weekday)
		cp 6
		jr nz,get_weekday_inc_nowrap
		ld a,-1
get_weekday_inc_nowrap:
		inc a
		ld (ix + ls_weekday),a
		jr get_weekday

get_weekday_dec:
		ld a,(ix + ls_weekday)
		cp 0
		jr nz,get_weekday_dec_nowrap
		ld a,7
get_weekday_dec_nowrap:
		dec a
		ld (ix + ls_weekday),a
		jr get_weekday

get_weekday_enter:
		xor a
		ret

get_weekday_clear:
		scf
		ret

	;---------------------------------------------------------------
	; show_weekday:
	; Displays the currently selected weekday (Sun..Sat)
	;
	; On entry:
	;	(IX + ls_weekday) = selected weekday (0..6)
	;
	; On return:
	;	selected weekday is displayed and cursor is positioned
	;	on it
	;
show_weekday:
		push bc
		push hl

		; position cursor
		ld bc,xy_weekday
		ld a,@dogoto
		rst 0x28

		; get selected weekday and multiply by four for label size
		ld a,(ix + ls_weekday)
		and 0x7			; mask and clear carry
		rlca			; multiply by 2
		rlca			; multiply by 2

		; point HL to selected label
		ld hl,weekday_label
		add a,l
		ld l,a
		adc a,h
		sub l
		ld h,a

		; display the weekday label
		ld a,@doputs
		rst 0x28

		; re-position the cursor
		ld bc,xy_weekday
		ld a,@dogoto
		rst 0x28

		pop hl
		pop bc
		ret

	;---------------------------------------------------------------
	; get_meridian:
	; Gets the time meridian (AM or PM) from user input.
	;
	; On entry:
	;	(IX + ls_meridian) = default meridian
	;
	;
get_meridian:
		call show_meridian

get_meridian_wait:
		ld a,@kiget
		rst 0x28
		jr z,get_meridian_wait
		cp ksym_enter
		jr z,get_meridian_enter
		cp ksym_clear
		jr z,get_meridian_clear
		cp ksym_dec
		jr z,get_meridian_toggle
		cp ksym_inc
		jr nz,get_meridian_wait

get_meridian_toggle:
                ld a,(ix + ls_meridian)
                xor 0x80
                ld (ix + ls_meridian),a
		jr get_meridian

get_meridian_enter:
		xor a
		ret

get_meridian_clear:
		scf
		ret

	;---------------------------------------------------------------
	; show_meridian:
	; Displays the currently selected time meridian (AM or PM).
	;
	; On entry:
	;	(IX + ls_meridian) = selected meridian (0 or 1)
	;
	; On return:
	;	selected meridian is displayed and cursor is positioned
	;	on it
	;
show_meridian:
		push bc
		push hl

		; position cursor
		ld bc,xy_meridian
		ld a,@dogoto
		rst 0x28

		; get meridian and multiply by 2 for label size
                ld a,(ix + ls_meridian)
                rlca
                and 0x1
		rla			; multiply by 2

		; point HL to selected label
		ld hl,meridian_label
		add a,l
		ld l,a
		adc a,h
		sub l
		ld h,a

		; fetch and display first character
		ld c,(hl)
		ld a,@doputc
		rst 0x28
		inc hl

		; fetch and display second character
		ld c,(hl)
		ld a,@doputc
		rst 0x28

		; add a trailing space (to overwrite weekday abbreviation)
		ld c,' '
		ld a,@doputc
		rst 0x28

		; re-position cursor
		ld bc,xy_meridian
		ld a,@dogoto
		rst 0x28

		pop hl
		pop bc
		ret

	;---------------------------------------------------------------
	; get_pair:
	; Gets a digit pair from the keyboard.
	;
	; Digits are entered and stored as ASCII decimal and are output
	; at the current position on the display.
	;
	; On entry:
	; 	HL = pointer to input buffer containing default digits
	;
	; On return
	;	when NC:
	;	  HL = HL + 2
	;	  (HL-2) and (HL-1) contain entered digit pair or default
	;	when C:
	;	  user pressed the clear key
	;
get_pair:
get_pair_first:
		ld a,@kiget
		rst 0x28
		jr z,get_pair_first

		cp ksym_clear
		jr z,get_pair_clear
		cp ksym_enter
		jr z,get_pair_enter

		ld (hl),a
		inc hl
		ld c,a
		ld a,@doputc
		rst 0x28
get_pair_second:
		ld a,@kiget
		rst 0x28
		jr z,get_pair_second

		cp ksym_clear
		jr z,get_pair_clear

		ld (hl),a
		inc hl
		ld c,a
		ld a,@doputc
		rst 0x28
		xor a			; set flags NC, Z
		ret

get_pair_enter:
		inc hl			; skip default digits
		inc hl
		xor a			; set flags NC, Z
		ret

get_pair_clear:
		scf			; set flags C
		ret

	;---------------------------------------------------------------
	; convert_date:
	; Converts the ASCII-coded decimal date input in the local
	; input buffer into binary-coded decimal in the local RTC buffer
	; as needed by the real time clock hardware.
	;
convert_date:
		; point HL to ACD date buffer
		ld l,(ix + ls_date_ptr)
		ld h,(ix + ls_date_ptr + 1)

		; point DE to RTC year
		ld e,(ix + ls_rtc_ptr)
		ld d,(ix + ls_rtc_ptr + 1)
		ld a,rtc_year
		add a,e
		ld e,a
		adc a,d
		sub e
		ld d,a

		; convert year
		call acd2bcd
		ld a,(de)
		cp 0x9A
		jr nc,convert_date_error
		dec de

		; convert month
		call acd2bcd
		ld a,(de)
		cp 0x13
		jr nc,convert_date_error
		cp 0x01
		jr c,convert_date_error
		dec de

		; convert day of week
		ld a,(ix + ls_weekday)
		inc a
		ld (de),a
		dec de

		; convert day of month
		call acd2bcd
		ld a,(de)
		cp 0x32
		jr nc,convert_date_error
		cp 0x01
		jr c,convert_date_error

		xor a
		ret

convert_date_error:
		scf
		ret


	;---------------------------------------------------------------
	; convert_time:
	; Converts the ASCII-coded decimal time input in the local buffer
	; into binary-coded decimal as required by the real time clock
	; hardware.
	;
convert_time:
		; point HL to ACD time buffer
		ld l,(ix + ls_time_ptr)
		ld h,(ix + ls_time_ptr + 1)

		; point DE to RTC hour
		ld e,(ix + ls_rtc_ptr)
		ld d,(ix + ls_rtc_ptr + 1)
		ld a,rtc_hour
		add a,e
		ld e,a
		adc a,d
		sub e
		ld d,a

		call acd2bcd
		ld a,(de)
		cp 0x13
		jr nc,convert_time_error
		cp 0x01
		jr c,convert_time_error

		; set high order bit if PM
                bit 7,(ix + ls_meridian)
                jr z,convert_time_min
                ld a,(de)
                or 0x80
                ld (de),a

convert_time_min:
		dec de
		call acd2bcd
		ld a,(de)
		cp 0x5A
		jr nc,convert_time_error

		dec de

		call acd2bcd
		ld a,(de)
		cp 0x5A
		jr nc,convert_time_error
		xor a
		ret

convert_time_error:
		scf
		ret

	;---------------------------------------------------------------
	; acd2bcd:
	; Converts two digits of ASCII-coded decimal to a single byte
	; of packed binary-coded decimal.
	;
	; On entry:
	;	HL = pointer to two digits of ASCII-coded decimal
	;	DE = pointer to one byte buffer for converted value
	;
	; On return:
	;	HL = HL + 2
	;	DE unchanged
	;	(DE) contains the converted value
	;	AF destroyed
	;
acd2bcd:
		ld a,(hl)
		inc hl
		sub '0'
		ex de,hl
		rld
		ex de,hl
		ld a,(hl)
		inc hl
		sub '0'
		ex de,hl
		rld
		ex de,hl
		ret

	;---------------------------------------------------------------
	; bcd2acd:
	; Converts a packed binary-coded decimal value to two digits of
	; ASCII-coded decimal.
	;
	; On entry:
	;	HL = pointer to value to be converted
	;	DE = pointer to buffer for two ASCII decimal digits
	;
	; On return:
	;	DE = DE + 2
	;	(DE-2) = tens digit
	;	(DE-1) = ones digit
	;	HL unchanged
	;	AF destroyed
	;
bcd2acd:
		push bc
		rld
		and 0xf
		ld c,a
		add a,'0'
		ld (de),a
		inc de
		ld a,c
		rld
		and 0xf
		ld c,a
		add a,'0'
		ld (de),a
		ld a,c
		inc de
		rld
		pop bc
		ret


		; time meridian labels
meridian_label	db 'AM'
		db 'PM'

		; weekday labels (zero-padded to make them a multiple of 4)
weekday_label	db 'Sun', 0
		db 'Mon', 0
		db 'Tue', 0
		db 'Wed', 0
		db 'Thu', 0
		db 'Fri', 0
		db 'Sat', 0

date_prompt	db 'Set date:',0
time_prompt	db 'Set time:',0


ksym_nul	equ	0
ksym_enter	equ	1
ksym_clear	equ	2
ksym_dec	equ	3
ksym_inc	equ	4

ksym_0		equ 	'0'
ksym_1		equ	'1'
ksym_2		equ	'2'
ksym_3		equ	'3'
ksym_4		equ	'4'
ksym_5		equ	'5'
ksym_6		equ	'6'
ksym_7		equ	'7'
ksym_8		equ	'8'
ksym_9		equ	'9'

		; keyboard symbol table for RTC date/time input
ktab_rtc:	db ksym_4, ksym_9, ksym_3, ksym_8, ksym_2
		db ksym_7, ksym_1, ksym_6, ksym_0, ksym_5
		db ksym_enter, ksym_clear, ksym_inc, ksym_dec, ksym_inc
		db ksym_dec, ksym_inc, ksym_dec, ksym_inc, ksym_dec
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul

		end

