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

        .def a          r32     ; Working registers
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

_main:
        cli                     ; Disable interrupts
        st      NULL, sseg_idx  ; SSEG counter = 0
        st      NULL, sseg_an_t ; Clear SSEG tables
        st      NULL, sseg_an_t + 1
        st      NULL, sseg_an_t + 2
        st      NULL, sseg_an_t + 3

        ldil    10reg, 10
        ldil    100reg, 100
        ldil    1000reg, 1000
        ldil    10000reg, 10000

        sei                     ; Enable interrupts

reset_fib:
        clr     a               ; a = 0
        ldih    b, 0
        ldil    b, 1            ; b = 1

next_fib:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum

        gte     sum, 10000reg   ; If sum > 10,000
        jmp     reset_fib       ; THEN reset

        ;; Convert to BCD
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

        ;; Write out digits to tables
        st      1digit,    sseg_an_t
        st      10digit,   sseg_an_t + 1
        st      100digit,  sseg_an_t + 2
        st      1000digit, sseg_an_t + 3

        st      1digit,    sseg_ka_t
        st      10digit,   sseg_ka_t + 1
        st      100digit,  sseg_ka_t + 2
        st      1000digit, sseg_ka_t + 3

        ;; Wait for next request
        call    btnc_press
        jmp     next_fib

        .undef a                ; Clear macros
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

        .isr 0 irq1
irq1:
        ;; Preserver registers
        pshr    r10
        pshr    r11
        pshr    r12

        ;; Prepare registers
        ld      r10, sseg_idx   ; r10 = i
        ldih    r11, 0
        ldih    r12, 0
        ldil    r11, sseg_an_t  ; r11 = an_t
        ldil    r12, sseg_ka_t  ; r12 = ka_t
        ldd     r11, r11, r10   ; r11 = an_t[i]
        ldd     r12, r12, r10   ; r12 = ka_t[i]

        ;;  Port writes
        stio    SSEG_AN, r11
        stio    SSEG_KA, r12

        ;; Increment index counter
        ldih    r12, 0
        ldil    r12, 4          ; r11 = 4
        inc     r10             ; i++
        lt      r10, r12        ; IF i < 4
        brts    irq1_2          ; THEN RETURN
        ldil    r10, 0          ; ELSE i = 0

irq1_2:
        st      r10, sseg_idx   ; Memory writes

        ;; Restore register file
        popr    r12
        popr    r11
        popr    r10
        reti
