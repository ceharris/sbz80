	; Service dispatcher function codes
	; To use any of these functions, set parameter registers
	; as needed, load A with the function code, and then execute 
	; a RST $28 instruction

__cgetc		defl 0		; Get char from console input to A
__cgetcnb	defl 1		; Get char from console to A, Z if none
__cgets		defl 2		; Get string from console input into (HL)
__cflush	defl 4		; Flush console input 
__cputc		defl 3		; Put character C to console output 
__cputs		defl 4		; Put string (HL) to console output
__delay		defl 5		; Delay for BC milliseconds
