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

        bcd2sseg_t:     .word 10 ; BCD to SSEG lookup table
        sseg_idx:       .word 1 ; SSEG refresh index
        sseg_an_t:      .word 4 ; SSEG Anode values
        sseg_ka_t:      .word 4 ; SSEG Cathode values


        ;; Program code:
        ;; =================================================

        .cseg

        ;; Working registers
        .def a          r32
        .def b          r33
        .def sum        r34
        .def 10reg      r60
        .def 100reg     r61
        .def 1000reg    r62
        .def 10000reg   r63

        .def 1digit     r100
        .def 10digit    r101
        .def 100digit   r102
        .def 1000digit  r103

        ;; Prepare memory and constant registers
_main:
        cli                     ; Disable interrupts
        st      NULL, sseg_idx  ; SSEG counter = 0

        ;; Setup SSEG tables
        ldih    r90,  0
        ldil    r90,  0x0E
        st      r90,  sseg_an_t
        st      NULL, sseg_ka_t
        ldil    r90,  0x0D
        st      r90,  sseg_an_t + 1
        st      NULL, sseg_ka_t + 1
        ldil    r90,  0x0B
        st      r90,  sseg_an_t + 2
        st      NULL, sseg_ka_t + 2
        ldil    r90,  0x07
        st      r90,  sseg_an_t + 3
        st      NULL, sseg_ka_t + 3

        ;; Setup constants registers
        ldil    10reg,    10
        ldil    100reg,   100
        ldil    1000reg,  1000
        ldil    10000reg, 10000

        sei                     ; Enable interrupts

        ;; Prepare registers
reset_fib:
        clr     a               ; a = 0
        ldih    b, 0
        ldil    b, 1            ; b = 1

        ;; Fibonacci sequence iteration
next_fib:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum

        ;; Reset on overflow
        gte     sum, 10000reg   ; If sum > 10,000
        brts    reset_fib       ; THEN reset

        ;; Binary to BCD conversion
        pshr    1000reg         ; Denominator
        pshr    sum             ; Numerator
        call    div
        popr    1digit          ; Thousand digit
        popr    r35

        pshr    100reg
        pshr    r35
        call    div
        popr    10digit         ; Hundreds digit
        popr    r35

        pshr    10reg
        pshr    r35
        call    div
        popr    100digit        ; Tens digit
        popr    1000digit       ; Single digit

        ;; Write out digits to SSEG table
        st      1digit,    sseg_ka_t
        st      10digit,   sseg_ka_t + 1
        st      100digit,  sseg_ka_t + 2
        st      1000digit, sseg_ka_t + 3

        ;; Wait for next request
        call    btnc_press
        jmp     next_fib

        ;; Clear our symbol space
        .undef a
        .undef b
        .undef sum
        .undef 10reg
        .undef 100reg
        .undef 1000reg

        .undef 1digit
        .undef 10digit
        .undef 100digit
        .undef 1000digit

        ;; SSG Driver.
        ;; =================================================

        .isr 0 isr1
isr1:
        ;; Preserver registers
        pshr    r10
        pshr    r11

        ;; Prepare registers
        ld      r10, sseg_idx   ; r10 = i
        ldih    r11, 0
        ldil    r11, sseg_an_t  ; r11 = an_t
        ldd     r11, r11, r10   ; r11 = an_t[i]
        stio    SSEG_AN, r11

        ldil    r11, sseg_ka_t  ; r11 = ka_t
        ldd     r11, r11, r10   ; r11 = ka_t[i]
        stio    SSEG_KA, r12

        ;; Increment index counter
        ldih    r11, 0
        ldil    r11, 4          ; r11 = 4
        inc     r10             ; i++
        lt      r10, r11        ; IF i < 4
        brts    isr1_2          ; THEN RETURN
        ldil    r10, 0          ; ELSE i = 0
isr1_2:
        st      r10, sseg_idx   ; Memory writes

        ;; Restore register file
        popr    r11
        popr    r10
        reti
