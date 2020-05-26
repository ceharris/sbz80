		;-----------------------------
		; Definitions for the Z80 PIO
		;-----------------------------

pio_port_a	equ 0
pio_port_b	equ 1
pio_cfg		equ 2

		; Mode control word bits
pio_mode_word	equ 0x0f
pio_mode3	equ 0xc0|pio_mode_word

		; Interrupt control word bits
pio_ictl_word	equ 0x7
pio_ien_word	equ 0x3

pio_ictl_ei	equ 0x80		; enable interrupts
pio_ictl_and	equ 0x40		; AND active inputs
pio_ictl_high	equ 0x20		; inputs are active high
pio_ictl_mask	equ 0x10

		; Definitions for zero bits
		; (used just for code readability)
pio_ictl_di	equ 0			; disable interrupts
pio_ictl_or	equ 0			; OR active inputs
pio_ictl_low	equ 0			; inputs are active low

