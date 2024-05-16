
	;---------------------------------------------------------------
	; delay:
	; Delay for approximately a given number of milliseconds.
	;
	; On entry:
	;	BC = delay time in milliseconds
	; On return:
	;	BC = 0
	;
	; Define T(n) as the number of T states per delay count. In the
	; implementation given below
	; 
	; T(n) = 34	(outer loop: load A, decrement BC, test, and jump)
	;      + 4 * J	(additional no-ops)
	;      + 14 * K	(inner loop: decrement A, jump)		
	;
	; We'd like for delay counts in the range from about 10 to 10,000
	; to result in a relatively small difference between the expected
	; delay and the actual delay. We choose J and K to minimize this
	; difference over this range of delay times.
	;
	; To reach this entry point, we have either a CALL (17 clocks)
	; or a RST + JP = (21 clocks), and to return we add 10 clocks. 
	; So the overhead is either 27 or 31 clocks per call. Small delay 
	; counts will incur the most additional delay due to overhead,
	; obviously, and the difference in expected versus actual delay
	; will therefore be higher for smaller delay counts.
	;
	; Given our system clock running at 7.3728 MHz, each T state is
	; approximately 125 nsec in duration. With some experimentation, 
	; we find that J=2 and K=7665 are reasonable choices that meet our
	; objectives for delay counts in the range of 10 up to the maximum
	; of 65,536 (BC = 0).
	;
	;   Count	  T states 	Delay time	 Error
	;   ------	-----------	---------- 	------
	;        1	    184,054	    1.0003      +0.03%
	;       10	  1,840,072	   10.0004      +0.00%	
	;      100       18,400,252	  100.0014      +0.00%
	;    1,000	184,002,052	 1000.0112      +0.00%
	;   10,000    1,840,020,052     10000.1090      +0.00%
	;   65,536   12,058,755,124     65536.7126      +0.00%
	;

		include "machine.h.asm"

		public delay

J_COUNT		equ 5
K_COUNT		equ 305

		macro nops count
		rept count
		nop
		endr
		endm

		section CODE_USER
delay:					; [31] RST + JMP to get here
delay_10:
		ld de,K_COUNT		; [10] inner loop count
delay_20:
		dec de			; [6] decrement inner loop count
		ld a,d			; [4] Is inner loop count 
		or e			; [4]     now zero?
		jp nz,delay_20		; [10]

		nops J_COUNT		; [J_COUNT*4]
		dec bc			; [6] decrement delay count
		ld a,b			; [4] is BC now
		or c			; [4]	equal to zero?
		jp nz,delay_10		; [10] go until BC = 0

		ret			; [10]
