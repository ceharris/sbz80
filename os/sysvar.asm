		name sysvar

		include memory.asm

		dseg
vars:
vectab::	ds	im2_table_size	; interrupt vector table
vrst10::     	ds 	2		; RST 10 vector
vrst18::     	ds 	2		; RST 18 vector
vrst20::     	ds 	2		; RST 20 vector
vrst38::     	ds 	2		; RST 38 vector
kiring::	ds	ki_ring_size	; ring buffer (must be size aligned)
kirhd::		ds	2		; ring head pointer
kirtl::		ds	2		; ring tail pointer
kiflag::	ds	1		; keyboard input flags
kitab::		ds	2		; pointer to keyboard symbol table
kisamp::	ds	1		; index into keyboard input samples
		ds	ki_samples*2	; 16-bit keyboard input samples
kistat::	ds	2		; debounced keyboard input
kiprev::	ds	2		; previous debounced keyboard input
rtcph::		ds	2		; RTC periodic timer handler
rtcah::		ds	2		; RTC alarm handler
tkcnt::		ds	4		; 32-bit tick counter
cknsec::	ds	2		; clock period (nsec)
tkprd::		ds	2		; tick period (units of 500 usec)
syscfg::	ds	1		; system configuration bits
align		ds	(align-vars)%2	; pad for alignment

		end

