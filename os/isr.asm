

        ;--------------------------------------------------------------
        ; Interrupt vector definitions
        ; 
        ; The number of vectors defined here must not exceed the size
        ; of the vector table specified in sysvar.asm.
        ;--------------------------------------------------------------

isr_ctc0_ch0            .equ 0
isr_ctc0_ch1            .equ 2
isr_ctc0_ch2            .equ 4
isr_ctc0_ch3            .equ 6                  ; timer tick

isr_pio0_a              .equ 8                  ; keyboard input
isr_pio0_b              .equ 10
isr_pio1_a              .equ 12
isr_pio1_b              .equ 14

isr_sio0_b_txrdy        .equ 16                 ; port B transmit ready
isr_sio0_b_status       .equ 18                 ; port B status change
isr_sio0_b_rxrdy        .equ 20                 ; port B receiver ready
isr_sio0_b_error        .equ 22                 ; port B error condition
isr_sio0_a_txrdy        .equ 24                 ; port A transmit ready
isr_sio0_a_status       .equ 26                 ; port A status change
isr_sio0_a_rxrdy        .equ 28                 ; port A receiver ready
isr_sio0_a_error        .equ 30                 ; port A error condition


; if adding more vectors, be sure to resize vector table in memory.asm


