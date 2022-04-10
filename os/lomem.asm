
        ;---------------------------------------------------------------
        ; System variables
        ; Resserved system memory space is $0000..0100. This file
        ; defines constants for the offset of each variable.
        ;---------------------------------------------------------------

                .name lomem

                .extern init

                .include memory.asm

                .aseg

                .org 0
                jp init


                .org $40
isrtab::        ds isrtab_size          ; ISR vector table

        ; keyboard
kiring::        ds kiring_size          ; keyboard ring buffer
kihead::        ds 2                    ; keyboard ring head pointer
kitail::        ds 2                    ; keyboard ring tail pointer
kibat::         ds 1                    ; keyboard BAT code
kiflag::        ds 1                    ; keyboard flags
kimod::         ds 1                    ; keyboard modifiers
        
        ; GPIO register masks
gpin::          ds 1                    ; GPIO input port image
gpout::         ds 1                    ; GPIO output port image

        ; tick counter
tkflag::        ds 1                    ; tick counter flags
tkcnt::         ds tkcnt_size           ; tick counter

        ; SIO port A
sacfg::         ds 1                    ; configuration bitmap
sawr5::         ds 1                    ; WR 5 mask
sarr0::         ds 1                    ; RR 0 at last tx status interrupt
sarr1::         ds 1                    ; RR 1 at last rx error interrupt
satxc::         ds 1                    ; num chars waiting in tx buf
sarxc::         ds 1                    ; num chars waiting in rx buf
satxh::         ds 2                    ; tx buffer head pointer
satxt::         ds 2                    ; tx buffer tail pointer
sarxh::         ds 2                    ; rx buffer head pointer
sarxt::         ds 2                    ; rx buffer tail pointer

        ; SIO port B
sbcfg::         ds 1                    ; configuration bitmap
sbwr5::         ds 1                    ; WR 5 mask
sbrr0::         ds 1                    ; RR 0 at last tx status interrupt
sbrr1::         ds 1                    ; RR 1 at last rx error interrupt
sbtxc::         ds 1                    ; num chars waiting in tx buf
sbrxc::         ds 1                    ; num chars waiting in rx buf
sbtxh::         ds 2                    ; tx buffer head pointer
sbtxt::         ds 2                    ; tx buffer tail pointer
sbrxh::         ds 2                    ; rx buffer head pointer
sbrxt::         ds 2                    ; rx buffer tail pointer

conidl::        ds 2                    ; consin idle callback

                .org $c0
satxbf::        ds sio_a_tx_size        ; sio A tx buffer

                .org $100
sarxbf::        ds sio_rx_size          ; sio A rx buffer

                .org $200
consin::        ds consin_size

                .org $300
svctab::
svc_table:
        ; console functions must be first in the table
                .extern cagetc
_cgetc          dw cagetc
@cgetc          .equ (_cgetc - svc_table)/2

                .extern caputc
_cputc          dw caputc
@cputc          .equ (_cputc - svc_table)/2

                .extern cagets
_cgets          dw cagets
@cgets          .equ (_cgets - svc_table)/2

                .extern caputs
_cputs          dw caputs
@cputs          .equ (_cputs - svc_table)/2

                .extern sapoll
_cpoll          dw sapoll
@cpoll          .equ (_cpoll - svc_table)/2

                .extern caflsh
_cflsh          dw caflsh
@cflsh          .equ (_cflsh - svc_table)/2

                .extern consa
_consa          dw consa
@consa          .equ (_consa - svc_table)/2

                .extern consb
_consb          dw consb
@consb          .equ (_consb - svc_table)/2

                .extern consic
_consic         dw consic
@consic         .equ (_consic - svc_table)/2

                .extern d8x8
_md8x8          dw d8x8
@md8x8          .equ (_md8x8 - svc_table)/2

                .extern d16x8
_md16x8          dw d16x8
@md16x8          .equ (_md16x8 - svc_table)/2

                .extern d32x8
_md32x8         dw d32x8
@md32x8         .equ (_md32x8 - svc_table)/2

                .extern d1610
_md1610         dw d1610
@md1610         .equ (_md1610 - svc_table)/2

                .extern d3210
_md3210         dw d3210
@md3210         .equ (_md3210 - svc_table)/2

                .extern m16x8
