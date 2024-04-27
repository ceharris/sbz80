
		include "machine.h.asm"
		include "convert.h.asm"
		include "stdio.h.asm"

		public monitor
		extern run_basic_cold
		extern run_basic_warm

IO_BUFFER_SIZE		defl 128
PEEK_BUFFER_SIZE	defl 16 


RADIX_2		defl '%'
RADIX_8		defl '#'
RADIX_10	defl '>'
RADIX_16	defl '$'

CMD_CALL	defl 1
CMD_FILL	defl 2
CMD_IN		defl 3
CMD_JUMP	defl 4
CMD_LOAD	defl 5
CMD_OUT		defl 6
CMD_PEEK	defl 7
CMD_POKE	defl 8
CMD_PORT	defl 9
CMD_RADIX	defl 10
CMD_RUN		defl 11

RUN_BASIC	defl 1

COLD_START      defl 1
WARM_START      defl 2


		section CODE_USER

monitor:
		ld hl,title
		call puts

		ld a,RADIX_16
		ld (radix),a

		ld hl,0
		ld (mem_p),hl

		ld hl,io_buf
		ld (buf_p),hl
		ld hl,peek_buf
		ld (peek_p),hl
		
monitor_return:

monitor_next:
		call read_line
		ld c,'\n'
		call putc
		call next_token
		ld a,(hl)
		or a
		jr z,monitor_next

		ld de,commands
		call match_token
		cp CMD_CALL
		jp z,cmd_jump
		cp CMD_FILL
		jp z,cmd_fill
		cp CMD_IN
		jp z,cmd_in
		cp CMD_JUMP
		jp z,cmd_jump
		cp CMD_LOAD
		jp z,cmd_load
		cp CMD_OUT
		jp z,cmd_out
		cp CMD_PEEK
		jp z,cmd_peek
		cp CMD_POKE
		jp z,cmd_poke
		cp CMD_RADIX
		jp z,cmd_radix
		cp CMD_RUN
		jp z,cmd_run

		ld hl,err_invalid
monitor_err:
		call puts
		ld c,'\n'
		call putc
		jr monitor_next

cmd_fill:
		call next_token
		call convert_arg
		jp c,monitor_err
		ld a,(de)
		or a
		jr z,cmd_fill_one
		cp '-'
		jr z,cmd_fill_range
		cp '+'
		jr z,cmd_fill_length
		ld hl,err_bad_arg
		jp monitor_err

cmd_fill_one:
		ld e,l
		ld d,h
		inc de
		jr cmd_fill_mem

cmd_fill_range:
		ld c,l
		ld b,h
		ex de,hl
		inc hl
		call validate_arg
		ex de,hl
		ld l,c
		ld h,b
		jr cmd_fill_mem

cmd_fill_length:
		ld c,l
		ld b,h
		ex de,hl
		call validate_arg
		add hl,bc
		ex de,hl
		ld l,c
		ld h,b

cmd_fill_mem:
		ex de,hl
		or a
		sbc hl,de
		jr nc,cmd_fill_mem_10
		jr nz,cmd_fill_mem_10
		ld hl,err_fill
		jp monitor_err
cmd_fill_mem_10:
		ld c,l
		ld b,h
		ex de,hl
		ld e,l
		ld d,h
		inc de
		push bc
		push de
		push hl
		call next_token
		call validate_arg
		ld a,l
		pop hl
		pop de
		pop bc
		ld (hl),a
		ldir
		jp monitor_next

cmd_in:
		call next_token
		call validate_arg
		ld e,l
		ld hl,(peek_p)
		call u8toh
		call puts
		ld c,':'
		call putc
		ld c,e
		ld b,d
		in e,(c)
		ld hl,(peek_p)
		call u8toh
		call puts
		ld c,'\n'
		call putc
		jp monitor_next

cmd_jump:
		push af
		call next_token
		call validate_arg
		pop af
		cp CMD_CALL
		jr nz,cmd_jump_10
		ld de,monitor_return
		push de
cmd_jump_10:
		jp (hl)

cmd_load:
		ld hl,load_prompt
		call puts
cmd_load_next:
		ld hl,(buf_p)
		ld b,IO_BUFFER_SIZE
		call gets
		ld b,c			; save terminating char
		ld c,'\n'			
		call putc		; output newline
		ld a,b				
		cp 3			; terminated by Ctrl-C?
		jp z,monitor_next

		ld hl,(buf_p)

