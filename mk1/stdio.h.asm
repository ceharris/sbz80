#ifndef _STDIO_H
#define _STDIO_H

		include "machine.h.asm"
		include "ioctl.h.asm"

		global acia_ioctl
		global acia_getc
                global acia_getcnb
		global acia_putc
		global gets
		global puts
ioctl		defl acia_ioctl
getc		defl acia_getc
getcnb          defl acia_getcnb
putc		defl acia_putc

#endif ; _STDIO_H
