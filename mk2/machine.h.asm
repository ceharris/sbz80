#ifndef _MACHINE_H
#define _MACHINE_H

F_CPU_8		equ 7372800		; ~8 MHz clock
F_CPU_4		equ 3686400		; ~4 MHz clock
F_CPU_2		equ 1843200		; ~2 MHz clock

F_CPU		equ F_CPU_8

ACIA_PORT	equ $80
I2C_PORT	equ $90
GPIO_PORT	equ $D0
MMU_CTRL_PORT	equ $E0
MMU_PAGE_PORT	equ $F0

ROM_PG_MONITOR	equ 0
ROM_PG_BASIC	equ 1

WORKSPACE_TOP	equ $2000
WORKSPACE_SIZE	equ 512
;WORKSPACE_TOP	equ $8000
WORKSPACE_START equ WORKSPACE_TOP - WORKSPACE_SIZE

RAM_START       equ $4000



		section CODE
		org     0

		section CODE_LOMEM
		section RODATA
		section CODE_USER

                section WORKSPACE
                org     WORKSPACE_START
		section WORKSPACE_ACIA
		section WORKSPACE_DATA
		section WORKSPACE_END

                section PAGE1
		section CODE_MONITOR
                org     WORKSPACE_TOP
		section CODE_BASIC
		org	WORKSPACE_TOP
		section CODE_END

		section BSS
		org	RAM_START
		section BSS_END

#endif ; _MACHINE_H
        