cmd_load_find_rec:
		ld a,(hl)
		inc hl
		or a
		jr z,cmd_load_next
		cp ':'
		jr nz,cmd_load_find_rec

		ld c,0			; clear checksum
		call cmd_load_read_byte
		ld b,a			; B = length
		call cmd_load_read_byte	
		ld d,a			; D = address MSB
		call cmd_load_read_byte
		ld e,a			; E = address LSB
		call cmd_load_read_byte
		or a
		jr z,cmd_load_data_rec	; go if type 0
		cp 1
		jr z,cmd_load_eof_rec	; go if type 1
		jr cmd_load_bad_type

cmd_load_data_rec:
		ld a,b			; A = record length
		or a
		jr z,cmd_load_rec_done	; go if zero length record
cmd_load_data_10:
		call cmd_load_read_byte	; read next byte
		ld (de),a		; store it
		inc de
		djnz cmd_load_data_10	; until all bytes read or error
cmd_load_rec_done:
		call cmd_load_read_byte	; read the checksum
		ld a,c			; A = final checksum
		or a
		jr nz,cmd_load_bad_checksum
		jr cmd_load_next

cmd_load_eof_rec:
		call cmd_load_read_byte	; read the checksum
		ld a,c			; A = final checksum
		or a
		jp z,monitor_next	; go if checksum good
		
cmd_load_bad_checksum:
		ld hl,err_bad_cksum
		jp monitor_err

cmd_load_bad_type:
		ld hl,err_bad_type
		jp monitor_err

cmd_load_read_byte:
		push bc			; save length and checksum
		call cmd_load_read_hex	; read upper nibble
		rlca			; shift it into the upper half
		rlca
		rlca
		rlca
		ld c,a			; save upper nibble
		call cmd_load_read_hex	; read lower nibble
		or c			; merge in upper nibble
		ld (load_buffer),a	; save byte
		pop bc			; recover length and checksum
		add a,c			; include byte in checksum
		ld c,a			; C = new checksum
		ld a,(load_buffer)	; recover byte
		ret

cmd_load_read_hex:
		ld a,(hl)
		inc hl
		or a			; did we hit the null terminator?
		jr z,cmd_load_bad_hex

		sub '0'			; convert digit to binary
		cp 9 + 1		; is it in range for a digit?
		ret c			; go if digit
		and 0xdf		; clear bit 5 to convert case
		sub 7			; translate 'A'..'F' to 10..15
		cp 10			; check lower bound
		jr c,cmd_load_bad_hex	; error if some char before 'A'
		cp 15 + 1		; check upper bound
		ret c			; go if 'F' or smaller
cmd_load_bad_hex:
		pop af			; discard return address
		pop bc			; discard saved length and checksum
		ld hl,err_bad_hex
		jp monitor_err


cmd_out:
		call next_token
		call validate_arg
		ld c,l
		ld b,h
		call next_token
		call validate_arg
		out (c),l
		jp monitor_next

cmd_peek:
		call next_token
		call convert_arg
		jp c,monitor_err
		ld a,(de)
		or a
		jr z,cmd_peek_one
		cp '-'
		jr z,cmd_peek_range
		cp '+'
		jr z,cmd_peek_length
		ld hl,err_bad_arg
		jp monitor_err

cmd_peek_one:
		ld e,l
		ld d,h
		inc de
		jr cmd_peek_dump

cmd_peek_range:
		ld c,l
		ld b,h
		ex de,hl
		inc hl
		call validate_arg
		ex de,hl
		ld l,c
		ld h,b
		jr cmd_peek_dump

cmd_peek_length:
		ld c,l
		ld b,h
		ex de,hl
		call validate_arg
		add hl,bc
		ex de,hl
		ld l,c
		ld h,b

cmd_peek_dump:
		push de
		ex de,hl
		or a
		sbc hl,de
		ld a,h
		or a
		ld b,16
		jr nz,cmd_peek_dump_10
		ld a,l
		cp 16
		jr nc,cmd_peek_dump_10
		ld b,l
cmd_peek_dump_10:
		ex de,hl
		pop de
		ld a,b
		or a
		jp z,monitor_next
		call getcnb
		jr z,cmd_peek_dump_20
		cp a,3
		jp z,monitor_next
cmd_peek_dump_20:
		call cmd_peek_show_addr
		call cmd_peek_dump_hex
		ld c,' '
		call putc
		call cmd_peek_dump_asc
		ld c,'\n'
		call putc
		ld a,l
		add b
		ld l,a
		ld a,0
		adc a,h
		ld h,a
		jr cmd_peek_dump

cmd_peek_dump_hex:
		push bc
		push de
		push hl
		ld e,0
cmd_peek_dump_hex_10:
		ld a,e
		inc e
		and 0x7
		jr nz,cmd_peek_dump_hex_20
		ld c,' '
		call putc
