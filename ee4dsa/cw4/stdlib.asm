;;; stdlib.asm - Standard library of utilities and functions
;;;
;;;    Chris Cummins
;;;    17 March 2014
;;;    Aston University
;;;    EE4DSA Digital Systems Design
;;;
;;; ========================================================
;;; Begin code:

;;; User configurable options.
;;; ========================================================

        ;; The start of user program label:
        .defp _STDLIB_USER_ENTRY_POINT _main

        ;; Internally, this library used a number of registers to
        ;; perform initial setup, execute subroutines, etc.

        .defp _STDLIB_REG_BASE 255


;;; Definitions.
;;; ========================================================


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


        ;; Status flag bits.
        ;; =================================================
        .def SREG_I     0       ; Interrupt
        .def SREG_T     1       ; Test flag
        .def SREG_C     2       ; Carry flag


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
        .def SSD_CHAR_0 0xC0
        .def SSD_CHAR_1 0xF9
        .def SSD_CHAR_2 0xA4
        .def SSD_CHAR_3 0xB0
        .def SSD_CHAR_4 0x99
        .def SSD_CHAR_5 0x92
        .def SSD_CHAR_6 0x82
        .def SSD_CHAR_7 0xF8
        .def SSD_CHAR_8 0x80
        .def SSD_CHAR_9 0x90
        ;; AND mask to add the period to SSD.
        .def SSD_P_MASK 0x7F


;;; Initialisation.
;;; ========================================================

        ;; Internal register file subset:
        .defp $r        _STDLIB_REG_BASE
        .defp $r1       $r - 1
        .defp $r2       $r - 2
        .defp $r3       $r - 3
        .defp $r4       $r - 4
        .defp $r5       $r - 5
        .defp $r6       $r - 6
        .defp $r7       $r - 7
        .defp $r8       $r - 8
        .defp $r9       $r - 9
        .defp $ra       $r - 10
        .defp $rb       $r - 11
        .defp $rc       $r - 12
        .defp $rd       $r - 13
        .defp $re       $r - 14
        .defp $rf       $r - 15

        ;; We define a couple of useful symbols to expose the start and
        ;; end ranges of our internal register file to userland.
        .def STDLIB_REG_MIN $rf
        .def STDLIB_REG_MAX $r

        .cseg
        .org PROG_START

        ;; Initialises the microcontroller components and jumps into
        ;; the user specified code entry point.
        ;;
        ;;   @inline
        ;;   @requires _STDLIB_USER_ENTRY_POINT
_stdlib_init:
        call    _bcd2ssd_init     ; Setup bcd2ssd conversion tables
        jmp     _STDLIB_USER_ENTRY_POINT ; Jump to user code entry point


;;; Button input operations.
;;; ========================================================

        ;; Press and release the up button.
        ;;
        ;;   @return void
btnu_press:
        tsti    BUTTONS, BTNU, BTNU
        rbrts   -1
        tsti    BUTTONS, BTNU, 0x00
        rbrts   -1
        ret

        ;; Press and release the down button.
        ;;
        ;;   @return void
btnd_press:
        tsti    BUTTONS, BTND, BTND
        rbrts   -1
        tsti    BUTTONS, BTND, 0x00
        rbrts   -1
        ret

        ;; Press and release the centre button.
        ;;
        ;;   @return void
btnc_press:
        tsti    BUTTONS, BTNC, BTNC
        rbrts   -1
        tsti    BUTTONS, BTNC, 0x00
        rbrts   -1
        ret

        ;; Press and release the left button.
        ;;
        ;;   @return void
btnl_press:
        tsti    BUTTONS, BTNL, BTNL
        rbrts   -1
        tsti    BUTTONS, BTNL, 0x00
        rbrts   -1
        ret

        ;; Press and release the right button.
        ;;
        ;;   @return void
btnr_press:
        tsti    BUTTONS, BTNR, BTNR
        rbrts   -1
        tsti    BUTTONS, BTNR, 0x00
        rbrts   -1
        ret


