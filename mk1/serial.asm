
		include "machine.h.asm"

		public	serial_init
		public	serial_putc

		extern	gpio_out

#if (F_CPU == F_CPU_8)

#if BAUD_RATE == 115200
START_BIT_LOOPS         defl    1
START_BIT_NOPS          defl    3
NEXT_BIT_LOOPS          defl    0
NEXT_BIT_NOPS           defl    3
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    2
STOP_BIT_NOPS           defl    5
#elif BAUD_RATE == 57600
START_BIT_LOOPS         defl    5
START_BIT_NOPS          defl    1
NEXT_BIT_LOOPS          defl    4
NEXT_BIT_NOPS           defl    1
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    6
STOP_BIT_NOPS           defl    2
#elif BAUD_RATE == 38400
START_BIT_LOOPS         defl    8
START_BIT_NOPS          defl    4
NEXT_BIT_LOOPS          defl    7
NEXT_BIT_NOPS           defl    4
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    10
STOP_BIT_NOPS           defl    1
#elif BAUD_RATE == 19200
START_BIT_LOOPS         defl    18
START_BIT_NOPS          defl    6
NEXT_BIT_LOOPS          defl    17
NEXT_BIT_NOPS           defl    6
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    20
STOP_BIT_NOPS           defl    4
#else	; default to 9600
START_BIT_LOOPS         defl    40
START_BIT_NOPS          defl    3
NEXT_BIT_LOOPS          defl    39
NEXT_BIT_NOPS           defl    3
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    42
STOP_BIT_NOPS           defl    1
#endif ; BAUD_RATE

#elif F_CPU == F_CPU_4

#if BAUD_RATE == 57600
START_BIT_LOOPS         defl    1
START_BIT_NOPS          defl    3
NEXT_BIT_LOOPS          defl    0
NEXT_BIT_NOPS           defl    3
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    2
STOP_BIT_NOPS           defl    5
#elif BAUD_RATE == 38400
START_BIT_LOOPS         defl    3
START_BIT_NOPS          defl    2
NEXT_BIT_LOOPS          defl    2
NEXT_BIT_NOPS           defl    3
LAST_BIT_NOPS           defl    1
STOP_BIT_LOOPS          defl    4
STOP_BIT_NOPS           defl    4
#elif BAUD_RATE == 19200
START_BIT_LOOPS         defl    8
START_BIT_NOPS          defl    4
NEXT_BIT_LOOPS          defl    7
NEXT_BIT_NOPS           defl    4
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    10
STOP_BIT_NOPS           defl    1
#else ; default to 9600
START_BIT_LOOPS         defl    18
START_BIT_NOPS          defl    6
NEXT_BIT_LOOPS          defl    17
NEXT_BIT_NOPS           defl    6
LAST_BIT_NOPS           defl    2
STOP_BIT_LOOPS          defl    20
STOP_BIT_NOPS           defl    4
#endif ; BAUD_RATE

#endif ; F_CPU


                macro  delay_loop count
                local  delay_loop_10
                ld      a,count                 ; [T=7]
#if count > 0
delay_loop_10:
                dec     a                       ; [T=4]
                nop                             ; [T=4]
                jp      nz,delay_loop_10        ; [T=10]
#endif
                endm

                macro   delay_nops count
                rept    count
                nop                             ; [T=4]
                endr
                endm

		section	CODE_USER

	;--------------------------------------------------------------
	; serial_init:
	; Prepares GPIO pin 0 for use as an asynchronous serial
	; transmitter.
	;
serial_init:
		ld	a,(gpio_out)	; get GPIO output state
		; TX pin should idle in the MARK state
		rra			; discard pin 0 state
		scf			; set TX pin state (mark)
		rla			; rotate it in
		ld	(gpio_out),a	; put GPIO output state
		out	(GPIO_PORT),a	; latch new GPIO state
		ret

	;--------------------------------------------------------------
	; serial_putc:
	; Transmits a character via asynchronous serial signaling on
	; pin 0 of the GPIO port. Serial framing is 8 bits per frame,
        ; no parity, 1 stop bit, and at the bit rate given by the
	; BAUD_RATE symbol defined in machine.h.asm.
	;
	; On entry:
	;	C = character to transmit
	;
	; On return
	;	AF clobbered
	;
serial_putc:
		push	bc
		push	de
                push    hl
		ld	a,(gpio_out)
		rra			; throw out bit 0
		ld	l,a		; save shifted GPIO bits
		ld	b,8		; 8 data bits to transmit
                or	a		; clear carry flag
                rla			; tx_pin = 0 (start bit)
           	out	(GPIO_PORT),a	; transmit the start bit

                delay_loop      START_BIT_LOOPS
                delay_nops      START_BIT_NOPS

serial_putc_10:
		ld	a,l		; [T=4] recover shifted GPIO bits
		rrc	c		; [T=8] put next bit into carry flag
		rla			; [T=4] put data bit into tx_pin
		out	(GPIO_PORT),a	; [T=11] transmit the data bit
	; before bit 1 (lsb)
	; cycles = 7 + 3*18 + 2*4 + 4 + 8 + 4 + 11 = 34 + 3*18 + 2*4 = 96
	; before bits 2..7
	; cycles = 7 + 3*18 + 2*4 + 4 + 10 + 4 + 8 + 4 + 11 = 48 + 2*18 + 3*4 = 96

       	;
        ; delay before bit 2..7 starts here and continues at serial_putc_10 above
       	;
                delay_loop      NEXT_BIT_LOOPS
                delay_nops      NEXT_BIT_NOPS

                dec	b			; [T=4]
                jp	nz,serial_putc_10	; [T=10]

	; delay for bit 8 (msb) continues here
		delay_nops      LAST_BIT_NOPS

                ld	a,l		; [T=4] recover shifted GPIO bits
		scf			; [T=4]
		rla			; [T=4] tx_pin = 1 (stop bit)
		out (GPIO_PORT),a	; [T=11]

	; before stop bit
	; cycles = 7 + 2*18 + 3*4 + 4 + 10 + 1*4 + 4 + 4 + 4 + 11 = 96

                delay_loop      STOP_BIT_LOOPS
                delay_nops      STOP_BIT_NOPS

	; after stop bit
	; cycles = 7 + 4*18 + 4*4 = 95

		pop	hl
                pop	de
		pop	bc
		ret
