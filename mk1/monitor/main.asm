	include "../machine.h.asm"
	include "workspace.h.asm"

	include "../../include/acia.h.asm"
	include "../../include/delay.h.asm"
	include "../../include/monitor.h.asm"


	; TODO -- is there a symbol we could use to calculate this?
	defc MONITOR_SIZE = $2000

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
	ret
	align 8

;---------------------------------------------------------------
; RST $38
;
	jp acia_isr
	align 8

init:
	di

	; initialize the MMU
	ld hl,pagemap			; HL -> page map
	ld c,MMU_PAGE_PORT
	ld b,0				; B7..5 will provide A2..0 to the 74189
load_pagemap:
	ld a,(hl)  			; get page number from map
	inc hl				; next map entry
	out (c),a			; write entry in page register
	ld a,b				; get 74189 address bits
	add a,$20			; increment 3 top-most bits
	ld b,a				; B = new 74189 address bits
	jr nc,load_pagemap		; go until all entries written
	ld a,MMUE
	out (MMU_CTRL_PORT),a		; enable MMU

	; copy monitor image into start of RAM
	; which is mapped to RAM_PAGE_MONITOR at this point
	ld hl,0
	ld de,RAM_START
	ld bc,MONITOR_SIZE
	ldir

	; put RAM_PAGE_MONITOR at $0000..1FFFF (page slot 0)
	ld b,PAGE_SLOT_0
	ld c,MMU_PAGE_PORT
	ld a,RAM_PAGE_MONITOR
	out (c),a
	
	; put in RAM page 9 at $2000..3FFF (page slot 1)
	ld b,PAGE_SLOT_1
	ld c,MMU_PAGE_PORT
	ld a,RAM_PAGE_9
	out (c),a
	
	ld sp,WORKSPACE_TOP

	call    acia_init
	im      1
	ei

	jp monitor

pagemap:
	db ROM_PAGE_MONITOR,RAM_PAGE_MONITOR,RAM_PAGE_10,RAM_PAGE_11
	db RAM_PAGE_12,RAM_PAGE_13,RAM_PAGE_14,RAM_PAGE_15



	