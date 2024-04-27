                #include "machine.h.asm"

                section CODE_LOMEM
                extern  init
                extern  acia_isr

rst_0:
                call init
rst_8:
                align 8
                ret
rst_10:
                align 8
                ret
rst_18:
                align 8
                ret
rst_20:
                align 8
                ret
rst_28:
                align 8
                ret
rst_30:
                align 8
                ret
rst_38:
                align 8
                jp acia_isr
