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

        .def 1digit     r100
        .def 10digit    r101
        .def 100digit   r102
        .def 1000digit  r103

_main:
        cli                     ; Disable interrupts
        rtm     NULL, sseg_idx  ; SSEG counter = 0
        rtm     NULL, sseg_an_t ; Clear SSEG tables
        rtm     NULL, sseg_an_t + 1
        rtm     NULL, sseg_an_t + 2
        rtm     NULL, sseg_an_t + 3

        ;; Prepare interrupt registers
        clr     r10
        clr     r11
        clr     r12
        clr     r14
        ldil    r11, 4          ; r11 = 4
        ldil    r12, sseg_an_t  ; r12 = an_t
        ldil    r14, sseg_ka_t  ; r14 = ka_t

        clr     b
        clr     a               ; a = 0
        ldil    b, 1            ; b = 1
        ldil    10reg, 10
        ldil    100reg, 100
        ldil    1000reg, 1000

        sei                     ; Enable interrupts
next_fib:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum

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

        rtm     1digit,    sseg_an_t
        rtm     10digit,   sseg_an_t + 1
        rtm     100digit,  sseg_an_t + 2
        rtm     1000digit, sseg_an_t + 3

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

        .isr 0 irq0
irq0:
        imtr    r13, r12, r10   ; r13 = an_t[i]
        rtio    SSEG_AN, r13    ; Set SSEG anodes
        imtr    r13, r14, r10   ; r13 = ka_t[i]
        rtio    SSEG_KA, r13    ; Set SSEG cathodes
        inc     r10             ; i++
        lt      r10, r11        ; IF i < 4
        brts    irq0_ret        ; THEN RETURN
        ldil    r10, 0          ; ELSE i = 0
irq0_ret:
        reti
