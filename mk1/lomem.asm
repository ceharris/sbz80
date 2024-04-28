		#include "machine.h.asm"
		#include "stdio.h.asm"

		section CODE_LOMEM
		extern init
		extern delay
		extern acia_getc
		extern acia_getcnb
		extern acia_flush
		extern acia_putc
		extern acia_isr

	;---------------------------------------------------------------
	; RST $0
	;
		call init		
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
		push hl			; save caller's HL
		ld hl,svc_table		; point to start of table
		add a,a			; 2 bytes per table entry
		add a,l			; add LSB of table
		ld l,a			; save table offset LSB
		jr nc,rst_28_10
		inc h			; carry into table offset MSB
rst_28_10:
		ld a,(hl)		; get LSB of entry point
		inc hl			
		ld h,(hl)		; get MSB of entry point
		ld l,a			; copy MSB of entry point
		ex (sp),hl		; swap with caller's HL on stack
		ret			; jump to entry point
		align 8

	;---------------------------------------------------------------
	; RST $30
	; PLEASE NOTE -- code for RST $28 overlaps with the space
	; allocated for RST $30, so the latter cannot be used.
	;

	;---------------------------------------------------------------
	; RST $38
		jp acia_isr
		align 8

	;---------------------------------------------------------------
	; Service Table
	; Each table entry points to a subroutine that is available to
	; user programs. To access a subroutine, specify the table entry
	; index and invoke RST $28.
	;
	; When adding table entries, add a definition to svc.h.asm as a
	; convenience.
	;
svc_table:
		dw acia_getc		; 0
		dw acia_getcnb		; 1
		dw gets			; 2
		dw acia_putc		; 3
		dw puts			; 4
		dw acia_flush		; 5
