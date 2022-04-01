
        ;---------------------------------------------------------------
        ; Memory definitions
        ;
        ; After system reset, the bootstrap memory mode is automatically
        ; selected by the hardware. In this mode, the ROM is selected for
        ; address $0000..7FFF and RAM is selected for $8000..FFFF. When
        ; the normal mode is selected, the 32K bank at address $8000 is 
        ; relocated to $0000..FFFF and another 32K bank is addressable
        ; at $8000..FFFF.
        ; 
        ; In the bootstrap mode, the contents of the ROM can be copied
        ; to RAM. After switching to normal mode, execution of the ROM-
        ; based program continues in RAM.
        ;---------------------------------------------------------------

        ; These definitions are used to set the memory mode register
        ;
mode_bootstrap          .equ 0
mode_normal             .equ $80

        ; Bootstrap memory mode configuration
        ;
bootstrap_rom           .equ $0000
bootstrap_ram           .equ $8000
rom_size                .equ 8192

        ; Sizes of low memory structures
        ;
isrtab_size             .equ 32                 ; Z80 interrupt mode 2 vector table      
kiring_size             .equ 16                 ; keyboard input ring
tkcnt_size              .equ 4                  ; tick counter

consin_size             .equ 256                ; Console input line buffer
sio_a_tx_size           .equ 64                 ; SIO port A tx buffer size
sio_rx_size             .equ 256                ; SIO receive buffer size

