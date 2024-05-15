		section	CODE
		org	$0

gpio_reg	defl	$0
gpio_p1		defl	$2
gpio_p2         defl    $4

                ld      sp,0
		ld	c,gpio_p2
loop:
		ld	a,c
		xor	gpio_p1|gpio_p2
		ld	c,a
		out	(gpio_reg),a
#ifdef USE_STACK
                call    delay
#else
		ld	b,2
loop_10:
		ld	de,0
loop_20:
		dec	de
		ld	a,d
		or	e
		jp	nz, loop_20
		djnz	loop_10
#endif
		jp	loop

delay:          
                ld      b,2
delay_10:
                ld      de,0
delay_20:
                dec     de
                ld      a,d
                or      e
                jp      nz, delay_20
                djnz    delay_10
                ret

