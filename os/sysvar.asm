		name sysvar

		include memory.asm

		dseg
vars:
vectab::	ds im2_table_size	; interrupt vector table
vrst10::     	ds 	2		; RST 10 vector
vrst18::     	ds 	2		; RST 18 vector
vrst20::     	ds 	2		; RST 20 vector
vrst38::     	ds 	2		; RST 38 vector
tkcnt::		ds	5		; 40-bit time tick counter
		ds 	2
kisamp::	ds	1		; index into keyboard input samples
		ds	ki_samples*2	; 16-bit keyboard input samples
kistat::	ds	2		; debounced keyboard input
ckusec::	ds	2		; clock period (usec)
syscfg::	ds	1		; system config register contents
align		ds	(align-vars)%2	; pad for alignment

		end

