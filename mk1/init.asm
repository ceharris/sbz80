
		include "machine.h.asm"
		include "stdio.h.asm"
		include "bcd.h.asm"
                include "convert.h.asm"
		include "am9511.h.asm"
                include "acia.h.asm"
                include "monitor.h.asm"


		public  gpio_out
		public  init

		section CODE_USER
init:
		ld      sp,0

                xor     a
                ld      (gpio_out),a
                out     (GPIO_PORT),a

                call    acia_init
                ld      c,IOCTL_COOKED|IOCTL_XON_XOFF|IOCTL_CRLF
                call    acia_ioctl

                im      1
                ei

init_10:
                call    monitor
                jp      init_10

	;---------------------------------------------------------------
	; delay:
delay:
		push    bc
		push    de
		ld      b,1
delay_10:
		ld      de,$1000
delay_20:
		dec     de
		ld      a,d
		or      e
		jp      nz,delay_20
		djnz    delay_10
		pop     de
		pop     bc
		ret

convert_demo:
                ld      de,0
convert_demo_10:
                ld      hl,out_buffer
                call    u8toh
                call    puts
                ld      c,' '
                call    putc

                ld      hl,out_buffer
                call    u8toq
                call    puts
                ld      c,' '
                call    putc

                ld      hl,out_buffer
                call    u8tob
                call    puts
                ld      c,' '
                call    putc

                ld      hl,out_buffer
                call    u16toh
                call    puts
                ld      c,' '
                call    putc

                ld      hl,out_buffer
                call    u16toq
                call    puts
                ld      c,' '
                call    putc

                ld      hl,out_buffer
                call    u16tob
                call    puts
                ld      c,' '
                call    putc

                ld      hl,out_buffer
                call    u16toa
                call    puts
                ld      c,'\n'
                call    putc

                inc     de
                jp      convert_demo_10


		section BSS
gpio_out:       ds      1
out_buffer:     ds      32
