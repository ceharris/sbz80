
	#include "machine.h.asm"
	#include "workspace.h.asm"

	include "../include/ascii.h.asm"
	include "../include/acia.h.asm"
	include "../include/convert.h.asm"
	include "../include/romjump.h.asm"
	include "../include/stdio.h.asm"
	include "../include/monitor.h.asm"

	global jp_basic_rom

	defc IO_BUFFER_SIZE = 80
	defc PEEK_BUFFER_SIZE = 16

	defc BUF_P = WORKSPACE_MONITOR
	defc PEEK_P = BUF_P + 2
	defc MEM_P = PEEK_P + 2
	defc TOK_P = MEM_P + 2
	defc RADIX = TOK_P + 2
	defc LOAD_BUFFER = RADIX + 1
	defc IO_BUF = LOAD_BUFFER + 1
	defc PEEK_BUF = IO_BUF + IO_BUFFER_SIZE

	defc RADIX_2 = '%'
	defc RADIX_8 = '#'
	defc RADIX_10 = '>'
	defc RADIX_16 = '$'

	defc CMD_CALL = 1
	defc CMD_DATE = 2
	defc CMD_FILL = 3
	defc CMD_IN = 4
	defc CMD_JUMP = 5
	defc CMD_LOAD = 6
	defc CMD_OUT = 7
	defc CMD_PEEK = 8
	defc CMD_POKE = 9
	defc CMD_PORT = 10
	defc CMD_RADIX = 11
	defc CMD_RUN = 12
	defc CMD_TIME = 13

	defc RUN_BASIC = 1
	defc COLD_START = 1
	defc WARM_START = 2


monitor:
	ld hl,title
	call puts

	ld a,RADIX_16
	ld (RADIX),a

	ld hl,0
	ld (MEM_P),hl

	ld hl,IO_BUF
	ld (BUF_P),hl
	ld hl,PEEK_BUF
	ld (PEEK_P),hl
	
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
	ifdef RTC_PORT
	cp CMD_DATE
	jp z,cmd_date
	endif
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
	jp z,cmd_RADIX
	cp CMD_RUN
	jp z,cmd_run
	ifdef RTC_PORT
	cp CMD_TIME
	jp z,cmd_time
	endif
	ld hl,err_invalid
monitor_err:
	call puts
	ld c,'\n'
	call putc
	jr monitor_next

	ifdef RTC_PORT
cmd_date:
	call next_token
	ld a,(hl)
	jr NZ,cmd_date_set
	ld hl,(PEEK_P)
	call rtc_get_sdate
	call puts
	ld c,'\n'
	call putc
cmd_date_set:
	jp monitor_next
	endif


cmd_fill:
	call next_token			; get start address arg
	call convert_arg		; HL=start address
	jp c,monitor_err		; go if bad start address
	ld a,(de)			; A=terminating char
	or a
	jr z,cmd_fill_one		; go if at end of input
	cp '-'				; specifying a range?
	jr z,cmd_fill_range		; go if a range
	cp '+'				; specifying a length?
	jr z,cmd_fill_length		; go if a length
	ld hl,err_bad_arg		; otherwise, it's error
	jp monitor_err

cmd_fill_one:
	ld e,l				; DE=start address
	ld d,h
	inc de				; DE=end address (exclusive)
	jr cmd_fill_mem

cmd_fill_range:
	ld c,l				; BC=start address
	ld b,h
	ex de,hl			; HL->terminating char
	inc hl				; skip terminating char
	call validate_arg		; convert required arg
	ex de,hl			; DE=end address (exclusive)
	ld l,c				; HL=start address
	ld h,b
	jr cmd_fill_mem

cmd_fill_length:
	ld c,l				; BC=start address
	ld b,h
	ex de,hl			; DE=start address
	call validate_arg		; convert required arg
	add hl,bc			; HL=end address (exclusive)
	ex de,hl			; DE=end address (exclusive)
	ld l,c				; HL=start address
	ld h,b

