                .name prog

                .extern gpout

                .include memory.asm
                .include svcid.asm
                .include ports.asm
                .include adc.asm
                .include pio_defs.asm
                .include ascii.asm

argc_limit      .equ 63

lsr_port        .equ adc0_ch2
pot_port        .equ adc0_ch3

blink_loops     .equ $100

kb_size         .equ 12

                .cseg
prog::

                ld c,$4                 ; display on
                ld a,@lcctl
                rst $28

                ld iy,uptime

                ld hl,blink_loops
                ld (loop_cnt),hl
                xor a
                ld (kb_cnt),a
                ld (blinker),a

                call reset_last

                ld hl,idle
                ld a,@consic
                rst $28

                ld c,ascii_lf
                ld a,@cputc
                rst $28

loop:        
                ld hl,ready
                ld a,@cputs
                rst $28
                ld a,@cgets
                rst $28
                call parse_args
                ld a,(argc)
                or a
                jp z,loop
                call interp
                jp nc,loop
                call execute
                jp loop 

idle:
                call blink
                call kb_read
                call update_adc
                call l7ticks
                call lc_uptime
                ret

reset_last:
                ld a,$ff
                ld (last_secs),a
                ld (last_lsr),a
                ld (last_pot),a
                ret

kb_read:
                ld a,@kiread
                rst $28
                ret z
                ld c,a

                cp $1b
                jp nz,kb_read_05

                xor a
                ld (kb_cnt),a
                call reset_last
                ld a,@lccls
                rst $28
                ret

kb_read_05:
                cp $20
                ret c

                ld a,(kb_cnt)
                cp kb_size
                jp z,kb_read_10
                inc a
                ld (kb_cnt),a
                ld hl,kb_buf-1
                add a,l
                ld l,a
                jp kb_read_20
kb_read_10:
                ld a,c
                ld bc,kb_size-1
                ld de,kb_buf
                ld hl,kb_buf+1
                ldir
                dec hl
                ld c,a
kb_read_20:
                ld (hl),c
kb_read_30:
                ld bc,$0104
                ld a,@lcgoto
                rst $28

                ld hl,kb_buf
                ld a,(kb_cnt)
                ld b,a
kb_read_40:
                ld a,(hl)
                jr c,kb_read_50
                ld c,a
                ld a,@lcputc
                rst $28
kb_read_50:
                inc hl
                djnz kb_read_40

                jp kb_read

blink:
                ld hl,(loop_cnt)
                dec hl
                ld (loop_cnt),hl
                ld a,l
                or h
                ret nz
blink_10:
                ld a,(blinker)
                xor $1
                ld (blinker),a
                out (pio1_base+pio_port_a),a
                out (pio1_base+pio_port_b),a
                ld hl,blink_loops
                ld (loop_cnt),hl
                ret

update_adc:
                in a,(lsr_port)                
                ld c,a
                ld de,100
                ld a,@mm16x8
                rst $28
                ld a,(last_lsr)
                cp h
                ret z                
                
                ld a,h
                ld (last_lsr),a
                ld bc,$0100
                ld a,@lcgoto
                rst $28

                ld l,h
                ld h,0
                ld a,@lcpd16
                rst $28

                ld c,'%'
                ld a,@lcputc
                rst $28

                ld c,' '
                ld a,@lcputc
                rst $28

                in a,(pot_port)
                ld c,a
                ld de,100
                ld a,@mm16x8
                rst $28
                ld a,(last_pot)
                cp h
                ret z                
                
                ld a,h
                ld (last_pot),a

                ld l,h
                ld h,0
                ld a,@lcpd16
                rst $28

                ld c,'%'
                ld a,@lcputc
                rst $28

                ld c,' '
                ld a,@lcputc
                rst $28
                ret


l7ticks:
                ld a,@tkrd32
                rst $28

                ld c,01010000b
                ld b,10000111b
                ld a,@l7pd32
                rst $28
                ret

lc_uptime:
                ld a,@tkrdut
                rst $28

                ld a,(last_secs)
                cp (iy+4)
                ret z

                ld a,(iy+4)
                ld (last_secs),a

                ld bc,0
                ld a,@lcgoto
                rst $28

                ld l,(iy+0)
                ld h,(iy+1)
                ld a,@lcpd16
                rst $28

                ld hl,days
                ld a,@lcputs
                rst $28

                ld h,0
                ld l,(iy+2)
                ld a,l
                cp 10
                jp nc,nopad_hh
                ld c,'0'
                ld a,@lcputc
                rst $28
nopad_hh:
                ld a,@lcpd16
                rst $28

                ld c,':'
                ld a,@lcputc
                rst $28

                ld h,0
                ld l,(iy+3)
                ld a,l
                cp 10
                jp nc,nopad_mm
                ld c,'0'
                ld a,@lcputc
                rst $28
