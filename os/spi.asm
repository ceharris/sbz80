        ;---------------------------------------------------------------
        ; Serial Peripheral Interface module
        ;
        ; The Serial Peripheral Interface (SPI) is a de-facto standard
        ; four-wire interface used to communicate with peripheral
        ; devices. This module supports SPI mode 0 (CPOL=0, CPHA=0).
        ;
        ; The sdata and sdata signals are connected to bit D7 of the GPIO
        ; interface. The SCLK signal is connected to bit D6 (output only).
        ;
        ; SPI peripherals are selected by writing an address to a 3-bit
        ; register addressed as the spi_addr_port (see ports.asm). Bits
        ; D1..D0 of the address are used to select one of four
        ; peripheral devices. Bit D7 is used as an inhibit bit. If this
        ; bit is set in the address value, no SPI peripheral device
        ; will have its chip select (CS) input asserted. This allows
        ; the GPIO pins used for sdata and SCLK to be used for other
        ; purposes without inadvertently signalling an SPI device.
        ;
        ; See spi_defs.asm for SPI peripheral address assignments
        ;---------------------------------------------------------------


                .name spi

                .extern gpout

                .include memory.asm
                .include ports.asm

cs              .equ $08
sclk            .equ $40
sdata           .equ $80

                .cseg

        ;---------------------------------------------------------------
        ; Exchanges an 8-bit value with a peripheral via SPI.
        ; Bits are sent in most-significant-bit-first order.
        ;
        ; On entry:
        ;       C = SPI peripheral address
        ;       E = 8-bit value to transmit to peripheral
        ;
        ; On return:
        ;       E = 8-bit value received from peripheral
        ;       AF destroyed
        ;
spi8::
                push bc

                ; Pull SDATA and SCLK low before chip select.
                ; This allows peripherals that automatically choose SPI mode
                ; to determine the clock polarity.
                ld a,(gpout)
                and low ~(sdata|sclk)
                out (gpio_port),a

                ; Select the specified SPI peripheral by address
                ld b,c                  ; preserve peripheral address
                ld c,a                  ; preserve GPIO output bit mask
                ld a,b                  ; recover peripheral address
                or cs                   ; set chip select bit
                out (spi_addr_port),a   ; select SPI peripheral

                ; Will transmit and receive 8 bits
                ld b,8
spi8_10:
                ; get next transmit bit into carry
                rl e

                ; send and receive one bit
                rra                     ; get bit to send from carry
                and sdata               ; sdata = bit to send, others zero
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; sdata = output bit, SCLK = low
                or sclk
                out (gpio_port),a       ; sdata = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rla                     ; carry bit = MISO
                ld a,c
                out (gpio_port),a       ; SCLK = low, other GPIO bits unchanged
                djnz spi8_10

                ; rotate in last received bit
                rl e

                ; Deselect SPI peripheral
                xor a
                out (spi_addr_port),a

                ; Restore all GPIO outputs
                ld a,(gpout)
                out (gpio_port),a

                pop bc
                ret


        ;---------------------------------------------------------------
        ; Exchanges a 16-bit value with a peripheral via SPI.
        ; Bits are sent in most-significant-bit-first order.
        ;
        ; On entry:
        ;       C = SPI peripheral address
        ;       DE = 16-bit value to transmit to peripheral
        ;
        ; On return:
        ;       DE = 16-bit value received from peripheral
        ;       AF destroyed
spi16::
                push bc

                ; Pull SDATA and SCLK low before chip select.
                ; This allows peripherals that automatically choose SPI mode
                ; to determine the clock polarity
                ld a,(gpout)
                and low ~(sdata|sclk)
                out (gpio_port),a

                ; Select the specified SPI peripheral by address
                ld b,c                  ; preserve peripheral address
                ld c,a                  ; preserve GPIO output bit mask
                ld a,b                  ; recover peripheral address
                or cs                   ; set chip select bit
                out (spi_addr_port),a   ; select SPI peripheral

                ; Will transmit and receive 16 bits
                ld b,16
spi16_10:
                ; get next transmit bit into carry
                rl e
                rl d

                ; send and receive one bit
                rra                     ; get bit to send from carry
                and sdata               ; sdata = bit to send, others zero
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; sdata = output bit, SCLK = low
                or sclk
                out (gpio_port),a       ; sdata = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rla                     ; carry bit = MISO
                ld a,c
                out (gpio_port),a       ; SCLK = low, other GPIO bits unchanged
                djnz spi16_10

                ; rotate in last received bit
                rl e
                rl d

                ; Delect SPI peripheral
                xor a
                out (spi_addr_port),a

                ; Restore all GPIO outputs
                ld a,(gpout)
                out (gpio_port),a

                pop bc
                ret


        ;---------------------------------------------------------------
        ; Exchanges a block of 8-bit values with a peripheral via SPI.
        ; Bits are set in most signficant bit first order.
        ;
        ; On entry:
        ;       B = number of bytes to exchange (1..256)
        ;       C = SPI peripheral address
        ;       HL = pointer to 8-bit values to transmit
        ;
        ; On return:
        ;       HL = entry HL + B
        ;       [HL-B..HL] = received 8-bit values
        ;       AF destroyed
        ;
spi8x::
                push bc
                push de

                ; Pull sdata and SCLK low before chip select.
                ; This allows peripherals that automatically choose SPI mode
                ; to determine the clock polarity.
                ld a,(gpout)
                and low ~(sdata|sclk)
                out (gpio_port),a

                ; Select the specified SPI peripheral by address
                ld d,c                  ; preserve peripheral address
                ld c,a                  ; preserve GPIO output bit mask
                ld a,d                  ; recover peripheral address
                or cs                   ; set chip select bit
                out (spi_addr_port),a   ; select SPI peripheral

spi8x_10:
                ld d,b                  ; preserve number of bytes
                ld b,8                  ; transmit and receive 8 bits
spi8x_20:
                ; get next transmit bit into carry
                rl (hl)

                ; send and receive one bit
                rra                     ; get bit to send from carry
                and sdata               ; sdata = bit to send, others zero
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; sdata = output bit, SCLK = low
                or sclk
                out (gpio_port),a       ; sdata = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rla                     ; carry bit = MISO
                ld a,c
                out (gpio_port),a       ; SCLK = low, other GPIO bits unchanged
                djnz spi8x_20

                ; rotate in last received bit
                rl (hl)

                inc hl
                ld b,d                  ; recover byte count
                djnz spi8x_10

                ; Deselect SPI peripheral
                xor a
                out (spi_addr_port),a

                ; Restore all GPIO outputs
                ld a,(gpout)
                out (gpio_port),a

                pop de
                pop bc
                ret


                .end
