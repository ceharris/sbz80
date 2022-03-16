        ;---------------------------------------------------------------
        ; l7_out:
        ; Sends a sequence of (address, pattern) values to the display.
        ;
        ; On entry:
        ;       B = number of pairs to send
        ;       IY -> values to be sent
        ; On return:
        ;       HL destroyed

l7_out:
                ex de,hl
l7_out_10:
                ld c,spi_l7
                ld d,(iy)
                inc iy
                ld e,(iy)
                inc iy
                call spi16
                djnz l7_out_10
                ex de,hl
                ret
