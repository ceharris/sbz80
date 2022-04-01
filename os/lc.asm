        ;---------------------------------------------------------------
        ; LCD Display
        ;
        ; This module provides supporting subroutines for LCD display
        ; functions.
        ;---------------------------------------------------------------


                .name lc

                .extern gpin

                .extern d1610
                .extern d3210

                .include memory.asm
                .include ports.asm
                .include pio_defs.asm

lcd_port        .equ pio0_base+pio_port_b

lcd_out_mask    .equ 0                  ; all pins are outputs
lcd_in_mask     .equ $0f                ; PB3..PB0 are inputs

lcd_e           .equ $10                ; E signal is PB4
lcd_rs          .equ $20                ; RS signal is PB5
lcd_rw          .equ $40                ; RW signal is PB6

; LCD commands
lcd_clear       .equ $1
lcd_home        .equ $2
lcd_entry_mode  .equ $4
lcd_disp_ctrl   .equ $8
lcd_disp_shift  .equ $10
lcd_function    .equ $20
lcd_cgram_addr  .equ $40
lcd_ddram_addr  .equ $80

; LCD function register bits
lcd_8bits       .equ $10
lcd_2rows       .equ $8
lcd_font_5x10   .equ $4
lcd_4bits       .equ 0
lcd_font_5x8    .equ 0

; LCD display control register bits
lcd_display_on  .equ $4
lcd_cursor_on   .equ $2
lcd_blink_on    .equ $1
lcd_display_off .equ 0
lcd_cursor_off  .equ 0
lcd_blink_off   .equ 0

; LCD display shift flags
lcd_shift_disp  .equ $8
lcd_shift_right .equ $4
lcd_shift_cur   .equ 0
lcd_shift_left  .equ 0

; LCD display entry mode bits
lcd_incr        .equ $2
lcd_shift       .equ $1
lcd_decr        .equ 0
lcd_no_shift    .equ 0


lcd_busy        .equ $80                ; on read, high order bit is busy flag
lcd_row_length  .equ 64                 ; each row is 64 characters


;lc_no_wait      .equ 1

        ;---------------------------------------------------------------
        ; lc_delay:
        ; Imposes a delay in microseconds of no less than than 10 times
        ; the value specified as the argument. If the value of the
        ; argument is specified as zero, it is treated as $10000 (65536).
        ; Assumes the "normal" clock speed is 4 MHz and the "turbo"
        ; clock speed is 8 Mhz.
        ;
lc_delay        .macro du
                .local lc_delay_10

                ld bc,du                ;T=10) 2.5  | 1.25  usec

                ; get the "turbo" bit (if 0 our clock is twice as fast)
                ld a,(gpin)             ;T=13) 3.25 | 1.625 usec
                rla                     ;T=4)  1.0  | 0.5   usec
                jp c,lc_delay_10        ;T=10) 2.5  | 1.25  usec

                ; double the delay count for turbo
                rl c                    ;T=8)  2.0  | 1.0   usec
                rl b                    ;T=8)  2.0  | 1.0   usec
                                        ;----------------
                                        ;     10.75 | 5.375 usec (before)
                .ifndef lc_no_wait
lc_delay_10:
                nop                     ;T=4)  1.0  | 0.5   usec
                nop                     ;T=4)  1.0  | 0.5   usec
                nop                     ;T=4)  1.0  | 0.5   usec
                nop                     ;T=4)  1.0  | 0.5   usec
                dec bc                  ;T=6)  1.5  | 0.75  usec
                ld a,b                  ;T=4)  1.0  | 0.5   usec
                or c                    ;T=4)  1.0  | 0.5   usec
                jp nz,lc_delay_10       ;T=10) 2.5  | 1.25  usec
                                        ;--------------
                                        ;     10.0    5.0   usec (in the loop)
                .endif
                .endm


lc_write4       .macro r
                ld a,(r)>>4
                and ~lcd_e
                out (lcd_port),a
                or lcd_e
                out (lcd_port),a
                nop
                and ~lcd_e
                out (lcd_port),a
                .endm

                .cseg


        ;---------------------------------------------------------------
        ; lcinit:
        ; Initializes the LCD display for 4-bit interface operation as
        ; described under "Initializing by Instruction" in the datasheet.
        ;
        ; On return:
        ;       all general purpose registers destroyed
        ;
