		;-------------------------------------------------------
		; Definitions for the Z80 CTC
		;-------------------------------------------------------

		; Control word bits
ctc_ei		equ	0x80		; enable interrupts
ctc_counter	equ 	0x40		; counter mode
ctc_pre256	equ	0x20		; prescale by 256
ctc_rising	equ	0x10		; trigger on rising edge
ctc_trigger	equ	0x8		; start timer on trigger
ctc_tc		equ	0x4		; time constant
ctc_reset	equ	0x2		; software reset
ctc_ctrl	equ	0x1		; control word

		; Definitions for zero bits
		; (used just for code readability)
ctc_di		equ	0 		; disable interrupts
ctc_timer	equ 	0		; timer mode
ctc_pre16	equ	0		; prescale by 16
ctc_falling	equ	0		; trigger on falling edge
ctc_auto	equ	0		; start timer automatically
ctc_notc	equ	0		; no time constant

		; Default control word
ctc_default	equ 	ctc_di|ctc_counter|ctc_pre16|ctc_falling|ctc_trigger|ctc_notc|ctc_reset|ctc_ctrl

		; Port offsets for channels
ctc_ch0		equ 	ctc_port_base + 0	; assigned to tick counter
ctc_ch1		equ	ctc_ch0 + 1
ctc_ch2		equ	ctc_ch0 + 2
ctc_ch3		equ	ctc_ch0 + 3
ctc_ch4		equ	ctc_ch0 + 4
ctc_ch5		equ	ctc_ch0 + 5
ctc_ch6		equ	ctc_ch0 + 6
ctc_ch7		equ	ctc_ch0 + 7		; assigned to keyboard debounce
