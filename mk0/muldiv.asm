
        ;---------------------------------------------------------------
        ; Integer multiplication and division support
        ;---------------------------------------------------------------
                .name muldiv

                .cseg

        ;---------------------------------------------------------------
        ; d8x8:
        ; Divide C by D.
        ;
        ; On entry:
        ;       C = dividend
        ;       D = divisor
        ;
        ; On return:
        ;       A = C mod D
        ;       C = C / D
        ;       B is zero
        ;       D, E, H, L unchanged
        ;
d8x8::
                ld b,8
                xor a
d8x8_10:        
                sla c
                rla
                cp d
                jr c,d8x8_20
                inc c
                sub d
d8x8_20:
                djnz d8x8_10
                ret


        ;---------------------------------------------------------------
        ; d16x8:
        ; Divide HL by C.
        ;
        ; On entry:
        ;       HL = dividend
        ;       C = divisor
        ;
        ; On return:
        ;       A = remainder
        ;       B = 0
        ;       HL = quotient
        ;       C, DE are unchanged
        ;
d16x8::
                ld b,16
                xor a
d16x8_10:
                add hl,hl
                rla
                cp c
                jr c,d16x8_20
                inc l
                sub c
d16x8_20:
                djnz d16x8_10
                ret


        ;---------------------------------------------------------------
        ; d32x8:
        ; Divide DEHL by C.
        ;
        ; On entry:
        ;       DEHL = dividend
        ;       C = divisor
        ;
        ; On return:
        ;       A = DEHL mod C
        ;       DEHL = DEHL / C
        ;       B is zero
        ;       C is unchanged
        ;       
d32x8::
                ld b,32
                xor a
d32x8_10:
                add hl,hl
                rl e
                rl d
                rla
                cp c
                jp c,d32x8_20
                inc l
                sub c
d32x8_20:
                djnz d32x8_10
                ret                       

        ;---------------------------------------------------------------
        ; d1610:
        ; Divide HL by 10.
        ; 
        ; On entry:
        ;       HL = dividend
        ;
        ; On return:
        ;       HL = quotient
        ;       A = remainder
        ;       DE is unchanged
        ;       BC is ten
d1610::
                ld bc,$0d0a
                xor a
                
                add hl,hl
                rla
                add hl,hl
                rla
                add hl,hl
                rla
d1610_10:
                add hl,hl
                rla
                cp c
                jr c,d1610_20
                sub c
                inc l
d1610_20:
                djnz d1610_10           
                ret


        ;---------------------------------------------------------------
        ; d3210:
        ; Divide DEHL by 10.
        ; 
        ; On entry:
        ;       DEHL = dividend
        ;
        ; On return:
        ;       DEHL = quotient
        ;       A = remainder
        ;       BC is ten
d3210::
                ld bc,$0d0a
                xor a
                ex de,hl
                add hl,hl
                rla
                add hl,hl
                rla
                add hl,hl
                rla
d3210_10:
                add hl,hl
                rla
                cp c
                jr c,d3210_20
                sub c
                inc l
d3210_20:
                djnz d3210_10

                ex de,hl
                ld b,16
d3210_30:
                add hl,hl
                rla
                cp c
                jr c,d3210_40
                sub c
                inc l
d3210_40:
                djnz d3210_30
                ret

        ;---------------------------------------------------------------
        ; m16x8
        ; Multiply DE by C.
        ;
        ; On return:
        ;       A = C
        ;       HL = product
        ;       B = 0
        ;       C, D, E not changed
m16x8::
                ld a,c
                ld b,8
                ld hl,0
m16x8_10:
                add hl,hl
                rlca
                jr nc,m16x8_20
                add hl,de
m16x8_20:
                djnz m16x8_10
                ret

        ;---------------------------------------------------------------
        ; m16x16
        ; Multiply DE by BC.
        ;
        ; On return:
        ;       DEHL = product
        ;       BC is unchanged
        ;       A = 0
m16x16::
                ld hl,0
                ld a,16
m16x16_10:
                add hl,hl
                rl e
                rl d
                jr nc,m16x16_20
                add hl,bc
                jr nc,m16x16_20
                inc de
m16x16_20:
                dec a
                jr nz,m16x16_10
                ret
                
                .end