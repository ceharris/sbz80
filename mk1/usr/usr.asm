deintp	defl $200d
abpassp defl $200f

	org $fc00

	ld hl,(deintp)
	ld (deint+1),hl
	ld hl,(abpassp)
	ld (abpass+1),hl

	call deint
	ld l,e
	ld h,d
	add hl,hl
	add hl,hl
	add hl,de
	ld b,l
	ld a,h
	jp abpass

deint:
	db 0xc3
	ds 2

abpass:
	db 0xc3
	ds 2
