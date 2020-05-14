		name demo

		include svc.asm

		cseg

demo::
		; initialize last keyboard scan
		ld hl,last_ki
		ld a,0xff
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl

		; initialize last tick count
		inc a
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
demo10:
		call kiscan
		call tkscan
		jr demo10

kiscan:
		ld a,@kiread
		rst 0x28
		ld e,l
		ld d,h
		ld hl,last_ki
		ld a,e
		cp (hl)
		jr nz,kiscan10
		ld a,d
		inc hl
		cp (hl)
		ret z
kiscan10:
		ld (hl),d
		dec hl
		ld (hl),e
		call tobin
		ret		
		
tobin:
		ld bc,0
		ld a,@dogoto
		rst 0x28

		ld b,16
tobin10:
		sla e
		rl d
		ld c,'0'
		jr nc,tobin20
		inc c
tobin20:
		ld a,@doputc
		rst 0x28
		djnz tobin10
		ret

ticks_per_sec	equ 10000

tkscan:
		ld a,@tkread
		rst 0x28

		; divide by 10,000 to get number of seconds
		ld a,@d3210
		rst 0x28
		ld a,@d3210
		rst 0x28
		ld a,@d3210
		rst 0x28
		ld a,@d3210
		rst 0x28

		; get number of seconds into BCDE
		ld c,e
		ld b,d
		ld e,l
		ld d,h

		; save current count
		ld hl,this_tc
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld (hl),c
		inc hl
		ld (hl),b

		; compute the difference
		ld bc,this_tc
		ld de,diff_tc
		ld hl,last_tc
		ld a,(bc)			; byte 0 of this
		inc bc			
		sub (hl)			; minus byte 0 of last
		inc hl
		ld (de),a			; store byte 0 of diff
		inc de
		ld a,(bc)			; byte 1 of this
		inc bc
		sbc (hl)			; minus byte 1 of last
		inc hl
		ld (de),a			; store byte 1 of diff
		inc de
		ld a,(bc)			; byte 2 of this
		inc bc
		sbc (hl)			; minus byte 2 of last
		inc hl
		ld (de),a			; store byte 2 of diff
		inc de
		ld a,(bc)			; byte 3 of this
		inc bc
		sbc (hl)			; minus byte 3 of last
		inc hl
		ld (de),a			; store byte 3 of diff
		inc de

		; store this count as last count
		ld bc,this_tc
		ld hl,last_tc
		ld a,(bc)			; byte 0 of this
		inc bc
		ld (hl),a			; store as byte 0 of last
		inc hl
		ld a,(bc)			; byte 1 of this
		inc bc
		ld (hl),a			; store as byte 1 of last
		inc hl
		ld a,(bc)			; byte 2 of this
		inc bc
		ld (hl),a			; store as byte 2 of last
		inc hl
		ld a,(bc)			; byte 3 of this
		inc bc
		ld (hl),a			; store as byte 3 of last
		inc hl

		; is the difference at least one second
		ld hl,diff_tc
		ld a,(hl)
		inc hl
		or a
		jr nz,tkscan10
		
		ld a,(hl)
		inc hl
		or a
		jr nz,tkscan10		

		ld a,(hl)
		inc hl
		or a
		jr nz,tkscan10		

		ld a,(hl)
		inc hl
		or a
		ret z

tkscan10:		
		ld bc,0x0100
		ld a,@dogoto
		rst 0x28

		ld hl,blanks
		ld a,@doputs
		rst 0x28		

		ld bc,0x0100
		ld a,@dogoto
		rst 0x28

		ld hl,this_tc
		ld (hl),c
		inc hl
		ld (hl),b
		inc hl
		ld (hl),e
		inc hl
		ld (hl),d
		ld l,c
		ld h,b

		; display the current tick count
		ld hl,this_tc
		ld a,@dop10w
		rst 0x28

		ret


blanks		dc 	' ',16
		db	0

		dseg
last_ki		ds 	2
last_tc		ds 	4
this_tc		ds 	4
diff_tc		ds 	4

		end
