
	include "machine.h.asm"
	include "../include/romjump.h.asm"

;----------------------------------------------------------------------
; jp_rom_monitor:
; Restarts the machine in the monitor program.
; Does not return.
;
jp_rom_monitor:
	ld a,ROM_PAGE_MONITOR
	jr relocate

;----------------------------------------------------------------------
; jp_rom_basic:
; Restarts the machine in the BASIC interpreter.
; Does not return.
;
jp_rom_basic:
	ld a,ROM_PAGE_BASIC
	jr relocate

;----------------------------------------------------------------------
; jp_rom_basic:
; Restarts the machine in the BASIC interpreter.
; Does not return.
;
jp_rom_forth:
	ld a,ROM_PAGE_FORTH
	jr relocate

jp_rom_other:
	ld a,ROM_PAGE_OTHER

relocate:
	di
	ld hl,swap_rom
	ld de,RAM_START
	ld bc,SWAP_ROM_SIZE
	ldir
	jp RAM_START


;----------------------------------------------------------------------
; swap_rom:
; A relocatable procedure that swaps in ROM page at $0000..1FFF and
; transfers control to it.
;
; On entry:
;	A = ROM page number (complement of 0..3) to map into $0000..1FFF
;
; Does not return.
;
swap_rom:
	ld c,MMU_PAGE_PORT
	ld b,PAGE_SLOT_0
	out (c),a
	jp 0

	defc SWAP_ROM_SIZE = $ - swap_rom
