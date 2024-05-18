	; Service dispatcher function codes
	; To use any of these functions, set parameter registers
	; as needed, load A with the function code, and then execute 
	; a RST $28 instruction

__cgetc		equ 0		; Get char from console input to A
__cgetcnb	equ 1		; Get char from console to A, Z if none
__cgets		equ 2		; Get string from console input into (HL)
__cputc		equ 3		; Put character C to console output 
__cputs		equ 4		; Put string (HL) to console output
__cflush	equ 5		; Flush console input 
__jprom		equ 6		; Switch to rom page C and jump to HL
