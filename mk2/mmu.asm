
		include "machine.h.asm"
		
		public mmu_init
		public jp_rom

		section CODE_USER

MMU_RAM_EN0	equ	1 << 0			; enable RAM from 0000..1fff
MMU_RAM_EN1	equ	1 << 1			; enable RAM from 2000..3fff

MMU_ROM_PAGE0	equ	0
MMU_RAM_BANK0	equ	$10

	;---------------------------------------------------------------
	; mmu_init:
	; Initializes the MMU. Before calling this function, the stack
	; MUST be located between in the range 4000..7FFF.
	;
	;   1. Selects RAM bank 0 for upper memory (8000..FFFF).
	;   2. Copies memory segment 0000..1FFF (lower ROM) to 
	;      RAM at 8000..9FFF.
	;   3. Makes RAM bank 0 visible in lower memory from 
	;      0000..1FFF.
	;   4. Selects RAM bank 1 for upper memory (8000..FFFF).
	;   5. Selects upper ROM page 0 for 2000..3FFF.
	;
mmu_init:
		; select lower ROM, put RAM bank 0 in upper memory
		xor a
		out (MMU_PAGE_PORT),a
		out (MMU_CTRL_PORT),a

		; copy lower ROM image into RAM
		ld hl,0
		ld de,$8000
		ld bc,$2000
		ldir

		; make RAM bank 0 visible from 0000..1FFF
		ld a,MMU_RAM_EN0
		ld (mmu_ctrl_reg),a
		out (MMU_CTRL_PORT),a

		; NOTE: at this point we're executing in RAM

		; select upper RAM page 0 and RAM bank 1
		ld a,MMU_RAM_BANK0 | MMU_ROM_PAGE0
		ld (mmu_page_reg),a
		out (MMU_PAGE_PORT),a
		ret

jp_rom:
		ld a,c			; get ROM page number 0..15
		and $f			; only want ROM page bits
		ld c,a
		ld a,(mmu_page_reg)
		or c
		ld (mmu_page_reg),a
		out (MMU_PAGE_PORT),a
		jp (hl)



		section WORKSPACE_DATA
mmu_ctrl_reg:	ds 1
mmu_page_reg:	ds 1

