		include "machine.h.asm"
		include "ioctl.h.asm"

		public init
		extern mmu_init
		extern acia_init
		extern acia_ioctl
		extern monitor
		extern delay

		section CODE_USER


init:
		di
		ld sp,$8000
		ld bc,500
		rst $20

		call mmu_init

		ld sp,WORKSPACE_TOP

                call acia_init
                ld c,IOCTL_COOKED|IOCTL_XON_XOFF|IOCTL_CRLF
                call acia_ioctl

                im 1
                ei

init_10:
                jp monitor
