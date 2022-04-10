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

                .include ports.asm
                .include spi_defs.asm

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

rtc_tm_strlen   .equ 8
rtc_dt_strlen   .equ 14


rtcrd::
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

                dec hl                  ; HL -> control
                ld a,(hl)
                and low ~rtc_osf        ; clear OSF bit
                ld (hl),a               ; put it back in the buffer
                dec hl                  ; HL -> address

                ld (hl),rtc_write+rtc_status
                ld b,2                  ; exchange 2 bytes (addr + 1 data)
                ld c,spi_rtc+spi_cpha
                call spi8x

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
                ld (hl),' '
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
        ;       [HL-8, HL-1] = date string of the form "hh:mm:ss"
        ;       HL = HL' + 8
        ;
rtcrtm::
                push bc
                push de
        
                ex de,hl                ; DE -> output buffer

                ; use HL as a stack frame pointer
                ld hl,-rtc_bufsize
                add hl,sp
                ld sp,hl

                ; specify address for date fields
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

rtc_2acd:
                ld c,a
                rrca
                rrca
                rrca
                rrca
                and $0f
                add a,'0'
                ld (de),a
                inc de
                ld a,c
                and $0f
                add a,'0'
                ld (de),a
                inc de
                ret

rtc_2day:
                dec a                   ; day 1..6 -> 0..6
                ld hl,days
                jr z,rtc_2day_copy
                ld b,a
                ld c,3
                xor a
rtc_2day_multiply:
                add a,c
                djnz rtc_2day_multiply
                ld c,a
                ld b,0
                add hl,bc
rtc_2day_copy:
                ld b,3
rtc_2day_next:
                ld a,(hl)
                ld (de),a
                inc hl
                inc de
                djnz rtc_2day_next

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
                ex de,hl                ; DE -> input string

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

                ld hl,rtc_bufsize
                add hl,sp
                ld sp,hl
                pop hl
                pop de
                pop bc
                ret

rtc_2bcd:
                dec de
                ld a,(de)
                and $0f
                ld (hl),a
                dec de
                ld a,(de)
                and $0f
                rlca
                rlca
                rlca
                rlca
                or (hl)
                ld (hl),a
                ret

rtc_2dow:
                push hl
                ld hl,days

                ld c,1
rtc_2dow_next:
                ld b,3
                push de
rtc_2dow_match:
                ld a,(de)
                cp (hl)
                jr nz,rtc_2dow_no_match
                inc de
                inc hl
                djnz rtc_2dow_match
                pop de
                pop hl
                ld a,c
                ret

rtc_2dow_no_match:
                inc hl
                djnz rtc_2dow_no_match
                pop de
                inc c
                ld a,(hl)
                or a
                jr nz,rtc_2dow_next
                ld a,1
                ret

days:           db "SunMonTueWedThuFriSat",0
months:         db "JanFebMarAprMayJunJulAugSepOctNovDec",0

                .end