cmd_fill_mem:
	ex de,hl			; swap start and end addresses
	or a				; clear carry
	sbc hl,de			; size to fill
	jr nc,cmd_fill_mem_10
	jr nz,cmd_fill_mem_10
	ld hl,err_fill
	jp monitor_err
cmd_fill_mem_10:
	ld c,l				; BC=size to fill
	ld b,h
	ex de,hl			; HL=start address
	ld e,l				; DE=start address
	ld d,h
	inc de				; DE=start address + 1
	dec bc				; don't overrun by 1
	push bc
	push de
	push hl
	call next_token	
	call validate_arg		; get fill value
	ld a,l
	pop hl
	pop de
	pop bc
	ld (hl),a			; fill first one
	ldir				; fill the rest
	jp monitor_next

cmd_in:
	call next_token
	call validate_arg
	ld e,l
	ld hl,(PEEK_P)
	call u8toh
	call puts
	ld c,':'
	call putc
	ld c,e
	ld b,d
	in e,(c)
	ld hl,(PEEK_P)
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
	ld hl,(BUF_P)
	ld b,IO_BUFFER_SIZE
	call gets
	ld b,c				; save terminating char
	ld c,'\n'			
	call putc			; output newline
	ld a,b				
	cp 3				; terminated by Ctrl-C?
	jp z,monitor_next

	ld hl,(BUF_P)

cmd_load_find_rec:
	ld a,(hl)
	inc hl
	or a
	jr z,cmd_load_next
	cp ':'
	jr nz,cmd_load_find_rec

	ld c,0				; clear checksum
	call cmd_load_read_byte
	ld b,a				; B = length
	call cmd_load_read_byte	
	ld d,a				; D = address MSB
	call cmd_load_read_byte
	ld e,a				; E = address LSB
	call cmd_load_read_byte
	or a
	jr z,cmd_load_data_rec		; go if type 0
	cp 1
	jr z,cmd_load_eof_rec		; go if type 1
	jr cmd_load_bad_type

cmd_load_data_rec:
	ld a,b				; A = record length
	or a
	jr z,cmd_load_rec_done		; go if zero length record
cmd_load_data_10:
	call cmd_load_read_byte		; read next byte
	ld (de),a			; store it
	inc de
	djnz cmd_load_data_10		; until all bytes read or error
cmd_load_rec_done:
	call cmd_load_read_byte		; read the checksum
	ld a,c				; A = final checksum
	or a
	jr nz,cmd_load_bad_checksum
	jr cmd_load_next

cmd_load_eof_rec:
	call cmd_load_read_byte		; read the checksum
	ld a,c				; A = final checksum
	or a
	jp z,monitor_next		; go if checksum good
	
cmd_load_bad_checksum:
	ld hl,err_bad_cksum
	jp monitor_err

cmd_load_bad_type:
	ld hl,err_bad_type
	jp monitor_err

cmd_load_read_byte:
	push bc				; save length and checksum
	call cmd_load_read_hex		; read upper nibble
	rlca				; shift it into the upper half
	rlca
	rlca
	rlca
	ld c,a				; save upper nibble
	call cmd_load_read_hex		; read lower nibble
	or c				; merge in upper nibble
	ld (LOAD_BUFFER),a		; save byte
	pop bc				; recover length and checksum
	add a,c				; include byte in checksum
	ld c,a				; C = new checksum
	ld a,(LOAD_BUFFER)		; recover byte
	ret

cmd_load_read_hex:
	ld a,(hl)
	inc hl
	or a				; did we hit the null terminator?
	jr z,cmd_load_bad_hex

	sub '0'				; convert digit to binary
	cp 9 + 1			; is it in range for a digit?
	ret c				; go if digit
	and 0xdf			; clear bit 5 to convert case
	sub 7				; translate 'A'..'F' to 10..15
	cp 10				; check lower bound
	jr c,cmd_load_bad_hex		; error if some char before 'A'
	cp 15 + 1			; check upper bound
	ret c				; go if 'F' or smaller
cmd_load_bad_hex:
	pop af				; discard return address
	pop bc				; discard saved length and checksum
	ld hl,err_bad_hex
	jp monitor_err


