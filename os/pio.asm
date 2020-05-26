	;---------------------------------------------------------------
	; Mainboard PIO support
	;
	; The mainboard PIO connects the display and keyboard. Port A
        ; is used for the keyboard and the LCD display control pins.
	; Port B is used for the LCD display data pins. The LCD display
	; uses the defacto standard Hitachi HD44780U controller in 8-bit
	; interface mode. This requires three control pins and 8 data
	; I/O pins.
	;
	; The keyboard is essentially a collection of momentary contact
	; switches and pullup resistors wired to a pair of 74HC165 shift
	; registers with parallel (broadside) load. The shift register
	; interface requires just three pins; one for serial input, and
	; two control pins (load and clock).
	;
	; Pin assignments
	; ---------------
	; PA0 -- LCD display EN pin (output)
	; PA1 -- LCD display RS pin (output)
	; PA2 -- LCD display RW pin (output)
	; PA3 -- Keyboard register serial input (input)
	; PA4 -- Keyboard register parallel load enable (output)
	; PA5 -- Keyboard register serial clock (output)
	; PA6 -- (unused, not connected) (output)
	; PA7 -- RTC interrupt input
	; PB0 -- LCD display D0 pin (output)
	; PB1 -- LCD display D1 pin (output)
	; PB2 -- LCD display D2 pin (output)
	; PB3 -- LCD display D3 pin (output)
	; PB4 -- LCD display D4 pin (output)
	; PB5 -- LCD display D5 pin (output)
	; PB6 -- LCD display D6 pin (output)
	; PB7 -- LCD display D7 pin (output)
	;
	; The keyboard is scanned and debounced during a timer
	; interrupt, and the display programming is performed
	; synchronously, therefore interrupts are not needed from the
	; PIO. The IEI input of the PIO is shunted to ground, and the
	; INT# ; and IEO outputs are not connected.
	;
	; Both PIO ports are configured using mode 3 with fixed masks
	; and interrupt generation disabled.
	;---------------------------------------------------------------


		name pio
		include isr.asm
		include ports.asm
		include pio_defs.asm


pio_mask_a	equ 0x88		; only pins PA3 and PA7 are inputs
pio_mask_b	equ 0			; all PBx pins are outputs


pio_icfg_a	equ pio_ictl_word|pio_ictl_ei|pio_ictl_mask

pio_imask_a	equ 0x7f		; only pin PA7 should interrupt

		cseg

	;--------------------------------------------------------------
	; pioini:
	; Initializes the mainboard PIO ports.
	;
pioini::
		; port A mode 3
		ld a,pio_mode3
		out (pio_port_base+pio_port_a+pio_cfg),a

		; port A mode I/O control word
		ld a,pio_mask_a
		out (pio_port_base+pio_port_a+pio_cfg),a

		; port A interrupt vector
		ld a,2*isr_pio_port_a
		out (pio_port_base+pio_port_a+pio_cfg),a

		; port A interrupt control word
		ld a,pio_icfg_a
		out (pio_port_base+pio_port_a+pio_cfg),a

		; port A interrupt mask
		ld a,pio_imask_a
		out (pio_port_base+pio_port_a+pio_cfg),a

		; port B mode 3
		ld a,pio_mode3
		out (pio_port_base+pio_port_b+pio_cfg),a

		; port B I/O control word
		ld a,pio_mask_b
		out (pio_port_base+pio_port_b+pio_cfg),a

		ret

		end
