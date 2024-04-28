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
                ex de,hl		; preserve DE in HL
l7_out_10:
                ld c,spi_l7		; SPI address for the display
                ld d,(iy)		; D is the digit address
                inc iy
                ld e,(iy)		; E is the pattern to display
                inc iy
                call spi16		; send DE (MSB first)
                djnz l7_out_10		; Go until all pairs sent
                ex de,hl		; recover DE
                ret