cmd_out:
	call next_token			; get port address
	call validate_arg
	ld c,l				; BC = port address
	ld b,h
	call next_token			; get value to write
	call validate_arg		
	out (c),l			; write value to port
	jp monitor_next

cmd_peek:
	call next_token			; get starting address
	call convert_arg		; convert to uint16
	jp c,monitor_err		; go on conversion error
	ld a,(de)			; get char after starting addr
	or a
	jr z,cmd_peek_one_page		; go if null terminator 
	cp '-'
	jr z,cmd_peek_range		; handle range if start-end
	cp '+'		
	jr z,cmd_peek_length		; handle length if start+length
	ld hl,err_bad_arg		; otherwise it's an error
	jp monitor_err

cmd_peek_one_page:			; range will be start+256
	ld e,l				; DE = start address
	ld d,h
	ld bc,256			; BC = length to peek
	add hl,bc			; HL = end address
	ex de,hl			; HL = start address, DE = end address
	jr cmd_peek_dump		; go do it

cmd_peek_range:				; range specified as start-end
	ld c,l				; BC = start address
	ld b,h				
	ex de,hl			; HL -> char after starting addr
	inc hl				; HL -> end address arg
	call validate_arg		; HL = end address as uint16
	ex de,hl			; DE = end address
	ld l,c				; HL = start address
	ld h,b
	jr cmd_peek_dump		; go do it

cmd_peek_length:			; range specified as start+length
	ld c,l				; BC = start address
	ld b,h
	ex de,hl			; HL -> char after start address
	call validate_arg		; HL = length as uint16
	add hl,bc			; HL = start + length
	ex de,hl			; DE = end address
	ld l,c				; HL = start address
	ld h,b

cmd_peek_dump:				; peek range (HL=start, DE=end)
	push de				; save end address
	ex de,hl			; DE = next address to peek, HL = end address
	or a				; clear carry
	sbc hl,de			; how much left?
	ld a,h				; A = MSB of remaining length
	or a		
	ld b,16				; assume at least 16 bytes left
	jr nz,cmd_peek_dump_10		; go if at least 256 bytes left
	ld a,l				; A = LSB of remaining length
	cp 16
	jr nc,cmd_peek_dump_10		; go if at least 16 bytes left
	ld b,l				; B = actual number of bytes left
cmd_peek_dump_10:
	ex de,hl			; HL = start address
	pop de				; DE = end address
	ld a,b				; A = number of bytes to dump
	or a
	jp z,monitor_next		; go if nothing left to dump
	call getcnb			; check for Ctrl-C
	jr z,cmd_peek_dump_20
	cp a,CTRL_C
	jp z,monitor_next		; stop if Ctrl-C pressed

cmd_peek_dump_20:
	call cmd_peek_show_addr		; print start address for this line 
	call cmd_peek_dump_hex		; print hex dump of up to 16 bytes
	ld c,SPC			
	call putc			; print an extra space
	call cmd_peek_dump_asc		; print ASCII dump of up to 16 bytes
	ld c,NL
	call putc			; go to next line
	ld a,l				; get LSB of start address for this line
	add a,b				; add number of bytes dumped on this line
	ld l,a				; L = LSB of next address to peek
	ld a,0				; A = 0 (without clearing carry)
	adc a,h				; carry into MSB
	ld h,a				; H = MSB of next address to peek
	jr cmd_peek_dump		; go do the next line

cmd_peek_dump_hex:			; hex dump B bytes at HL 
	push bc
	push de
	push hl
	ld e,0				; E = offset into data for this line			
cmd_peek_dump_hex_10:
	ld a,e				; A = offset into data for this line
	inc e				; next byte
	and 0x7				
	jr nz,cmd_peek_dump_hex_20	; go if A is between 1 and 7
	ld c,SPC			
	call putc			; print an extra space
