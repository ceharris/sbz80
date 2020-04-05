		name demo
		include svc.asm

rbuf_addr	equ 0x4000
cbuf_addr	equ rbuf_addr + 32

		cseg
demo::
		ld a,@doinit
		rst 0x28
		ld a,@doclr
		rst 0x28
		ld a,@dohome
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

		ld a,@exit
		rst 0x28

gpregs1		db "AF=xxxx BC=xxxx",0
gpregs2		db "DE=xxxx HL=xxxx",0

ixregs		db "IX=xxxx IY=xxxx",0
mregs		db "SP=xxxx PC=xxxx",0

		end
