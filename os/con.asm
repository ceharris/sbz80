        ;---------------------------------------------------------------
        ; Console I/O Support
        ;---------------------------------------------------------------

                .name con
                
                .extern conidl

                .extern sagetc
                .extern saputc
                .extern sapoll
                .extern saflsh
                .extern sbgetc
                .extern sbputc
                .extern sbpoll
                .extern sbflsh
                .extern svctab

                .include memory.asm
                .include ascii.asm

                .cseg

conini::
                ld hl,cgets_idle_default
                ld (conidl),hl

        ;---------------------------------------------------------------
        ; consic:
        ; Sets the console idle callback.
        ;
        ; On entry:
        ;       HL = pointer to subroutine to call when idle during
        ;            console input via cgets, or 0 to reset to default
consic::
                ld a,l
                or h
                jr nz,consic_set
                ld hl,cgets_idle_default
consic_set:
                ld (conidl),hl
                ret

        ;---------------------------------------------------------------
        ; consa:
        ; Selects SIO port A as the console.
        ;
consa::
                push hl
                ld hl,svctab

                ; assumes that console functions are first in the table
                ld (hl),low cagetc
                inc hl
                ld (hl),high cagetc
                inc hl
                ld (hl),low caputc
                inc hl
                ld (hl),high caputc
                inc hl
                ld (hl),low cagets
                inc hl
                ld (hl),high cagets
                inc hl
                ld (hl),low caputs
                inc hl
                ld (hl),high caputs
                inc hl
                ld (hl),low sapoll
                inc hl
                ld (hl),high sapoll
                inc hl
                ld (hl),low caflsh
                inc hl
                ld (hl),high caflsh
                inc hl

                pop hl
                ret

        ;---------------------------------------------------------------
        ; consb:
        ; Selects SIO port B as the console.
        ;
consb::
                push hl
                ld hl,svctab

                ; assumes that console functions are first in the table
                ld (hl),low cbgetc
                inc hl
                ld (hl),high cbgetc
                inc hl
                ld (hl),low cbputc
                inc hl
                ld (hl),high cbputc
                inc hl
                ld (hl),low cbgets
                inc hl
                ld (hl),high cbgets
                inc hl
                ld (hl),low cbputs
                inc hl
                ld (hl),high cbputs
                inc hl
                ld (hl),low sbpoll
                inc hl
                ld (hl),high sbpoll
                inc hl
                ld (hl),low cbflsh
                inc hl
                ld (hl),high cbflsh
                inc hl

                pop hl
                ret

        ;---------------------------------------------------------------
        ; cagetc:
        ; Gets a character from console port A.
        ; 
        ; On return:
        ;       if C flag set, A contains an character from the console
        ;
cagetc::
                push hl
                call sagetc
                pop hl
                ret

cgets_idle:
                ld hl,(conidl)
                jp (hl)

cgets_idle_default:
                ret

        ;---------------------------------------------------------------
        ; cagets:
        ; Gets a line of input from console port A.
        ; Assumes that buffer is page aligned.
        ; 
cagets::
                push bc
                push de
                ld de,consin            ; point to start of line buffer
cagets_next:
                call sagetc
                jr c,cagets_chk_print   ; go if input available
                push de
                call cgets_idle
                pop de
                jr cagets_next

cagets_chk_print:
                cp ascii_space          ; is it in range of ASCII printables?
                jr c,cagets_chk_bs      ; nope...
                ld c,a                  ; preserve input char
                ld a,e
                cp consin_size-1        ; is the buffer full?
                jr z,cagets_next        ; yep...
                ld a,c
                ld (de),a               ; store input char               
                call saputc             ; echo it
                inc e                   ; next buffer position
                jr cagets_next

cagets_chk_bs:
                cp ascii_bs             ; is it backspace?
                jr nz,cagets_chk_cr     ; nope...
                ld a,e
                or a                    ; is the input non-empty?
                jr z,cagets_next        ; yep...
                ld c,ascii_bs
                call saputc             ; send backspace
                ld c,ascii_space                
                call saputc             ; send space to overwrite
                ld c,ascii_bs
                call saputc             ; backspace again
                dec e                   ; prior buffer position
                jr cagets_next

cagets_chk_cr:
                cp ascii_cr             ; is it carriage return?
                jr nz,cagets_next       ; nope...
                ld c,a
                call saputc             ; echo the carriage return
                ld c,ascii_lf
                call saputc             ; follow with line feed
                xor a
                ld (de),a               ; null-terminate the input
                ld hl,consin            ; return pointer to input
                pop de
                pop bc
                ret

        ;---------------------------------------------------------------
        ; caputc:
        ; Puts a character to console port A.
        ; 
        ; On entry:
        ;       C is the character to put
        ;
caputc::
                push hl
                ld a,c
                cp ascii_lf
                jr z,caputc_newline
                call saputc               
                pop hl
                ret

caputc_newline:
                ld c,ascii_cr
                call saputc
                ld c,ascii_lf
                call saputc
                pop hl
                ret


        ;---------------------------------------------------------------
        ; caputs:
        ; Puts a string to console port A.
        ; 
        ; On entry:
        ;       HL = pointer to null-terminated string
        ;
caputs::
                push de
                push hl
                ex de,hl
caputs_next:
                ld a,(de)
                inc de
                or a
                jr z,caputs_done
                cp ascii_lf
                jr z,caputs_newline
                ld c,a
                call saputc
                jp caputs_next

caputs_newline:
                ld c,ascii_cr
                call saputc
                ld c,ascii_lf
                call saputc
                jp caputs_next
caputs_done:
                pop hl
                pop de
                ret


        ;---------------------------------------------------------------
        ; caflsh:
        ; Flushes all pending input from console port A.
        ;
caflsh::
                push hl
                call saflsh
                pop hl
                ret


        ;---------------------------------------------------------------
        ; cagetc:
        ; Gets a character from console port B.
        ; 
        ; On return:
        ;       if C flag set, A contains an character from the console
        ;
cbgetc::
                push hl
                call sbgetc
                pop hl
                ret

cbgets::
                ; TODO
                ret

        ;---------------------------------------------------------------
        ; caputc:
        ; Puts a character to console port B.
        ; 
        ; On entry:
        ;       C is the character to put
        ;
cbputc::
                push hl
                ld a,c
                cp $0a
                jr z,cbputc_newline
                call sbputc               
                pop hl
                ret

cbputc_newline:
                ld c,$0d
                call sbputc
                ld c,$0a
                call sbputc
                pop hl
                ret


        ;---------------------------------------------------------------
        ; cbputs:
        ; Puts a string to console port B.
        ; 
        ; On entry:
        ;       HL = pointer to null-terminated string
        ;
cbputs::
                push de
                push hl
                ex de,hl
cbputs_next:
                ld a,(de)
                inc de
                or a
                jr z,cbputs_done
                cp ascii_lf
                jr z,cbputs_newline
                ld c,a
                call sbputc
                jp cbputs_next

cbputs_newline:
                ld c,ascii_cr
                call sbputc
                ld c,ascii_lf
                call sbputc
                jp cbputs_next

cbputs_done:
                pop hl
                pop de
                ret


        ;---------------------------------------------------------------
        ; cbflsh:
        ; Flushes all pending input from console port B.
        ;
cbflsh::
                push hl
                call sbflsh
                pop hl
                ret


                .end                                             