        ;---------------------------------------------------------------
        ; LED 7-segment display module
        ;---------------------------------------------------------------

		.name l7

                .extern spi16
                .extern d3210


                .include spi_defs.asm

num_digits      .equ 8
buf_size        .equ 2*num_digits + 4

no_decode       .equ $0900
intensity       .equ $0a00
scan_limit      .equ $0b00
no_shutdown     .equ $0c01
mode_test       .equ $0f01
mode_normal     .equ $0f00

                .cseg

        ;---------------------------------------------------------------
        ; l7init:
        ; Initializes the 7-segment LED display.
        ;---------------------------------------------------------------
l7init::
                ; display test mode: test
                ld c,spi_l7             ; SPI peripheral address
                ld de,mode_test         ; put display into test mode
                call spi16
                call l7_delay

                ; display test mode: normal
                ld c,spi_l7
                ld de,mode_normal
                call spi16

                ; no BCD decode
                ld c,spi_l7
                ld de,no_decode
                call spi16

                ; max intensity
                ld c,spi_l7
                ld de,intensity+15
                call spi16

                ; scan all digits
                ld c,spi_l7
                ld de,scan_limit+(num_digits-1)
                call spi16

                ; shutdown mode: normal
                ld c,spi_l7
                ld de,no_shutdown
                call spi16

                ; display segment test patter
                call l7_segtest

                ret

        ;---------------------------------------------------------------
        ; l7_segtest:
        ; Displays each segment of each digit individually.
        ;
l7_segtest:
                xor a                   ; all segments off
                scf                     ; set carry
l7_segtest_10:
                rra                     ; next segment
                jr c,l7_segtest_20      ; go if no more

                push af
                call l7_pattern
                call l7_delay
                pop af
                jr l7_segtest_10
l7_segtest_20:
                xor a
                call l7_pattern
                ret

        ;---------------------------------------------------------------
        ; l7_pattern:
        ; Displays a bit pattern in A on all digits
        ;
l7_pattern:
                ld h,a                  ; preserve pattern
                ld l,1                  ; start with digit 1
                ld b,num_digits         ; display all digits
l7_pattern_10:                
                ld e,h                  ; segment bit
                ld d,l                  ; digit number
                ld c,spi_l7             ; SPI peripheral address
                call spi16
                inc l                   ; next digit
                djnz l7_pattern_10      ; loop for all digits
                ret
              
        ;---------------------------------------------------------------
        ; l7_delay:
        ; Short counter-based delay
        ;
l7_delay:
                ld de,$4000
l7_delay_10:
                dec de
                ld a,e
                or d
                jr nz,l7_delay_10
                ret


        ;---------------------------------------------------------------
        ; l7ph8:
        ; Prints an 8-bit hexadecimal value on two digits of the display.
        ;
        ; On entry:
        ;       L = value to display
        ;       C = specifies rightmost digit, where the the lowest 3
        ;           bits represent the digit number (0-7) and the high
        ;           order bit indicates whether the point segment should
        ;           be displayed to the right of the value
        ; 
        ; On return:
        ;       AF destroyed
        ;
l7ph8::
                push bc
                push hl
                push iy

                ; reserve buffer space on the stack
                ld iy,-buf_size
                add iy,sp
                ld sp,iy

                ; point to the top of the buffer
                ld iy,buf_size
                add iy,sp

                ; convert lower nibble to pattern
                ld a,l
                call l7_phex4

                ; next display digit
                ld a,c
                and $7f         ; clear the decimal point bit
                inc a           ; next digit number
                ld c,a

                ; convert upper nibble to pattern
                ld a,l          ; recover value to display
                rrca
                rrca
                rrca
                rrca
                call l7_phex4

                ; disable BCD decode
                dec iy
                ld (iy),$00 
                dec iy
                ld (iy),$09

                ld b,3          ; BCD decode pair + two (address, pattern) pairs
                call l7_out

                ld iy,buf_size
                add iy,sp
                ld sp,iy

                pop iy
                pop hl
                pop bc
                ret


        ;---------------------------------------------------------------
        ; l7ph16:
        ; Prints a 16-bit hexadecimal value on four digits of the 
        ; display.
        ;
        ; On entry:
        ;       HL = value to display
        ;       C = specifies rightmost digit, where the the lowest 3
        ;           bits represent the digit number (0-7) and the high
        ;           order bit indicates whether the point segment should
        ;           be displayed to the right of the value
        ; 
        ; On return:
        ;       AF destroyed
        ;
