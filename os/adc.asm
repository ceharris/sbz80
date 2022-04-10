        ;---------------------------------------------------------------
        ; Analog-to-Digital Conversion Support
        ;
        ; There are two ADC units in the system.
        ; 
        ; Unit adc0 is a Maxim 118 8-channel 8-bit ADC with single-ended
        ; inputs referenced to the +5V power supply. This ADC has a
        ; parallel bus interface, allowing any of its inputs to be read 
        ; using an IN instruction that addresses the intended channel.
        ; See channel definitions in adc_defs.asm.
        ;
        ; Unit adc1 is a Microchip 3008 8/4-channel 10-bit ADC. Each 
        ; pair of channels can be used as either two independent single-
        ; ended inputs or as a differential input pair. This ADC is
        ; connected via the SPI interface, and therefore requires a 
        ; call to the supervisor to read any of its inputs.
        ;----------------------------------------------------------------

                .name adc

                .extern spi8x

                .include ports.asm
                .include adc_defs.asm
                .include spi_defs.asm

buf_size        .equ 3

                .cseg

        ;---------------------------------------------------------------
        ; adcrd:
        ; Performs a conversion on a single-ended channel or differential
        ; channel pair and returns 10-bit result.
        ;
        ; On entry:
        ;       C = channel
        ;               0 = single-ended ch 0
        ;               1 = single-ended ch 1
        ;               ...
        ;               7 = single-ended ch 7
        ;               8 = differential pair ch 0 (+IN) and ch 1 (-IN)
        ;               9 = differential pair ch 0 (-IN) and ch 1 (+IN)
        ;               10 = differential pair ch 2 (+IN) and ch 3 (-IN)
        ;               11 = differential pair ch 2 (-IN) and ch 3 (+IN)
        ;               ...
        ;               15 = differential pair ch 6 (-IN) and ch 7 (+IN)
        ;
        ; On return:
        ;       HL = 10-bit conversion result
        ;
adcrd::
                push bc
                ex de,hl
                push hl                 ; save caller's DE
                ; use HL as a stack frame pointer for local buffer
                ld hl,-buf_size
                add hl,sp
                ld sp,hl

                ld a,c                  ; get channel and mode
                rlca
                rlca
                rlca
                rlca

                ld (hl),00000001b       ; start bit
                inc hl
                ld (hl),a               ; set channel and mode
                dec hl

                ld b,3                  ; transfer 3 bytes
                ld c,spi_adc            ; ADC address on SPI bus
                call spi8x      
                dec hl
                ld e,(hl)               ; get least significant bits
                dec hl  
                ld a,(hl)               ; get most signficant bits
                and $03                 ; only two of them are significant
                ld d,a                  ; DE = 10-bit channel reading

                ; remove stack frame
                ld hl,buf_size
                add hl,sp
                ld sp,hl
                pop hl                  ; restore caller's DE as HL
                ex de,hl                ;   and put return value in HL        
                pop bc  
                ret


                .end
