        ;---------------------------------------------------------------
        ; Supervisor bootstrap
        ;---------------------------------------------------------------

                .name init
        
                .extern gpin
                .extern gpout
                .extern isrtab
                .extern svctab

                .extern ctcini
                .extern kiinit
                .extern l7init
                .extern lcinit
                .extern pioini
                .extern sioini
                .extern conini
                .extern prog
                .extern svcall
                .extern tkinit

                .include memory.asm
                .include ports.asm


                .cseg
init::
                ld a,mode_bootstrap
                out (mode_port),a

                ld hl,bootstrap_rom
                ld de,bootstrap_ram
                ld bc,rom_size
                ldir

                ; select normal memory mode
                ld a,mode_normal
                out (mode_port),a

                ; put the stack at the top of RAM
                ld sp,0

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
                call sioini
                call conini

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
                ; RST $0 will jump to the reset spin
                ; (since software reset isn't working properly yet)
                ld hl,$0
                ld (hl),$c3
                inc hl
                ld (hl),low reset_spin
                inc hl
                ld (hl),high reset_spin

                ; RST $8 through RST $20 default to no-op
                ld hl,$8
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

        ;---------------------------------------------------------------
        ; Spin forever with alternating LEDs on RST $0 or otherwise 
        ; ending up with PC=$0000.
        ;
reset_spin:     
                di
                ld c,a
reset_spin_10:
                ld a,c
                out (gpio_port),a
                xor 3
                ld c,a
reset_spin_20:
                inc hl
                ld a,l
                or h
                jr nz,reset_spin_20
                jr reset_spin_10

                .end

