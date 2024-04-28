        ;---------------------------------------------------------------
        ; Real-Time Clock Support
        ;
        ; The system includes a Maxim 3234 Real-Time Clock module. The
        ; clock provides accurate timekeeping and 256-bytes of SRAM that
        ; can be used for any purpose. When the system power is
        ; disconnected, the battery on the clock module is used to
        ; provide power for timekeeping and to maintain the contents of
        ; the integral SRAM.
        ;
        ; The clock module is interfaced through the SPI bus.
        ;---------------------------------------------------------------

                .name rtc

                .extern spi8x
		.extern l7ph8

                .include ports.asm
                .include spi_defs.asm
                .include ascii.asm

                .cseg


rtc_tm_second   .equ $00
rtc_tm_minute   .equ $01
rtc_tm_hours    .equ $02
rtc_tm_dow      .equ $03
rtc_tm_dom      .equ $04
rtc_tm_month    .equ $05
rtc_tm_year     .equ $06
rtc_a1_second   .equ $07
rtc_a1_minute   .equ $08
rtc_a1_hour     .equ $09
rtc_a1_day      .equ $0a
rtc_a2_minute   .equ $0b
rtc_a2_hour     .equ $0c
rtc_a2_day      .equ $0d

rtc_a2m2	.equ $80
rtc_a2m3	.equ $80
rtc_a2m4	.equ $80

rtc_ctrl        .equ $0e
rtc_status      .equ $0f
rtc_aging       .equ $10
rtc_temp_msb    .equ $11
rtc_temp_lsb    .equ $12
rtc_temp_ctrl   .equ $13
rtc_sram_addr   .equ $18
rtc_sram_data   .equ $19

rtc_12hour      .equ $60

rtc_read        .equ $00
rtc_write       .equ $80

rtc_eosc        .equ $80
rtc_bbsqw       .equ $40
rtc_conv        .equ $20
rtc_rs2         .equ $10
rtc_rs1         .equ $08
rtc_intcn       .equ $04
rtc_a2ie        .equ $02
rtc_a1ie        .equ $01

rtc_osf         .equ $80
rtc_bb32khz     .equ $40
rtc_crate1      .equ $20
rtc_crate0      .equ $10
rtc_en32khz     .equ $08
rtc_busy        .equ $04
rtc_a2f         .equ $02
rtc_a1f         .equ $01

rtc_bufsize     .equ 24

rtc_dow_strlen	.equ 3
rtc_mon_strlen	.equ 3

rtc_dt_strlen	.equ 14
rtc_tm_strlen	.equ 8
rtc_a2_strlen	.equ 5
rtc_abbrev_len  .equ 3
rtc_num_days	.equ 7


	;--------------------------------------------------------------
	; rtcex:
	; Perform a low-level data exchange with the RTC using the
	; buffer addressed by HL.
	;
	; In the buffer, the first byte MUST be an address. If the
	; most significant bit of the address is set, the exchange will
	; be a write operation, otherwise the exchange will be a read
	; operation.
	;
	; On entry:
	;	B = number of bytes to exchange
	;	HL -> buffer for the exchange of at least B bytes
	;
rtcex::
                push bc
                push hl
                ld c,spi_rtc+spi_cpha   ; RTC address on SPI bus
                call spi8x
                pop hl
                pop bc
                ret

        ;---------------------------------------------------------------
        ; rtcosf:
        ; Reset the OSF bit in the control register.
        ;
rtcosf::
                push bc
                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ld (hl),rtc_status      ; read status register
                ld b,2                  ; exchange 2 bytes (addr + 1 data)
                ld c,spi_rtc+spi_cpha
                call spi8x

                dec hl                  ; HL -> status
                ld a,(hl)
                and low ~rtc_osf        ; clear OSF bit
                ld (hl),a               ; put it back in the buffer
                dec hl                  ; HL -> address

                ld (hl),rtc_write+rtc_status
                ld b,2                  ; exchange 2 bytes (addr + 1 data)
                ld c,spi_rtc+spi_cpha
                call spi8x