cmd_peek_dump_hex_20:
		call cmd_peek_show_hex
		inc hl
		djnz cmd_peek_dump_hex_10
		pop hl
		pop de
		pop bc
		ld a,16
		sub b
		ret z
		push bc
		push de
		ld b,a
cmd_peek_dump_hex_30:
		ld a,e
		inc e
		and 0x7
		jr nz,cmd_peek_dump_hex_40
		ld c,' '
		call putc
cmd_peek_dump_hex_40:
		call cmd_peek_skip_hex
		djnz cmd_peek_dump_hex_30
		pop de
		pop bc
		ret

cmd_peek_dump_asc:
		push bc
		push de
		push hl
		ld e,16
cmd_peek_dump_asc_10:
		ld a,e
		inc e
		and 0x7
		jr nz,cmd_peek_dump_asc_20
		ld c,' '
		call putc
cmd_peek_dump_asc_20:
		call cmd_peek_show_asc
		inc hl
		djnz cmd_peek_dump_asc_10
		pop hl
		pop de
		pop bc
		ld a,16
		sub b
		ret z
		push bc
		push de
		ld b,a
cmd_peek_dump_asc_30:
		ld a,e
		inc e
		and 0x7
		jr nz,cmd_peek_dump_asc_40
		ld c,' '
		call putc
cmd_peek_dump_asc_40:
		ld c,' '
		call putc
		djnz cmd_peek_dump_asc_30
		pop de
		pop bc
		ret

cmd_peek_show_addr:
		push de
		push hl
		ex de,hl
		ld hl,(peek_p)
		call u16toh
		call puts
		ld c,':'
		call putc
		pop hl
		pop de
		ret

cmd_peek_skip_hex:
		ld c,' '
		call putc
		call putc
		call putc
		ret

cmd_peek_show_hex:
		push de
		push hl
		ld c,' '
		call putc
		ld e,(hl)
		ld hl,(peek_p)
		call u8toh
		call puts
		pop hl
		pop de
		ret

cmd_peek_show_asc:
		ld a,(hl)
		cp ' '
		jr c,cmd_peek_show_asc_10
		cp 0x7f
		jr c,cmd_peek_show_asc_20
cmd_peek_show_asc_10:
		ld a,'.'
cmd_peek_show_asc_20:
		ld c,a
		call putc
		ret

cmd_poke:
		call next_token
		ld a,(hl)
		or a
		jr z,cmd_poke_10
		call validate_arg
		ld (mem_p),hl
cmd_poke_10:
		call next_token
		ld a,(hl)
		or a
		jr z,cmd_poke_mode
cmd_poke_20:
		call validate_arg
		call cmd_poke_store
		call next_token
		ld a,(hl)
		or a
		jr nz,cmd_poke_20
		jp monitor_next
cmd_poke_mode:
		ld c,':'
		call show_prompt
		ld hl,(buf_p)
		ld (tok_p),hl
		ld b,IO_BUFFER_SIZE
		call gets
		ld c,'\n'
		call putc
		ld hl,(buf_p)
		ld a,(hl)
		or a
		jp z,monitor_next
cmd_poke_mode_10:
		call next_token
		ld a,(hl)
		or a
		jr z,cmd_poke_mode
		call validate_arg
		call cmd_poke_store
		jr cmd_poke_mode_10

cmd_poke_store:
		ld a,l
		ld hl,(mem_p)
		ld (hl),a
		inc hl
		ld (mem_p),hl
		ret

cmd_radix:
		call next_token
		ld a,(hl)
		or a
		jr z,cmd_radix_err
		ld de,radixes
		call match_token
		or a
		jr z,cmd_radix_err
		ld (radix),a
		jp monitor_next
cmd_radix_err:
		ld hl,err_radix
		jp monitor_err


cmd_run:
		call next_token
		ld a,(hl)
		or a
		jr z,cmd_run_err
		ld de,runnables
		call match_token
		or a
		jr z,cmd_run_err
		cp RUN_BASIC
		jr z,cmd_run_basic
		jp monitor_next
cmd_run_err:
		ld hl,err_run
		jp monitor_err


cmd_run_basic:
		call next_token
		ld a,(hl)
		or a
		jp z,run_basic_cold
		ld de,modes
		call match_token
		or a
		jr z,mode_err
		cp WARM_START
		jp z,run_basic_warm
		jp run_basic_cold

mode_err:
		ld hl,err_mode
		jp monitor_err

validate_arg:
		call convert_arg
		jp c,require_arg_err
		ld a,(de)
		or a
		ret z
		ld hl,err_bad_arg