lcinit::
                ; set all pins low
                xor a
                out (lcd_port),a

                ; wait for more than 15 ms after Vcc rises to 4.5 V
                lc_delay 1500           ; 15,000 usec

                ; (8-bit mode) function set 8-bit interface
                lc_write4 lcd_function+lcd_8bits

                ; wait for more than 4.1 ms
                lc_delay 500            ; 5,000 usec

                ; (8-bit mode) function set 8-bit interface
                lc_write4 lcd_function+lcd_8bits

                ; wait for more than 100 us
                lc_delay 10             ; 100 usec

                ; (8-bit mode) function set 8-bit interface
                lc_write4 lcd_function+lcd_8bits
                lc_delay 5              ; 50 usec

                ; (8-bit mode) function set 4-bit interface
                lc_write4 lcd_function+lcd_4bits
                lc_delay 5              ; 50 usec

                ; (4-bit mode) function set 4-bit interface, 2 rows, 5x8 font
                ld a,lcd_function+lcd_4bits+lcd_2rows+lcd_font_5x8
                call lc_cmd
                lc_delay 5              ; 50 usec

                ; (4-bit mode) display off
                ld a,lcd_disp_ctrl+lcd_display_off+lcd_cursor_off+lcd_blink_off
                call lc_cmd
                lc_delay 5              ; 50 usec

                ; (4-bit mode) clear display
                ld a,lcd_clear
                call lc_cmd
                lc_delay 250            ; 2500 usec

                ; (4-bit mode) set entry mode
                ld a,lcd_entry_mode+lcd_incr+lcd_no_shift
                call lc_cmd
                lc_delay 250            ; 2500 usec

                ret

        ;---------------------------------------------------------------
        ; lc_cmd:
        ; Executes an LCD command, assuming that the LCD controller is
        ; operating in 4-bit mode.
        ;
        ; On entry:
        ;       A = LCD command
        ;
        ; On return:
        ;       AF, C destroyed
        ;
lc_cmd:
                ld c,a                  ;save command word

                ; prepare to send upper nibble
                rrca
                rrca
                rrca
                rrca
                and $0f

                out (lcd_port),a        ;RW=0, RS=0, EN=0
                or lcd_e
                out (lcd_port),a        ;RW=0, RS=0, EN=1
                and ~lcd_e
                out (lcd_port),a        ;RW=0, RS=0, EN=0

                ; prepare to send lower nibble
                ld a,c                  ;recover command word
                and $0f

                out (lcd_port),a        ;RW=0, RS=0, EN=0
                or lcd_e
                out (lcd_port),a        ;RW=0, RS=0, EN=1
                and ~lcd_e
                out (lcd_port),a        ;RW=0, RS=0, EN=0

                ret

        ;---------------------------------------------------------------
        ; lc_ddwrite:
        ; Puts a character into the DDRAM of the display.
        ;
        ; On entry:
        ;       C = character code to display
        ; On return:
        ;       AF, BC destroyed
        ;
lc_ddwrite:
                ; put upper nibble of character code into lower nibble of A
                ld a,c
                rrca
                rrca
                rrca
                rrca
                and $0f

                ; strobe upper nibble to the controller
                or lcd_rs+lcd_e
                out (lcd_port),a        ; RS=1, E=1, upper nibble
                and ~lcd_e
                out (lcd_port),a        ; RS=1, E=0

                ; put lower nibble of character code into lower nibble of A
                ld a,c
                and $0f

                ; strobe lower nibble to the controller
                or lcd_rs+lcd_e
                out (lcd_port),a        ; RS=1, E=1, lower nibble
                and ~lcd_e
                out (lcd_port),a        ; RS=1, E=0

                lc_delay 5
                ret

        ;---------------------------------------------------------------
        ; lc_phex8:
        ; Puts the ASCII hexadecimal representation of an 8-bit value
        ; into the DDRAM of the display.
        ;
        ; On entry:
        ;       A = 8-bit value to display
        ;
        ; On return:
        ;       AF, BC, E destroyed
        ;
lc_phex8:
                ld b,a
                rrca
                rrca
                rrca
                rrca
                and $0f
                cp 10
                jp nc,lc_phex8_10
                add a,'0'
                ld c,a
                push bc
                call lc_ddwrite
                pop bc
                jp lc_phex8_20
