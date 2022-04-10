        ;---------------------------------------------------------------
        ; Serial Peripheral Interface module
        ;
        ; The Serial Peripheral Interface (SPI) is a de-facto standard
        ; four-wire interface used to communicate with peripheral
        ; devices. This module supports SPI mode 0 (CPOL=0, CPHA=0).
        ;
        ; SPI data lines are connected to the GPIO interface as follows:
        ;       D7 - MOSI
        ;       D6 - SCLK
        ;       D0 - MISO
        ;
        ; SPI peripherals are selected by writing an address to a 3-bit
        ; register addressed as the spi_addr_port (see ports.asm). Bits
        ; D1..D0 of the address are used to select one of four
        ; peripheral devices. Bit D7 is used as an inhibit bit. If this
        ; bit is set in the address value, no SPI peripheral device
        ; will have its chip select (CS) input asserted. This allows
        ; the GPIO pins used for mosi and SCLK to be used for other
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
mosi            .equ $80

bit_sclk        .equ 6
bit_mosi        .equ 7

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

                ; Pull MOSI and SCLK low before chip select.
                ; This allows peripherals that automatically choose SPI mode
                ; to determine the clock polarity.
                ld a,(gpout)
                and low ~(mosi|sclk)
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
                and mosi                ; mosi = bit to send, others zero
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; mosi = output bit, SCLK = low
                or sclk
                out (gpio_port),a       ; mosi = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rra                     ; carry bit = MISO
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

                ; Pull MOSI and SCLK low before chip select.
                ; This allows peripherals that automatically choose SPI mode
                ; to determine the clock polarity
                ld a,(gpout)
                and low ~(mosi|sclk)
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
                and mosi
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; mosi = output bit, SCLK = low
                or sclk
                out (gpio_port),a       ; mosi = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rra                     ; carry bit = MISO
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
        ; spi8x: 
        ; Exchanges a block of 8-bit values with a peripheral via SPI.
        ; Bits are exchanged in most signficant bit first order.
        ;
        ; On entry:
        ;       B = number of bytes to exchange (1..256)
        ;       C = bit-packed options
        ;               D7 - CPOL
        ;               D6 - CPHA
        ;               D5..D3 - don't care
        ;               D2..D0 - SPI peripheral address
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

                ; Pull MOSI low and set SCLK according to CPOL before chip 
                ; select. This allows peripherals that support it to automatically 
                ; detect the polarity.
                ld a,c
                rla
                ld a,(gpout)
                jr c,spi8x_10
                and low ~(mosi|sclk)
                jr spi8x_20                

spi8x_10:
                and low ~mosi
                or sclk
spi8x_20:
                out (gpio_port),a
                and low ~(mosi|sclk)    ; keep bits other than MOSI and SCLK

                ; Select the specified SPI peripheral by address
                ld d,c                  ; preserve peripheral address
                ld c,a                  ; preserve GPIO output bit mask
                ld a,d                  ; recover peripheral address
                and 7                   ; address is only 3 bits
                or cs                   ; set chip select bit
                out (spi_addr_port),a   ; select SPI peripheral

                ld a,d                  ; get option bit mask
                rla                     ; set carry to CPOL bit
                jp c,spi8x_mode23       ; CPOL=1 => modes 2 and 3
                rla                     ; set carry to CPHA bit
                jp c,spi8x_mode1        ; CPHA=1 => mode 1

                ;-------------------------------------------------------
                ; SPI mode 0 (CPOL=0, CPHA=0)
                ;
spi8x_mode0:
spi8x_mode0_next:
                ld d,b                  ; preserve number of bytes
                ld b,8                  ; transmit and receive 8 bits
spi8x_mode0_bit:
                rl (hl)                 ; get next transmit bit into carry
                rra                     ; get bit to send from carry
                and mosi                ; keep only the MOSI bit
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; MOSI = output bit, SCLK = low
                or sclk
                out (gpio_port),a       ; MOSI = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rra                     ; carry bit = MISO

                djnz spi8x_mode0_bit

                ld a,c
                out (gpio_port),a       ; SCLK = low, other GPIO bits unchanged

                ; rotate in final received bit
                rl (hl)

                inc hl                  ; next buffer position
                ld b,d                  ; recover byte count
                djnz spi8x_mode0_next
                jp spi8x_done

                ;-------------------------------------------------------
                ; SPI mode 1 (CPOL=0, CPHA=1)
spi8x_mode1:
spi8x_mode1_next:
                ld d,b                  ; preserve number of bytes
                ld b,8                  ; transmit and receive 8 bits
spi8x_mode1_bit:
                ld a,c                  ; get GPIO bits
                set bit_sclk,a          ; set SCLK bit without affecting carry
                out (gpio_port),a       ; SCLK = high
                rl (hl)                 ; get next transmit bit into carry
                rra                     ; get bit to send from carry
                and mosi
                or c                    ; mask in GPIO bits
                out (gpio_port),a       ; MOSI = output bit, SCLK = low        
                in a,(gpio_port)        ; read MISO while clock is low
                rra                     ; carry bit = MISO
                djnz spi8x_mode1_bit

                rl (hl)                 ; rotate in last received bit
                inc hl                  ; next buffer position
                ld b,d                  ; recover byte count
                djnz spi8x_mode1_next
                jp spi8x_done

spi8x_mode23:
                rla                     ; set carry to CPHA bit
                jp c,spi8x_mode3        ; CPHA=1 => mode 3


                ; SPI mode 2 (CPOL=1, CPHA=0)
spi8x_mode2:
                ; get GPIO output bits other than MOSI and SCLK
                ld a,(gpout)
                and low ~(mosi|sclk)
                ld c,a                  ; save output bits
spi8x_mode2_next:
                ld d,b                  ; preserve number of bytes
                ld b,8                  ; transmit and receive 8 bits
spi8x_mode2_bit:
                rl (hl)                 ; get next transmit bit into carry
                rra                     ; get bit to send from carry
                and mosi
                or sclk
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; MOSI = output bit, SCLK = high
                and ~sclk
                out (gpio_port),a       ; MOSI = output bit, SCLK = low
                in a,(gpio_port)        ; read MISO
                rra                     ; carry bit = MISO
                djnz spi8x_mode2_bit

                ; rotate in last received bit
                rl (hl)

                ld a,c
                or sclk
                out (gpio_port),a       ; SCLK = high, other GPIO bits unchanged

                inc hl                  ; next buffer position
                ld b,d                  ; recover byte count
                djnz spi8x_mode2_next
                jp spi8x_done

                ; SPI mode 3 (CPOL=1, CPHA=1)
spi8x_mode3:
                ; get GPIO output bits other than MOSI and SCLK
                ld a,(gpout)
                and low ~(mosi|sclk)
                ld c,a                  ; save output bits
spi8x_mode3_next:
                ld d,b                  ; preserve number of bytes
                ld b,8                  ; transmit and receive 8 bits
spi8x_mode3_bit:
                ld a,c
                out (gpio_port),a       ; SCLK = low

                ; get next transmit bit into carry
                rl (hl)
                rra                     ; get bit to send from carry
                and mosi
                or sclk
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; MOSI = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rra                     ; carry bit = MISO
                djnz spi8x_mode3_bit

                ld a,c
                or sclk
                out (gpio_port),a       ; SCLK = high, other GPIO bits unchanged

                ; rotate in last received bit
                rl (hl)

                inc hl                  ; next buffer position
                ld b,d                  ; recover byte count
                djnz spi8x_mode3

spi8x_done:
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
