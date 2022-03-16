
                .org 0

gpout           .equ $4000

spi_buf         .equ $4008

gpio_port       .equ $f0
spi_cs_port     .equ $f8
sclk            .equ $40
mosi            .equ $80

                
                ld sp,0
                ld a,$01
                ld (gpout),a
                out (gpio_port),a

loop:
                ld hl,$010f
                ld (spi_buf),hl
                ld bc,$0200
                ld hl,spi_buf
                call spi8x

                ld de,0
                call delay

                ; normal display
                ld hl,$000f
                ld (spi_buf),hl
                ld bc,$0200
                ld hl,spi_buf
                call spi8x

                ld de,0
                call delay

                ld a,(gpout)
                xor $3
                ld (gpout),a
                out (gpio_port),a

                jp loop

delay:
                dec de
                ld a,e
                or d
                jp nz,delay
                ret

        ;---------------------------------------------------------------
        ; Exchanges an 8-bit value with a peripheral via SPI.
        ; Bits are sent in most-significant-bit-first order.
        ;
        ; On entry:
        ;       C = SPI peripheral address (0-127)
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
                out (spi_cs_port),a     ; select SPI peripheral

                ; Will transmit and receive 8 bits
                ld b,8
spi8_10:
                ; get next transmit bit into carry
                rl e                   

                ; send and receive one bit
                rra                     ; get bit to send from carry
                and mosi                ; MOSI = bit to send, others zero
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; MOSI = output bit, SCLK = low
                or sclk                 
                out (gpio_port),a       ; MOSI = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rla                     ; carry bit = MISO
                ld a,c                  
                out (gpio_port),a       ; SCLK = low, other GPIO bits unchanged
                djnz spi8_10

                ; rotate in last received bit
                rl e                    

                ; Deselect SPI peripheral
                ld a,$ff
                out (spi_cs_port),a

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
        ;       C = SPI peripheral address (0-127)
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
                out (spi_cs_port),a     ; select SPI peripheral

                ; Will transmit and receive 16 bits
                ld b,16
spi16_10:
                ; get next transmit bit into carry
                rl e                   
                rl d

                ; send and receive one bit
                rra                     ; get bit to send from carry
                and mosi                ; MOSI = bit to send, others zero
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; MOSI = output bit, SCLK = low
                or sclk                 
                out (gpio_port),a       ; MOSI = output bit, SCLK = high
                in a,(gpio_port)        ; read MISO
                rla                     ; carry bit = MISO
                ld a,c                  
                out (gpio_port),a       ; SCLK = low, other GPIO bits unchanged
                djnz spi16_10

                ; rotate in last received bit
                rl e                    
                rl d

                ; Delect SPI peripheral
                ld a,$ff
                out (spi_cs_port),a

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
        ;       C = SPI peripheral address (0-127)
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

                ; Pull MOSI and SCLK low before chip select.
                ; This allows peripherals that automatically choose SPI mode 
                ; to determine the clock polarity.
                ld a,(gpout)
                and low ~(mosi|sclk)
                out (gpio_port),a

                ; Select the specified SPI peripheral by address
                ld d,c                  ; preserve peripheral address
                ld c,a                  ; preserve GPIO output bit mask
                ld a,d                  ; recover peripheral address
                out (spi_cs_port),a     ; select SPI peripheral

spi8x_10:
                ld d,b                  ; preserve number of bytes
                ld b,8                  ; transmit and receive 8 bits
spi8x_20:
                ; get next transmit bit into carry
                rl (hl)                  

                ; send and receive one bit
                rra                     ; get bit to send from carry
                and mosi                ; MOSI = bit to send, others zero
                or c                    ; mask in GPIO bits other than SCLK
                out (gpio_port),a       ; MOSI = output bit, SCLK = low
                or sclk                 
                out (gpio_port),a       ; MOSI = output bit, SCLK = high
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
                ld a,$ff
                out (spi_cs_port),a

                ; Restore all GPIO outputs
                ld a,(gpout)
                out (gpio_port),a
                
                pop de
                pop bc
                ret


                .end