;;; Seven Segment Display.
;;; ========================================================

        .dseg

        ;; BCD to SSD lookup table
        _bcd2ssd_t:     .word 10

        .cseg

        ;; Initialises _bcd2ssd_t table with SSD characters, where
        ;; the indexes 0-9 in the table correspond to the SSD
        ;; encodings for digits 0-9.
        ;;
        ;;   @inline
        ;;   @reg $r
_bcd2ssd_init:
        ldih    $r, 0
        ldil    $r, SSD_CHAR_0
        st      $r, _bcd2ssd_t
        ldil    $r, SSD_CHAR_1
        st      $r, _bcd2ssd_t + 0x1
        ldil    $r, SSD_CHAR_2
        st      $r, _bcd2ssd_t + 0x2
        ldil    $r, SSD_CHAR_3
        st      $r, _bcd2ssd_t + 0x3
        ldil    $r, SSD_CHAR_4
        st      $r, _bcd2ssd_t + 0x4
        ldil    $r, SSD_CHAR_5
        st      $r, _bcd2ssd_t + 0x5
        ldil    $r, SSD_CHAR_6
        st      $r, _bcd2ssd_t + 0x6
        ldil    $r, SSD_CHAR_7
        st      $r, _bcd2ssd_t + 0x7
        ldil    $r, SSD_CHAR_8
        st      $r, _bcd2ssd_t + 0x8
        ldil    $r, SSD_CHAR_9
        st      $r, _bcd2ssd_t + 0x9
        ret

        ;; Convert a binary coded decimal digit to a Seven Segment
        ;; Display cathode mask.
        ;;
        ;;   @param  BCD digit
        ;;   @return SSD digit
        ;;   @reg    $r-$r2
bcd2ssd:
        popr    $r              ; Return address
        popr    $r1             ; BCD digit 'i'
        ldih    $r2, 0
        ldil    $r2, _bcd2ssd_t ; $r2 = bcd2ssd_t
        ldd     $r2, $r2, $r1   ; $r2 = bcd2ss_t[i]
        pshr    $r2             ; Push result
        pshr    $r              ; Push return address
        ret

        ;; Convert a binary coded decimal digit to a Seven Segment
        ;; Display cathode mask, with the period set.
        ;;
        ;;   @param  BCD digit
        ;;   @return SSD digit with period
        ;;   @reg    $r-$r2
bcd2ssd_p:
        popr    $r              ; Return address
        popr    $r1             ; BCD digit 'i'
        ldih    $r2, 0
        ldil    $r2, _bcd2ssd_t ; $r2 = bcd2ssd_t
        ldd     $r2, $r2, $r1   ; $r2 = bcd2ss_t[i]
        and     $r2, $r2, SSD_P_MASK ; Add the period
        pshr    $r2             ; Push result
        pshr    $r              ; Push return address
        ret

        ;; Converts a binary integer into a set of four cathode masks
        ;; for displaying on the seven segment display, writing the
        ;; results to memory. If the result is greater than 10,000, it
        ;; cannot be displayed on the four digits of the seven segment
        ;; display, and this will be indicated by lighting the decimal
        ;; point of the least significant digit.
        ;;
        ;;   @param  Base address of cathode table
        ;;   @param  Unsigned integer to encode
        ;;   @return void
        ;;   @reg    $r4-$r7
