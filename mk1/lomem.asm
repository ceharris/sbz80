                #include "machine.h.asm"

                section CODE_LOMEM
                extern  init
                extern  acia_isr
                extern  acia_putc
                extern  acia_getc
                extern  acia_getcnb

rst_0:
                call init
rst_8:
                align 8
                jp acia_putc
rst_10:
                align 8
                jp acia_getc
rst_18:
                align 8
                jp acia_getcnb
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