lc_phex8_10:
                add a,'a'-10
                ld c,a
                push bc
                call lc_ddwrite
                pop bc
lc_phex8_20:
                ld a,b
                and $0f
                cp 10
                jp nc,lc_phex8_30
                add a,'0'
                ld c,a
                jp lc_ddwrite
lc_phex8_30:
                add a,'a'-10
                ld c,a
                jp lc_ddwrite

        ;---------------------------------------------------------------
        ; lccls:
        ; Clears the LCD display.
        ;
        ; On return:
        ;       AF destroyed
        ;
lccls::
                push bc
                ld a,lcd_clear
                call lc_cmd
                lc_delay 250            ; 2,500 usec
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lchome:
        ; Moves the LCD cursor to the home position.
        ;
        ; On return:
        ;       AF destroyed
        ;
lchome::
                push bc
                ld a,lcd_home
                call lc_cmd
                lc_delay 250            ; 2,500 usec
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcctl:
        ; Configures the LCD display controls.
        ;
        ; On entry:
        ;       C = LCD control bits
        ;               c0 = blink on/off
        ;               c1 = cursor on/off
        ;               c2 = display on/off
        ;
        ; On return:
        ;       AF destroyed
        ;
        ;
lcctl::
                push bc
                ld a,c
                and lcd_display_on+lcd_cursor_on+lcd_blink_on
                ld c,a
                ld a,lcd_disp_ctrl
                or c
                call lc_cmd
                lc_delay 5              ; 50 usec
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcent:
        ; Configures the LCD entry mode.
        ;
        ; On entry:
        ;       C = LCD entry mode bits
        ;               c0 = shift on/off
        ;               c1 = increment or decrement
        ;
        ; On return:
        ;       AF destroyed
        ;
lcent::
                push bc
                ld a,c
                and lcd_shift+lcd_incr
                ld c,a
                ld a,lcd_entry_mode
                or c
                call lc_cmd
                lc_delay 5              ; 50 usec
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcshft:
        ; Shifts the display or cursor without changing DDRAM.
        ;
        ; On entry:
        ;       C = shift control bits
        ;               c0 = move left or right
        ;               c1 = shift display or cursor
        ;
        ; On return:
        ;       AF destroyed
        ;
lcshft::
                push bc
                ld a,c
                rlca
                rlca
                and lcd_shift_disp+lcd_shift_right
                ld c,a
                ld a,lcd_disp_shift
                or c
                call lc_cmd
                lc_delay 5              ; 50 usec
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcgoto:
        ; Moves the LCD cursor to the home position.
        ;
        ; On entry:
        ;       B = row number (zero-based)
        ;       C = column number (zero-based)
        ; On return:
        ;       AF, BC destroyed
        ;
lcgoto::
                ld a,b
                or a
                jp z,lcgoto_col         ; jump if row z
                xor a                   ; start at row zero
lcgoto_row:
                add lcd_row_length      ; add a row offset
                djnz lcgoto_row         ; loop for all rows
lcgoto_col:
                add c                   ; add column offset
                or lcd_ddram_addr       ; set command bit
                call lc_cmd
                lc_delay 5              ; 50 usec
                ret

        ;---------------------------------------------------------------
        ; lcputc:
        ; Puts a character into the DDRAM of the display at the cursor
        ; position and updates the cursor position according to the
        ; display's entry mode.
        ;
        ; On entry:
        ;       C = character code to display
        ; On return:
        ;       AF destroyed
        ;
lcputc::
                push bc
                call lc_ddwrite
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcputs:
        ; Puts a string into the DDRAM of the display. As each character
        ; is written, the cursor position is updated according to the
        ; display's entry mode.
        ;
        ; On entry:
        ;       HL = pointer to null-terminated string to display
        ; On return:
        ;       HL = pointer to byte following null terminator
        ;       AF destroyed
        ;
lcputs::
                push bc
lcputs_10:
                ld a,(hl)
                inc hl
                or a
                jp z,lcputs_20
                ld c,a
                call lc_ddwrite
                jp lcputs_10
