		name setvec
default_vec	equ 0x8

	;--------------------------------------------------------------
	; inivec:
	; Initializes the user-programmable restart vectors
		cseg
inivec::
		ld hl,default_vec
		ld (vrst10),hl
		ld (vrst18),hl
		ld (vrst20),hl
		ld (vrst38),hl
		ret
		
	;--------------------------------------------------------------
	; SVC: setvec
	; Sets a restart vector. Restart vectors 0x10, 0x18, 0x20,
	; and 0x38 are user configurable. Attempts to set other vectors
	; are ignored and NZ status is returned.
	;
	; On entry:
	; 	C = restart vector to set (0x10, 0x18, 0x20, or 0x38)
	;	HL = handler address
	;	Z if the specified restart vector was set
		
		cseg
setvec::
		ld a,c			; get selected vector
		cp 0x10
		jr nz,setvec18		; go if not RST 0x10
		ld (vrst10),hl	; store vector
		ret
setvec18:
		cp 0x18			
		jr nz,setvec20		; go if not RST 0x18
		ld (vrst18),hl	; store vector
		ret
setvec20:
		cp 0x20
		jr nz,setvec38		; go if not RST 0x20
		ld (vrst20),hl	; store vector
		ret
setvec38:
		cp 0x38		
		ret nz			; return NZ if not RST 0x38
		ld (vrst38),hl	; store vector
		ret

		dseg
vars:
vrst10::     ds 	2		; RST 10 vector
vrst18::     ds 	2		; RST 18 vector
vrst20::     ds 	2		; RST 20 vector
vrst38::     ds 	2		; RST 38 vector
align		ds	(align-vars)%2	; pad for alignment

		end
