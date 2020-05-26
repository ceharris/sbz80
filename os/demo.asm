		name demo

		include isr.asm
		include svc.asm
		include ports.asm
		include pio_defs.asm
		include ctc_defs.asm
		include rtc_defs.asm

		cseg

rtc_data	db '202005252170000',0

demo::
;		ld hl,rtc_data
;		ld a,@rtcset
;		rst 0x28

;		ld a,rtc_alm_m
;		ld b,a
;		ld c,a
;		ld d,a
;		ld e,0x10
;		ld hl,rtc_handler
;		ld a,@rtcalm
;		rst 0x28

		; initialize last keyboard scan
		ld hl,0x0000
		ld (last_ki),hl

		; initialize et_last
		xor a
		ld (et_last+et_length-1),a
demo10:
		call kiscan
		call tkscan
		jr demo10

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

shrtc:
		ld hl,rtc_buffer
		ld c,0
		ld a,@rtcget
		rst 0x28

		ld bc,0x0100
		ld a,@dogoto
		rst 0x28

		ld a,@doputs
		rst 0x28

		ld bc,0x0110
		ld a,@dogoto
		rst 0x28

		ld bc,0x4000
shrtc10:
		dec bc
		ld a,b
		or c
		jr nz,shrtc10

		ret

shrtcl:
		ld hl,rtc_buffer
		ld c,1
		ld a,@rtcget
		rst 0x28

		ld bc,0x000
		ld a,@dogoto
		rst 0x28

		ld a,@doputs
		rst 0x28

		ld bc,0x0100
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

		dseg
last_ki		ds 	2

et_length	equ	16

et_last		ds	et_length
et_now		ds 	et_length+1

rtc_buffer	ds	32
		end