bin2ssd_tm:
        popr    $r4             ; Return address
        popr    $r5             ; Unsigned integer
        popr    $r6             ; cathode_t address
        pshr    $r4             ; Push return address
        ldih    $r4, 0

        ldil    $r4, 10000      ; 10,000 digit
        pshr    $r4
        pshr    $r5
        call    div
        popr    $r7             ; BCD 10,000 digit
        popr    $r5             ; Remainder

        ldil    $r4, 1000       ; 1,000 digit
        pshr    $r4
        pshr    $r5
        call    div
        popr    $r4             ; BCD 1000 digit
        popr    $r5             ; Remainder
        pshr    $r4
        call    bcd2ssd
        popr    $r4             ; SSD 1000 digit
        std     $r6, NULL, $r4  ; STORE SSD 1000 digit
        inc     $r6             ; Bump table address

        ldil    $r4, 100        ; 100 digit
        pshr    $r4
        pshr    $r5
        call    div
        popr    $r4             ; BCD 100 digit
        popr    $r5             ; Remainder
        pshr    $r4
        call    bcd2ssd
        popr    $r4             ; SSD 100 digit
        std     $r6, NULL, $r4  ; STORE SSD 100 digit
        inc     $r6             ; Bump table address

        ldil    $r4, 10         ; 10 digit
        pshr    $r4
        pshr    $r5
        call    div
        popr    $r4             ; BCD 10 digit
        nez     $r7             ; Check whether we've overflown 10,000
        rbrts   3
        call    bcd2ssd         ; (note we leave the remainder on the stack)
        rjmp    2
        call    bcd2ssd_p
        popr    $r5             ; SSD 1 digit
        pshr    $r4
        call    bcd2ssd
        popr    $r4             ; SSD 10 digit
        std     $r6, NULL, $r4  ; STORE SSD 10 digit
        inc     $r6
        std     $r6, NULL, $r5  ; STORE SSD 1 digit
        ret

;;; Software arithmetic.
;;; ========================================================

        ;; Multiply two unsigned numbers.
        ;;
        ;;   @param  operand A
        ;;   @param  operand B
        ;;   @return result
mult:
        popr    $r              ; Return address
        popr    $r1             ; a
        popr    $r2             ; b
        clr     $r3             ; y = 0
        dec     $r2             ; i = b - 1
        add     $r3, $r3, $r1   ; y += a
        dec     $r2             ; i--
        nez     $r2             ; Repeat while i > 0
        rbrts   -3
        pshr    $r3             ; Push result
        pshr    $r              ; Push return address
        ret

        ;; Multiply two signed numbers.
        ;;
        ;; @param  operand A
        ;; @param  operand B
        ;; @return result
mults:
        popr    $r              ; Return address
        popr    $r1             ; a
        popr    $r2             ; b
        lts     $r2, 0          ; IF b < 0
        subs    $r1, 0, $r1     ; a = 0 - a
        subs    $r2, 0, $r2     ; b = 0 - b
        pshr    $r1             ; Push a
        pshr    $r2             ; Push b
        call    mult            ; Unsigned multiplication
        ret

        ;; Unsigned integer division.
        ;;
        ;;   @param  numerator
        ;;   @param  denominator
        ;;   @return remainder
        ;;   @return result
        ;;   @reg    $r-$r3
div:
        popr    $r              ; Return address
        popr    $r1             ; a
        popr    $r2             ; b
        clr     $r3             ; i = 0
        lt      $r1, $r2        ; IF a < b
        rbrts   4               ; RETURN
        sub     $r1, $r1, $r2   ; ELSE a -= b
        inc     $r3             ; i++
        rjmp    -4
        pshr    $r1             ; Push remainder
        pshr    $r3             ; Push result
        pshr    $r              ; Push return address
        ret

;;; Tidy up.
;;; ========================================================

        ;; Remove the definitions for our internal registers
        ;; so as not to pollute the global symbol namespace.
        .undef $r
        .undef $r1
        .undef $r2
        .undef $r3
        .undef $r4
        .undef $r5
        .undef $r6
        .undef $r7
        .undef $r8
        .undef $r9
        .undef $ra
        .undef $rb
        .undef $rc
        .undef $rd
        .undef $re
        .undef $rf

        ;; If the calling code doesn't define an entry point label,
        ;; then assembly will fail, as the _STDLIB_USER_ENTRY_POINT
        ;; label can't be resolved. To prevent this, we define a
        ;; fall-through so that assembly will not fail, and the
        ;; processor will just halt if no main method is provided:
_STDLIB_USER_ENTRY_POINT:
        halt
