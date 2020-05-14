;-----------------------------
; Definitions for the Z80 CTC
;-----------------------------

; Control word bits
ctc_ei		equ	0x80		; enable interrupts
ctc_counter	equ 	0x40		; counter mode
ctc_timer	equ 	0		; timer mode
ctc_pre256	equ	0x20		; prescale by 256
ctc_pre16	equ	0		; prescale by 16
ctc_rising	equ	0x10		; trigger on rising edge
ctc_falling	equ	0		; trigger on falling edge
ctc_trigger	equ	0x8		; start timer on trigger
ctc_auto	equ	0		; start timer automatically
ctc_tc		equ	0x4		; time constant
ctc_reset	equ	0x2		; software reset
ctc_ctrl	equ	0x1		; control word

; Port offsets for channels
ctc_ch0		equ 	ctc_port_base + 0	
ctc_ch1		equ	ctc_ch0 + 1
ctc_ch2		equ	ctc_ch0 + 2
ctc_ch3		equ	ctc_ch0 + 3
