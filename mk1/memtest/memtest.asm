
		section	CODE
		org	$0

ram_start       defl    $8000
ram_size        defl    $8000

gpio_reg	defl	$0
gpio_p1		defl	$2
gpio_p2         defl    $4
pattern         defl    $55

                ld      sp,0
                ex      af,af'
                xor     a
                out     (gpio_reg),a
                ex      af,af'
loop:
                ld      a,pattern
                ld      hl,ram_start
                ld      e,l
                ld      d,h
                inc     e
                ld      (hl),a
                ld      bc,ram_size - 1
                ldir                

                ld      hl,ram_start
                ld      bc,ram_size
loop_10:
                cpi
                jp      nz,error
                jp      po,loop_10

                ex      af,af'
                xor     gpio_p2
                out     (gpio_reg),a
                ex      af,af'
                jp      loop

error:
                ld      a,gpio_p2
error_10:
                xor     gpio_p1|gpio_p2
                out     (gpio_reg),a
                call    delay
                jp      error_10

delay:          
                ld      b,2
delay_10:
                ld      de,0
delay_20:
                dec     de
                ld      a,d
                or      e
                jp      nz, delay_20
                djnz    delay_10
                ret



