		include "machine.h.asm"
		include "ioctl.h.asm"

		public init
		extern acia_init
		extern acia_ioctl
		extern monitor
		extern delay

		section CODE_USER


init:
		di
		xor 0
		out (MMU_CTRL_PORT),a
		ld a,1				; ROM page 1, RAM page 0
		out (MMU_PAGE_PORT),a
		ld hl,0
		ld de,$8000
		ld bc,$4000
		ldir
		ld a,1
		out (MMU_CTRL_PORT),a
		ld a,$10			;RAM page 1 (ROM switched out)
		out (MMU_PAGE_PORT),a
		
		ld sp,WORKSPACE_TOP

                call acia_init
                ld c,IOCTL_COOKED|IOCTL_XON_XOFF|IOCTL_CRLF
                call acia_ioctl

                im 1
                ei

init_10:
                call monitor
                jp init