cmd_peek_dump_hex_20:
	call cmd_peek_show_hex		; display a byte in hex
	inc hl				; HL = next address to dump
	djnz cmd_peek_dump_hex_10	; decrement count of bytes to dump
	pop hl
	pop de
	pop bc
	ld a,16
	sub b				; A = 16 - number of bytes dumped
	ret z				; go if exactly 16
	push bc
	push de
	ld b,a				; B = 16 - number of bytes dumped
cmd_peek_dump_hex_30:
	ld a,e				; A = offset into data for this line
	inc e				; next byte
	and 0x7		
	jr nz,cmd_peek_dump_hex_40	; go if A is between 1 and 7
	ld c,SPC
	call putc			; print an extra space
cmd_peek_dump_hex_40:
	call cmd_peek_skip_hex		; print spaces instead of hex
	djnz cmd_peek_dump_hex_30	; keep going for remainder of line
	pop de
	pop bc
	ret

cmd_peek_dump_asc:			; ASCII dump B bytes at HL
	push bc
	push de
	push hl
	ld e,16				; E offset for this line
cmd_peek_dump_asc_10:
	ld a,e				; A offset into this line
	inc e				; next offset
	and 0x7	
	jr nz,cmd_peek_dump_asc_20	; go if A is between 1 and 7
	ld c,SPC
	call putc			; print an extra space
cmd_peek_dump_asc_20:
	call cmd_peek_show_asc		; display a byte in ASCII
	inc hl				; HL = next address to dump
	djnz cmd_peek_dump_asc_10	; decrement number of bytes to dump
	pop hl
	pop de
	pop bc
	ld a,16
	sub b				; A = 16 - number of bytes dumped
	ret z				; go if exactly 16
	push bc
	push de
	ld b,a				; B = 16 - number of bytes dumped
cmd_peek_dump_asc_30:
	ld a,e				; A = offset into this line
	inc e				; E = next offset
	and 0x7	
	jr nz,cmd_peek_dump_asc_40	; go if A is between 1 and 7
	ld c,SPC
	call putc			; print an extra space
cmd_peek_dump_asc_40:
	ld c,SPC			
	call putc			; print a space
	djnz cmd_peek_dump_asc_30	; keep going for remainder of line
	pop de
	pop bc
	ret

cmd_peek_show_addr:			; print address given in HL
	push de
	push hl
	ex de,hl			; DE = address to show
	ld hl,(PEEK_P)			; HL = buffer for conversion
	call u16toh			; convert to ASCII hex
	call puts			; print the address
	ld c,COLON
	call putc			; print a colon after the address
	pop hl
	pop de
	ret

cmd_peek_skip_hex:			; print 3 spaces in lieu of hex byte
	ld c,SPC
	call putc
	call putc
	call putc
	ret

cmd_peek_show_hex:			; print byte at HL in ASCII hex
	push de			
	push hl
	ld c,SPC
	call putc			; print leading space
	ld e,(hl)			; E = byte to print
	ld hl,(PEEK_P)			; HL = buffer for conversion
	call u8toh			; convert to ASCII hex
	call puts			; print the byte
	pop hl
	pop de
	ret

cmd_peek_show_asc:			; print byte at HL as ASCII char
	ld a,(hl)			; A = byte to print
	cp SPC
	jr c,cmd_peek_show_asc_10	; go if control char
	cp 0x7f
	jr c,cmd_peek_show_asc_20	; go if printable char
cmd_peek_show_asc_10:
	ld a,DOT 			; use a dot instead
cmd_peek_show_asc_20:
	ld c,a				; C = character to print
	call putc			; print it
	ret

cmd_poke:
	call next_token
	ld a,(hl)
	or a
	jr z,cmd_poke_10
	call validate_arg
	ld (MEM_P),hl
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
	ld hl,(BUF_P)
	ld (TOK_P),hl
	ld b,IO_BUFFER_SIZE
	call gets
	ld c,'\n'
	call putc
	ld hl,(BUF_P)
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
	ld hl,(MEM_P)
	ld (hl),a
	inc hl
	ld (MEM_P),hl
	ret

cmd_RADIX:
	call next_token
	ld a,(hl)
	or a
	jr z,cmd_RADIX_err
	ld de,radixes
	call match_token
	or a
	jr z,cmd_RADIX_err
	ld (RADIX),a
	jp monitor_next
