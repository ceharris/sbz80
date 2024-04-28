        ;---------------------------------------------------------------
        ; PIO 0: Keyboard and LCD Display
        ;
        ; The keyboard interface is connected to port A and is designed
        ; to use PIO mode 1. Input data from the keyboard is strobed into
        ; the port whenever the port A is ready (ARDY asserted), generating
        ; an interrupt that will invoke the corresponding service routine
        ; to read the input.
        ;
        ; The LCD display is conneted to port B and is designed to use
        ; PIO mode 3. The LCD controller is the defacto standard Hitachi
        ; HD44780U operated in 4-bit interface mode. The four data lines
        ; from the LCD controller are connected to the least significant
        ; bits port B (PB0-PB3). The control signals for the LCD controller
        ; are connected as follows.
        ;
        ; PB4 -- LCD controller E signal
        ; PB5 -- LCD controller RS singal
        ; PB6 -- (available)
        ; PB7 -- (available)
        ;
        ; Note that the LCD controller's RW signal is not connected to the
        ; PIO. As a result, the LCD driver must insert a delay after each
        ; command to allow the controller sufficient time to complete each
        ; requested operation. Also, because no read operations are
        ; perfomed each of PIO pins PB5..PB0 will be used as outputs.


                .name pio

                .extern isrtab

                .include memory.asm
                .include ports.asm
                .include isr.asm
                .include pio_defs.asm

                .cseg
pioini::
                ; PIO 0 port A will use mode 1
                ld a,pio_mode1
                out (pio0_base+pio_port_a+pio_cfg),a

                ; set PIO 0 port A interrupt vector
                ld a,isrtab+isr_pio0_a
                out (pio0_base+pio_port_a+pio_cfg),a

                ; disable PIO 0 port A interrupts
                ld a,pio_ictl_di+pio_ictl_word
                out (pio0_base+pio_port_a+pio_cfg),a

                ; PIO 0 port B will use mode 3
                ld a,pio_mode3
                out (pio0_base+pio_port_b+pio_cfg),a

                ; set PIO 0 port B PB7..PB0 as outputs
                xor a
                out (pio0_base+pio_port_b+pio_cfg),a

                ; disable PIO 0 port B interrupts
                ld a,pio_ictl_di+pio_ictl_word
                out (pio0_base+pio_port_b+pio_cfg),a

                ; PIO 1 port A will use mode 3
                ld a,pio_mode3
                out (pio1_base+pio_port_a+pio_cfg),a

                ; set PIO 1 port A PA7..PA0 as outputs
                xor a
                out (pio1_base+pio_port_a+pio_cfg),a

                ; disable PIO 1 port A interrupts
                ld a,pio_ictl_di+pio_ictl_word
                out (pio1_base+pio_port_A+pio_cfg),a

                ; PIO 1 port B will use mode 3
                ld a,pio_mode3
                out (pio1_base+pio_port_b+pio_cfg),a

                ; set PIO 1 port B PB7..PB0 as outputs
                xor a
                out (pio1_base+pio_port_b+pio_cfg),a

                ; disable PIO 1 port B interrupts
                ld a,pio_ictl_di+pio_ictl_word
                out (pio1_base+pio_port_b+pio_cfg),a

                ret



