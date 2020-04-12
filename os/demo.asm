		name demo
		include svc.asm

rbuf_addr	equ 0x4000
cbuf_addr	equ rbuf_addr + 32

		cseg
demo::
		ld a,@doinit
		rst 0x28

		rst 0x30
		ld hl,rbuf_addr
		ld a,@rpcpy
		rst 0x28
		
		; copy template to character buffer
		ld hl,gpregs1
		ld de,cbuf_addr
		ld a,@strcpy
		rst 0x28

		; convert stored AF to hex
		ld bc,(rbuf_addr+0)
		ld hl,cbuf_addr+3
		ld a,@hex16
		rst 0x28

		; convert stored BC to hex
		ld bc,(rbuf_addr+2)
		ld hl,cbuf_addr+11
		ld a,@hex16
		rst 0x28
		
		; display registers in buffer on line 1
		ld a,@doclr
		rst 0x28
		ld bc,0
		ld a,@dogoto
		rst 0x28
		ld hl,cbuf_addr
		ld a,@doputs
		rst 0x28

		; copy template to character buffer
		ld hl,gpregs2
		ld de,cbuf_addr
		ld a,@strcpy
		rst 0x28

		; convert stored DE to hex
		ld bc,(rbuf_addr+4)
		ld hl,cbuf_addr+3
		ld a,@hex16
		rst 0x28

		; convert stored HL to hex
		ld bc,(rbuf_addr+6)
		ld hl,cbuf_addr+11
		ld a,@hex16
		rst 0x28
		
		; display registers in buffer on line 2
		ld bc,0x0100
		ld a,@dogoto
		rst 0x28
		ld hl,cbuf_addr
		ld a,@doputs
		rst 0x28

		; copy template to character buffer
		ld hl,agpregs1
		ld de,cbuf_addr
		ld a,@strcpy
		rst 0x28

		; convert stored AF' to hex
		ld bc,(rbuf_addr+8)
		ld hl,cbuf_addr+4
		ld a,@hex16
		rst 0x28

		; convert stored BC' to hex
		ld bc,(rbuf_addr+10)
		ld hl,cbuf_addr+12
		ld a,@hex16
		rst 0x28

		call delay
		
		; display registers in buffer on line 1
		ld a,@doclr
		rst 0x28
		ld bc,0
		ld a,@dogoto
		rst 0x28
		ld hl,cbuf_addr
		ld a,@doputs
		rst 0x28

		; copy template to character buffer
		ld hl,agpregs2
		ld de,cbuf_addr
		ld a,@strcpy
		rst 0x28

		; convert stored DE' to hex
		ld bc,(rbuf_addr+12)
		ld hl,cbuf_addr+4
		ld a,@hex16
		rst 0x28

		; convert stored HL' to hex
		ld bc,(rbuf_addr+14)
		ld hl,cbuf_addr+12
		ld a,@hex16
		rst 0x28
		
		; display registers in buffer on line 2
		ld bc,0x0100
		ld a,@dogoto
		rst 0x28
		ld hl,cbuf_addr
		ld a,@doputs
		rst 0x28

		; copy template to character buffer
		ld hl,ixregs
		ld de,cbuf_addr
		ld a,@strcpy
		rst 0x28

		; convert stored IX to hex
		ld bc,(rbuf_addr+16)
		ld hl,cbuf_addr+3
		ld a,@hex16
		rst 0x28

		; convert stored IY to hex
		ld bc,(rbuf_addr+18)
		ld hl,cbuf_addr+11
		ld a,@hex16
		rst 0x28
		
		call delay

		; display registers in buffer on line 1
		ld a,@doclr
		rst 0x28
		ld bc,0
		ld a,@dogoto
		rst 0x28
		ld hl,cbuf_addr
		ld a,@doputs
		rst 0x28

		; copy template to character buffer
		ld hl,mregs1
		ld de,cbuf_addr
		ld a,@strcpy
		rst 0x28

		; convert stored SP to hex
		ld bc,(rbuf_addr+22)
		ld hl,cbuf_addr+3
		ld a,@hex16
		rst 0x28

		; convert stored PC to hex
		ld bc,(rbuf_addr+24)
		ld hl,cbuf_addr+11
		ld a,@hex16
		rst 0x28
		
		; display registers in buffer on line 2
		ld bc,0x0100
		ld a,@dogoto
		rst 0x28
		ld hl,cbuf_addr
		ld a,@doputs
		rst 0x28

		call delay

		ret

delay:
		ld hl,16384
delay10:
		ld b,l
delay20:
		djnz delay20
		dec h
		ret z
		jr delay10
	

gpregs1		db "AF=xxxx BC=xxxx",0
gpregs2		db "DE=xxxx HL=xxxx",0
agpregs1	db "AF'=xxxx BC'=xxxx",0
agpregs2	db "DE'=xxxx HL'=xxxx",0
ixregs		db "IX=xxxx IY=xxxx",0
mregs1		db "SP=xxxx PC=xxxx",0
mregs2		db "I=XX R=XX",0

		end
