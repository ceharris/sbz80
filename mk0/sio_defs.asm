        ;---------------------------------------------------------------
        ; Definitions for the Z80 SIO
        ;---------------------------------------------------------------

sio_port_a              .equ 0
sio_port_b              .equ 1
sio_cfg                 .equ 2

sio_reg0                .equ 0
sio_reg1                .equ 1
sio_reg2                .equ 2
sio_reg3                .equ 3
sio_reg4                .equ 4
sio_reg5                .equ 5
sio_reg6                .equ 6
sio_reg7                .equ 7

; Write Register 0 Commands
sio_send_sdlc_abort     .equ $08
sio_reset_ext_stat_int  .equ $10
sio_channel_reset       .equ $18
sio_ei_next_rx_char     .equ $20
sio_reset_tx_int        .equ $28
sio_error_reset         .equ $30
sio_reti                .equ $38

; Write Register 0 Reset Codes
sio_reset_rx_crc        .equ $40
sio_reset_tx_crc        .equ $80
sio_reset_tx_underrun   .equ $c0

; Write Register 1 Bits
sio_wrdy_enable         .equ $80
sio_wrdy_function       .equ $40
sio_wrdy_on_rx_tx       .equ $20
sio_rx_int_disable      .equ $00
sio_rx_int_first        .equ $08
sio_rx_int_parity_ok    .equ $10
sio_rx_int_all          .equ $18
sio_vector_by_status    .equ $04
sio_tx_int_enable       .equ $02
sio_ext_int_enable      .equ $01

; Write Register 3 Bits
sio_rx_8bits            .equ $c0
sio_rx_6bits            .equ $80
sio_rx_7bits            .equ $40
sio_rx_5bits            .equ $00
sio_rx_auto_enables     .equ $20
sio_rx_enter_hunt       .equ $10
sio_rx_crc_enable       .equ $08
sio_rx_search_mode      .equ $04
sio_sync_load_inhibit   .equ $02
sio_rx_enable           .equ $01

; Write Register 4 Bits
sio_clock_x64           .equ $c0
sio_clock_x32           .equ $80
sio_clock_x16           .equ $40
sio_clock_x1            .equ $00
sio_ext_sync_mode       .equ $30
sio_sdlc_mode           .equ $20
sio_sync_16bit_char     .equ $10
sio_sync_8bit_char      .equ $00
sio_stop_2bits          .equ $0c
sio_stop_15bits         .equ $08
sio_stop_1bit           .equ $04
sio_sync_mode           .equ $00
sio_parity_odd          .equ $03
sio_parity_even         .equ $01
sio_parity_none         .equ $00

; Write Register 5 Bits
sio_dtr                 .equ $80
sio_tx_8bits            .equ $60
sio_tx_6bits            .equ $40
sio_tx_7bits            .equ $20
sio_tx_5bits            .equ $00
sio_send_break          .equ $10
sio_tx_enable           .equ $08
sio_sdlc_crc16          .equ $04
sio_rts                 .equ $02
sio_tx_crc_enable       .equ $01

; Read Register 0 Bits
sio_break_abort         .equ $80
sio_tx_underrun         .equ $40
sio_cts                 .equ $20
sio_sync_hunt           .equ $10
sio_dcd                 .equ $08
sio_tx_buffer_empty     .equ $04
sio_int_pending         .equ $02
sio_rx_char_available   .equ $01

; Read Register 1 Bits
sio_sdlc_end_of_frame   .equ $80
sio_crc_framing_error   .equ $40
sio_rx_overrun_error    .equ $20
sio_parity_error        .equ $10
sio_residue_code2       .equ $08
sio_residue_code1       .equ $04
sio_residue_code0       .equ $02
sio_all_sent            .equ $01



