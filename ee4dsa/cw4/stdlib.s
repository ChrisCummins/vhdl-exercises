;;; stdlib.s - Standard library of utilities and functions
;;;
;;;    Chris Cummins
;;;    17 March 2014
;;;    Aston University
;;;    EE4DSA Digital Systems Design
;;;
;;; ========================================================
;;; Begin code:


        ;; Definitions.
        ;; =================================================

        ;; The start of user program label
        .def _MAIN_ENTRY_POINT _main

        ;; Registers.
        ;; =================================================
        .def NULL       r0
        .def PC         r1
        .def SP         r2
        .def SREG       r3

        ;; Device IO.
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


;;; Initialisation.
;;; ========================================================

        .cseg
        .org PROG_START

_stdlib_init:
        jmp     _MAIN_ENTRY_POINT ; Jump to user code entry point

;;; Subroutines.
;;; ========================================================

        ;; System IO Operations.
        ;; =================================================

        ;; Press and release the up button.
btnu_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnu_press
_btnu_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    _btnu_press_2
        ret

        ;; Press and release the down button.
btnd_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnd_press
_btnd_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    _btnd_press_2
        ret

        ;; Press and release the centre button.
btnc_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnc_press
_btnc_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    _btnc_press_2
        ret

        ;; Press and release the left button.
btnl_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnl_press
_btnl_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    _btnl_press_2
        ret

        ;; Press and release the right button.
btnr_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnr_press
_btnr_press_2:
        tsti    BUTTONS, BTNC, BTNC
        brts    _btnr_press_2
        ret

        ;; Arithmetic.
        ;; =================================================

        ;; Multiply two unsigned numbers.
        ;;
        ;;   @param  operand A
        ;;   @param  operand B
        ;;   @return result
multu:
        popr    r16             ; Return address
        popr    r17             ; a
        popr    r18             ; b
        clr     r19             ; y = 0
        dec     r18             ; i = b - 1
_multu_2:
        add     r19, r19, r17   ; y += a
        dec     r18             ; i--
        nez     r18             ; Repeat while i > 0
        brts    _multu_2
        pshr    r19             ; Push result
        pshr    r16             ; Push return address
        ret

        ;; Multiply two signed numbers.
        ;;
        ;; @param  operand A
        ;; @param  operand B
        ;; @return result
mult:
        popr    r16             ; Return address
        popr    r17             ; a
        popr    r18             ; b

        ;; Convert negative numbers to positive
        lts     r18, 0          ; IF b < 0
        subs    r17, 0, r17     ; a = 0 - a
        subs    r18, 0, r18     ; b = 0 - b

        pshr    r17             ; Push a
        pshr    r18             ; Push b
        call    multu
        ret
