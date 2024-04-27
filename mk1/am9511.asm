		include "machine.h.asm"
		include "am9511.h.asm"

		extern	gpio_out

OP_SADD         defl    $6c

APU_DATA	defl	APU_PORT + 0
APU_CTRL	defl	APU_PORT + 1

APU_BUSY	defl	$80


		section	CODE_USER
	; 16-bit fixed point add: y = y + x
	; On entry:
	;       HL = y
	;       DE = x
	; On return:
	;       HL contains the result
sadd:
		ld	a,l
		out 	(APU_DATA),a
		ld	a,h
		out	(APU_DATA),a
		ld	a,e
		out	(APU_DATA),a
		ld	a,l
		out	(APU_DATA),a
		ld	a,OP_SADD
		out	(APU_CTRL),a
		call	apu_wait
		in	a,(APU_DATA)
		ld	h,a
		in	a,(APU_DATA)
		ld	l,a
		ret

apu_wait:
		in	a,(APU_CTRL)
		rla
		jp	c,apu_wait
		ret

