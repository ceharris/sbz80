
		section	CODE
		org	$0

gpio_port       defl    $0
gpio_p0		defl	$1
gpio_p1         defl    $2
gpio_p2         defl    $4

delay_count	defl	30

		ld	sp,0			; place stack at top of RAM

                ld      a,gpio_p0               ; TX=MARK
                ld      (gpio_out),a
                out     (gpio_port),a

hello:
                ; send one character
                ld	hl,message
		call	bb_puts

                ; toggle the activity LED
                ld      a,(gpio_out)
                xor     gpio_p2
                ld      (gpio_out),a
                out     (gpio_port),a

                call    delay
                jp      hello

	;---------------------------------------------------------------
	; bb_puts:
	; Transmits a null-terminated straing using asynchronous serial
	; on an unused pin in the the MMU register.
	;
	; On entry:
	;	(HL) first character of string
	; On return:
	;	(HL) null terminator
	;	C destroyed
	;
bb_puts:
		ld	a,(hl)
		or	a
		ret	z			; done if null terminator
		ld	c,a
		call	bb_putc			; transmit it
		inc	hl
		jp	bb_puts

	;---------------------------------------------------------------
	; bb_putc:
	; Transmits a character using asynchronous serial on an unused
	; pin in the MMU register. Serial framing is 8 bits, no parity
	; and 1 stop bit. Baud rate is 9600 bps with 7.3728 MHz system
	; clock.
	;
	; On entry:
	;	C = character to transmit
	;
bb_putc:
		push	bc
		push	de
                push    hl
		ld	a,(gpio_out)
		rra			; throw out bit 0
		ld	l,a		; save shifted GPIO bits
		ld	b,8		; 8 data bits to transmit
                or	a		; clear carry flag
                rla			; gpio_p0 = 0 (start bit)
           	out	(gpio_port),a	; transmit the start bit

           	;
           	; delay for ~383 clock cycles
     		;
                ld	a,18		; [T=7]
bb_putc_05:
		dec	a		; [T=4] 
         	nop			; [T=4]
         	jp	nz,bb_putc_05	; [T=10]
         	nop			; [T=4]
         	nop			; [T=4]
         	nop			; [T=4]
         	nop			; [T=4]
         	nop			; [T=4]
         	nop			; [T=4]

bb_putc_10:
		ld	a,l		; [T=4] recover shifted GPIO bits
		rrc	c		; [T=8] put next bit into carry flag
		rla			; [T=4] put data bit into gpio_p0
		out	(gpio_port),a	; [T=11] transmit the data bit
		; before first bit
         	; cycles = 7 + 40*18 + 3*4 + 4 + 8 + 4 + 11 = 34 + 18*18 + 6*4 = 382
         	; time = 382 cycles * 135.633 nsec/cycle = 51.81 usec
         	; before remaining bits
         	; cycles = 7 + 39*18 + 3*4 + 4 + 4 + 10 + 4 + 8 + 4 + 11 = = 52 + 17*18 + 6*4 = 382
         	; time = 382 cycles * 135.633 nsec/cycle = 51.81 usec

         	;
         	; delay ~383 clock cycles
         	;
		ld	a,17		; [T=7]
bb_putc_15:
		dec	a		; [T=4]
		nop			; [T=4]
		jp	nz,bb_putc_15	; [T=10]
		nop			; [T=4]
		nop			; [T=4]
		nop			; [T=4]
		nop			; [T=4]
		nop			; [T=4]
		nop			; [T=4]
                dec	b		; [T=4]
                jp	nz,bb_putc_10	; [T=10]

                nop			; [T=4]
                nop			; [T=4]
                ld	a,l		; [T=4] recover shifted GPIO bits
		scf			; [T=4]
		rla			; [T=4] gpi_p0 = 1 (stop bit)	
		out (gpio_port),a	; [T=11]
		; before stop bit 
		; cycles = 7 + 39*18 + 3*4 + 4 + 10 + 2*4 + 4 + 4 + 4 + 11 = 44 + 17*18 + 6*4 + 2*4 = 382
         	; time = 382 cycles * 135.633 nsec/cycle = 51.81 usec

         	;
         	; delay ~767 clock cycles
         	;
         	ld	a,20		; [T=7]
 bb_putc_25:
 		dec	a		; [T=4]
 		nop			; [T=4]
 		jp	nz,bb_putc_25	; [T=10]
 		nop			; [T=4]
 		nop			; [T=4]
 		nop			; [T=4]
 		nop			; [T=4]
 		; after stop bit
 		; cycles = 7 + 42*18 + 4 = 7 + 20*18 + 4*4 = 383
         	; time = 383 cycles * 135.633 nsec/cycle = 51.95 usec

		pop	hl
                pop	de
		pop	bc
		ret

	;---------------------------------------------------------------	
	; Delay for about half a second
delay:
		push	bc
                push	de
                ld	b,2
delay_10:
		ld	de,0
delay_20:
		dec	de
		ld	a,d
		or	e
		jp	nz,delay_20
		djnz	delay_10
		pop	de
		pop	bc
		ret

		section RODATA
message:
		db	"Hello, world.\r\n",0


                section BSS
                org     $8000
gpio_out:       ds      1