l7ph16::
                push bc
                push hl
                push iy

                ; reserve buffer space on the stack
                ld iy,-buf_size
                add iy,sp
                ld sp,iy

                ; point to the top of the buffer
                ld iy,buf_size
                add iy,sp

                ; convert lower nibble of lower byte to pattern
                ld a,l
                call l7_phex4

                ; next display digit
                ld a,c
                and $7f         ; clear the decimal point bit
                inc a           ; next digit number
                ld c,a

                ; convert upper nibble of lower byte to pattern
                ld a,l          ; recover value to display
                rrca
                rrca
                rrca
                rrca
                call l7_phex4
                inc c           ; next diplay digit

                ; convert lower nibble of upper byte to pattern
                ld a,h
                call l7_phex4
                inc c           ; next display digit

                ; convert upper nibble of upper byte to pattern
                ld a,h
                rrca
                rrca
                rrca
                rrca
                call l7_phex4

                ; disable BCD decode
                dec iy
                ld (iy),$00 
                dec iy
                ld (iy),$09

                ld b,4          ; BCD decode pair + four (address, pattern) pairs
                call l7_out

                ld iy,buf_size
                add iy,sp
                ld sp,iy

                pop iy
                pop hl
                pop bc
                ret


        ;---------------------------------------------------------------
        ; l7ph32:
        ; Prints a 32-bit hexadecimal value on all eight digits of the 
        ; display.
        ;
        ; On entry:
        ;       DEHL = value to display
        ; 
        ; On return:
        ;       AF destroyed, C is zero
        ;
l7ph32::
                push bc
                push hl
                push iy

                ; reserve buffer space on the stack
                ld iy,-buf_size
                add iy,sp
                ld sp,iy

                ; point to the top of the buffer
                ld iy,buf_size
                add iy,sp

                ld c,0          ; start at digit 0

                ; convert lower nibble of lower byte of lower word
                ld a,l
                call l7_phex4
                inc c           ; next digit number

                ; convert upper nibble of lower byte of lower word
                ld a,l          ; recover value to display
                rrca
                rrca
                rrca
                rrca
                call l7_phex4
                inc c           ; next diplay digit

                ; convert lower nibble of upper byte of lower word
                ld a,h
                call l7_phex4
                inc c           ; next display digit

                ; convert upper nibble of upper byte of lower word
                ld a,h
                rrca
                rrca
                rrca
                rrca
                call l7_phex4
                inc c           ; next display digit


                ; convert lower nibble of lower byte of upper word
                ld a,e
                call l7_phex4
                inc c           ; next digit number

                ; convert upper nibble of lower byte of upper word
                ld a,e          ; recover value to display
                rrca
                rrca
                rrca
                rrca
                call l7_phex4
                inc c           ; next diplay digit

                ; convert lower nibble of upper byte of upper word
                ld a,d
                call l7_phex4
                inc c           ; next display digit

                ; convert upper nibble of upper byte of upper word
                ld a,d
                rrca
                rrca
                rrca
                rrca
                call l7_phex4

                ; disable BCD decode
                dec iy
                ld (iy),$00 
                dec iy
                ld (iy),$09

                ld b,9         ; BCD decode pair + eight (address, pattern) pairs
                call l7_out

                ld iy,buf_size
                add iy,sp
                ld sp,iy

                pop iy
                pop hl
                pop bc
                ret


        ;---------------------------------------------------------------
        ; l7_phex4:
        ; Converts a 4-bit value to 16=bit word representing a display 
        ; register address and pattern for a display digit
        ; 
        ; On entry:
        ;       A = 4-bit value to convert
        ;       C = target display digit in which the lowest 3 bits are 
        ;           used as the digit number and the high order bit
        ;           indicates whether the point segment should be 
        ;           displayed
        ;
        ; On return:
        ;       IY = IY' - 2
        ;       [IY + 0] = register address
        ;       [IY + 1] = pattern
        ;
l7_phex4:
                push hl
                and $0f                 ; 4 bits only

                ; get pointer to pattern
                ld hl,patterns                
                add a,l
                ld l,a
                ld a,h
                adc a,0
                ld h,a

                ; fetch pattern and add decimal point bit
                ld a,(hl)
                rla
                rlc c
                rra
                rrc c

                ; store the pattern                                
                dec iy
                ld (iy),a

                ; compute and store display register address
                ld a,c                
                and 7                   ; 3 bits only
                inc a                   ; digits are number 1-8
                dec iy                  
                ld (iy),a

                pop hl
                ret

                .include l7out.asm
                .include l7pd16.asm

patterns:
                ; segment patterns ---------- Pabcdefg
                db $7e                  ; 0 - 01111110
                db $30                  ; 1 - 00110000
                db $6d                  ; 2 - 01101101
                db $79                  ; 3 - 01111001
                db $33                  ; 4 - 00110011
                db $5b                  ; 5 - 01011011
                db $5f                  ; 6 - 01011111
                db $70                  ; 7 - 01110000
                db $7f                  ; 8 - 01111111
                db $7b                  ; 9 - 01111011
                db $77                  ; A - 01110111
                db $1f                  ; b - 00011111
                db $4e                  ; C - 01001110
                db $3d                  ; d - 00111101
                db $4f                  ; E - 01001111
                db $47                  ; F - 01000111

                .end

