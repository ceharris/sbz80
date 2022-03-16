
        ;---------------------------------------------------------------
        ; Serial I/O Support
        ;
        ; The system includes the standard Z80 SIO peripheral, which 
        ; provides two fully independent serial interfaces. The SIO
        ; supports a asynchronous and synchronous modes with a variety
        ; of different protocols. However, this module provides support
        ; only for common asynchronous modes, with a single bit
        ; rate for both the tranmsit and receive directions.
        ;
        ; Each port may be configured for 5, 6, 7, or 8 bits, with 
        ; 1, 1 1/2, or 2 stop bits, and parity none, even, or odd.
        ; 
        ; Clock rates are produced by dividing the system clock using
        ; a CTC channel in counter mode. The following common bit rates 
        ; are supported.
        ;
        ;      TC    Bit Rate
        ;      --    --------
        ;       1     115,200
        ;       2      57,600
        ;       3      38,400
        ;       4      28,800
        ;       6      19,200
        ;       8      14,400
        ;      12       9,600
        ;      24       4,800
        ;      48       2,400
        ;      96       1,200
        ;     192         600
        ;
        ; These rates are based on a system clock of either 3.6864 MHz
        ; or 7.3728 MHz. When the system clock is 3.6864 MHz the SIO
        ; clock divisor is set to 16; at 7.3738 MHz, the SIO clock
        ; divisor is set to 32.
        ; 
        ; SIO port A is a TTL serial interface which is terminated
        ; using an FTDI-type USB cable adapter. SIO port B is configured
        ; as a standard EIA/TIA 232 interfae, on a 9-pin m
        ;---------------------------------------------------------------


; 0. Each port has a control block in system memory that contains the
;    ring buffers for transmit and receive (along with their head and
;    tail pointers) and fields for the modem status bits (DCD, CTS) and
;    error condition flags.
; 1. The init function must be called once for each port. The control
;    block for the specified port is initialized, and ISR addresses are
;    configured. 
; 2. Each of the ISRs starts by getting a pointer to the control block 
;    for the port that generated the interrupt before jumping to code 
;    that is shared for each port.
; 3. Whenever the transmit ring is empty a bit flag is set in the
;    control block by the ISR. The `siotx` function tests this bit
;    and if set, clears the flag and then directly outputs the value to
;    be transmitted. If the flag is not set, the `siotx` function 
;    places the value to be sent into the transmit ring buffer.
; 4. As data is received, an ISR places each received value into the
;    receive ring buffer. The `siorx` function is used to retrieve 
;    data from the ring.