cmd_RADIX_err:
	ld hl,err_RADIX
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
	jr z,cmd_run_basic_cold
	ld de,modes
	call match_token
	or a
	jr z,mode_err
	cp WARM_START
	jr z,cmd_run_basic_warm

cmd_run_basic_cold:
	jr cmd_run_basic_jp

cmd_run_basic_warm:

cmd_run_basic_jp:
	jp jp_rom_basic

	ifdef RTC_PORT
cmd_time:
	call next_token
	ld a,(hl)
	jr nz,cmd_time_set
	ld hl,(PEEK_P)
	call rtc_get_stime
	call puts
	ld c,'\n'
	call putc
cmd_time_set:
	jp monitor_next
	endif

mode_err:
	ld hl,err_mode
	jp monitor_err

;---------------------------------------------------------------
; validate_arg:
; Converts a string argument to a 16-bit unsigned int, validating
; that it is present and syntactically correct.
;
validate_arg:
	call convert_arg		; convert arg to uint16
	jp c,require_arg_err		; go if error
	ld a,(de)			; get terminating cahr
	or a				; make sure nothing left
	ret z				; go if nothing left
	ld hl,err_bad_arg		; HL = error message
require_arg_err:
	pop af				; discard return address
	jp monitor_err			; go display error

;---------------------------------------------------------------
; convert_arg:
; Converts a string argument at HL to a 16-bit unsigned int.
; 
; The string can be prefixed to explicitly indicate a RADIX.
; Otherwise, the string is interpreted using the selected 
; default RADIX.
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
	jr z,convert_RADIX_2
	cp RADIX_8
	jr z,convert_RADIX_8
	cp RADIX_10
	jr z,convert_RADIX_10
	cp '+'
	jr z,convert_RADIX_10
	cp RADIX_16
	jr z,convert_RADIX_16
	cp '0'
	jp z,convert_arg_20
	dec hl
	ld a,(RADIX)
	jr convert_arg_10
convert_arg_20:
	ld a,(hl)
	inc hl
	cp 'b'
	jr z,convert_RADIX_2
	cp 'q'
	jr z,convert_RADIX_8
	cp 'd'
	jr z,convert_RADIX_10
	cp 'x'
	jr z,convert_RADIX_16
	dec hl
	dec hl
	ld a,(RADIX)
	jr convert_arg_10

convert_RADIX_2:
	ld a,(hl)
	or a
	jr z,convert_no_arg
	ex de,hl
	call btou16
	or a
	ret

convert_RADIX_8:
	ld a,(hl)
	or a
	jr z,convert_no_arg
	ex de,hl
	call qtou16
	or a
	ret

convert_RADIX_10:
	ld a,(hl)
	or a
	jr z,convert_no_arg
	ex de,hl
	call atou16
	or a
	ret

convert_RADIX_16:
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
; token pointer (TOK_P) is set to the next input buffer position.
; Otherwise, the token pointer is positioned at the null 
; terminator for the input.
;
; On return:
;	HL = pointer to null terminated token; an empty token
;	     indicates the end of the input has been reached
;
next_token:
	ld hl,(TOK_P)			; get token pointer

	; skip leading whitespace
next_token_10:
	ld a,(hl)			; get token char
	or a			
	jr z,next_token_20		; go if null terminator
	cp ' ' + 1
	jr nc,next_token_20		; go if not control char
	inc hl				; next char
	jr next_token_10
		
	; find the end of the token
next_token_20:
	ld e,l				; DE = HL
	ld d,h
	jr z,next_token_90		; go if at null terminator
next_token_30:
	ld a,(de)			; get token char
	cp ' ' + 1
	jr c,next_token_40		; go if control char
	inc de				; next char
	jr next_token_30		; keep looking for end

	; null terminate token if needed
next_token_40:
	or a
	jr z,next_token_90		; go if end is the null terminator
	xor a			
	ld (de),a			; insert a null terminator
	inc de				; point to next token

	; save next token pointer
