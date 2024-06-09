                section CODE
                org     0

gpio_reg        defl    $0
gpio_p0         defl    $1
gpio_p1         defl    $2

                xor     a
                out     (gpio_reg),a
loop:
                in      a,(gpio_reg)
                cpl     
                and     gpio_p0
                rlca
                out     (gpio_reg),a
                jp      loop