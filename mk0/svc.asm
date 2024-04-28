        ;---------------------------------------------------------------
        ; Supervisor call dispatch
        ;---------------------------------------------------------------
                .name svc

                .extern svctab
                
                .cseg        

svcall::
                push hl                 ; save caller's HL
                ld h,high(svctab)       ; point to start of page-aligned table
                add a,a                 ; two bytes per entry
                ld l,a                  ; HL now points to table entry
                ld a,(hl)               ; A = LSB of entry point
                inc hl                        
                ld h,(hl)               ; H = MSB of entry point
                ld l,a                  ; HL = entry point
                ex (sp),hl              ; swap with caller's HL on stack
                ret                     ; jump to entry point

                .end