rtcosf_out:
                ; discard stack frame
                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl

                pop bc
                ret


        ;---------------------------------------------------------------
        ; rtctcv:
        ; Perform a temperature conversion and return the result.
        ;
        ; On return:
        ;       L = temperature LSB (fractional part)
        ;       H = temperature MSB (integer part)
rtctcv::
                push bc
                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; wait for any conversion in progress to end
                inc hl
rtctcv_busy:
                dec hl                  ; HL -> address
                ld (hl),rtc_ctrl        ; read control and status registers
                ld b,3                  ; exchange 3 bytes (addr + 2 data)
                ld c,spi_rtc+spi_cpha
                call spi8x
                dec hl                  ; HL -> status
                ld a,(hl)
                dec hl                  ; HL -> control
                and rtc_busy
                jr nz,rtctcv_busy       ; wait until not busy

                ; start a user-initiated temperature conversion
                ld a,(hl)               ; get control register contents
                or rtc_conv             ; set the conversion bit
                ld (hl),a               ; put it back in the buffer
                dec hl                  ; HL -> address
                ld (hl),rtc_write+rtc_ctrl
                ld b,2                  ; exchange 2 bytes (addr + 1 data)
                ld c,spi_rtc+spi_cpha
                call spi8x
                dec hl                  ; HL -> control
rtctcv_conv:
                dec hl                  ; HL -> address
                ld (hl),rtc_ctrl
                ld b,2                  ; exchange 2 bytes (addr + 1 data)
                ld c,spi_rtc+spi_cpha
                call spi8x
                dec hl                  ; HL -> control
                ld a,(hl)
                and rtc_conv
                jr nz,rtctcv_conv       ; wait until conversion complete

                ; read the converted temperature
                dec hl                  ; HL -> address
                ld (hl),rtc_temp_msb
                ld b,3                  ; exchange 3 bytes (address + 2 data)
                ld c,spi_rtc+spi_cpha
                call spi8x

                dec hl                  ; HL -> temp LSB
                ld a,(hl)
                dec hl                  ; HL -> temp MSB
                ld b,(hl)

                ; discard stack frame
                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl

                ; set up return value
                ld l,a
                ld h,b

                pop bc
                ret

        ;---------------------------------------------------------------
        ; rtcctm:
        ; Reads the time and date fields of the clock to produce a
        ; formatted string similar to the unix `ctime` function.
        ;
        ; On entry:
        ;       HL -> buffer of at least 21 bytes
        ;
        ; On return:
        ;       [HL-21, HL-1] = date string of the form "day mon hh:mm:ss yyyy"
        ;       HL = HL' + 21
        ;
rtcctm::
                push bc
                push de
                ex de,hl                ; DE -> output buffer

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; specify address for time fields
                ld (hl),rtc_read+rtc_tm_second
                ld b,8                  ; exchange 4 bytes (1 addr + 7 data)
                ld c,spi_rtc+spi_cpha   ; peripheral address and mode
                call spi8x              ; read the time and date

                ld bc,-4
                add hl,bc               ; HL -> day of week

                ld a,(hl)               ; get day of week
                call rtc_2day           ; convert to day name in buffer
                ex de,hl
                ld (hl),ascii_space     ; delimiter
                inc hl
                ex de,hl

                inc hl                  ; HL -> day of month
                inc hl                  ; HL -> month
                ld a,(hl)               ; get month
                and $1f                 ; mask off century bit
                call rtc_2mon           ; convert to month name in buffer
                ex de,hl
                ld (hl),ascii_space     ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> day of month
                ld a,(hl)               ; get day of month
                call rtc_2acd           ; convert to decimal in buffer
                ex de,hl
                ld (hl),ascii_space     ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> day of week
                dec hl                  ; HL -> hour
                ld a,(hl)               ; get hour
                call rtc_2acd           ; convert to decimal in buffer
                ex de,hl
                ld (hl),':'             ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> minute
                ld a,(hl)               ; get minute
                call rtc_2acd           ; convert to decimal in buffer
                ex de,hl
                ld (hl),':'             ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> second
                ld a,(hl)               ; get second
                call rtc_2acd           ; convert to decimal in buffer
                ex de,hl
                ld (hl),ascii_space     ; delimiter
                inc hl
                ld (hl),'2'             ; first century digit
                inc hl
                ld (hl),'0'             ; second century digit
                inc hl
                ex de,hl

                ld bc,rtc_tm_year
                add hl,bc               ; HL -> year
                ld a,(hl)               ; get year
                call rtc_2acd           ; convert to decimal in buffer

                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl
                ex de,hl
                pop de
                pop bc
                ret

        ;---------------------------------------------------------------
        ; rtcrdt:
        ; Reads the date fields of the clock to produce a formatted
        ; string output.
        ;
        ; On entry:
        ;       HL -> buffer of at least 14 bytes
        ;
        ; On return:
        ;       [HL-14, HL-1] = date string of the form "yyyy-mm-dd day"
        ;       HL = HL' + 14
        ;
