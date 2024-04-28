
		include "machine.h.asm"
		include "ioctl.h.asm"
		include "acia.h.asm"

		public acia_isr
		public acia_init
		public acia_ioctl
		public acia_getc
		public acia_getcnb
		public acia_flush
		public acia_putc

		extern delay

ACIA_CTRL       defl ACIA_PORT + 0
ACIA_DATA       defl ACIA_PORT + 1

ACIA_DIV_1      defl 0
ACIA_DIV16      defl 1
ACIA_DIV64      defl 2
ACIA_RESET      defl 3

ACIA_7E2        defl 0 << 2
ACIA_7O2        defl 1 << 2
ACIA_7E1        defl 2 << 2
ACIA_7O1        defl 3 << 2
ACIA_8N2        defl 4 << 2
ACIA_8N1        defl 5 << 2
ACIA_8E1        defl 6 << 2
ACIA_8O1        defl 7 << 2

ACIA_RTS_DTI    defl 0 << 5
ACIA_RTS_ETI    defl 1 << 5
ACIA_NOT_RTS 	defl 2 << 5
ACIA_RTS_BRK    defl 3 << 5

ACIA_DRI        defl 0 << 7
ACIA_ERI        defl 1 << 7

ACIA_RDRF       defl 1 << 0
ACIA_TDRE       defl 1 << 1
ACIA_DCD        defl 1 << 2
ACIA_CTS        defl 1 << 3
ACIA_FE         defl 1 << 4
ACIA_OVRN       defl 1 << 5
ACIA_PE         defl 1 << 6
ACIA_IRQ        defl 1 << 7

ACIA_READY	defl ACIA_DIV64 | ACIA_8N1 | ACIA_RTS_DTI | ACIA_ERI
ACIA_NOT_READY	defl ACIA_DIV64 | ACIA_8N1 | ACIA_NOT_RTS | ACIA_ERI

RX_BUFFER_SIZE	defl 128
RX_BUFFER_LO	defl 16
RX_BUFFER_HI	defl RX_BUFFER_SIZE - RX_BUFFER_LO

LF		defl 0x0a
CR		defl 0x0d
XON             defl 0x11
XOFF            defl 0x13

RX_READY	defl 1 << 6
TX_READY	defl 1 << 7

FLUSH_DELAY	defl 10			; flush delay in milliseconds


		section	CODE_USER

	;---------------------------------------------------------------
	; acia_init:
	; Prepares the MC6850 ACIA for use.
	;
acia_init:
		ld	a,TX_READY | RX_READY
		ld      (io_flags),a
		xor	a
		ld	(tx_last),a
		ld	(rx_drops),a
		ld	hl,rx_buffer
		ld	(rx_head),hl
		ld	(rx_tail),hl
		ld	a,ACIA_RESET | ACIA_RTS_DTI
		out	(ACIA_CTRL),a
		ld	a,ACIA_READY
		out	(ACIA_CTRL),a
		ret


	;---------------------------------------------------------------
	; acia_ioctl:
	; Sets the I/O control flags.
	; 
	; On entry:
	;	C = flags to set
	; 
	; On return:
	;	C's most significant bit may be clobbered
	;
acia_ioctl:
		ld	a,(io_flags)
		rrca				; set carry if in cooked mode
		jp	nc,acia_ioctl_10	; go if in raw mode

		rlca				; restore original flags

		; In cooked mode now, so we need to preserve 
		; current TX_READY AND RX_READY bit states
		rl	c			; discard TX_READY flag
		rl	c			; discard RX_READY flag

		rlca				; copy RX_READY to carry
		rlca				
		rr	c			; move RX_READY into flags
		rrca				; copy TX_READY to carry
		rrca
		rr	c			; move TX_READY into flags
		ld	a,c
		ld	(io_flags),a		; store new flags
		ret

		; if in raw mode now, we assume ready until we hear otherwise
