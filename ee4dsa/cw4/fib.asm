;;; fib.s - Fibonacci calculator
;;;
;;;    Chris Cummins
;;;    17 March 2014
;;;    Aston University
;;;    EE4DSA Digital Systems Design
;;;
;;; ========================================================
;;; Begin code:

        .include "stdlib.asm"

        .cseg

        .def a          r32     ; Working registers
        .def b          r33
        .def sum        r34
        .def 10reg      r60
        .def 100reg     r61
        .def 1000reg    r62

_main:
        cli                     ; Disable interrupts

init:
        clr     b
        clr     a               ; a = 0
        inc     b               ; b = 1
        ldil    10reg, 10
        ldil    100reg, 100
        ldil    1000reg, 255
        ldih    1000reg, 745
next_fib:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum

        ;; Display sum
        pshr    1000reg         ; Denominator
        pshr    sum             ; Numerator
        call    div
        popr    r100            ; Thousand digit
        popr    r101
        rtio    LEDS, r100

        pshr    100reg
        pshr    r101
        call    div
        popr    r101            ; Hundreds digit
        popr    r102
        rtio    LEDS, r101

        pshr    10reg
        pshr    r102
        call    div
        popr    r102            ; Tens digit
        popr    r103            ; Single digit
        rtio    SSEG_AN, r102
        rtio    SSEG_KA, r103

        ;; Wait for next request
        call    btnc_press
        jmp     next_fib

        .undef a                ; Clear macros
        .undef b
        .undef sum
        .undef 10reg
        .undef 100reg
        .undef 1000reg