rtcrdt::
                push bc
                push de

                ld (hl),'2'             ; first century digit
                inc hl
                ld (hl),'0'             ; second century digit
                inc hl
                ex de,hl                ; DE -> output buffer

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; specify address for date fields
                ld (hl),rtc_read+rtc_tm_dow
                ld b,5                  ; exchange 5 bytes (1 addr + 4 data)
                ld c,spi_rtc+spi_cpha   ; peripheral address and mode
                call spi8x              ; read the date

                dec hl                  ; HL -> year
                ld a,(hl)
                call rtc_2acd
                ex de,hl
                ld (hl),'-'             ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> month
                ld a,(hl)
                and $1f                 ; mask off century bit
                call rtc_2acd
                ex de,hl
                ld (hl),'-'
                inc hl
                ex de,hl

                dec hl                  ; HL -> day of month
                ld a,(hl)
                call rtc_2acd
                ex de,hl
                ld (hl),ascii_space
                inc hl
                ex de,hl

                dec hl                  ; HL -> day of week
                ld a,(hl)
                call rtc_2day

                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl
                ex de,hl
                pop de
                pop bc
                ret

        ;---------------------------------------------------------------
        ; rtcrtm:
        ; Reads the time fields of the clock to produce a formatted
        ; string output.
        ;
        ; On entry:
        ;       HL -> buffer of at least 8 bytes
        ;
        ; On return:
        ;       HL[-8..-1] = date string of the form "hh:mm:ss"
        ;       HL := HL + 8
        ;
rtcrtm::
                push bc
                push de

                ex de,hl                ; DE -> output buffer

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; specify address for time fields
                ld (hl),rtc_read+rtc_tm_second
                ld b,4                  ; exchange 4 bytes (1 addr + 3 data)
                ld c,spi_rtc+spi_cpha   ; peripheral address and mode
                call spi8x              ; read the time

                dec hl                  ; HL -> hour
                ld a,(hl)
                call rtc_2acd
                ex de,hl
                ld (hl),':'             ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> minute
                ld a,(hl)
                call rtc_2acd
                ex de,hl
                ld (hl),':'             ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> second
                ld a,(hl)
                call rtc_2acd

                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl
                ex de,hl
                pop de
                pop bc
                ret

        ;---------------------------------------------------------------
        ; rtcral:
        ; Reads the the alarm fields of the clock to produce a formatted
        ; string output.
        ;
        ; On entry:
        ;       HL -> buffer of at least 5 bytes
        ;
        ; On return:
        ;       HL[-5..-1] = time string of the form "hh:mm"
        ;       HL := HL + 5
        ;
