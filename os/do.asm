		name do
		include ports.asm

lcd_ctl		equ dsp_port_base + 0
lcd_data   	equ dsp_port_base + 1

pio_mode3	equ 0xcf

lcd_out_mask	equ 0
lcd_in_mask	equ 0x80

lcd_dr		equ 0x4
lcd_rd		equ 0x2
lcd_e		equ 0x1

lcd_clr_disp	equ 0x1
lcd_go_home	equ 0x2
lcd_entry_mode	equ 0x4
lcd_disp_ctl	equ 0x8
lcd_cur_shift	equ 0x10
lcd_function	equ 0x20
lcd_cgram_addr	equ 0x40
lcd_ddram_addr  equ 0x80

lcd_busy	equ 0x80

lcd_row_length	equ 0x40

lcd_8bits	equ 0x10
lcd_two_rows	equ 0x8
lcd_display_on	equ 0x4
lcd_cursor_on	equ 0x2
lcd_blink_on	equ 0x1
lcd_incr	equ 0x2
lcd_shift	equ 0x1


		cseg

doinit::
		; clear the LCD display memory
	 	ld c,lcd_clr_disp
		call doexec

		; set LCD for 8-bit mode with two rows
		ld c,lcd_function + lcd_8bits + lcd_two_rows
		call doexec

		; set LCD display on with blink
		ld c,lcd_disp_ctl + lcd_display_on + lcd_blink_on
		call doexec

		; set LCD entry mode to increment address (no shift)
		ld c,lcd_entry_mode + lcd_incr
		call doexec

		ret

doclr::
		ld c,lcd_clr_disp
		call doexec
		ret

dohome::
		ld c,lcd_go_home
		call doexec
		ret

dogoto::
		ld a,b			; start at offset 0
		or a
		ld a,0			; start at offset 0
		jr z,dogotocol	; jump if no row offsets to add
dogotorow:
		add lcd_row_length	; add a row offset
		djnz dogotorow	; for all rows
dogotocol:
		add c			; add column offset
		or lcd_ddram_addr	; set command bit
		ld c,a			; C is the command to execute
		call doexec		; execute it
		ret
doputs::
		ld a,(hl)
		or a
		ret z
		ld c,a
		call doputc
		inc hl
		jr doputs
		ret

doputc::
		call dowait

		; set PIO port for LCD data to mode 3 
		ld a,pio_mode3
	 	out (lcd_data+2),a
		xor a			; zero => all lines are outputs
		out (lcd_data+2),a

		; put the character into the data register
		ld a,c			; A is the character to output
		out (lcd_data),a

		ld a,lcd_dr+lcd_e	; raise enable, select data reg
		out (lcd_ctl),a
		xor a
		out (lcd_ctl),a		; lower enable, deselect data reg
		ret

doexec:
		; set PIO port for LCD control to mode 3 
		ld a,pio_mode3
		out (lcd_ctl+2),a
		xor a			; zero => all lines are outputs
		out (lcd_ctl+2),a

		call dowait		; wait until LCD isn't busy

		; set PIO port for LCD data to mode 3 
		ld a,pio_mode3
	 	out (lcd_data+2),a
		xor a			; zero => all lines are outputs
		out (lcd_data+2),a

		; put the instruction in the LCD register	
		ld a,c			; C is the instruction
		out (lcd_data),a
		
		ld a,lcd_e
		out (lcd_ctl),a		; raise enable flag
		xor a
		out (lcd_ctl),a		; lower enable flag
		ret

dowait:
		push bc

		; set PIO port for LCD data to mode 3 
		ld a,pio_mode3
		out (lcd_data+2),a
		ld a,lcd_in_mask	; set busy bit as input
		out (lcd_data+2),a
dobusy:
		; read busy bit
		ld a,lcd_rd + lcd_e
		out (lcd_ctl),a
		in a,(lcd_data)
		ld c,a
		ld a,lcd_rd
		out (lcd_ctl),a

		; test busy bit
		ld a,c
		and lcd_busy
		jr nz,dobusy

		pop bc
		ret

		end
