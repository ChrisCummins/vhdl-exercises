;;; Fibonacci.asm

;;; Macros.
;;; ========================================================

        ;; Device IO
        ;; =================================================

        ;; Input ports
        .def SWITCHES   0x00
        .def BUTTONS    0x01

        ;; Output ports
        .def LEDS       0x00
        .def SSEG_AN    0x01
        .def SSEG_KA    0x02

        ;; Button masks
        .def BTNU       0x00
        .def BTND       0x10
        .def BTNC       0x20
        .def BTNL       0x40
        .def BTNR       0x80

;;; Program code.
;;; ========================================================

        .cseg

        .def a          r32     ; Working registers
        .def b          r33
        .def sum        r34

_main:
        clr     b
        clr     a               ; a = 0
        inc     b               ; b = 1
fibonacci:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum
        call    btnc_press
        jmp     fibonacci

        .undef a                ; Clear macros
        .undef b
        .undef sum

;;; Subroutines.
;;; ========================================================

        ;; Multiply two numbers iteratively.
multiply_unsigned:
        popr    r16             ; Return address
        popr    r17             ; Operand 1
        popr    r18             ; Operand 2
        clr     r19
multiply_unsigned_2:
        add     r19, r19, r17   ; Double value
        dec     r18             ; Decrement counter
        nez     r18             ; Branch if zero
        brts    multiply_unsigned_2
        pshr    r19             ; Push result
        pshr    r16             ; Push return address
        ret

        ;; Press and release the up button
btnu_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnu_press
btnu_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnu_press_2
        ret

        ;; Press and release the down button
btnd_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnd_press
btnd_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnd_press_2
        ret

        ;; Press and release the centre button
btnc_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnc_press
btnc_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnc_press_2
        ret

        ;; Press and release the left button
btnl_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnl_press
btnl_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnl_press_2
        ret

        ;; Press and release the right button
btnr_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnr_press
btnr_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnr_press_2
        ret
