		name lomem

		extern init
		extern post
		extern rpeek
		extern vrst10
		extern vrst18
		extern vrst20
		extern vrst38

		include memory.asm

		aseg

	;--------------------------------------------------------------
	; RST 0 vector (system reset)
	;
		org 0x0
		jp post
noprst::	ret
nopisr::	ei
		reti

	;--------------------------------------------------------------
	; RST 0x08 vector (reserved)
	;
		org 0x8
		ret

	;--------------------------------------------------------------
	; RST 0x10 vector (user assignable)
	;
		org 0x10
		push hl
		ld hl,(vrst10)
		ex (sp),hl
		ret

	;--------------------------------------------------------------
	; RST 0x18 vector (user assignable)
	;
		org 0x18
		push hl
		ld hl,(vrst18)
		ex (sp),hl
		ret

	;--------------------------------------------------------------
	; RST 0x20 vector (user assignable)
	;
		org 0x20
		push hl
		ld hl,(vrst20)
		ex (sp),hl
		ret

        ;--------------------------------------------------------------
        ; RST 0x28 vector (supervisor call handler)
        ;
                org 0x28
                jr svc_dispatch

        ;--------------------------------------------------------------
        ; RST 0x30 vector (register peek)
        ;
                org 0x30
                jp rpeek

	;--------------------------------------------------------------
	; RST 0x38 vector (user assignable)
	;
		org 0x38
		push hl
		ld hl,(vrst38)
		ex (sp),hl
		ret

	;--------------------------------------------------------------
	; Supervisor call dispatch
	;
	; This routine dispatches to the supervisor function identified
	; by the A register.
	;
		org 0x40
svc_dispatch:
        	push hl			; save caller's HL
        	ld h,svc_page		; point to SVC function table page
		add a,a			; 2-bytes per entry
 		ld l,a			; now HL points at entry point address

		ld a,(hl)		; get entry point LSB
		inc hl
		ld h,(hl)		; get entry point MSB
		ld l,a			; now HL is entry point address

        	ex (sp),hl		; now (SP) is entry point address
					; and caller's HL is restored

        	ret			; jumps to entry point

	;--------------------------------------------------------------
	; NMI restart vector
	;
		org 0x66
		retn                            ; nothing to do

	;--------------------------------------------------------------
	; Supervisor call table
	; This must be aligned on a 256-byte page boundary
	;
        	org 0x100
svc_table:
svc_page	equ high(svc_table)		; page address of svc_table

		extern exit
_exit		dw exit
@exit		equ (_exit - svc_table)/2

		extern m16x8
_m16x8		dw m16x8
@m16x8		equ (_m16x8 - svc_table)/2

		extern d32x8
_d32x8		dw d32x8
@d32x8		equ (_d32x8 - svc_table)/2

		extern d3210
_d3210		dw d3210
@d3210		equ (_d3210 - svc_table)/2

		extern d32x16
_d32x16		dw d32x16
@d32x16		equ (_d32x16 - svc_table)/2

		extern d16x8
_d16x8		dw d16x8
@d16x8		equ (_d16x8 - svc_table)/2

		extern bnksel
_bnksel		dw bnksel
@bnksel		equ (_bnksel - svc_table)/2

		extern tkgets
_tkgets		dw tkgets
@tkgets		equ (_tkgets - svc_table)/2

		extern tkread
_tkread		dw tkread
@tkread		equ (_tkread - svc_table)/2

		extern tkrdms
_tkrdms		dw tkrdms
@tkrdms		equ (_tkrdms - svc_table)/2

		extern doclr
_doclr		dw doclr
@doclr		equ (_doclr - svc_table)/2

		extern dogoto
_dogoto		dw dogoto
@dogoto		equ (_dogoto - svc_table)/2

		extern dohome
_dohome		dw dohome
@dohome		equ (_dohome - svc_table)/2

		extern doinit
_doinit		dw doinit
@doinit	equ 	(_doinit - svc_table)/2

		extern doputc
_doputc		dw doputc
@doputc		equ (_doputc - svc_table)/2

		extern doputs
_doputs		dw doputs
@doputs		equ (_doputs - svc_table)/2

		extern dop10w
_dop10w		dw dop10w
@dop10w		equ (_dop10w - svc_table)/2

		extern kiptr
_kiptr		dw kiptr
@kiptr		equ (_kiptr - svc_table)/2

		extern kiread
_kiread		dw kiread
@kiread		equ (_kiread - svc_table)/2

		extern kiget
_kiget		dw kiget
@kiget		equ (_kiget - svc_table)/2

		extern hex16
_hex16		dw hex16
@hex16		equ (_hex16 - svc_table)/2

		extern hex8
_hex8		dw hex8
@hex8		equ (_hex8 - svc_table)/2

		extern rpcpy
_rpcpy		dw rpcpy
@rpcpy		equ (_rpcpy - svc_table)/2

		extern rtcset
_rtcset		dw rtcset
@rtcset		equ (_rtcset - svc_table)/2

		extern rtcget
_rtcget		dw rtcget
@rtcget		equ (_rtcget - svc_table)/2

		extern rtcpt
_rtcpt		dw rtcpt
@rtcpt		equ (_rtcpt - svc_table)/2

		extern rtcalm
_rtcalm		dw rtcalm
@rtcalm		equ (_rtcalm - svc_table)/2

		extern setisr
_setisr		dw setisr
@setisr		equ (_setisr - svc_table)/2

		extern setvec
_setvec		dw setvec
@setvec		equ (_setvec - svc_table)/2

		extern strcpy
_strcpy		dw strcpy
@strcpy		equ (_strcpy - svc_table)/2

		end
