#ifndef _MACHINE_H
#define _MACHINE_H

	defc F_CPU_8 = 7372800	; ~8 MHz clock
	defc F_CPU_4 = 3686400	; ~4 MHz clock
	defc F_CPU_2 = 1843200	; ~2 MHz clock

	defc F_CPU = F_CPU_8

	defc BAUD_RATE = 115200

	defc ACIA_PORT = $80
	defc MMU_PORT = $F0
	defc MMU_PAGE_PORT = MMU_PORT
	defc MMU_CTRL_PORT = MMU_PORT + 1

	defc MMUE = $08
	defc MMU_R0 = 0
	defc MMU_R1 = 1

	; MMU can map these ROM pages only in slots 0-3
	defc ROM_PAGE_MONITOR = ~0
	defc ROM_PAGE_BASIC = ~1
	defc ROM_PAGE_FORTH = ~2
	defc ROM_PAGE_OTHER = ~3

	; MMU can map these first four RAM pages only in slots 4-7
	defc RAM_PAGE_0 = ~0
	defc RAM_PAGE_1 = ~1
	defc RAM_PAGE_2 = ~2
	defc RAM_PAGE_3 = ~3

	; MMU can map these RAM pages into any slot
	defc RAM_PAGE_4 = ~4
	defc RAM_PAGE_5 = ~5
	defc RAM_PAGE_6 = ~6
	defc RAM_PAGE_7 = ~7
	defc RAM_PAGE_8 = ~8
	defc RAM_PAGE_9 = ~9
	defc RAM_PAGE_10 = ~10
	defc RAM_PAGE_11 = ~11
	defc RAM_PAGE_12 = ~12
	defc RAM_PAGE_13 = ~13
	defc RAM_PAGE_14 = ~14
	defc RAM_PAGE_15 = ~15
	
	defc RAM_PAGE_MONITOR = RAM_PAGE_4

	defc PAGE_SLOT_0 = 0 << 5
	defc PAGE_SLOT_1 = 1 << 5
	defc PAGE_SLOT_2 = 2 << 5
	defc PAGE_SLOT_3 = 3 << 5
	defc PAGE_SLOT_4 = 4 << 5
	defc PAGE_SLOT_5 = 5 << 5
	defc PAGE_SLOT_6 = 6 << 5
	defc PAGE_SLOT_7 = 7 << 5

	defc RAM_START = $2000

	
#endif ; _MACHINE_H