_mm16x8         dw m16x8
@mm16x8         .equ (_mm16x8 - svc_table)/2

                .extern m16x16
_mm16x16        dw m16x16
@mm16x16        .equ (_mm16x16 - svc_table)/2

                .extern kiread
_kiread         dw kiread
@kiread         .equ (_kiread - svc_table)/2

                .extern l7ph8
_l7ph8          dw l7ph8
@l7ph8          .equ (_l7ph8 - svc_table)/2

                .extern l7ph16
_l7ph16          dw l7ph16
@l7ph16          .equ (_l7ph16 - svc_table)/2

                .extern l7ph32
_l7ph32          dw l7ph32
@l7ph32          .equ (_l7ph32 - svc_table)/2

                .extern l7pd8
_l7pd8          dw l7pd8
@l7pd8          .equ (_l7pd8 - svc_table)/2

                .extern l7pd16
_l7pd16          dw l7pd16
@l7pd16          .equ (_l7pd16 - svc_table)/2

                .extern l7pd32
_l7pd32          dw l7pd32
@l7pd32          .equ (_l7pd32 - svc_table)/2

                .extern lccls
_lccls          dw lccls
@lccls          .equ (_lccls - svc_table)/2

                .extern lchome
_lchome         dw lchome
@lchome         .equ (_lchome - svc_table)/2

                .extern lcctl
_lcctl          dw lcctl
@lcctl          .equ (_lcctl - svc_table)/2

                .extern lcent
_lcent          dw lcent
@lcent          .equ (_lcent - svc_table)/2

                .extern lcshft
_lcshft         dw lcshft
@lcshft         .equ (_lcshft - svc_table)/2

                .extern lcgoto
_lcgoto         dw lcgoto
@lcgoto         .equ (_lcgoto - svc_table)/2

                .extern lcputc
_lcputc         dw lcputc
@lcputc         .equ (_lcputc - svc_table)/2

                .extern lcputs
_lcputs         dw lcputs
@lcputs         .equ (_lcputs - svc_table)/2

                .extern lcph8
_lcph8          dw lcph8
@lcph8          .equ (_lcph8 - svc_table)/2

                .extern lcph16
_lcph16         dw lcph16
@lcph16         .equ (_lcph16 - svc_table)/2

                .extern lcph32
_lcph32         dw lcph32
@lcph32         .equ (_lcph32 - svc_table)/2

                .extern lcpd16
_lcpd16         dw lcpd16
@lcpd16         .equ (_lcpd16 - svc_table)/2

                .extern lcpd32
_lcpd32         dw lcpd32
@lcpd32         .equ (_lcpd32 - svc_table)/2

                .extern tkrd16
_tkrd16         dw tkrd16
@tkrd16         .equ (_tkrd16 - svc_table)/2

                .extern tkrd32
_tkrd32         dw tkrd32
@tkrd32         .equ (_tkrd32 - svc_table)/2

                .extern tkrdut
_tkrdut         dw tkrdut
@tkrdut         .equ (_tkrdut - svc_table)/2

                .extern adcrd
_adcrd          dw adcrd
@adcrd          .equ (_adcrd - svc_table)/2

                .extern rtcrd
_rtcrd          dw rtcrd
@rtcrd          .equ (_rtcrd - svc_table)/2

                .extern rtcosf
_rtcosf         dw rtcosf
@rtcosf         .equ (_rtcosf - svc_table)/2

                .extern rtctcv
_rtctcv         dw rtctcv
@rtctcv         .equ (_rtctcv - svc_table)/2

                .extern rtcctm
_rtcctm         dw rtcctm
@rtcctm         .equ (_rtcctm - svc_table)/2

                .extern rtcrdt
_rtcrdt         dw rtcrdt
@rtcrdt         .equ (_rtcrdt - svc_table)/2

                .extern rtcrtm
_rtcrtm         dw rtcrtm
@rtcrtm         .equ (_rtcrtm - svc_table)/2

                .extern rtcwdt
_rtcwdt         dw rtcwdt
@rtcwdt         .equ (_rtcwdt - svc_table)/2

                .extern rtcwtm
_rtcwtm         dw rtcwtm
@rtcwtm         .equ (_rtcwtm - svc_table)/2

                .end