        ;---------------------------------------------------------------
        ; Analog-to-Digital Conversion Support
        ;
        ; There are two ADC units in the system.
        ; 
        ; Unit adc0 is a Maxim 118 8-channel 8-bit ADC with single-ended
        ; inputs referenced to the +5V power supply. This ADC has a
        ; parallel bus interface, allowing any of its inputs to be read 
        ; using an IN instruction that addresses the intended channel.
        ; See channel channel definitions beow.
        ;
        ; Unit adc1 is a Microchip 3008 8/4-channel 10-bit ADC. Each 
        ; pair of channels can be used as either two independent single-
        ; ended input or as a differential input pair. This ADC is
        ; connected via the SPI interface, and therefore requires a 
        ; call to the supervisor to read any of its inputs.
        ;----------------------------------------------------------------


adc0_ch0        .equ adc0_base+0        
adc0_ch1        .equ adc0_base+1
adc0_ch2        .equ adc0_base+2
adc0_ch3        .equ adc0_base+3
adc0_ch4        .equ adc0_base+4
adc0_ch5        .equ adc0_base+5
adc0_ch6        .equ adc0_base+6
adc0_ch7        .equ adc0_base+7        ; reports the fixed reference voltage