nopad_mm:
                ld a,@lcpd16
                rst $28

                ld c,':'
                ld a,@lcputc
                rst $28

                ld h,0
                ld l,(iy+4)
                ld a,l
                cp 10
                jp nc,nopad_ss
                ld c,'0'
                ld a,@lcputc
                rst $28
nopad_ss:
                ld a,@lcpd16
                rst $28
                ret

chrono:
                ifdef BROKEN
                ; divide time by 100 to get seconds and hundredths
                ld c,100
                ld a,@md32x8
                rst $28

                ; display hundredths in a two-digit zero-padded field
                ; in digits 1..0
                push hl
                ld l,a
                ld c,00000000b
                ld b,00000001b
                ld a,@l7pd8
                rst $28
                pop hl

                ; divide time by 60 to get minutes and seconds
                ld c,60
                ld a,@md32x8
                rst $28

                ; display seconds in a two-digit zero-padded field
                ; with trailing decimal point in digits 3..2
                push hl
                ld l,a
                ld c,00010010b
                ld b,10000011b
                ld a,@l7pd8
                rst $28
                pop hl

                ; divide time by 60 to get hours and minutes
                ld c,60
                ld a,@md32x8
                rst $28

                ; display minutes in a two-digit zero-padded field
                ; with trailing decimal point in digits 5..4
                push hl
                ld l,a
                ld c,00100100b
                ld b,10000101b
                ld a,@l7pd8
                rst $28
                pop hl

                ; divide time by 24 to get days and hours
                ld c,24
                ld a,@md32x8
                rst $28

                ; display hours in a two-digit space-padded field
                ; with trailing decimal point in digits 7..6
                push hl
                ld l,a
                ld c,01110110b
                ld b,10000111b
                ld a,@l7pd8
                rst $28
                pop hl
           
                endif

        ;---------------------------------------------------------------
        ; parse_args:
        ; Parses a command line to produce a C-style argument count
        ; and argument vector. Parses a maximum of arg_limit - 1
        ; tokens from the command line.
        ;
        ; On entry:
        ;       HL = pointer to null-terminated command input
        ;
        ; On return:
        ;       (argc) = argument count
        ;       [argv+2i..argv+2i+1] = pointer to argument i
        ;       [argv+2n..argv+2n+1] = 0 (where n = argc)
        ;       HL = pointer to last input byte parsed
        ;       AF destroyed
        ;
parse_args:
                push ix
                xor a
                ld (argc),a
                ld ix,argv

parse_next_token:
                ; find start of token
                ld a,(hl)               ; get input char
                or a
                jr z,parse_args_end     ; go if end of input
                cp ascii_space
                jr z,parse_skip_space   ; ignore space
                cp ascii_tab
                jr z,parse_skip_space   ; ignore tab

                ; store pointer to token in argv
                ld (ix),l              
                ld (ix+1),h
                inc ix
                inc ix
                ; update arg count and check limit
                ld a,(argc)
                inc a
                ld (argc),a
                cp argc_limit-1
                jr nc,parse_args_end    ; stop parsing if at limit

parse_past_token:
                ; find end of token
                inc hl
                ld a,(hl)
                or a                    ; end of input?
                jr z,parse_args_end     ; yep... end of args
                cp ascii_space          ; space delimiter?
                jr z,parse_end_token    ; yep... end of token
                cp ascii_tab            ; tab delimiter?
                jr nz,parse_past_token  ; nope... still more token

parse_end_token:
                ; null terminate the token
                xor a
                ld (hl),a
                ; go parse next token
                inc hl
                jr parse_next_token

parse_skip_space:
                inc hl
                jr parse_next_token

parse_args_end:
                ; null-terminate argv
                ld (ix+0),0
                ld (ix+1),0
                pop ix
                ret


interp:
                ld ix,cmdtab

                ; compare first argument to next command in table
interp_next:
                ld e,(ix+0)             ; LSB of command string to match
                ld d,(ix+1)             ; MSB of command string to match

                ; at end of command table?
                ld a,e
                or d
                jr z,interp_not_found

                ; compare input with command string
                ld hl,(argv)            ; HL -> arg to compare
interp_compare:
                ld a,(de)
                or a                    ; at end of command?
                jr z,interp_check       ; yep... check for end of arg
                cp (hl)                 ; does command match arg?
                jr nz,interp_no_match   ; nope... try next command
                inc de                  ; next command char
                inc hl                  ; next arg char
                jr interp_compare

interp_check:
                ld a,(hl)
                or a                    ; end of the arg?
                jr nz,interp_no_match   ; nope... not a match

                ld l,(ix+2)             ; get LSB of handler
                ld h,(ix+3)             ; get MSB of handler
                scf
                ret                     ; return C and HL = handler

interp_no_match:
                ; set up to compare next command in table
                ld bc,4                 
                add ix,bc               ; point to next table entry
                jr interp_next          ; try next command

