	;---------------------------------------------------------------
	; Interrupt vector definitions
	;---------------------------------------------------------------

isr_ctc_ch0	equ 0		; timer tick (tk.asm)
isr_ctc_ch1	equ 1
isr_ctc_ch2	equ 2
isr_ctc_ch3	equ 3
isr_ctc_ch4	equ 4
isr_ctc_ch5	equ 5
isr_ctc_ch6	equ 6
isr_ctc_ch7	equ 7		; keyboard scan and debounce (ki.asm)

isr_pio_port_a	equ 8		; RTC alarm/periodic/power-fail interrupt
isr_pio_port_b	equ 9