lcputs_20:
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcph8:
        ; Puts a two-character ASCII hexadecimal representation of an 8
        ; bit value into the DDRAM of the display, updating the cursor
        ; position according to the display's entry mode.
        ;
        ; On entry:
        ;       C = value to display
        ;
        ; On return:
        ;       AF destroyed
        ;
lcph8::
                push bc
                ld a,c
                call lc_phex8
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcph16:
        ; Puts a four-character ASCII hexadecimal representation of a 16
        ; bit value into the DDRAM of the display, updating the cursor
        ; position according to the display's entry mode.
        ;
        ; On entry:
        ;       HL = value to display
        ;
        ; On return:
        ;       AF destroyed
        ;
lcph16::
                push bc
                ld a,h
                call lc_phex8
                ld a,l
                call lc_phex8
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcph32:
        ; Puts an eight-character ASCII hexadecimal representation of a
        ; 32 bit value into the DDRAM of the display, updating the cursor
        ; position according to the display's entry mode.
        ;
        ; On entry:
        ;       DEHL = value to display
        ;
        ; On return:
        ;       AF destroyed
        ;
lcph32::
                push bc
                ld a,d
                call lc_phex8
                ld a,e
                call lc_phex8
                ld a,h
                call lc_phex8
                ld a,l
                call lc_phex8
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcpd16:
        ; Puts an ASCII decimal representation of a 16 bit value into
        ; the DDRAM of the display, updating the cursor position
        ; according to the display's entry mode.
        ;
        ; On entry:
        ;       HL = value to display
        ;
        ; On return:
        ;       AF destroyed
        ;
lcpd16_bsize    .equ    11               ; ten digits + null terminator
lcpd16::
                push bc
                push hl
                push ix
                ld ix,-lcpd16_bsize     ; two's complement of buffer size
                add ix,sp               ; reserve buffer space
                ld sp,ix                ; new top of stack is below buffer

                ld bc,lcpd16_bsize-1
                add ix,bc               ; point to end of buffer
                ld (ix),0               ; end with null terminator
lcpd16_10:
                call d1610              ; divide HL by 10
                add a,'0'               ; convert remainder to ASCII
                dec ix                  ; working backwards
                ld (ix),a               ; store digit

                ; is our quotient zero?
                ld a,l
                or h
                jp nz,lcpd16_10         ; nope
lcpd16_20:
                ; display the result
                ld a,(ix)
                inc ix
                or a
                jp z,lcpd16_30          ; go if at null terminator
                ld c,a
                call lc_ddwrite
                jp lcpd16_20
lcpd16_30:
                ; restore the stack
                ld ix,lcpd16_bsize
                add ix,sp
                ld sp,ix
                pop ix
                pop hl
                pop bc
                ret

        ;---------------------------------------------------------------
        ; lcpd32:
        ; Puts an ASCII decimal representation of a 32 bit value into
        ; the DDRAM of the display, updating the cursor position
        ; according to the display's entry mode.
        ;
        ; On entry:
        ;       DEHL = value to display
        ;
        ; On return:
        ;       AF destroyed
        ;
lcpd32_bsize    .equ    11               ; ten digits + null terminator

lcpd32::
                push bc
                push de
                push hl
                push ix
                ld ix,-lcpd32_bsize     ; two's complement of buffer size
                add ix,sp               ; reserve buffer space
                ld sp,ix                ; new top of stack is below buffer

                ld bc,lcpd32_bsize-1
                add ix,bc               ; point to end of buffer
                ld (ix),0               ; end with null terminator
lcpd32_10:
                call d3210              ; divide DEHL by 10
                add a,'0'               ; convert remainder to ASCII
                dec ix                  ; working backwards
                ld (ix),a               ; store digit

                ; are the lower 16 bits of our quotient zero?
                ld a,l
                or h
                jp nz,lcpd32_10         ; nope

                ; are the upper 16 bits of our quotient zero?
                ld a,e
                or d
                jp nz,lcpd32_10         ; nope
lcpd32_20:
                ; display the result
                ld a,(ix)
                inc ix
                or a
                jp z,lcpd32_30          ; go if at null terminator
                ld c,a
                call lc_ddwrite
                jp lcpd32_20
lcpd32_30:
                ; restore the stack
                ld ix,lcpd32_bsize
                add ix,sp
                ld sp,ix
                pop ix
                pop hl
                pop de
                pop bc
                ret

                end
