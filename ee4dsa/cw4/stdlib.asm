;;; stdlib.asm - Standard library of utilities and functions
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

        ;; Interrupt lines.
        ;; =================================================
        .def ISR_TIMER  0       ; Timer
        .def ISR_SSD    1       ; Seven Segment Display

        ;; Device IO.
        ;; =================================================

        ;; Input ports
        .def SWITCHES   0x00
        .def BUTTONS    0x01

        ;; Output ports
        .def LEDS       0x00
        .def SSD_AN     0x01
        .def SSD_KA     0x02

        ;; Button masks
        .def BTNU       0x00
        .def BTND       0x10
        .def BTNC       0x20
        .def BTNL       0x40
        .def BTNR       0x80

        ;; Hexadecimal encodings for digits.
        .def SSD_DIG_0  0xC0
        .def SSD_DIG_1  0xF9
        .def SSD_DIG_2  0xA4
        .def SSD_DIG_3  0xB0
        .def SSD_DIG_4  0x99
        .def SSD_DIG_5  0x92
        .def SSD_DIG_6  0x82
        .def SSD_DIG_7  0xF8
        .def SSD_DIG_8  0x80
        .def SSD_DIG_9  0x90
        ;; AND mask to add the period to SSD.
        .def SSD_P_MASK 0x7F


;;; Initialisation.
;;; ========================================================

        .cseg
        .org PROG_START

_stdlib_init:
        call    _bcd2ssd_init     ; Setup bcd2ssd conversion tables
        jmp     _MAIN_ENTRY_POINT ; Jump to user code entry point

;;; Subroutines.
;;; ========================================================

        ;; Button operations.
        ;; =================================================

        ;; Press and release the up button.
btnu_press:
        tsti    BUTTONS, BTNU, BTNU
        brts    btnu_press
_btnu_press_2:
        tsti    BUTTONS, BTNU, 0x00
        brts    _btnu_press_2
        ret

        ;; Press and release the down button.
btnd_press:
        tsti    BUTTONS, BTND, BTND
        brts    btnd_press
_btnd_press_2:
        tsti    BUTTONS, BTND, 0x00
        brts    _btnd_press_2
        ret

        ;; Press and release the centre button.
btnc_press:
        tsti    BUTTONS, BTNC, BTNC
        brts    btnc_press
_btnc_press_2:
        tsti    BUTTONS, BTNC, 0x00
        brts    _btnc_press_2
        ret

        ;; Press and release the left button.
btnl_press:
        tsti    BUTTONS, BTNL, BTNL
        brts    btnl_press
_btnl_press_2:
        tsti    BUTTONS, BTNL, 0x00
        brts    _btnl_press_2
        ret

        ;; Press and release the right button.
btnr_press:
        tsti    BUTTONS, BTNR, BTNR
        brts    btnr_press
_btnr_press_2:
        tsti    BUTTONS, BTNR, 0x00
        brts    _btnr_press_2
        ret


        ;; Seven Segment Display.
        ;; =================================================

        .dseg

        _bcd2ssd_t:     .word 10 ; BCD to SSD lookup table

        .cseg

_bcd2ssd_init:
        ldih    r16, 0
        ldil    r16, SSD_DIG_0
        st      r16, _bcd2ssd_t
        ldil    r16, SSD_DIG_1
        st      r16, _bcd2ssd_t + 0x1
        ldil    r16, SSD_DIG_2
        st      r16, _bcd2ssd_t + 0x2
        ldil    r16, SSD_DIG_3
        st      r16, _bcd2ssd_t + 0x3
        ldil    r16, SSD_DIG_4
        st      r16, _bcd2ssd_t + 0x4
        ldil    r16, SSD_DIG_5
        st      r16, _bcd2ssd_t + 0x5
        ldil    r16, SSD_DIG_6
        st      r16, _bcd2ssd_t + 0x6
        ldil    r16, SSD_DIG_7
        st      r16, _bcd2ssd_t + 0x7
        ldil    r16, SSD_DIG_8
        st      r16, _bcd2ssd_t + 0x8
        ldil    r16, SSD_DIG_9
        st      r16, _bcd2ssd_t + 0x9
        ret

        ;; Convert a binary coded decimal digit to a Seven Segment
        ;; Display cathode mask.
        ;;
        ;;   @param  BCD digit
        ;;   @return SSD digit
bcd2ssd:
        popr    r16             ; Return address
        popr    r17             ; BCD digit 'i'
        ldih    r18, 0
        ldil    r18, _bcd2ssd_t ; r18 = bcd2ssd_t
        ldd     r18, r18, r17   ; r18 = bcd2ss_t[i]
        pshr    r18             ; Push result
        pshr    r16             ; Push return address
        ret

        ;; Convert a binary coded decimal digit to a Seven Segment
        ;; Display cathode mask, with the period set.
        ;;
        ;;   @param  BCD digit
        ;;   @return SSD digit with period
bcd2ssd_p:
        popr    r16
        popr    r17             ; BCD digit 'i'
        ldih    r18, 0
        ldil    r18, _bcd2ssd_t ; r18 = bcd2ssd_t
        ldd     r18, r18, r17   ; r18 = bcd2ss_t[i]
        and     r18, r18, SSD_P_MASK ; Add the period
        pshr    r18             ; Push result
        pshr    r16             ; Push return address
        ret

        ;; Software arithmetic.
        ;; =================================================

        ;; Multiply two unsigned numbers.
        ;;
        ;;   @param  operand A
        ;;   @param  operand B
        ;;   @return result
mult:
        popr    r16             ; Return address
        popr    r17             ; a
        popr    r18             ; b
        clr     r19             ; y = 0
        dec     r18             ; i = b - 1
_mult_2:
        add     r19, r19, r17   ; y += a
        dec     r18             ; i--
        nez     r18             ; Repeat while i > 0
        brts    _mult_2
        pshr    r19             ; Push result
        pshr    r16             ; Push return address
        ret

        ;; Multiply two signed numbers.
        ;;
        ;; @param  operand A
        ;; @param  operand B
        ;; @return result
mults:
        popr    r16             ; Return address
        popr    r17             ; a
        popr    r18             ; b

        ;; Convert negative numbers to positive
        lts     r18, 0          ; IF b < 0
        subs    r17, 0, r17     ; a = 0 - a
        subs    r18, 0, r18     ; b = 0 - b

        pshr    r17             ; Push a
        pshr    r18             ; Push b
        call    mult
        ret

        ;; Unsigned integer division.
        ;;
        ;;   @param  numerator
        ;;   @param  denominator
        ;;   @return result
div:
        popr    r16             ; Return address
        popr    r17             ; a
        popr    r18             ; b
        clr     r19             ; i = 0
_div_2:
        lt      r17, r18        ; IF a < b
        brts    _div_3          ; RETURN
        sub     r17, r17, r18   ; ELSE a -= b
        inc     r19             ; i++
        jmp     _div_2
_div_3:
        pshr    r17             ; Push remainder
        pshr    r19             ; Push result
        pshr    r16             ; Push return address
        ret

;;; Fall-through in case the including library doesn't implement it's
;;; own entry point:
_MAIN_ENTRY_POINT:
        nop