interp_not_found:
                ; display token that isn't a recognized command
                ld hl,(argv) 
                ld a,@cputs
                rst $28
                ; delimit the error message
                ld c,':'
                ld a,@cputc
                rst $28
                ld c,ascii_space
                ld a,@cputc
                rst $28
                ; display the error message
                ld hl,err_not_found
                ld a,@cputs
                rst $28
                ; followed by newline
                ld c,ascii_lf
                ld a,@cputc
                rst $28

                or a
                ret                     ; return NC (no command)

        ;---------------------------------------------------------------
        ; execute: Executes a command handler whose address is in HL
        ;---------------------------------------------------------------
execute:
                jp (hl)
                ret

        ;---------------------------------------------------------------
        ; Command Handler: cls, clear
        ;---------------------------------------------------------------
handle_cls:
                ; send the ANSI ED sequence with parameter 2 to clear
                ; the screen
                ld hl,ansi_ed2
                ld a,@cputs
                rst $28
                ret

        ;---------------------------------------------------------------
        ; Command Handler: ticks
        ;---------------------------------------------------------------
base10_bufsize .equ 16
handle_ticks:
                push ix
                ld ix,-base10_bufsize
                add ix,sp
                ld sp,ix
                ld ix,base10_bufsize
                add ix,sp

                dec ix
                ld (ix),0               ; null terminate the buffer

                ; read the tick counter into DEHL
                ld a,@tkrd32
                rst $28       

                ; divide DEHL by 10 to get hundredths
                ld a,@md3210
                rst $28
                add '0'                 ; convert remainder to ASCII digit
                dec ix
                ld (ix),a               ; store in buffer

                ; divide DEHL by 10 to get tenths
                ld a,@md3210
                rst $28
                add '0'                 ; convert remainder to ASCII digit
                dec ix
                ld (ix),a               ; store in buffer

                dec ix
                ld (ix),'.'             ; insert the decimal point

                ; divide DEHL by 10 to get next digit
handle_ticks_next:
                ld a,@md3210
                rst $28
                add '0'                 ; convert remainder to ASCII digit
                dec ix
                ld (ix),a               ; store in buffer

                ; is the quotient now zero?
                ld a,l
                or h
                jr nz,handle_ticks_next
                or e
                jr nz,handle_ticks_next
                or d
                jr nz,handle_ticks_next

                ; display the result
                push ix
                pop hl
                ld a,@cputs
                rst $28
                ld c,ascii_lf
                ld a,@cputc
                rst $28

                ld ix,base10_bufsize
                add ix,sp
                ld sp,ix
                pop ix
                ret

        ;---------------------------------------------------------------
        ; Command Handler: peek
        ;---------------------------------------------------------------
handle_peek:
                ld a,(argc)
                or a
                jr z,handle_peek_usage

handle_peek_addr:
                ld hl,(argv+2)
                call hex_parse
                jr c,handle_peek_usage

                call hexdump
                ret

handle_peek_usage:
                ld hl,err_peek_usage
                ld a,@cputs
                rst $28
                ret


        ;---------------------------------------------------------------
        ; Command Handler: poke
        ;---------------------------------------------------------------
handle_poke:
                ; validate at least two args
                ld a,(argc)
                cp 3                    ; command + args
                jr c,handle_poke_usage
                ld hl,(argv+2)          ; HL -> address arg
                call hex_parse          
                jr c,handle_poke_usage 
                push hl

                ld de,argv+4            ; DE = next arg vector
handle_poke_check:
                ; set DE = next arg address
                ex de,hl                ; HL = next arg vector
                ld e,(hl)             
                inc hl
                ld d,(hl)
                inc hl
                ; set HL = next arg address, DE = next arg vector
                ex de,hl
                ; check for end of args
                ld a,l
                or h
                jr z,handle_poke_begin
                ; validate argument
                call hex_parse
                jr c,handle_poke_usage
                ; must be no more than 8 signficant bits
                ld a,h
                or a
                jr nz,handle_poke_usage
                jr handle_poke_check    ; go check next arg

handle_poke_begin:
                ld de,argv+4            ; DE = next arg vector
handle_poke_next:
                ; set DE = next arg address
                ex de,hl                
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc hl
                ; set HL = next arg address, DE = next arg vector
                ex de,hl
                ; check for end of args
                ld a,l
                or h
                jr z,handle_poke_done
                ; convert arg to byte in A
                call hex_parse
                ld a,l
                pop hl                  ; recover target address
                ld (hl),a               ; store arg as a byte
                inc hl                  ; next target address
                push hl                 ; preserve target address
                jr handle_poke_next     ; go proces next arg

handle_poke_done:
                pop hl                  ; discard target address
                ret

