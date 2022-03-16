        ;---------------------------------------------------------------
        ; Supervisor bootstrap
        ;---------------------------------------------------------------

                .name init

                .extern ctcini
                .extern kiinit
                .extern l7init
                .extern lcinit
                .extern pioini
                .extern prog
                .extern svcall
                .extern tkinit

                .include memory.asm
                .include ports.asm

wait            macro 
                local wait_10
;                ld a,(gpout)
 ;               or a,$80
;                out (gpio_port),a

wait_10:
                in a,(gpio_port)
                and $80
                jp nz,wait_10

;                ld a,(gpout)
;                out (gpio_port),a
                endm  

                .cseg
                jp init
init::
                ; select normal memory mode to enable RAM
                ld a,mode_normal
                out (mode_port),a

                ; put the stack at the top of RAM
                ld sp,ram_top

                ; enable interrupt mode 2
                xor a
                ld i,a                  ; I -> page zero
                im 2

                ; read the GPIO input register to get switch positions
                in a,(gpio_port)
                rla                     ; shift off the momentary switch
                and $c0
                ld (gpin),a

                ; initialize the GPIO output register
                xor a
                ld (gpout),a
                out (gpio_port),a

                call init_vec
                call init_isr
                call ctcini
                call pioini

                call l7init
                call kiinit
                call tkinit
                call lcinit
                ei

                jp prog

        ;---------------------------------------------------------------
        ; Initialize restart vectors
        ;
init_vec:
                ; point RST $0 to init
                ld hl,0
                ld (hl),$c3
                inc hl
                ld (hl),low(init)
                inc hl
                ld (hl),high(init)

                ; RST $8 through RST $20 default to no-op
                ld l,$8
                ld (hl),$c9
                ld l,$10
                ld (hl),$c9
                ld l,$18
                ld (hl),$c9
                ld l,$20
                ld (hl),$c9

                ; point RST $28 to svc dispatcher
                ld l,$28
                ld (hl),$c3
                inc hl
                ld (hl),low(svcall)
                inc hl
                ld (hl),high(svcall)

                ; RST $30 through RST $38 default to no-op
                ld l,$30
                ld (hl),$c9
                ld l,$38
                ld (hl),$c9
                ret

        ;---------------------------------------------------------------
        ; Initialize all interrupt service routines to be no-ops.
        ;
init_isr:
                ld hl,3                 ; DE -> unused portion of RST 0 vector
                ld (hl),$fb             ; EI instruction
                inc hl
                ld (hl),$ed             ; extended opcode
                inc hl
                ld (hl),$4d             ; RETI instruction
                ex de,hl
                ld hl,isrtab            
                ld b,isrtab_size/2
init_vec_10:
                ld (hl),e
                inc hl
                ld (hl),d
                inc hl
                djnz init_vec_10
                ret

                .end

