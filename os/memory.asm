
        ;---------------------------------------------------------------
        ; Memory definitions
        ; 
        ; After system reset, the bootstrap memory mode is automatically
        ; selected by the hardware. In this mode, the ROM is selected for
        ; all memory accesses (by effectively ignoring A15..A13). Once 
        ; the normal memory mode is selected (by configuring the mode 
        ; port), the memory address space is divided as follows.
        ;
        ;       $0000..DFFF     RAM
        ;       $E000..FFFF     ROM
        ;---------------------------------------------------------------

        ; These definitions are used to set the memory mode register

mode_normal     .equ 0
mode_bootstrap  .equ $80

        ; Define the address ranges for RAM and ROM when in normal mode
ram_top         .equ $e000
rom_top         .equ $10000

        ;---------------------------------------------------------------
        ; System variables
        ; Resserved system memory space is $0000..0100. This file
        ; defines constants for the offset of each variable.
        ;
        ; Z80 restart vectors use address $0000..$003f
        ; We place other system variables just above, so that
        ; we have full use of the RST instructions.

rst_vec         .equ 0
rst_vec_size    .equ 64
isrtab          .equ rst_vec+rst_vec_size       ; interrupt vector table
isrtab_size     .equ 32                
kiring          .equ isrtab+isrtab_size         ; keyboard input ring
kiring_size     .equ 16
kihead          .equ kiring+kiring_size         ; keyboard ring head pointer
kihead_size     .equ 2
kitail          .equ kihead+kihead_size         ; keyboard ring tail pointer
kitail_size     .equ 2
kibat           .equ kitail+kitail_size         ; keyboard BAT code
kibat_size      .equ 1
kiflag          .equ kibat+kibat_size           ; keyboard flags
kiflag_size     .equ 1
kimod           .equ kiflag+kiflag_size         ; keyboard modifiers
kimod_size      .equ 1                          
gpin            .equ kimod+kimod_size           ; GPIO input register state
gpin_size       .equ 1
gpout           .equ gpin+gpin_size             ; GPIO output register state
gpout_size      .equ 1
tkflag          .equ gpout+gpout_size           ; tick flags
tkflag_size     .equ 1
tkcnt           .equ tkflag+tkcnt_size          ; tick counter (32 bits)
tkcnt_size      .equ 4          
