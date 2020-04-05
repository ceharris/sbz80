sm_bank_size    equ 8192                ; small memory bank size
lg_bank_size    equ 4*sm_bank_size      ; large memory bank size

ram_size        equ 3*sm_bank_size + lg_bank_size

ram_start       equ sm_bank_size                ; start of RAM
smem_start      equ ram_start                   ; start of system RAM
umem_start      equ ram_start + sm_bank_size    ; start of user RAM

im2_table_size	equ 256
