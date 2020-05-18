		name demo

		include svc.asm
		include ports.asm

		cseg

demo::
		; initialize last keyboard scan
		ld hl,last_ki
		ld a,0xff
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl

		; initialize last seconds count
		xor a
		ld (last_secs),a

demo10:
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
		jr nz,kiscan10

		in a,(sys_cfg_port)
		and ~1
		out (sys_cfg_port),a
		ret

kiscan10:
		ld (hl),d
		dec hl
		ld (hl),e
		call tobin
		in a,(sys_cfg_port)
		or 1
		out (sys_cfg_port),a

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

tkscan:
		; get system elapsed time in milliseconds
		ld a,@tkrdms
		rst 0x28
		
		; divide by 1000 to get seconds
		ld bc,1000
		ld a,@d32x16
		rst 0x28
		
		; divide by 60 to get minutes (quotient) 
		; and seconds (remainder)
		ld c,60
		ld a,@d32x8
		rst 0x28

		; has the number of seconds changed?
		ld c,a				; save seconds
		ld a,(last_secs)		; load last
		cp c				
		ld a,c				; restore seconds
		ret z				; go back if no change

		ld (last_secs),a		; saves seconds for next time

		; blank buffer and null terminate
		ld b,16
		ld ix,et_buffer
tkscan_05:
		ld (ix),' '
		inc ix
		djnz tkscan_05
		ld (ix),0

		; convert seconds to decimal and add delimiter
		call tocunit
		dec ix
		ld (ix),':'	
			
		; divide by 60 to get hours (quotient) 
		; and minutes (remainder)
		ld c,60
		ld a,@d32x8
		rst 0x28

		; convert minutes to decimal and add delimiter
		call tocunit
		dec ix
		ld (ix),':'

		; divide by 24 to get days (quotient)
		; and hours (remainder)
		ld c,24			
		ld a,@d32x8
		rst 0x28

		; convert hours to decimal and add delimiter
		call tocunit
		dec ix
		ld (ix),' '
		dec ix
		ld (ix),'d'
		dec ix
		ld (ix),'0'
		jr tkscan_20

tkscan_10:
		ld a,@d16x8
		ld c,10
		rst 0x28
		add a,'0'
		dec ix
		ld (ix),a		

		; is the quotient still non-zero?
		ld a,h
		or l
		jr nz,tkscan_10
tkscan_20:
		; position cursor and write new value
		ld bc,0x0100
		ld a,@dogoto
		rst 0x28
		ld hl,et_buffer
		ld a,@doputs
		rst 0x28

		ret

tocunit:
		push hl

		; get pointer to digit pair to display
		rlca			; times two for two digits
		ld hl,chrono_lookup	; point to start of lookup table
		add a,l			
		ld l,a			; L = table entry LSB
		adc a,h
		sub l
		ld h,a			; H = table entry MSB

		inc hl			; second digit first
		dec ix
		ld a,(hl)
		ld (ix),a
		
		dec hl			; now first digit
		dec ix
		ld a,(hl)
		ld (ix),a

		pop hl
		ret

blanks		dc 	' ',16
		db	0

chrono_lookup	db '000102030405060708091011121314'
		db '151617181920212223242526272829'
		db '303132333435363738394041424344'
		db '454647484950515253545556575859'


		dseg
last_ki		ds 	2
last_secs	ds	1
et_buffer	ds	17

		end
