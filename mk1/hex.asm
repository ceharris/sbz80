		include "machine.h.asm"
		include "hex.h.asm"

HEX_BUFFER_SIZE defl    9


		section CODE_USER

hex8:
		ld      hl,hex_buffer
		call    do_hex8
		ld      (hl),0
		ld      hl,hex_buffer
		ret

hex16:
		push    bc
		push    de
		ld      e,l
		ld      d,h
		ld      hl,hex_buffer
		ld      c,e
		call    do_hex8
		ld      c,d
		call    do_hex8
		ld      (hl),0
		ld      hl,hex_buffer        
		pop     de
		pop     bc
		ret

		do_hex8:
		ld      a,c
		rrca
		rrca
		rrca
		rrca
		call    hex4
		ld      a,c
		call    hex4
		ret

hex4:
		and     0xf
		cp      10
		jp      nc,hex4_10
		add     7
hex4_10:
		add     '0'
		ld      (hl),a
		inc     hl
		ret


		section BSS
hex_buffer:     ds      HEX_BUFFER_SIZE

