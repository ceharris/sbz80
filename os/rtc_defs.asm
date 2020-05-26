		;--------------------------------
		; Definitions for the BQ4845 RTC
		;--------------------------------

rtc_port_sec	equ rtc_port_base+0
rtc_port_asec	equ rtc_port_base+1
rtc_port_min	equ rtc_port_base+2
rtc_port_amin	equ rtc_port_base+3
rtc_port_hour	equ rtc_port_base+4
rtc_port_ahour	equ rtc_port_base+5
rtc_port_dom	equ rtc_port_base+6
rtc_port_adom	equ rtc_port_base+7
rtc_port_dow	equ rtc_port_base+8
rtc_port_month  equ rtc_port_base+9
rtc_port_year	equ rtc_port_base+10

rtc_port_rate	equ rtc_port_base+11
rtc_port_ei	equ rtc_port_base+12
rtc_port_flags	equ rtc_port_base+13
rtc_port_ctl	equ rtc_port_base+14

		; Alarm bit positions
rtc_alm1	equ 7
rtc_alm0	equ 6

		; Meridian bit (12 hour mode)
rtc_pmam	equ 7

		; Rate bit positions
rtc_rs0		equ 0
rtc_rs1		equ 1
rtc_rs2		equ 2
rtc_rs3		equ 3
rtc_wd0		equ 4
rtc_wd1		equ 5
rtc_wd2		equ 6

		; Interrupt enable bits
rtc_abe		equ 0			; alarm interrupt in backup
rtc_pwrie	equ 1			; power fail interrupt
rtc_pie		equ 2			; periodic timer interrupt
rtc_aie		equ 3			; alarm interrupt

		; Flag bit positions
rtc_bvf		equ 0			; battery voltage warning signal
rtc_pwrf	equ 1			; power fail signal
rtc_pf		equ 2			; periodic timer signal
rtc_af		equ 3			; alarm signal

		; Control word bit positions
rtc_dse		equ 0			; daylight savings enable
rtc_24hr	equ 1			; 24-hour mode
rtc_run		equ 2			; oscillator run
rtc_uti		equ 3			; update transfer inhibit

		; alarm mask
rtc_alm_m	equ 1<<rtc_alm1 | 1<<rtc_alm0

		; Control word masks
rtc_uti_m	equ 1<<rtc_uti
rtc_run_m	equ 1<<rtc_run
rtc_24hr_m	equ 1<<rtc_24hr
rtc_dse_m	equ 1<<rtc_dse

