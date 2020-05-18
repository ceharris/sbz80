		name do

		extern d3210
		include ports.asm
		include pio_defs.asm

lcd_ctl		equ pio_port_base + pio_port_a
lcd_data   	equ pio_port_base + pio_port_b

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

	;---------------------------------------------------------------
	; SVC: doinit
	; Initializes the LCD display. The result is similar to the
	; power-on reset state. The initialization need only be performed
	; once at startup. Reinitializing is time consuming and should
	; be avoided.
	;
	;	* 2 rows of display
	;	* display on with blinking cursor
	;	* entry mode set to increment without shifting the display
	;
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

	;---------------------------------------------------------------
	; SVC: doclr
	; Clears the LCD display memory.
	;
	; On return:
	;	AF, C destroyed
	;
doclr::
		ld c,lcd_clr_disp
		call doexec
		ret

	;---------------------------------------------------------------
	; SVC: dohome
	; Resets the LCD to the home position, reverting and shift and
	; positioning the cursor at 0,0.
	;
	; On return
	;	AF, C destroyed
	;
dohome::
		ld c,lcd_go_home
		call doexec
		ret

	;---------------------------------------------------------------
	; SVC: dogoto
	; Positions the LCD cursor.
	;
	; On entry:
	;	B = row (zero based), C = column (zero based)
	;
	; On return
	;	AF, C destroyed
	;
dogoto::
		ld a,b			; start at offset 0
		or a
		ld a,0			; start at offset 0
		jr z,dogoto_col		; jump if no row offsets to add
dogoto_row:
		add lcd_row_length	; add a row offset
		djnz dogoto_row		; for all rows
dogoto_col:
		add c			; add column offset
		or lcd_ddram_addr	; set command bit
		ld c,a			; C is the command to execute
		call doexec		; execute it
		ret

	;---------------------------------------------------------------
	; SVC: dop10w
	; Displays a 32-bit unsigned integer in decimal notation.
	;
	; On entry:
	;	DEHL is the quantity to display
	; On return:
	;	AF, BC, DE, HL destroyed 
	;	(only index and special purpose registers preserved)
	;
dop10w_bsize	equ	11		; ten digits + null terminator
dop10w::
		push ix
		ld ix,-dop10w_bsize	; two's complement of buffer size
		add ix,sp		; subtract buffer size 
		ld sp,ix		; reserve buffer space

		ld bc,dop10w_bsize-1
		add ix,bc		; point to end of buffer
		ld (ix),0		; null terminator
			
dop10w_10:
		; convert to decimal by repetitive division
		call d3210		; divide DEHL by 10
		add a,'0'		; convert remainder to decimal digit
		dec ix
		ld (ix),a		; store digit
		
		; anything left in the lower 16 bits ?
                ld a,l
                or h
                jr nz,dop10w_10

		; anything left in the upper 32 bits ?
                ld a,e
                or d
                jr nz,dop10w_10
dop10w_20:
		; display the result
		ld a,(ix)
		inc ix 
		or a
		jr z,dop10w_30		; go if null terminator
		ld c,a			; character to be displayed
		call doputc
		jr dop10w_20
dop10w_30:
		; restore stack
		ld ix,dop10w_bsize
		add ix,sp		; release buffer space
		ld sp,ix		

		pop ix			
		ret		

	;---------------------------------------------------------------
	; SVC: doputs
	; Displays a null-terminated string at current cursor position.
	;
	; On entry:
	;	HL points to the string to display
	; On return:
	;	HL points to the null terminator
	;	AF, C destroyed
	;
doputs::
		ld a,(hl)
		or a
		ret z
		ld c,a
		call doputc
		inc hl
		jr doputs
		ret

	;---------------------------------------------------------------
	; SVC: doputc
	; Displays a character at the current cursor position.
	;
	; On entry:
	;	C is the character to display
	; 
	; On return:
	;	AF destroyed
	;
doputc::
		call dowait

		; put the character into the data register
		ld a,c			; A is the character to output
		out (lcd_data),a

		in a,(lcd_ctl)
		or lcd_dr | lcd_e		
		out (lcd_ctl),a 	; DR=1, E=1
		and low(not(lcd_dr | lcd_e))
		out (lcd_ctl),a		; DR=0, E=0
		ret

	;---------------------------------------------------------------
	; doexec: 
	; Executes an instruction on the LCD.
	;
	; On entry:
	;	C is the instruction to execute
	;
	; On return:
	; 	AF destroyed
	;
doexec:
		call dowait		; wait until LCD isn't busy

		; put the instruction in the LCD register	
		ld a,c			; C is the instruction
		out (lcd_data),a
		
		in a,(lcd_ctl)
		or lcd_e
		out (lcd_ctl),a		; E=1
		and low(not(lcd_e))
		out (lcd_ctl),a		; E=0
		ret

	;---------------------------------------------------------------
	; dowait:
	; Waits for the LCD busy bit to clear.
	;
dowait:
		push bc

		; set PIO port for LCD data to mode 3 
		ld a,pio_mode3
		out (lcd_data+pio_cfg),a
		ld a,lcd_in_mask	; set mask for input
		out (lcd_data+pio_cfg),a
dowait_10:
		; read busy bit
		in a,(lcd_ctl)
		or lcd_rd | lcd_e	
		out (lcd_ctl),a 	; RD=1, E=1
		in a,(lcd_data)
		ld c,a
		in a,(lcd_ctl)
		and low(not(lcd_rd | lcd_e))	
		out (lcd_ctl),a 	; RD=0, E=0

		; test busy bit
		ld a,c
		and lcd_busy
		jr nz,dowait_10

		; set PIO port for LCD data to mode 3 
		ld a,pio_mode3
	 	out (lcd_data+pio_cfg),a
		ld a,lcd_out_mask	; set mask for output
		out (lcd_data+pio_cfg),a

		pop bc
		ret

		end
