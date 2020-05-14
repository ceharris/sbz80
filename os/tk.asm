
		name tk
		extern setisr
		extern tkcnt
		extern syscfg

		include ports.asm
		include isr.asm
		include ctc.asm

		cseg

	;---------------------------------------------------------------
	; tkinit:
	; Initializes the tick counter.
	
tkinit::
		; set the 40-bit counter to zero
                xor a
                ld hl,tkcnt
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a
                inc hl
                ld (hl),a

		; put the ISR address into the mode 2 interrupt vector table
		ld hl,tkinc			; address of the ISR
		ld c,isr_ctc_ch0		; interupt vector number
		call setisr			; set vector in table
		
ctc_ch0_config  equ ctc_ei|ctc_timer|ctc_pre16|ctc_tc|ctc_reset|ctc_ctrl
ctc_ch0_tc	equ 25

                ; program channel 0 on the CTC
                ld a,ctc_ch0_config
                out (ctc_ch0),a
	
		; get system config flags
		ld a,(syscfg)
		and 0x3				; just the clock speed bits
		cp 3
		ld a,ctc_ch0_tc			; load default time constant
		
		jr nz,tkinit10
		rlca 				; double TC for 8 MHz clock
tkinit10:
		out (ctc_ch0),a			; set TC for channel 0

		ret

	;---------------------------------------------------------------
	; tkinc:
	; Increments the tick counter. This routine is the interrupt
	; service routine for CTC channel 0 (which is interrupt vector 0)

tkinc::
                push af
                push hl

                ld hl,tkcnt                     ; point to byte 0
                inc (hl)                        ; increment it
                jr nz,tkinc10                   ; go if didn't wrap
                inc hl                          ; point to byte 1
                inc (hl)                        ; increment it
                jr nz,tkinc10                   ; go if didn't wrap
                inc hl                          ; point to byte 2
                inc (hl)                        ; increment it
                jr nz,tkinc10                   ; go if didn't wrap
                inc hl                          ; point to byte 3
                inc (hl)                        ; increment it
                jr nz,tkinc10                   ; go if didn't wrap
                inc hl                          ; point to byte 4
                inc (hl)                        ; increment it
tkinc10:
                pop hl
                pop af
		ei
                reti

	;---------------------------------------------------------------
	; SVC: tkread
	; Read the current value of the tick counter.
	; 
	; On return:
	; 	tick counter returned as a 40-bit value in ADEHL
	
tkread::
		push bc
		ld hl,tkcnt+4
		di
		ld a,(hl)
		dec hl
		ld d,(hl)
		dec hl
		ld e,(hl)
		dec hl
		ld b,(hl)
		dec hl
		ld c,(hl)
		ei
		ld l,c
		ld h,b
		pop bc
		ret		
		
		end
