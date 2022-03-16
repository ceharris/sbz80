dflag_signed    .equ $80
dflag_point     .equ $80
dflag_spaces    .equ $40

        ;---------------------------------------------------------------
        ; l7pd8:
        ; Prints an 8-bit decimal value on the display.
        ;
        ; On entry:
        ;       L = the value to display
        ;       C = bit-packed options as follows
        ;           bit 7: interpret L as signed (1) or unsigned (0)
        ;           bit 6: pad on left with spaces (1) or zeroes (0)
        ;           bits 5..3: digit position of the point (0..7 or 0 to omit it)
        ;           bits 2..0: rightmost digit for output
        ;       B = bit-packed options as follows
        ;           bit 7: include (1) or exclude (0) decimal point
        ;           bits 2..0: leftmost digit for output
        ;
l7pd8::
                push de
                push hl
                ld de,0
                ld h,0
                call l7pd32
                pop hl
                pop de
                ret

        ;---------------------------------------------------------------
        ; l7pd16:
        ; Prints a 16-bit decimal value on the display.
        ;
        ; On entry:
        ;       HL = the value to display
        ;       C = bit-packed options as follows
        ;           bit 7: interpret L as signed (1) or unsigned (0)
        ;           bit 6: pad on left with spaces (1) or zeroes (0)
        ;           bits 5..3: digit position of the point (0..7 or 0 to omit it)
        ;           bits 2..0: rightmost digit for output
        ;       B = bit-packed options as follows
        ;           bit 7: include (1) or exclude (0) decimal point
        ;           bits 2..0: leftmost digit for output
        ;
l7pd16::
                push de
                ld de,0
                call l7pd32
                pop de
                ret

        ;---------------------------------------------------------------
        ; l7pd32:
        ; Prints a 32-bit decimal value on the display.
        ;
        ; On entry:
        ;       DEHL = the value to display
        ;       C = bit-packed options as follows
        ;           bit 7: interpret L as signed (1) or unsigned (0)
        ;           bit 6: pad on left with spaces (1) or zeroes (0)
        ;           bits 5..3: digit position of the point (0..7 or 0 to omit it)
        ;           bits 2..0: rightmost digit for output
        ;       B = bit-packed options as follows
        ;           bit 7: include (1) or exclude (0) decimal point
        ;           bits 2..0: leftmost digit for output
        ;
l7pd32::
                push bc
                push de
                push hl
                push ix
                push iy
                ld ix,0                 
                add ix,sp               ; IX = SP
                ld iy,-buf_size         
                add iy,sp               ; make buffer space
                ld sp,iy                ; new SP below buffer
                push ix                 
                pop iy                  ; IY -> top of buffer

                ; get field width
                ld a,b
                and $07                 ; isolate leftmost digit number
                inc a                   
                ld b,a
                ld a,c
                and $07                 ; isolate rightmost digit number
                sub b
                neg         
                ld b,a                  ; B = field width

                ; is it a signed input?
                ld a,c
                and dflag_signed
                jr z,l7pd32_10          ; go if not signed
                
                ; one digit will be used for sign
                dec b                   

                ; error if remaining field width is zero
                ld a,b
                or a
                jp z,l7pd32_100        

                ; is the input negative?
                ld a,h
                and $80
                jr z,l7pd32_10          ; go if positive

                ; negate input to make it positive
                ld a,l
                cpl                     ; complement LSB
                ld l,a
                ld a,h
                cpl                     ; complement MSB
                ld h,a                  
                inc hl                  ; add one for two's complement
l7pd32_10:      
                ld a,c                  
                and $07                 ; isolate rightmost digit
                ld c,a
                inc c                   ; digit registers are biased by 1

l7pd32_20:
                push bc                 ; divide will destroy BC
                call d3210              ; divide to get modulo-10 remainder
                pop bc                  ; recover previous BC

                ; store digit (remainder) and digit address in buffer
                dec iy
                ld (iy),a               ; remainder is next digit to output
                dec iy
                ld (iy),c               ; digit register address
                inc c                   ; next register address
                dec b                   ; update remaining field width
                
                ; test quotient to see if now zero
                ld a,l                
                or h
                jr nz,l7pd32_25         ; go if not zero
                ld a,e
                or d
                jr z,l7pd32_30          ; go if zero

l7pd32_25:
                ; test remaining field width
                ld a,b
                or a
                jr nz,l7pd32_20         ; go if field width not exhausted
                jp l7pd32_100           ; field width exhausted

