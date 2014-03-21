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

        ;; Hexadecimal encodings for digits oriented abcdefg
        .def SSD_A2G_0  0x7E
        .def SSD_A2G_1  0x30
        .def SSD_A2G_2  0x6D
        .def SSD_A2G_3  0x79
        .def SSD_A2G_4  0x33
        .def SSD_A2G_5  0x5B
        .def SSD_A2G_6  0x5F
        .def SSD_A2G_7  0x70
        .def SSD_A2G_8  0x7F
        .def SSD_A2G_9  0x7B
        .def SSD_A2G_A  0x77
        .def SSD_A2G_B  0x1F
        .def SSD_A2G_C  0x4E
        .def SSD_A2G_D  0x3D
        .def SSD_A2G_E  0x4F
        .def SSD_A2G_F  0x47

        ;; Hexadecimal encodings for digits oriented gfedcba
        .def SSD_G2A_0  0x3F
        .def SSD_G2A_1  0x06
        .def SSD_G2A_2  0x5B
        .def SSD_G2A_3  0x4F
        .def SSD_G2A_4  0x66
        .def SSD_G2A_5  0x6D
        .def SSD_G2A_6  0x7D
        .def SSD_G2A_7  0x07
        .def SSD_G2A_8  0x7F
        .def SSD_G2A_9  0x6F
        .def SSD_G2A_A  0x77
        .def SSD_G2A_B  0x7C
        .def SSD_G2A_C  0x39
        .def SSD_G2A_D  0x5E
        .def SSD_G2A_E  0x79
        .def SSD_G2A_F  0x71

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

        _bcd2ssd_t:     .word 16 ; BCD to SSD lookup table

        .cseg

_bcd2ssd_init:
        ldih    r16, 0
        ldil    r16, SSD_A2G_0
        st      r16, _bcd2ssd_t
        ldil    r16, SSD_A2G_1
        st      r16, _bcd2ssd_t + 0x1
        ldil    r16, SSD_A2G_2
        st      r16, _bcd2ssd_t + 0x2
        ldil    r16, SSD_A2G_3
        st      r16, _bcd2ssd_t + 0x3
        ldil    r16, SSD_A2G_4
        st      r16, _bcd2ssd_t + 0x4
        ldil    r16, SSD_A2G_5
        st      r16, _bcd2ssd_t + 0x5
        ldil    r16, SSD_A2G_6
        st      r16, _bcd2ssd_t + 0x6
        ldil    r16, SSD_A2G_7
        st      r16, _bcd2ssd_t + 0x7
        ldil    r16, SSD_A2G_8
        st      r16, _bcd2ssd_t + 0x8
        ldil    r16, SSD_A2G_9
        st      r16, _bcd2ssd_t + 0x9
        ldil    r16, SSD_A2G_A
        st      r16, _bcd2ssd_t + 0xA
        ldil    r16, SSD_A2G_B
        st      r16, _bcd2ssd_t + 0xB
        ldil    r16, SSD_A2G_C
        st      r16, _bcd2ssd_t + 0xC
        ldil    r16, SSD_A2G_D
        st      r16, _bcd2ssd_t + 0xD
        ldil    r16, SSD_A2G_E
        st      r16, _bcd2ssd_t + 0xE
        ldil    r16, SSD_A2G_D
        st      r16, _bcd2ssd_t + 0xF
        ret

bcd2ssd:
        popr    r16             ; Return address
        popr    r17             ; BCD digit 'i'
        ldih    r18, 0
        ldil    r18, _bcd2ssd_t ; r18 = bcd2ssd_t
        ldd     r18, r18, r17   ; r19 = bcd2ss_t[i]
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
