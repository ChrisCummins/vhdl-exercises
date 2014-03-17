;;; fib.s - Fibonacci calculator
;;;
;;;    Chris Cummins
;;;    17 March 2014
;;;    Aston University
;;;    EE4DSA Digital Systems Design
;;;
;;; ========================================================
;;; Begin code:

        .include "stdlib.s"

        .cseg

        .def a          r32     ; Working registers
        .def b          r33
        .def sum        r34

_main:
        clr     b
        clr     a               ; a = 0
        inc     b               ; b = 1
next_fib:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum
        call    btnc_press
        jmp     next_fib

        .undef a                ; Clear macros
        .undef b
        .undef sum