rtcral::
                push bc
                push de

                ex de,hl                ; DE -> output buffer

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; specify address for alarm 2 fields
                ld (hl),rtc_read+rtc_a2_minute
                ld b,4                  ; exchange 4 bytes (1 addr + 3 data)
                ld c,spi_rtc+spi_cpha   ; peripheral address and mode
                call spi8x              ; read the time

		dec hl			; HL -> day
                dec hl                  ; HL -> hour
                ld a,(hl)
                call rtc_2acd
                ex de,hl
                ld (hl),':'             ; delimiter
                inc hl
                ex de,hl

                dec hl                  ; HL -> minute
                ld a,(hl)
                call rtc_2acd

                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl
                ex de,hl
                pop de
                pop bc
                ret

        ;---------------------------------------------------------------
	; rtc_2acd:
	; Converts a binary-coded decimal value in A to corresponding
	; ASCII-coded decimal value in buffer at DE.
	;
	; On entry:
	;	A = BCD value to be converted
	;	DE -> buffer of at least two bytes
	;
	; On return:
	;	DE[0..1] = ASCII decimal conversion of A
	;	DE := DE + 2
	;	C destroyed
	;
rtc_2acd:
                ld c,a			; preserve the value to be converted

		; put upper nibble of A into the lower nibble of A
                rrca
                rrca
                rrca
                rrca
                and $0f

                add a,'0'		; convert to ASCII digit
                ld (de),a		; store in buffer
                inc de
                ld a,c			; recover value to be converted
                and $0f			; discard upper nibble
                add a,'0'		; convert to ASCII digit
                ld (de),a		; store in buffer
                inc de
                ret

        ;---------------------------------------------------------------
	; rtc_2day:
	; Converts a day-of-the-week value (1..7) to the corresponding
	; US English abbreviation for the corresponding day name in the
	; buffer at DE.
	;
	; On entry:
	;	A = day of the week (1..7)
	;	DE -> buffer of at least rtc_abbrev_len bytes
	;
	; On return:
	;	DE[0..rtc_abbrev_len - 1] = day name
	;	DE := DE + rtc_abbrev_len
	;	BC destroyed
	;
rtc_2day:
                push hl
                ld hl,days		; HL -> table of day names
		call rtc_2str		; Copy string table entry
                pop hl
                ret

        ;---------------------------------------------------------------
	; rtc_2mon:
	; Converts a BCD month number (1..12) in A to the corresponding
	; US English abbreviation for the month name in the buffer at DE.
	;
	; On entry:
	;	A = BCD month number (1..12)
	;	DE -> buffer of at least rtc_abbrev_len bytes
	;
	; On return:
	;	DE[0..rtc_abbrev_len - 1] = day name
	;	DE := DE + rtc_abbrev_len
	;	BC destroyed
	;
rtc_2mon:
                push hl

	; convert BCD month number to binary month number
                cp a,$10
                jr c,rtc_2mon_no_adjust ; go if no tens digit
                sub a,$10-10		; BCD to binary conversion

rtc_2mon_no_adjust:
		ld hl,months
		call rtc_2str		; copy string table entry

                pop hl
                ret

        ;---------------------------------------------------------------
	; rtc_2str:
	; Copies an indexed value from a string table into the buffer
	; at DE. It is assumed that each string in the table is exactly
	; rtc_abbrev_len characters in length.
	;
	; On entry:
	;	A = one-based index into the string table (1..table_size)
	;	DE -> buffer of at least rtc_abbrev_len bytes
	;	HL -> source string table
	;
	; On return:
	;	DE[0..C-1] = copy of string
	; 	DE := DE + rtc_abbrev_len
	;	HL := HL + rtc_abbrev_len
	;	BC destroyed
	;
rtc_2str:
		dec a
                jr z,rtc_2str_copy	; if index = 0, no need to multiply
                ld b,a			; B = multiplier (index)
		ld c,rtc_abbrev_len	; C = multiplicand (string length)
                xor a			; start product at 0
rtc_2str_multiply:
                add a,c
                djnz rtc_2str_multiply

	; compute offset for specified index
                ld c,a
                ld b,0
                add hl,bc

	; copy the string from source table at (HL)
	; to the caller's buffer at (DE)
rtc_2str_copy:
                ld b,rtc_abbrev_len	; length of the string
