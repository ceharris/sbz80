                ;-------------------------------------------------------
                ; Definitions for the Z80 CTC
                ;-------------------------------------------------------

                ; Control word bits
ctc_ei          equ $80                 ; enable interrupts
ctc_counter     equ $40                 ; counter mode
ctc_pre256      equ $20                 ; prescale by 256
ctc_rising      equ $10                 ; trigger on rising edge
ctc_trigger     equ $8                  ; start timer on trigger
ctc_tc          equ $4                  ; time constant
ctc_reset       equ $2                  ; software reset
ctc_ctrl        equ $1                  ; control word

                ; Definitions for zero bits
                ; (used just for code readability)
ctc_di          equ 0                   ; disable interrupts
ctc_timer       equ 0                   ; timer mode
ctc_pre16       equ 0                   ; prescale by 16
ctc_falling     equ 0                   ; trigger on falling edge
ctc_auto        equ 0                   ; start timer automatically
ctc_notc        equ 0                   ; no time constant

                ; Default control word
ctc_default     equ ctc_di|ctc_counter|ctc_pre16|ctc_falling|ctc_trigger|ctc_notc|ctc_reset|ctc_ctrl

                ; Port offsets for channels
ctc0_ch0        equ ctc0_base + 0 
ctc0_ch1        equ ctc0_base + 1
ctc0_ch2        equ ctc0_base + 2       ; used for polled delay    
ctc0_ch3        equ ctc0_base + 3       ; used for tick counter (tk.asm)