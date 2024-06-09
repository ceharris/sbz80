deintp	defl $200d
abpassp defl $200f

	org $fc00

	ld hl,(deintp)
	ld (deint+1),hl
	ld hl,(abpassp)
	ld (abpass+1),hl

	call deint
	ld c,e
	ld b,d
	rst $20
	ld a,5
	rst $28
	ld a,0
	ld b,a
	jp abpass

deint:
	db 0xc3
	ds 2

abpass:
	db 0xc3
	ds 2