acia_ioctl_10:
		ld	a,c
		or	TX_READY | RX_READY
		ld	(io_flags),a		; store new flags
		ret



	;--------------------------------------------------------------
	; acia_putc:
	; Transmits a character via the MC6850 ACIA.
	;
	; On entry:
	;	C = character to transmit
	;
	; On return
	;	AF clobbered
	;
acia_putc:
		push bc
acia_putc_10:
		ld a,(io_flags)		; get transmit flags
		ld b,a			; save for later

		; check for cooked vs raw transmit mode
		and IOCTL_COOKED
		jp z,acia_putc_50	; raw mode; go transmit

		; check whether flow control is enabled
		ld a,b
		and IOCTL_COOKED | IOCTL_XON_XOFF | TX_READY
		cp  IOCTL_COOKED | IOCTL_XON_XOFF | TX_READY
		jp z,acia_putc_20	; flow control on, receiver ready
		cp  IOCTL_COOKED | IOCTL_XON_XOFF
		jp z,acia_putc_10	; flow control on, receiver not ready
acia_putc_20:
		; check whether we need to add CR before LF
		ld a,b			; recover transmit flags
		and IOCTL_CRLF
		jp z,acia_putc_50	; don't need to handle CR+LF

		; are we about to transmit LF?
		ld a,c
		cp LF
		jp nz,acia_putc_50	; not transmitting LF

		; was the previously transmitted character CR?
		ld a,(tx_last)
		cp CR
		jp z,acia_putc_50	; already sent a CR
acia_putc_30:
		; send a CR before sending the LF
		in a,(ACIA_CTRL)
		and ACIA_TDRE
		jp z,acia_putc_30
		ld a,CR
		out (ACIA_DATA),a
acia_putc_50:
		in a,(ACIA_CTRL)
		and ACIA_TDRE
		jp z,acia_putc_50
		ld a,c
		out (ACIA_DATA),a	
		ld (tx_last),a
		pop bc	
		ret


	;--------------------------------------------------------------
	; acia_getc:
	; Receives a character via the MC6850 ACIA. Waits until a
	; character is available in the receive buffer.
	;
	; On return:
	;	A is the received character
	;	C flag is reset
	;
