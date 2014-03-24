;;; fib.asm - Fibonacci calculator
;;;
;;;    Chris Cummins
;;;    17 March 2014
;;;    Aston University
;;;    EE4DSA Digital Systems Design
;;;
;;; ========================================================
;;; Begin code:

        .include "stdlib.asm"

        ;; Data Segment:
        ;; =================================================

        .dseg

        ;; Seven segment display memory:
        ssd_an_t:       .word 4         ; Anode mask table
        ssd_ka_t:       .word 4         ; Cathode mask table


        ;; Program code:
        ;; =================================================

        .cseg

        ;; Let's start by defining some symbolic names for
        ;; our working registers:
        .def a          r32             ; Fibonacci 'a' operand
        .def b          r33             ; Fibonacci 'b' operand
        .def sum        r34             ; Fibonacci result
        .def last       r35             ; Last result in Fibonacci sequence
        .def ssd_ka_r   r36             ; Pointer to SSD cathode table
        .def led_m      r38             ; LED port mask
        .def byte+1     r37             ; Byte overflow constant

        ;; The main code entry point. Begin by initialising
        ;; register and memory values as required. We do this
        ;; with interrupts disabled since we don't want to
        ;; be accessing uninitialised memory:
_main:
        cli                             ; Disable interrupts
        ldi     ssd_ka_r,     ssd_ka_t  ; Set a pointer to the cathode table
        ldi     byte+1,       0xFF + 1  ; Set the byte overflow
        sti     ssd_ka_t,     SSD_OFF   ; Zero the cathode table
        sti     ssd_ka_t + 1, SSD_OFF
        sti     ssd_ka_t + 2, SSD_OFF
        sti     ssd_ka_t + 3, SSD_OFF
        sti     ssd_an_t,     0x07      ; Anode table with fixed order
        sti     ssd_an_t + 1, 0x0B
        sti     ssd_an_t + 2, 0x0D
        sti     ssd_an_t + 3, 0x0E
        sei                             ; We're all set, so enable interrupts

reset_fib:
        ldi     a, 0                    ; a = 0
        ldi     b, 1                    ; b = 1
        ldi     last, 0
        ldi     led_m, 1
next_fib:                               ; The actual Fibonacci calculation:
        add     sum, a, b               ; sum = a + b
        mov     a, b                    ; a = b
        mov     b, sum                  ; b = sum
        brlt    sum, last, reset_fib    ; Reset if we have integer overflow
        mov     last, sum               ; last = current

        ;; Update Seven Segment Display:
        pshr    ssd_ka_r                ; Update the SSD cathode table
        pshr    sum
        call    bin2ssd_tm

        ;; Update LED indicator
        stio    LEDS, led_m
        lsli    led_m, led_m, 1         ; led_m << 1
        lt      led_m, byte+1           ; If we've overflown the port mask, reset
        rbrts   2
        ldil    led_m, 1

        ;; Wait for Button press
        call    btnc_press
        jmp     next_fib

        ;; Clear up our symbol space:
        .undef a
        .undef b
        .undef sum
        .undef last
        .undef ssd_ka_r
        .undef byte+1
        .undef led_m

;;; Seven Segment Display driver:
;;; ========================================================

        ;; Data Segment:
        ;; =================================================

        .dseg

        ssd_idx:        .word 1         ; Current digit index

        ;; Program code:
        ;; =================================================

        .cseg

        ;; Register our interrupt handler:
        .isr ISR_SSD ssd_update

        ;; When executed, this routine reads the anode and cathode
        ;; mask of one of the four seven segment display digits
        ;; from memory, and writes out the value to the
        ;; corresponding output port. It then increments and stores
        ;; a counter to determine the next digit to be displayed.
ssd_update:
        pshr    r10                     ; Preserve working registers
        pshr    r11
        ld      r10, ssd_idx            ; r10 = i
        lddi    r11, r10, ssd_an_t      ; r11 = an_t[i]
        stio    SSD_AN, r11             ; Write out anode
        lddi    r11, r10, ssd_ka_t      ; r11 = ka_t[i]
        stio    SSD_KA, r11             ; Write out cathode
        inc     r10                     ; i++
        lti     r10, 4                  ; IF i < 4
        rbrts   2                       ; THEN RETURN
        ldil    r10, 0                  ; ELSE i = 0
        st      ssd_idx, r10            ; Store i
        popr    r11                     ; Restore working registers
        popr    r10
        reti
