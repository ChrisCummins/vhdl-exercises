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

        ssd_idx:        .word 1 ; SSD refresh index
        ssd_an_t:       .word 4 ; SSD Anode values
        ssd_ka_t:       .word 4 ; SSD Cathode values


        ;; Program code:
        ;; =================================================

        .cseg

        ;; Working registers
        .def a          r32
        .def b          r33
        .def sum        r34
        .def last       r35
        .def ssd_ka_r   r26


_main:
        cli                     ; Disable interrupts

        ;; Prepare memory and constant registers
        ldi     ssd_ka_r, ssd_ka_t

        ;; Setup SSD tables
        st      NULL, ssd_idx   ; SSD counter = 0

        st      NULL, ssd_ka_t
        st      NULL, ssd_ka_t + 1
        st      NULL, ssd_ka_t + 2
        st      NULL, ssd_ka_t + 3

        sti     0x07, ssd_an_t
        sti     0x0B, ssd_an_t + 1
        sti     0x0D, ssd_an_t + 2
        sti     0x0E, ssd_an_t + 3

        sei                     ; Enable interrupts

reset_fib:
        ;; Prepare registers
        ldi     a, 0            ; a = 0
        ldi     b, 1            ; b = 1
        ldi     last, 0

        ;; Fibonacci sequence iteration
next_fib:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum

        lt      sum, last       ; IF sum < last
        brts    reset_fib       ; THEN RESET (overflow)
        mov     last, sum       ; last = current

        pshr    ssd_ka_r
        pshr    sum
        call    bin2ssd_tm

        ;; Wait for next request
        call    btnc_press
        jmp     next_fib

        ;; Clear our symbol space
        .undef a
        .undef b
        .undef sum
        .undef last
        .undef ssd_ka_r

        ;; SSG Driver.
        ;; =================================================

        .isr ISR_SSD ssd_update

ssd_update:
        ;; Preserver registers
        pshr    r10
        pshr    r11

        ;; Prepare registers
        ld      r10, ssd_idx    ; r10 = i
        ldi     r11, ssd_an_t   ; r11 = an_t
        ldd     r11, r11, r10   ; r11 = an_t[i]
        stio    SSD_AN, r11

        ldil    r11, ssd_ka_t   ; r11 = ka_t
        ldd     r11, r11, r10   ; r11 = ka_t[i]
        stio    SSD_KA, r11

        ;; Increment index counter
        ldil    r11, 4          ; r11 = 4
        inc     r10             ; i++
        lt      r10, r11        ; IF i < 4
        brts    ssd_update_2    ; THEN RETURN
        ldil    r10, 0          ; ELSE i = 0
ssd_update_2:
        st      r10, ssd_idx    ; Memory writes

        ;; Restore register file
        popr    r11
        popr    r10
        reti