require_arg_err:
		pop af
		jp monitor_err

	;---------------------------------------------------------------
	; convert_arg:
	; Converts a string argument at HL to a 16-bit unsigned int.
	; 
	; The string can be prefixed to explicitly indicate a radix.
	; Otherwise, the string is interpreted using the selected 
	; default radix.
	;
	; Supported prefixes:
	;       % or 0b -- binary
	;       # or 0q -- octal
	;       >, +, or 0d -- decimal
	;       $ or 0x -- hexadecimal
	;
	; On entry:
	;       HL points to the null-terminated string to convert
	;
	; On return:
	;       if NC, HL is the converted value
	;       DE points to the character that terminated conversion
	;
	;       if C, HL points to a null-terminated error message
	; 
convert_arg:
		ld a,(hl)
		inc hl
		or a
		jr z,convert_no_arg
convert_arg_10:                
		cp RADIX_2
		jr z,convert_radix_2
		cp RADIX_8
		jr z,convert_radix_8
		cp RADIX_10
		jr z,convert_radix_10
		cp '+'
		jr z,convert_radix_10
		cp RADIX_16
		jr z,convert_radix_16
		cp '0'
		jp z,convert_arg_20
		dec hl
		ld a,(radix)
		jr convert_arg_10
convert_arg_20:
		ld a,(hl)
		inc hl
		cp 'b'
		jr z,convert_radix_2
		cp 'q'
		jr z,convert_radix_8
		cp 'd'
		jr z,convert_radix_10
		cp 'x'
		jr z,convert_radix_16
		dec hl
		dec hl
		ld a,(radix)
		jr convert_arg_10

convert_radix_2:
		ld a,(hl)
		or a
		jr z,convert_no_arg
		ex de,hl
		call btou16
		or a
		ret

convert_radix_8:
		ld a,(hl)
		or a
		jr z,convert_no_arg
		ex de,hl
		call qtou16
		or a
		ret

convert_radix_10:
		ld a,(hl)
		or a
		jr z,convert_no_arg
		ex de,hl
		call atou16
		or a
		ret

convert_radix_16:
		ld a,(hl)
		or a
		jr z,convert_no_arg
		ex de,hl
		call htou16
		or a
		ret

convert_no_arg:
		ld hl,err_no_arg
		scf
		ret

convert_bad_arg:
		ld hl,err_bad_arg
		scf
		ret


	;---------------------------------------------------------------
	; next_token:
	; Gets the next token from the I/O buffer. 
	;
	; A line of input is considered to be a sequence of tokens
	; separated by one or more whitespace characters. This function
	; skips any leading whitespace to find the start of a token,
	; and then skips forward to find the end of the token or the
	; end of the input. If the end of the token is reached before
	; the end of the input, the token is null terminated, and the
	; token pointer (tok_p) is set to the next input buffer position.
	; Otherwise, the token pointer is positioned at the null 
	; terminator for the input.
	;
	; On return:
	;	HL = pointer to null terminated token; an empty token
	;	     indicates the end of the input has been reached
	;
next_token:
		ld hl,(tok_p)		; get token pointer
		; skip leading whitespace
next_token_10:
		ld a,(hl)		; get token char
		or a			
		jr z,next_token_20	; go if null terminator
		cp ' ' + 1
		jr nc,next_token_20	; go if not control char
		inc hl			; next char
		jr next_token_10
		
		; find the end of the token
next_token_20:
		ld e,l			; DE = HL
		ld d,h
		jr z,next_token_90	; go if at null terminator
next_token_30:
		ld a,(de)		; get token char
		cp ' ' + 1
		jr c,next_token_40	; go if control char
		inc de			; next char
		jr next_token_30	; keep looking for end

		; null terminate token if needed
next_token_40:
		or a
		jr z,next_token_90	; go if end is the null terminator
		xor a			
		ld (de),a		; insert a null terminator
		inc de			; point to next token

		; save next token pointer
next_token_90:
		ex de,hl		; HL = next token pointer, DE = token
		ld (tok_p),hl		; save token pointer
		ex de,hl		; HL = token, DE = next token pointer
		ret

	;---------------------------------------------------------------
	; match_token:
	; Compares an input token to possible matches in a table.
	;
	; On entry:
	;	DE = pointer to table
	;	HL = pointer to token
	;
	; On return:
	;	A = table tag for the matching entry or zero to indicate
	;	    that the end of the table was reached without finding
	;	    a match
	;	HL = pointer to token
	;	BC and DE clobbered
	;
