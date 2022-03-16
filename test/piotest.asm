RAM			.equ $4000
ROMSZ		.equ $2000
MODE		.equ $01
MODREG		.equ $ff


IOREG		.equ $f0
LEDSTART	.equ $f2
LEDSTOP		.equ $f1
LEDNONE		.equ $f0

PDATA		.equ $d1
PCTRL		.equ $d3
PMODE		.equ $cf
PMASK		.equ 0


LCEN		.equ $10

LCDATA		.equ $20
LDRD		.equ $40


delay		macro cnt
			local loop
			ld de,cnt
loop:
			dec de
			ld a,e
			or d
			jp nz,loop
			endm

			.aseg
			.org 0

			ld hl,0
			ld de,RAM
			ld bc,ROMSZ
			ldir
			ld a,MODE
			out (MODREG),a

			ld sp,0

			ld b,1

start:
			ld a,LEDSTART|LEDSTOP
			out (IOREG),a
			ld a,LEDNONE
			out (IOREG),a
			djnz start

			ld a,PMODE
			out (PCTRL),a
			ld a,PMASK
			out (PCTRL),a

			ld a,LEDSTART
			out (IOREG),a

			xor a
			out (PDATA),a

			ld a,LEDSTOP
			out (IOREG),a

			ld a,$3
			call lcwr4
			delay $200
			call lcwr4
			delay $200
			call lcwr4
			delay $200
			ld a,$2
			call lcwr4

			ld a,LEDSTART
			out (IOREG),a

			ld c,$28
			call lccmd
			ld c,$0c
			call lccmd
			ld c,$6
			call lccmd

			call lccls
			call lchome

			ld hl,message
mloop:
			ld a,(hl)
			inc hl
			or a
			jp z,iloop
			ld c,a
			call lcch
			jp mloop

			ld a,LEDSTOP
			out (IOREG),a

iloop:
			jp iloop


lcwr4:
			and ~LCEN
			out (PDATA),a
			or LCEN
			out (PDATA),a
			nop
			and ~LCEN
			out (PDATA),a
			ret

lccls:
			ld c,$01
			call lccmd
			call lcwait
			ret

lchome:
			ld c,$02
			call lccmd
			call lcwait
			ret

lcwait:
			push de
			ld de,$400
lcwait10:
			dec de
			ld a,e
			or l
			jp nz,lcwait10
			pop de
			ret

lccmd:
			ld a,c
			rrca
			rrca
			rrca
			rrca
			and $0f
			out (PDATA),a
			or LCEN
			out (PDATA),a
			nop
			and ~LCEN
			out (PDATA),a
			nop
			ld a,c
			and $0f
			out (PDATA),a
			or LCEN
			out (PDATA),a
			nop
			and ~LCEN
			out (PDATA),a
			nop			
			ret

lcch:
			ld a,c
			rrca
			rrca
			rrca
			rrca
			and $0f
			or LCDATA
			out (PDATA),a
			or LCEN
			out (PDATA),a
			nop
			and ~LCEN
			out (PDATA),a
			nop
			ld a,c
			and $0f
			or LCDATA
			out (PDATA),a
			or LCEN
			out (PDATA),a
			nop
			and ~LCEN
			out (PDATA),a
			nop			
			ret
message:
			db "Hello there!",0