acia_getc:
		ld a,(rx_length)	; get num chars waiting
		or a
		jp z,acia_getc		; block until non-zero

		push hl
		ld hl,(rx_head)
		inc hl

		; assume buffer is page-aligned and less than 256 bytes
		; and determine whether the pointer needs to wrap
		ld a,l			
		cp RX_BUFFER_SIZE	; is LSB less than buffer size?
		jp c,acia_getc_10	; if so, no wrap
		xor a			; wrap by zeroing the LSB
		ld l,a 			; (because we're page-aligned)
acia_getc_10:
		di
		ld (rx_head),hl		; store new head pointer
		; update buffer length
		ld a,(rx_length)
		dec a
		ld (rx_length),a
		ei
		cp RX_BUFFER_LO		; below the low water mark?
		jp nc,acia_getc_30	; go if still at or above low mark

		; assert RTS
		ld a,ACIA_READY
		out (ACIA_CTRL),a

		; is XON/XOFF flow control enabled and are we paused?
		ld a,(io_flags)		; get transmit flags
		and IOCTL_COOKED | IOCTL_XON_XOFF | RX_READY
		cp  IOCTL_COOKED | IOCTL_XON_XOFF
		jp nz,acia_getc_30

		; send an XON
acia_getc_20:
		in a,(ACIA_CTRL)
		and ACIA_TDRE
		jp z,acia_getc_20
		ld a,XON
		out (ACIA_DATA),a
		ld a,(io_flags)
		or RX_READY
		ld (io_flags),a
acia_getc_30:
		ld a,(hl)		; get the received char
		pop hl
		ret


	;---------------------------------------------------------------
	; acia_getcnb:
	; Receives a character from the MC6850 ACIA without blocking if
	; no character is available.
	;
	; On return:
	;	if Z flag set, no character is available
	;	if Z flag reset, A contains the received character
	;
acia_getcnb:
		ld a,(rx_length)
		or a
		ret z
		jp acia_getc

	;---------------------------------------------------------------
	; acia_flush:
	; Flushes the input queue, discarding all waiting characters.
	;
	; On return:
	;	A = 0 and Z flag set
	;
acia_flush:
		call acia_getcnb
		ret z			; go if nothing to flush
acia_flush_10:
		call acia_getcnb	; try again
		jr nz,acia_flush	; go until no input available

		; delay for about FLUSH_DELAY milliseconds
		push bc
		ld bc,FLUSH_DELAY		
		call delay
		pop bc
		
		; go check again
		jr acia_flush


	;---------------------------------------------------------------
	; acia_isr:
	; Interrupt service routine for the MC6850 ACIA.
	;
acia_isr:
		push af
		push hl

		; read ACIA status
		in a,(ACIA_CTRL)
		and ACIA_RDRF		
		jp z,acia_isr_90	; go if not receive event

		; read received character
		in a,(ACIA_DATA)
		ld l,a			; save for later

		; check whether XON/XOFF flow control is enabled
		ld a,(io_flags)		; get transmit flags
		ld h,a			; save for later
		and IOCTL_COOKED | IOCTL_XON_XOFF
		cp  IOCTL_COOKED | IOCTL_XON_XOFF
		jp nz,acia_isr_10  	; go if flow control not on

		; if XON or XOFF, change TX_READY bit and exit
		ld a,l			; recover received character
		and 0xfd		; XON and XOFF differ only by bit 2         
		cp XON
		jp nz,acia_isr_10	; go if neither XON nor XOFF
		ld a,l			; recover received character
		rl h			; discard TX_READY bit
		
		; put complement of new TX_READY bit state into carry
		rra
		rra
		ccf			; complement to get new flag state
		rr h			; rotate in new TX_READY bit
		ld a,h
		ld (io_flags),a		; update flags register
		jp acia_isr_90		; done

		; store received character in ring if possible
acia_isr_10:
		ld a,(rx_length)	; get current length
		cp RX_BUFFER_SIZE - 1	; is the buffer full?
		jp z,acia_isr_80	; go if full

		ld a,l			; A = received character
		push af			; save it
		ld hl,(rx_tail)		; get current tail pointer
		inc hl			; next buffer position

		; assume buffer is page-aligned and less than 256 bytes
		; and determine whether the pointer needs to wrap
		ld a,l			
		cp RX_BUFFER_SIZE	; is LSB less than buffer size
		jp c,acia_isr_20	; if so, no wrap
		xor a			; wrap by zeroing the LSB
		ld l,a 			; (because we're page-aligned)
acia_isr_20:
		ld (rx_tail),hl		; save new tail pointer
		pop af			; A = received character
		ld (hl),a		; store in buffer
		ld a,(rx_length)	; get buffer length
		inc a			; increase by 1
		ld (rx_length),a	; save new length
		cp RX_BUFFER_HI		; are we at the high water mark?
		jp c,acia_isr_90	; go if below high water mark

		; withdraw RTS
		ld a,ACIA_NOT_READY
		out (ACIA_CTRL),a	

		; is XON/XOFF flow control enabled?
		ld a,(io_flags)		; get transmit flags
		and IOCTL_COOKED | IOCTL_XON_XOFF | RX_READY
		cp  IOCTL_COOKED | IOCTL_XON_XOFF | RX_READY
		jp nz,acia_isr_90

		; send an XOFF
acia_isr_30:
		in a,(ACIA_CTRL)
		and ACIA_TDRE
		jp z,acia_isr_30
		ld a,XOFF
		out (ACIA_DATA),a
		ld a,(io_flags)
		and ~(RX_READY)
		ld (io_flags),a
		jp acia_isr_90

acia_isr_80:
		ld a,(rx_drops)
		inc a
		ld (rx_drops),a
acia_isr_90:
		pop hl
		pop af
		ei
		reti

		section ACIA_BUFFER
rx_buffer:	ds RX_BUFFER_SIZE
rx_head:	ds 2
rx_tail:	ds 2
rx_length:	ds 1
rx_drops:	ds 1
tx_last:	ds 1
io_flags:	ds 1