match_token:
		push hl			; save token pointer
		ex de,hl		; HL -> table, DE -> token
match_token_10:
		ld a,(hl)		; get the tag
		or a			; zero marks end of table
		jr nz,match_token_15	; go if there's another entry
		pop hl			; recover token pointer
		ret
match_token_15:
		ld c,a			; save the tag
		inc hl
		ld b,(hl)		; get the length
		inc hl
match_token_20:
		ld a,'/'		
		cp (hl)			; check for abbreviated match
		jr z,match_token_40
		ld a,(de)		; get token char
		cp (hl)			; compare to char in table
		jr nz,match_token_30	; skip to next table entry
		dec b
		jr z,match_token_60	; go if exact match
		inc de			; next token char
		inc hl			; next table char
		jr match_token_20	; continue matching

match_token_30:
		; skip remainder of table entry
		inc hl
		djnz match_token_30
		pop de			; recover token pointer
		push de			; save it again
		jr match_token_10	; go try another token
match_token_40:
		ld a,(de)		; get token char
		or a
		jr z,match_token_60	; go if exact abbreviated match
		inc hl			; skip abbreviation delimiter
		dec b			; account for abbreviation delimiter
match_token_50:
		cp (hl)			; compare to char in table
		jr nz,match_token_30	; skip to next table entry
		inc de			; next token char
		inc hl			; next table char
		ld a,(de)		; get token char
		djnz match_token_50
match_token_60:
		pop hl			; recover token pointer
		ld a,c
		ret


	;---------------------------------------------------------------
	; read_line:
	; Display the prompt and get a line of input from user.
	;
	; On entry:
	;	C = prompt character ('>' for command, ':' for continuation)
	;
	; On return:
	;	C = terminating input character
	;
read_line:
		ld a,(radix)
		ld c,a
		call show_prompt
		ld hl,(buf_p)
		ld (tok_p),hl
		ld b,IO_BUFFER_SIZE
		call gets
		ret


	;---------------------------------------------------------------
	; show_prompt:
	; Displays the input prompt.
	; 
	; On entry:
	;	C = prompt character
	;
show_prompt:
		; convert mem_p to hex in I/O buffer
		ld hl,(mem_p)
		ex de,hl
		ld hl,(buf_p)
		call u16toh

		; display prompt
		ld b,c
		ld c,'['
		call putc
		call puts		; display current mem_p
		ld c,']'
		call putc
		ld c,b			; display prompt character
		call putc
		ld c,' '
		call putc
		ret


		section RODATA
commands:
		db	CMD_CALL,5,"c/all"
		db	CMD_FILL,5,"f/ill"
		db	CMD_IN,3,"i/n"
		db	CMD_JUMP,5,"j/ump"
		db      CMD_LOAD,5,"l/oad"
		db	CMD_OUT,4,"o/ut"
		db	CMD_PEEK,5,"pe/ek"
		db	CMD_POKE,5,"po/ke"
		db	CMD_RADIX,6,"ra/dix"
		db	CMD_RUN,3,"run"
		db	0

radixes:	db	RADIX_2,4,"b/in"
		db	RADIX_16,4,"h/ex"
		db	RADIX_10,4,"d/ec"
		db	RADIX_8,4,"o/ct"
		db	0

runnables:	db	RUN_BASIC,6,"b/asic"
		db	0

modes:          db      COLD_START,5,"c/old"
		db      WARM_START,5,"w/arm"
		db      0

err_invalid:    db      "what?",0
err_radix:      db      "must specify radix",0
err_no_arg:     db      "argument expected",0
err_bad_arg:    db      "invalid argument",0
err_fill:	db	"invalid fill range",0
err_run:	db	"must specify runnable",0
err_mode:       db      "specify cold or warm start",0
err_bad_type:	db	"bad type",0
err_bad_cksum:	db	"bad checksum",0
err_bad_hex:	db	"bad hex encoding",0

title:		db	"\nSBZ80 Mark I System Monitor\n"
		db	"Copyright (c) 2024 Carl Harris, Jr\n\n",0
load_prompt:	db	"[Press Ctrl-C to stop]\n",0

		section BSS
buf_p:		dw io_buf		; pointer to our I/O buffer
peek_p:		dw peek_buf		; pointer to our peek buffer
mem_p:		ds 2			; pointer for memory operations
tok_p:		ds 2			; pointer to input argument
radix:		ds 1                    ; selected default radix
load_buffer:	ds 1			; temporary storage for load
io_buf:		ds IO_BUFFER_SIZE	; command I/O buffer
peek_buf:	ds PEEK_BUFFER_SIZE	; buffer used for peeking memory
