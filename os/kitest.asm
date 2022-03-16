

                .aseg
                .org $0

                ld sp,$e000
                call kiinit

                ; press right control
                ld a,$e0
                out ($d0),a
                call kiisr
                ld a,$14
                out ($d0),a
                call kiisr

                ; press A
                ld a,$1c
                out ($d0),a
                call kiisr

                ; release A
                ld a,$f0
                out ($d0),a
                call kiisr
                ld a,$1c
                out ($d0),a
                call kiisr

                ; release right shift
                ld a,$e0
                out ($d0),a
                call kiisr
                ld a,$f0
                out ($d0),a
                call kiisr
                ld a,$14
                out ($d0),a
                call kiisr

loop:
                jp loop

                .org $e000
                .include ki.asm

                .end