rtc_2str_next:
                ld a,(hl)
                ld (de),a
                inc hl
                inc de
                djnz rtc_2str_next

		ret

        ;---------------------------------------------------------------
        ; rtcwdt:
        ; Writes the date fields of the clock using a formatted string
        ; as input.
        ;
        ; On entry:
        ;       HL -> date string of the form "yyyy-mm-dd day"
        ;
        ; On return:
        ;       AF destroyed
        ;
rtcwdt::
                push bc
                push de
                push hl

                ; skip to end of formatted string
                ld bc,rtc_dt_strlen
                add hl,bc
                ex de,hl                ; DE -> input string

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; specify address for date fields
                ld (hl),rtc_write+rtc_tm_dow

                inc hl                  ; HL -> day-of-week

                dec de
                dec de
                dec de                  ; DE -> day-of-week input
                call rtc_2dow           ; convert to day number
                ld (hl),c               ; set day-of-week
                dec de                  ; DE -> delimiter

                inc hl                  ; HL -> day-of-month
                call rtc_2bcd           ; convert day-of-month to BCD
                inc hl                  ; HL -> month
                dec de                  ; DE -> delimiter
                call rtc_2bcd           ; convert month to BCD
                inc hl                  ; HL -> year
                dec de                  ; DE -> delimiter
                call rtc_2bcd           ; convert year to BCD
                dec de                  ; DE -> second digit of century
                ld a,(de)
                and $01                 ; isolate low order bit
                rrca                    ; make it the high order bit
                or (hl)                 ; include the year number
                ld (hl),a

                dec hl                  ; HL -> month
                dec hl                  ; HL -> day-of-month
                dec hl                  ; HL -> day-of-week
                dec hl                  ; HL -> address

                ld b,5                  ; exchange 5 bytes (addr + 4 data)
                ld c,spi_rtc+spi_cpha   ; RTC address on SPI bus
                call spi8x

                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl
                pop hl
                pop de
                pop bc
                ret

        ;---------------------------------------------------------------
        ; rtcwtm:
        ; Writes the time fields of the clock using a formatted string
        ; as input.
        ;
        ; On entry:
        ;       HL -> time string of the form "hh:mm:ss"
        ; On return:
        ;       AF destroyed
        ;
rtcwtm::
                push bc
                push de
                push hl

                ; skip to end of formatted string
                ld bc,rtc_tm_strlen
                add hl,bc
                ex de,hl                ; DE -> end of input string

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; specify address for time fields
                ld (hl),rtc_write+rtc_tm_second

                inc hl                  ; HL -> seconds
                call rtc_2bcd           ; convert second to BCD
                inc hl                  ; HL -> minute
                dec de                  ; DE -> delimiter
                call rtc_2bcd           ; convert minute to BCD
                inc hl                  ; HL -> hour
                dec de                  ; DE -> delimiter
                call rtc_2bcd           ; convert hour to BCD
                ld a,(hl)               ; get hour
                and ~rtc_12hour         ; turn off 12-hour format
                dec hl                  ; HL -> minute
                dec hl                  ; HL -> second
                dec hl                  ; HL -> address

                ld b,4                  ; exchange 4 bytes (addr + 3 data)
                ld c,spi_rtc+spi_cpha   ; RTC address on SPI bus
                call spi8x

	; remove stack frame
		ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl

                pop hl
                pop de
                pop bc
                ret

        ;---------------------------------------------------------------
        ; rtcwal:
        ; Writes the alarm 2 fields of the clock using a formatted string
        ; as input and enables the alarm.
        ;
        ; On entry:
        ;       HL -> time string of the form "hh:mm"
        ; On return:
        ;       AF destroyed
        ;
