RAM .equ $4000
ROMSZ		.equ $2000
MODE		.equ $01
MODREG		.equ $ff

ISRTAB		.equ $0100

CTC0		.equ $e0
CTC1		.equ $e1
CTC2		.equ $e2
CTC3		.equ $e3

CTCVEC		.equ 0
CTCCTL		.equ 10100101b
CTCTC		.equ 9

IOREG		.equ $f0
LEDBLINK	.equ $01		; blue LED will indicate we're alive
LEDSECS		.equ $02		; white LED will be used to blink 1 per second
LEDMASK		.equ LEDBLINK|$f0

CTCMULT		.equ 800

			.aseg
			.org 0

			ld hl,0
			ld de,RAM
			ld bc,ROMSZ
			ldir

			ld a,MODE
			out (MODREG),a

			ld a,LEDMASK
			ld (ledreg),a
			out (IOREG),a

			ld sp,0
			ld hl,ISRTAB
			ld a,h
			ld i,a
			im 2
			ei

			ld (hl),low(tick)
			inc hl
			ld (hl),high(tick)
			inc hl

			ld (hl),low(tick)
			inc hl
			ld (hl),high(tick)
			inc hl

			ld (hl),low(tick)
			inc hl
			ld (hl),high(tick)
			inc hl

			ld (hl),low(tick)
			inc hl
			ld (hl),high(tick)
			inc hl

			ld hl,CTCMULT
			ld (ctccnt),hl

			ld a,CTCVEC
			out (CTC0),a

			ld a,CTCCTL
			out (CTC1),a

			ld a,CTCTC
			out (CTC1),a

loop:
			ld de,$4000
delay:
			dec de
			ld a,e
			or d
			jr nz,delay

			ld a,(ledreg)
			xor LEDBLINK
			ld (ledreg),a
			out (IOREG),a

			jp loop

tick:
			push af
			push hl
			ei
			ld hl,(ctccnt)
			dec hl
			ld a,l
			or h
			jr nz,tick90

			ld a,(ledreg)
			xor LEDSECS
			ld (ledreg),a
			out (IOREG),a
			ld hl,CTCMULT
tick90:
			ld (ctccnt),hl
			pop hl
			pop af
			reti



ctccnt:		ds 2
ledreg:		ds 1