l7pd32_30:
                ; if there is field width remaining, pad it
                ld a,b          
                or a
                jr z,l7pd32_50          ; go if no padding needed

                ; pad field with spaces or zeros
                ld a,(ix+8)             ; get register C as it was on entry
                and dflag_spaces
                ld a,$0f                ; BCD encoding for blank
                jr nz,l7pd32_40         ; go if padding with spaces
                ld a,0                  ; BCD encoding for zero
l7pd32_40:
                ; store pad digit and digit address in buffer
                dec iy
                ld (iy),a
                dec iy
                ld (iy),c
                inc c
                djnz l7pd32_40

l7pd32_50:
                ; set sign digit if signed value
                ld a,(ix+8)             ; get register C as it was on entry
                ld b,a                  ; preserve it
                and dflag_signed
                jr z,l7pd32_70          ; go if unsigned

                ld a,(ix+5)             ; get register H as it was on entry
                and $80
                ld a,$0a                ; BCD encoding for minus sign
                jr nz,l7pd32_60
                ld a,$0f                ; BCD encoding for blank
l7pd32_60:
                ; store sign digit and digit address in buffer
                dec iy
                ld (iy),a
                dec iy
                ld (iy),c
                inc c
l7pd32_70:
                ; field width is leftmost - rightmost + 1
                ld c,b                  ; transfer saved value of C input
                ld a,(ix+9)             ; get register B as it was on entry
                ld h,a                  ; save it
                and $07                 ; isolate leftmmost digit number
                inc a
                ld b,a
                ld a,c                  
                and $07                 ; isolate rightmost digit number
                sub b
                neg                 
                ld b,a                  ; B = field width
                ld a,h                  ; A = register B as it was on entry
                ld h,b                  ; H = field width (or number of pairs)

                and dflag_point
                jr z,l7pd32_120         ; go if point not wanted

                ; set decimal point position if requested
                ld a,c                  ; A = register C as it was on entry
                
                ; get position of decimal point
                rrca
                rrca
                rrca
                and $07
                ld c,a                  ; save position of point

                ; don't set point if not within field bound
                ld a,h                  ; A = field width
                dec a
                cp c
                jr c,l7pd32_120         ; don't set point if out of field

                ; point IX to the pair for the point
                ld a,c
                inc a                   ; because IX is after the first pair
                rla                     ; multiply point position by 2
                cpl                     
                ld c,a                  ; C = one's complement of offset
                ld b,$ff                ; BC = one's complement of offset
                inc bc                  ; BC = two's complement of offset
                add ix,bc               ; IX -> pair that will get the point

                ; set the point bit
                ld a,(ix+1)             ; get BCD code for point position
                cp $0f                 
                jr nz,l7pd32_80         ; go if the BCD code is not space
                ld a,0                  ; replace space with zero
l7pd32_80:
                or $80                  ; set decimal point bit
l7pd32_90:
                ld (ix+1),a             ; replace BCD code
                inc ix
                inc ix                  ; point to next pair
                ld a,(ix+1)             ; get BCD code for next position
                cp $0f                  
                jr nz,l7pd32_120        ; go if BCD code is not a space
                ld a,0                  ; replace space with zero
                jr l7pd32_90

l7pd32_100:
                ; field overflow: display error indicator
                ld a,(ix+8)             ; get register C as it was on entry
                and $07                 ; isolate rightmost digit index
                ld c,a
                inc c                   ; bias it to use as register address
                push ix
                pop iy                  ; reset buffer pointer
                dec iy
                ld (iy),$0b             ; BCD code for `E`
                dec iy
                ld (iy),c               ; display in right most digit
                ld a,(ix+9)             ; get register B as it was on entry
                ld h,a
                dec a                   ; decrement to account for `E`
                or a
                jr z,l7pd32_120         ; go if no padding needed
                ld b,a
l7pd32_110:
                dec iy
                ld (iy),$0f             ; BCD code for space
                dec iy
                ld (iy),c
                inc c
                djnz l7pd32_110

l7pd32_120:
                ; include a pair to select BCD mode
                dec iy
                ld (iy),$ff
                dec iy
                ld (iy),$09

                ld b,h                  ; recover field width (number of pairs)
                inc b                   ; extra pair for BCD mode

                call l7_out

l7pd32_130:
                ld iy,buf_size
                add iy,sp
                ld sp,iy
                pop iy
                pop ix
                pop hl
                pop de
                pop bc
                ret