rtcwal::
                push bc
                push de
                push hl

                ; skip to end of formatted string
                ld bc,rtc_a2_strlen
                add hl,bc
                ex de,hl                ; DE -> end of input string

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

		ld (hl),rtc_read+rtc_status
		ld b,2
		call spi8x
		dec hl
		ld b,l
		ld l,(hl)
		ld c,0
		call l7ph8
		ld l,b

		ld a,(hl)
		and low(~rtc_a2f)
		ld (hl),a
		dec hl
		ld (hl),rtc_write+rtc_status
		ld b,2
		call spi8x
		dec hl
		dec hl

                ; specify address for alarm 2 fields
                ld (hl),rtc_write+rtc_a2_minute

                inc hl                  ; HL -> minutes
                call rtc_2bcd           ; convert minute to BCD
                inc hl                  ; HL -> hour
                dec de                  ; DE -> delimiter
                call rtc_2bcd           ; convert hour to BCD
		inc hl			; HL -> day
		ld (hl),rtc_a2m4

                dec hl                  ; HL -> hour
                dec hl                  ; HL -> minute
                dec hl                  ; HL -> address

                ld b,4                  ; exchange 4 bytes (addr + 3 data)
                ld c,spi_rtc+spi_cpha   ; RTC address on SPI bus
                call spi8x

		dec hl			; HL -> day
		dec hl			; HL -> hour
		dec hl			; HL -> minute
		dec hl			; HL -> address

                ld (hl),rtc_ctrl	; address of the control register
		ld b,2			; exchange 3 bytes (address + 1 data)
		call spi8x		; read control register
		dec hl			; HL -> status register content
		ld a,(hl)
		or rtc_intcn+rtc_a2ie	; set the INTCN and A2IE bits
		ld (hl),a
	 	dec hl

		ld (hl),rtc_write+rtc_ctrl
		ld b,2			; exchange 2 bytes (address + 1 data)
		call spi8x

	; remove stack frame
		ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl

                pop hl
                pop de
                pop bc
                ret


        ;---------------------------------------------------------------
	; rtc_2bcd:
	; Converts an ASCII-coded decimal value in a buffer at DE
	; to binary-coded decimal (BCD) value in a buffer at HL
	;
	; On entry:
	;	DE -> source buffer + 3 (2 digits + 1)
	;	HL -> target buffer (1 byte)
	;
	; On return:
	;	DE := DE - 2
	;	(HL) = BCD conversion result
	;
rtc_2bcd:
                dec de			; DE -> least significant ASCII digit
                ld a,(de)
                and $0f			; convert to BCD nibble
                ld (hl),a		; (HL) = partial conversion
                dec de			; DE -> most significant ASCII digit
                ld a,(de)
                and $0f			; convert to BCD nibble

	; rotate to upper nibble
                rlca
                rlca
                rlca
                rlca

                or (hl)			; merge in lower nibble
                ld (hl),a		; (HL) = final conversion
                ret

        ;---------------------------------------------------------------
	; Converts a US English abbreviation for day-of-the-week to a
	; day number 1..7
rtc_2dow:
                push hl
                ld hl,days		; HL -> table of day names

                ld c,1			; C = first table index (one-based)
rtc_2dow_next:
                ld b,rtc_abbrev_len	; B + number of chars to compare
                push de			; save caller's pointer
rtc_2dow_match:
                ld a,(de)		; A = current caller char
                cp (hl)			; compare to current table char
                jr nz,rtc_2dow_no_match

                inc de			; DE -> next caller char
                inc hl			; HL -> next table char
                djnz rtc_2dow_match	; continue until all chars matched

                pop de			; recover caller's pointer
                pop hl
                ld a,c			; return matching day number
                ret

rtc_2dow_no_match:
	; skip remaining characters of current table entry
                inc hl
                djnz rtc_2dow_no_match

                pop de			; recover caller's pointer
                inc c			; C = next table index (one-based)

	; check for end of table
                ld a,c
		cp rtc_num_days+1
		jr c,rtc_2dow_next	; not at end of table

                ld a,1			; assume first day
                ret

	; String tables for day names and month names
	; Each abbreviation must be rtc_abbrev_len chars in length
days:           db "SunMonTueWedThuFriSat"
months:         db "JanFebMarAprMayJunJulAugSepOctNovDec"

                .end
