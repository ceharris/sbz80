
        ;---------------------------------------------------------------
        ; CTC: Base timer support
        ;
        ; The CTC provides four channels of timer/counter support.
        ; Channels 1 and 2 are used to provide the transceiver clocks
        ; for the SIO. Channel 3 is used for the system timer tick
        ; (see tk.asm). Channel 0 is unassigned and may be used to
        ; provide precise timing for user programs.
        ;---------------------------------------------------------------

                .name ctc

                .extern isrtab
                
                .include memory.asm
                .include ports.asm
                .include isr.asm
                .include ctc_defs.asm

                .cseg

ctcini::
                ; Set the ctc0 interrupt vector (all channels)
                ld a,isrtab+isr_ctc0_ch0
                out (ctc0_ch0),a

                ; configure defaults for ctc0 (all channels)
                ld a,ctc_default
                out (ctc0_ch0),a
                out (ctc0_ch1),a
                out (ctc0_ch2),a
                out (ctc0_ch3),a

                ret
