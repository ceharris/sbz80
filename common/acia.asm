 
 ;----------------------------------------------------------------------
 ; MC6850 Asynchronous Communication Adapter Support Functions
 ; These routines are slight modifications of code originally written
 ; by Phillip Stevens (https://github.com/feilipu) and licensed for
 ; non-commericial use.
 ;-----------------------------------------------------------------------

	include "machine.h.asm"
	include "workspace.h.asm"

	include "../include/ascii.h.asm"
	include "../include/acia.h.asm"

	defc ACIA_CTRL_PORT = ACIA_PORT
	defc ACIA_DATA_PORT = ACIA_PORT + 1

	; fixed config: 115200,8,N,2 (assert RTS, enable RX interrupt, disable TX interrupt)
	defc ACIA_CONFIG = %10010010	

	defc ACIA_TDRE = $2 
	defc ACIA_TEI_MASK = $60
	defc ACIA_TDI_RTS_HIGH = $40
	defc ACIA_TEI_RTS_LOW = $20
	defc ACIA_TDI_RTS_LOW = $0

 	defc ACIA_RESET = $3


;-----------------------------------------------------------------------
; acia_init:
; Initializes the ACIA hardware and associated in-memory state.
;
acia_init:
	; reset the ACIA hardware
	ld a,ACIA_RESET
	out (ACIA_CTRL_PORT),a

	; initialize in-memory state
	xor a
	ld hl,ACIA_RX_BUFFER
	ld (ACIA_RX_HEAD),hl
	ld (ACIA_RX_TAIL),hl
	ld (ACIA_RX_LENGTH),a
	ld (ACIA_TX_LAST),a
	
	; configure the ACIA
	ld a,ACIA_CONFIG
	ld (ACIA_CTRL_REG),a
	out (ACIA_CTRL_PORT),a

	ret

;-----------------------------------------------------------------------
; acia_isr:
; Interrupt service routine for the MC6850 ACIA. 
; This implementation supports interrupt driven receive only.
;
acia_isr:
	push af
	push hl

	in a,(ACIA_CTRL_PORT)		; read ACIA status
	rrca				; put RDRF into carry flag
	jp NC,acia_isr_end

acia_isr_rx:
	in a,(ACIA_DATA_PORT)		; read received char
	ld l,a				; save for later

	ld a,(ACIA_RX_LENGTH)		; number of chars already waiting
	cp ACIA_BUFFER_SIZE-1		; is there space in the buffer
	jp NC,acia_isr_rx_again		; buffer full, check for another

	ld a,l				; recover received char
	ld hl,(ACIA_RX_TAIL)			; HL -> tail of ring buffer
	ld (hl),a			; store received char
	inc l				; next ring buffer position
	ld (ACIA_RX_TAIL),hl			; save new tail pointer

	; atomically increment count of waiting chars
	ld hl,ACIA_RX_LENGTH
	inc (hl)

	ld a,(ACIA_RX_LENGTH)		; number of chars waiting
	cp ACIA_BUFFER_HI			; check high water mark
	jp NZ,acia_isr_rx_again		; not there yet, check for another

	ld a,(ACIA_CTRL_REG)		; fetch control register state
	and ~ACIA_TEI_MASK		; isolate the bits we want to change
	or ACIA_TDI_RTS_HIGH		; disable tx interrupt and withdraw RTS
	ld (ACIA_CTRL_REG),a		; store new control register state
	out (ACIA_CTRL_PORT),a		; write new control state to ACIA

acia_isr_rx_again:
	in a,(ACIA_CTRL_PORT)		; read ACIA status
	rrca				; put RDRF into carry flag
	jp C,acia_isr_rx		; go handle another eceived char

acia_isr_end:
	pop hl
	pop af
	ei
	reti


;-----------------------------------------------------------------------
; acia_getcnb:
; Gets a received character if one is avaiable.
; 
; On return:
;	If NZ, A is the received character.
;	Otherwise no character was received.
;
acia_getcnb:
	ld a,(ACIA_RX_LENGTH)		; get number of chars waiting
	or a
	ret Z				; go if no character is available
	jr acia_getc_check_rts


;-----------------------------------------------------------------------
; acia_getc:
; Gets the next received character. If no character is available, this
; function blocks until a character is received.
; 
; On return:
;	A is the received character
;
acia_getc:
	ld a,(ACIA_RX_LENGTH)		; get number of chars waiting
	or a
	jr Z,acia_getc			; wait until there's a char available

acia_getc_check_rts:
	cp ACIA_BUFFER_LO			; check low water mark
	jr NZ,acia_getc_char		; go if no change to RTS

	di
	ld a,(ACIA_CTRL_REG)		; fetch control register state
	and ~ACIA_TEI_MASK		; isolate the bits we want to change
	or ACIA_TDI_RTS_LOW		; disable tx interrupt and assert RTS
	ld (ACIA_CTRL_REG),a		; store new control register state
	ei
	out (ACIA_CTRL_PORT),a		; write new control state to ACIA

acia_getc_char:
	push hl

	ld hl,(ACIA_RX_HEAD)			; HL -> head of the ring buffer
	ld a,(hl)			; fetch waiting char
	inc l				; next ring buffer position
	ld (ACIA_RX_HEAD),hl			; store new ring head pointer

	; atomically decrement count of waiting chars
	ld hl,ACIA_RX_LENGTH
	dec (hl)

	or a				; NZ only if it isn't ASCII NUL
	pop hl
	ret


;-----------------------------------------------------------------------
; acia_flush:
; Flushes the receive buffer, discarding any received characters.
;
acia_flush:
	call acia_getcnb
	jr NZ,acia_flush
	ret
	

;-----------------------------------------------------------------------
; acia_putc:
; Puts a character for transmission. This function blocks until the
; character can be transmitted.
; 
; On entry:
;		C is the character to send
;
acia_putc:
	push hl
	
	ld a,(ACIA_TX_LAST)
	cp '\r'				; was last a carriage return?
	jr z,acia_putc_tx		; no need to consider line feed
	ld a,c				; A = char to send
	cp '\n'				; sending a line feed?
	jr nz,acia_putc_tx		; if not, go ahead and send it

	; before sending a line feed, insert a carriage return
acia_putc_cr:
	in a,(ACIA_CTRL_PORT)		; read ACIA status
	and ACIA_TDRE
	jr Z,acia_putc_cr
	ld a,'\r'
	out (ACIA_DATA_PORT),a		; send CR

acia_putc_tx:
	in a,(ACIA_CTRL_PORT)		; read ACIA status
	and ACIA_TDRE
	jr Z,acia_putc_tx		; wait until transmitter ready

	ld a,c				; A = char to send
	out (ACIA_DATA_PORT),a		; transmit char
	ld (ACIA_TX_LAST),a			; store last character sent
	pop hl
	ret
