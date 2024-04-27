#ifndef _MACHINE_H
#define _MACHINE_H

F_CPU_8		defl    7372800		; ~8 MHz clock
F_CPU_4		defl    3686400		; ~4 MHz clock
F_CPU_2		defl    1843200		; ~2 MHz clock

F_CPU		defl	F_CPU_8

BAUD_RATE	defl    115200


GPIO_PORT       defl    $0
ACIA_PORT	defl	$40

BASIC_START     defl    $2000
RAM_START       defl    $8000


		section CODE
		org     0

		section CODE_LOMEM

		section RODATA
		align   16
		section RODATA_END

		section CODE_USER
		align   16

                section CODE_BASIC
                org     BASIC_START

		section CODE_END

                section ACIA_BUFFER
                org     RAM_START
                section ACIA_BUFFER_END

		section DATA
		section DATA_END

		section BSS
		section BSS_END

#endif ; _MACHINE_H
        