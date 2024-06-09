	include "machine.h.asm"
	include "workspace.h.asm"

	include "../../include/acia.h.asm"
	include "../../include/delay.h.asm"
	include "../../include/msbasic.h.asm"
	include "../../include/romjump.h.asm"

	org 0
;---------------------------------------------------------------
; RST $0
;
	jp init		
	align 8

;---------------------------------------------------------------
; RST $8
;
	jp acia_putc
	align 8

;---------------------------------------------------------------
; RST $10
;
	jp acia_getc
	align 8

;---------------------------------------------------------------
; RST $18
;
	jp acia_getcnb
	align 8

;---------------------------------------------------------------
; RST $20
;
	jp delay
	align 8

;---------------------------------------------------------------
; RST $28
;
	ret
	align 8

;---------------------------------------------------------------
; RST $30
;
	jp jp_rom_monitor
	align 8
;---------------------------------------------------------------
; RST $38
	jp acia_isr
	align 8

init:
	di
	ld sp,0
	call acia_init
	im 1
	ei
	jp basic_cold_start
