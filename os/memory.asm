; Sizing of memory components used in the hardware
sm_bank_size    equ 8192                ; small memory bank size
lg_bank_size    equ 4*sm_bank_size      ; large memory bank size

; These definitions are used in init.asm to place the stack and other
; system variables
ram_size        equ 3*sm_bank_size + lg_bank_size
ram_start       equ sm_bank_size                ; start of RAM
smem_start      equ ram_start                   ; start of system RAM
umem_start      equ ram_start + sm_bank_size    ; start of user RAM
im2_table_size	equ 256				; size of mode 2 vector table

; These definitions are used in post.asm to make it easier to choose a
; a starting address and size for memory tests than the real starting
; address and size of RAM.
ram_post_start	equ ram_start
ram_post_size	equ ram_size

; Number of keyboard input samples to keep for debounce
ki_samples	equ 2

; Size of keyboard ring buffer (must be a power of two)
ki_ring_size	equ 4
