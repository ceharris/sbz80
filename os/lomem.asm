
        ;---------------------------------------------------------------
        ; System variables
        ; Resserved system memory space is $0000..0100. This file
        ; defines constants for the offset of each variable.
        ;---------------------------------------------------------------

                ; Z80 restart vectors use address $0000..$003f
                ; We place other system variables just above, so that
                ; we have full use of the RST instructions.

rst_vec         .equ 0
rst_vec_size    .equ $40
isrtab          .equ rst_vec+rst_vec_size       ; interrupt vector table
istab_size      .equ 16                
kiring          .equ isrtab+isrtab_size         ; keyboard input ring
kiring_size     .equ 16
kihead          .equ kiring+kiring_len          ; keyboard ring head pointer
kihead_size     .equ 2
kitail          .equ kihead+kihead_size         ; keyboard ring tail pointer
kitail_size     .equ 2
kibat           .equ kitail+kitail_size         ; keyboard BAT code
kibat_size      .equ 1
kiflag          .equ kibat+kibat_size           ; keyboard flags
kiflag_size     .equ 1
kimod           .equ kiflag+kiflag_size         ; keyboard modifiers
kimod_size      .equ 1                          
gpout           .equ kimod+kimod_size           ; GPIO output register state
gpout_zie       .equ 1
tkcnt           .equ gpout+gpout_size           ; tick counter
tkcnt_size      .equ 4          