next_token_90:
	ex de,hl			; HL = next token pointer, DE = token
	ld (TOK_P),hl			; save token pointer
	ex de,hl			; HL = token, DE = next token pointer
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
	push hl				; save token pointer
	ex de,hl			; HL -> table, DE -> token
match_token_10:
	ld a,(hl)			; get the tag
	or a				; zero marks end of table
	jr nz,match_token_15		; go if there's another entry
	pop hl				; recover token pointer
	ret
match_token_15:
	ld c,a				; save the tag
	inc hl
	ld b,(hl)			; get the length
	inc hl
match_token_20:
	ld a,'/'		
	cp (hl)				; check for abbreviated match
	jr z,match_token_40
	ld a,(de)			; get token char
	cp (hl)				; compare to char in table
	jr nz,match_token_30		; skip to next table entry
	dec b
	jr z,match_token_60		; go if exact match
	inc de				; next token char
	inc hl				; next table char
	jr match_token_20		; continue matching

match_token_30:
	; skip remainder of table entry
	inc hl
	djnz match_token_30
	pop de				; recover token pointer
	push de				; save it again
	jr match_token_10		; go try another token
match_token_40:
	ld a,(de)			; get token char
	or a
	jr z,match_token_60		; go if exact abbreviated match
	inc hl				; skip abbreviation delimiter
	dec b				; account for abbreviation delimiter
match_token_50:
	cp (hl)				; compare to char in table
	jr nz,match_token_30		; skip to next table entry
	inc de				; next token char
	inc hl				; next table char
	ld a,(de)			; get token char
	djnz match_token_50
match_token_60:
	pop hl				; recover token pointer
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
	ld a,(RADIX)
	ld c,a
	call show_prompt
	ld hl,(BUF_P)
	ld (TOK_P),hl
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
	; convert MEM_P to hex in I/O buffer
	ld hl,(MEM_P)
	ex de,hl
	ld hl,(BUF_P)
	call u16toh

	; display prompt
	ld b,c
	ld c,'['
	call putc
	call puts			; display current MEM_P
	ld c,']'
	call putc
	ld c,b				; display prompt character
	call putc
	ld c,' '
	call putc
	ret

commands:
	db	CMD_CALL,5,"c/all"
	ifdef RTC_PORT
	db      CMD_DATE,5,"d/ate"
	endif
	db	CMD_FILL,5,"f/ill"
	db	CMD_IN,3,"i/n"
	db	CMD_JUMP,5,"j/ump"
	db      CMD_LOAD,5,"l/oad"
	db	CMD_OUT,4,"o/ut"
	db	CMD_PEEK,5,"pe/ek"
	db	CMD_POKE,5,"po/ke"
	db	CMD_RADIX,6,"ra/dix"
	db	CMD_RUN,3,"run"
	ifdef RTC_PORT
	db	CMD_TIME,5,"t/ime"
	endif
	db	0
radixes:	
	db	RADIX_2,4,"b/in"
	db	RADIX_16,4,"h/ex"
	db	RADIX_10,4,"d/ec"
	db	RADIX_8,4,"o/ct"
	db	0

runnables:	
	db	RUN_BASIC,6,"b/asic"
	db	0

modes:         
	db      COLD_START,5,"c/old"
	db      WARM_START,5,"w/arm"
	db      0

err_invalid:
	db      "what?",0
err_RADIX:
	db      "must specify RADIX",0
err_no_arg:
	db      "argument expected",0
err_bad_arg:
	db      "invalid argument",0
err_fill:
	db	"invalid fill range",0
err_run:
	db	"must specify runnable",0
err_mode:
	db      "specify cold or warm start",0
err_bad_type:
	db	"bad type",0
err_bad_cksum:
	db	"bad checksum",0
err_bad_hex:	
	db	"bad hex encoding",0

title:		
	db	"\nSBZ80 Mark I System Monitor\n"
	db	"Copyright (c) 2024 Carl Harris, Jr\n\n",0

load_prompt:
	db	"[Press Ctrl-C to stop]\n",0