handle_poke_usage:
                ld hl,err_poke_usage
                ld a,@cputs
                rst $28
                ret

        ;---------------------------------------------------------------
        ; hexdump:
        ; Dump a 256-byte section of memory to the console in hexadecimal 
        ; and ascii forms.
        ;
        ; On entry:
        ;       HL = starting address
        ;
hexdump:
                ld d,h
                ld e,l
                ld b,16
hexdump_next:
                ld c,b
                push de
                ld hl,hexdump_line

                ld a,d
                call hex_octet
                ld a,e
                call hex_octet
                ld (hl),':'
                inc hl
                ld (hl),ascii_space
                inc hl

                ld b,16
hexdump_next_hex:
                ld a,(de)
                call hex_octet
                ld (hl),ascii_space
                inc hl
                ld a,b
                cp 16-7
                jr nz,hexdump_next_hex_loop
                ld (hl),ascii_space
                inc hl
hexdump_next_hex_loop:
                inc de
                djnz hexdump_next_hex
                pop de

                ld (hl),ascii_space
                inc hl
                ld b,16
hexdump_next_ascii:
                ld a,(de)
                cp ascii_space
                jr c,hexdump_next_ascii_dot
                cp ascii_del
                jr nc,hexdump_next_ascii_dot
                ld (hl),a
                jr hexdump_next_ascii_loop

hexdump_next_ascii_dot:
                ld (hl),'.'

hexdump_next_ascii_loop:
                inc hl
                ld a,b
                cp 16-7
                jr nz,hexdump_next_ascii_no_pad
                ld (hl),ascii_space
                inc hl
hexdump_next_ascii_no_pad:
                inc de
                djnz hexdump_next_ascii

                ld b,c

                ld (hl),ascii_lf
                inc hl
                ld (hl),0
                ld hl,hexdump_line
                ld a,@cputs
                rst $28

                djnz hexdump_next
                ret

        ;---------------------------------------------------------------
        ; hex_octet:
        ; Dump a octet to the console in hexadecimal form.
        ; forms.
        ;
        ; On entry:
        ;       C = octet to dump
        ; 
        ; On return:
        ;       HL modified
        ;
hex_octet:
                push bc
                ld c,a
                rrca
                rrca
                rrca
                rrca
                and $0f
                cp 10
                jr nc,hex_octet_letter1
                add a,'0'
                ld (hl),a
                jr hex_octet_lower

hex_octet_letter1:
                add a,'a'-10
                ld (hl),a

hex_octet_lower:
                inc hl
                ld a,c
                and $0f
                cp 10
                jr nc,hex_octet_letter2
                add a,'0'
                ld (hl),a
                inc hl
                pop bc
                ret

hex_octet_letter2:
                add a,'a'-10
                ld (hl),a
                inc hl
                pop bc
                ret

hex_parse:
                push bc
                push de
                ex de,hl
                ld hl,0
hex_parse_next:
                ld a,(de)
                inc de
                or a
                jr z,hex_parse_done
                cp '0'
                jr c,hex_parse_done
                cp '9'+1
                jr c,hex_parse_digit
                cp 'A'
                jr c,hex_parse_done
                cp 'F'+1
                jr c,hex_parse_letter
                cp 'a'
                jr c,hex_parse_done
                cp 'f'+1
                jr c,hex_parse_letter
                scf
                jr hex_parse_done
hex_parse_letter:
                and ~$20
                sub 'A'-10
                jr hex_parse_fold
hex_parse_digit:
                sub '0'
hex_parse_fold:
                ld c,a
                ld a,l
                ld b,4
                or a
hex_parse_multiply:
                rla
                rl h
                djnz hex_parse_multiply
                or c
                ld l,a
                jr hex_parse_next

hex_parse_done:
                pop de
                pop bc
                ret

days:           db "d ",0

ready:          db "Ready", $d, $a, "> ", 0

err_not_found:  db "not found",0
err_peek_usage: db "usage: peek <address>",ascii_lf,0
err_poke_usage: db "usage: poke <address> <octet> [<octet> ...]",ascii_lf,0
ansi_ed2:       db ascii_esc,"[2J",0

cmd_cls:        db "cls",0
cmd_clear:      db "clear",0
cmd_peek:       db "peek",0
cmd_poke:       db "poke",0
cmd_ticks:      db "ticks",0

cmdtab:
                dw cmd_cls,handle_cls
                dw cmd_clear,handle_cls
                dw cmd_peek,handle_peek
                dw cmd_poke,handle_poke
                dw cmd_ticks,handle_ticks
                dw 0

                .dseg

uptime:         ds 8
last_secs:      ds 1
last_lsr:       ds 1
last_pot:       ds 1
loop_cnt:       ds 2
blinker:        ds 1

kb_buf          ds kb_size
kb_cnt          ds 1


argc:           ds 1
argv:           ds 128
hexdump_line:   ds 80
