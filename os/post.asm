		name post
		include memory.asm
		include ports.asm

		extern init
		extern pioini
		extern doinit
		extern dohome
		extern dogoto
		extern doputs
		extern hex8
		extern hex16

mem_pattern	equ	0x55

smem_size	equ	umem_start - smem_start

	;--------------------------------------------------------------
	; Power-on Self Tests
	; This routine runs tests on memory and various other subsystems.
	;
		cseg
post::
		; initialize system configuration register
		; need this to ensure upper bank zero is selected
		xor a
		out (sys_cfg_port),a

		; note: use of stack assumes memory is viable
		ld sp,umem_start - buflen
		call pioini
		call doinit

		ld ix,0				; zero test count
		ld iy,0				; zero fail count

post_again:
		; fill memory with pattern
		ld hl,ram_post_start
		ld bc,ram_post_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),mem_pattern
                ldir

		; test that memory contains the pattern
                ld hl,ram_post_start
		ld bc,ram_post_size
		ld a,mem_pattern
post_mem10:
                cpi
		ld e,a				; pattern we were testing
		jp nz,post_fail
		jp pe,post_mem10

		; fill memory with pattern complement
                ld hl,ram_post_start
		ld bc,ram_post_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),~mem_pattern
                ldir

		; test that memory contains the pattern complement
                ld hl,ram_post_start
		ld bc,ram_post_size
		ld a,~mem_pattern
post_mem20:
                cpi
		ld e,a				; pattern we were testing
		jp nz,post_fail
                jp pe,post_mem20

		; fill memory with values that correspond to address LSB
                ld hl,ram_post_start
		ld bc,ram_post_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),0
post_mem30:
                ldi
		jp po,post_mem40
		inc (hl)
		jr post_mem30
post_mem40:
		inc (hl)

		; test that memory contains expected address LSBs
                ld hl,ram_post_start
		ld bc,ram_post_size
post_mem50:
		ld a,l
                cpi
		ld e,0xff			; indicate correlation test
		ld d,a				; correlation bits that failed
		jp nz,post_fail
		jp po,post_ok
		jr post_mem50

		; post passed
post_ok:
		inc ix				; increment total count

		; have we already had a failure?
		push iy
		pop hl
		ld a,l
		or h
		jp nz,post_counts		; just show the updated counts

		call dohome			; home cursor
		ld hl,okmsg
		call doputs			; display ok message
		jp post_counts

		; post failed
		; E = test id; pattern, complement, or 0xff for correlation
		; D = correlation pattern when E = 0xff
		; HL = address of failure + 1

post_fail:
		dec hl				; actual address of failure
		push hl				; save it

		ld a,e				; get test id
		cp mem_pattern
		jr nz,post_fail10
		ld a,(hl)			; get byte at failure address
		ld hl,patmsg
		jr post_fail30
post_fail10:
		cp ~mem_pattern
		ld a,(hl)			; get byte at failure address
		jr nz,post_fail20
		ld hl,cmpmsg
		jr post_fail30
post_fail20:
		ld hl,cormsg
post_fail30:
		ld de,umem_start - buflen
		ld bc,buflen
		ldir				; copy template to buffer

		ld e,a				; save byte at failure address
		ld c,a				; get pattern byte
		ld hl,umem_start - buflen + addrbuf
		pop bc				; get address of failure
		call hex16			; convert address to hex
		inc hl				; skip ':' delimiter
		ld c,e				; get byte at failure address
		call hex8			; convert to hex in buffer

		call dohome			; home cursor
		ld hl,umem_start - buflen
		call doputs			; write buffer to display
		inc ix				; increment test count
		inc iy				; increment fail count

post_counts:
		ld hl,cntmsg			; point to counts template
		ld de,umem_start - buflen
		ld bc,buflen
		ldir				; copy template to buffer

		ld hl,umem_start - buflen + totbuf
		push ix				; transfer total count
		pop bc
		call hex16			; convert to hex in buffer

		; skip delimiting text
		inc hl
		inc hl
		inc hl

		push iy				; transfer fail count
		pop bc
		call hex16			; convert to hex in buffer

		ld b,1
		ld c,0
		call dogoto			; position cursor at 0,1

		ld hl,umem_start - buflen
		call doputs			; display counts

		; check number of passes and exit to init if finished
		push ix
		pop hl
		ld a,l
		cp num_passes
		jp nz,post_again		; do next pass

		in a,(sys_cfg_port)		; get bank bits
		rlca				; convert to
		rlca				;   bank number
		inc a				; next bank
		cp 3
		jr nc,post_done			; no more banks
		rrca				; convert to
		rrca				;   selection bits
		out (sys_cfg_port),a
		ld ix,0				; zero pass count
		jp post_again			; test next bank

post_done:
		xor a
		out (sys_cfg_port),a		; select bank zero

		; zero out all writable memory
                ld hl,ram_post_start
                ld bc,ram_post_size-1
                ld e,l
                ld d,h
                inc de
                ld (hl),0
                ldir

		jp init

num_passes	equ 2
buflen		equ 24
addrbuf		equ 9
totbuf		equ 2

okmsg		db "ok",0
patmsg		db "err: pat=xxxx:xx",0
cmpmsg		db "err: cmp=xxxx:xx",0
cormsg		db "err: cor=xxxx:xx",0
cntmsg		db "t=xxxx f=xxxx",0

		end
