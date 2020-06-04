		name demo

		include isr.asm
		include svc.asm
		include ports.asm
		include pio_defs.asm
		include ctc_defs.asm
		include rtc_defs.asm

		extern setrtc

		cseg


ksym_nul	equ	0
ksym_enter	equ	1
ksym_clear	equ	2
ksym_N		equ	'N'
ksym_Y		equ 	'Y'

		; keyboard symbol table for yes/no input
ktab_yn:	db ksym_enter, ksym_nul, ksym_N, ksym_Y, ksym_N
		db ksym_Y, ksym_N, ksym_Y, ksym_N, ksym_Y
		db ksym_enter, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul
		db ksym_nul, ksym_nul, ksym_nul, ksym_nul, ksym_nul

demo::
		call kiscan_init
		call tkscan_init
		call shrtc_init

		call demo_choice
		cp ksym_N
		jr z,demo10
		call setrtc

		ld a,@doclr
		rst 0x28
demo10:
		call shrtcl
		jr demo10

kiscan_init:
		; initialize last keyboard scan
		ld hl,0x0000
		ld (last_ki),hl
		ret

kiscan:
		ld a,@kiread
		rst 0x28
		ld de,last_ki
		ld a,(de)
		cp l
		jr nz,kiscan10
		inc de
		ld a,(de)
		cp h
		ret z
kiscan10:
		ld (last_ki),hl
		call tobin
		ret

tobin:
		ld bc,0
		ld a,@dogoto
		rst 0x28

		ld b,16
tobin10:
		sla l
		rl h
		ld c,'0'
		jr nc,tobin20
		inc c
tobin20:
		ld a,@doputc
		rst 0x28
		djnz tobin10
		ret

tkscan_init:
		; initialize et_last
		xor a
		ld (et_last+et_length-1),a
		ret

tkscan:
		ld hl,et_now
		ld a,@tkgets
		rst 0x28
tkscan05:
		ld hl,et_now+et_length-1
		ld de,et_last+et_length-1
		ld bc,et_length
tkscan10:
		ld a,(de)
		cpd
		dec de
		ret po
		jr z,tkscan10

		; copy et_now to et_last
		ld hl,et_now
		ld de,et_last
		ld bc,et_length
		ldir

		; display new elapsed time
tkscan90:
		ld bc,0x0100
		ld a,@dogoto
		rst 0x28

		ld hl,et_now
		ld a,@doputs
		rst 0x28

		ld bc,0x4000
tkscan95:
		dec bc
		ld a,b
		or c
		jr nz,tkscan95

		ret

shrtc_init:
		ld hl,rtc_last
		ld de,rtc_last+1
		ld bc,2*rtc_length-1
		ld (hl),0
		ldir
		ret

shrtcl:
		ld hl,rtc_now
		ld c,1
		ld a,@rtcgta
		rst 0x28

		ld hl,rtc_now+rtc_length-1
		ld de,rtc_last+rtc_length-1
		ld bc,rtc_length
shrtcl_compare:
		ld a,(de)
		cpd
		dec de
		ret po
		jr z,shrtcl_compare

		; copy rtc_now to rtc_last
		ld hl,rtc_now
		ld de,rtc_last
		ld bc,rtc_length
		ldir

		; display new time and date
		ld bc,0
		ld a,@dogoto
		rst 0x28

		ld hl,rtc_now
		ld a,@doputs
		rst 0x28

		ld bc,0x0104
		ld a,@dogoto
		rst 0x28

		inc hl
		ld a,@doputs
		rst 0x28

		ld bc,0x0110
		ld a,@dogoto
		rst 0x28

		ret

rtc_handler:
		ret

demo_choice:
		ld hl,ktab_yn
		ld a,@kistab
		rst 0x28

		ld bc,0
		ld a,@dogoto
		rst 0x28

		ld hl,prompt
		ld a,@doputs
		rst 0x28

demo_choice_again:
		ld bc,0x0a
		ld a,@dogoto
		rst 0x28

demo_choice_wait:
		ld a,@kiget
		rst 0x28
		jr z,demo_choice_wait

		cp ksym_enter
		jr z,demo_choice_commit

		cp ksym_clear
		jr z,demo_choice_clear

		ld (choice),a

		ld a,(choice)
		ld c,a
		ld a,@doputc
		rst 0x28

		jr demo_choice_again

demo_choice_clear:
		xor a
		ld (choice),a
		ld c,' '
		ld a,@doputc
		rst 0x28
		jr demo_choice_again

demo_choice_commit:
		ld a,(choice)
		or a
		jr z,demo_choice_wait

		ld a,@doclr
		rst 0x28

		ld a,(choice)
		ret


prompt		db 'Set RTC?',0

		dseg
choice		ds	1
last_ki		ds 	2

ksym_length	equ	16
ksym_buf	ds	32

et_length	equ	16

et_last		ds	et_length
et_now		ds 	et_length+1

rtc_length	equ	32

rtc_last	ds 	rtc_length
rtc_now		ds	rtc_length+1
