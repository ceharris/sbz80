
		.name l7test

		.extern d3210

spi_l7 		.equ 0
num_digits      .equ 8
buf_size        .equ 2*num_digits + 4


		.org 0
		ld sp,0

                ; unsigned 8-bit, zero padded, digits 3..2 with decimal point
                ld c,00000010b
                ld b,10000011b
                ld l,9
                call l7pd8               

                ifdef FINISHED
                ; unsigned, exact fit
                ld b,4
                ld c,01000000b
                ld de,0
                ld hl,12345
                call l7pd32

                ; unsigned, padded with spaces
                ld b,8
                ld c,01000000b
                ld hl,12345
                call l7pd16

                ; unsigned, padded with zeroes
                ld b,8
                ld c,00000000b
                ld hl,12345
                call l7pd16

                ; signed positive, exact fit, decimal point at 2
                ld b,6
                ld c,11010000b
                ld hl,12345
                call l7pd16

                ; signed negative, exact fit, decimal point at 2
                ld b,6
                ld c,11010000b
                ld hl,-12345
                call l7pd16                

                ; signed positive, pad with spaces, decimal point at 4
                ld b,8
                ld c,11100000b
                ld hl,12345
                call l7pd16

                ; signed negative, pad with zeroes, decimal point at 4
                ld b,8
                ld c,10100000b
                ld hl,-12345
                call l7pd16

                ; field width is zero
                ld b,0
                ld c,11100000b
                ld hl,-12345
                call l7pd16

                ; field width is one with signed input
                ld b,1
                ld c,11100000b
                ld hl,-12345
                call l7pd16

                ; field width is one, unsigned, input value > 9
                ld b,1
                ld c,01000000b
                ld hl,10
                call l7pd16

                ; field width is two, signed, abs(input value) > 9
                ld b,2
                ld c,11000000b
                ld hl,-10
                call l7pd16

                endif

loop:
		jp loop

spi16:
		ret

		.include l7pd16.asm
                .include l7out.asm

		end
