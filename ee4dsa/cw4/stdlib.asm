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

        ;; Internally, this library uses a number of registers to
        ;; perform initial setup, execute subroutines, etc. These
        ;; registers are given sequentially decreasing addresses,
        ;; starting at this base:
        .defp _STDLIB_REG_BASE 255


;;; Definitions.
;;; ========================================================


        ;; Registers.
        ;; =================================================
        .def NULL       r0              ; Null (zero) register
        .def PC         r1              ; Program counter
        .def SP         r2              ; Stack Pointer
        .def SREG       r3              ; Status register


        ;; Interrupt lines.
        ;; =================================================
        .def ISR_TIMER  0               ; Timer
        .def ISR_SSD    1               ; Seven Segment Display


        ;; Status flag bits.
        ;; =================================================
        .def SREG_I     0               ; Interrupts enabled flag
        .def SREG_T     1               ; Test flag
        .def SREG_C     2               ; Carry flag


        ;; Device IO.
        ;; =================================================

        ;; Input ports
        .def SWITCHES   0x00            ; Input switches port
        .def BUTTONS    0x01            ; Input buttons port

        ;; Output ports
        .def LEDS       0x00            ; Output LEDs port
        .def SSD_AN     0x01            ; Output SSD anodes port
        .def SSD_KA     0x02            ; Output SSD cathodes port

        ;; Button mask bit positions
        .def BTND       4               ; Down button
        .def BTNC       5               ; Centre button
        .def BTNL       6               ; Left button
        .def BTNR       7               ; Right button

        ;; Bit masks for seven segment display characters
        .def SSD_CHAR_0 0b11000000      ; Decimal digit 0
        .def SSD_CHAR_1 0b11111001      ; Decimal digit 1
        .def SSD_CHAR_2 0b10100100      ; Decimal digit 2
        .def SSD_CHAR_3 0b10110000      ; Decimal digit 3
        .def SSD_CHAR_4 0b10011001      ; Decimal digit 4
        .def SSD_CHAR_5 0b10010010      ; Decimal digit 5
        .def SSD_CHAR_6 0b10000010      ; Decimal digit 6
        .def SSD_CHAR_7 0b11111000      ; Decimal digit 7
        .def SSD_CHAR_8 0b10000000      ; Decimal digit 8
        .def SSD_CHAR_9 0b10010000      ; Decimal digit 9
        .def SSD_PERIOD 0b01111111      ; Period '.'
        .def SSD_OFF    0b11111111      ; All segments off


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
        .def STDLIB_REG_MIN $rf         ; Used register file address
        .def STDLIB_REG_MAX $r          ; Highest register file address

        .cseg
        .org PROG_START

        ;; Initialises the microcontroller components and jumps into
        ;; the user specified code entry point.
        ;;
        ;;   @inline
        ;;   @noreturn
        ;;   @requires _STDLIB_USER_ENTRY_POINT
_stdlib_init:
        call    _bcd2ssd_init            ; Setup bcd2ssd conversion table
        jmp     _STDLIB_USER_ENTRY_POINT ; Jump to user code entry point


;;; Button input operations.
;;; ========================================================

        ;; Press and release the up button.
        ;;
        ;;   @return void
btnu_press:
        tsti    BUTTONS, 0, 0
        rbrts   -1
        tsti    BUTTONS, 0, 0
        rbrts   -1
        ret

        ;; Press and release the down button.
        ;;
        ;;   @return void
btnd_press:
        tsti    BUTTONS, 1 << BTND, 1 << BTND
        rbrts   -1
        tsti    BUTTONS, 1 << BTND, 0 << BTND
        rbrts   -1
        ret

        ;; Press and release the centre button.
        ;;
        ;;   @return void
btnc_press:
        tsti    BUTTONS, 1 << BTNC, 1 << BTNC
        rbrts   -1
        tsti    BUTTONS, 1 << BTNC, 0 << BTNC
        rbrts   -1
        ret

        ;; Press and release the left button.
        ;;
        ;;   @return void
btnl_press:
        tsti    BUTTONS, 1 << BTNL, 1 << BTNL
        rbrts   -1
        tsti    BUTTONS, 1 << BTNL, 0 << BTNL
        rbrts   -1
        ret

        ;; Press and release the right button.
        ;;
        ;;   @return void
btnr_press:
        tsti    BUTTONS, 1 << BTNR, 1 << BTNR
        rbrts   -1
        tsti    BUTTONS, 1 << BTNR, 0 << BTNR
        rbrts   -1
        ret


;;; Seven Segment Display.
;;; ========================================================

        .dseg

        ;; BCD to SSD lookup table:
        _bcd2ssd_t:     .word 10

        .cseg

        ;; Initialises _bcd2ssd_t table with SSD characters, where
        ;; the indexes 0-9 in the table correspond to the SSD
        ;; encodings for digits 0-9.
        ;;
        ;;   @inline
        ;;   @return void
_bcd2ssd_init:
        sti     _bcd2ssd_t,       SSD_CHAR_0
        sti     _bcd2ssd_t + 0x1, SSD_CHAR_1
        sti     _bcd2ssd_t + 0x2, SSD_CHAR_2
        sti     _bcd2ssd_t + 0x3, SSD_CHAR_3
        sti     _bcd2ssd_t + 0x4, SSD_CHAR_4
        sti     _bcd2ssd_t + 0x5, SSD_CHAR_5
        sti     _bcd2ssd_t + 0x6, SSD_CHAR_6
        sti     _bcd2ssd_t + 0x7, SSD_CHAR_7
        sti     _bcd2ssd_t + 0x8, SSD_CHAR_8
        sti     _bcd2ssd_t + 0x9, SSD_CHAR_9
        ret

        ;; Convert a binary coded decimal digit to a Seven Segment
        ;; Display cathode mask.
        ;;
        ;;   @param  BCD digit
        ;;   @return SSD digit
        ;;   @reg    $r-$r1
bcd2ssd:
        popr    $r                      ; $r = Return address
        popr    $r1                     ; $r1 = BCD digit 'i'
        lddi    $r1, $r1, _bcd2ssd_t    ; $r1 = bcd2ss_t[i]
        pshr    $r1                     ; Push result
        pshr    $r                      ; Push return address
        ret

        ;; Convert a binary coded decimal digit to a Seven Segment
        ;; Display cathode mask, with the period set.
        ;;
        ;;   @param  BCD digit
        ;;   @return SSD digit with period
        ;;   @reg    $r-$r1
bcd2ssd_p:
        popr    $r                      ; $r = Return address
        popr    $r1                     ; $r1 = BCD digit 'i'
        lddi    $r1, $r1, _bcd2ssd_t    ; $r1 = bcd2ss_t[i]
        andi    $r1, $r1, SSD_PERIOD    ; Add the period
        pshr    $r1                     ; Push result
        pshr    $r                      ; Push return address
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
        popr    $r4                     ; $r4 = Return address
        popr    $r5                     ; $r5 = Unsigned integer
        popr    $r6                     ; $r6 = cathode_t address
        pshr    $r4                     ; Push return address

        pshi    10000                   ; 10,000 digit
        pshr    $r5
        call    divu
        popr    $r7                     ; $r7 = BCD 10,000 digit
        popr    $r5                     ; $r5 = Remainder

        pshi    1000                    ; 1,000 digit
        pshr    $r5
        call    divu
        popr    $r4                     ; $r4 = BCD 1000 digit
        popr    $r5                     ; $r5 = Remainder
        pshr    $r4
        call    bcd2ssd
        popr    $r4                     ; $r4 = SSD 1000 digit
        str     $r6, $r4                ; STORE SSD 1000 digit
        inc     $r6                     ; $r6++ Bump table address

        pshi    100                     ; 100 digit
        pshr    $r5
        call    divu
        popr    $r4                     ; $r4 = BCD 100 digit
        popr    $r5                     ; $r5 = Remainder
        pshr    $r4
        call    bcd2ssd
        popr    $r4                     ; $r4 = SSD 100 digit
        str     $r6, $r4                ; STORE SSD 100 digit
        inc     $r6                     ; $r6++ Bump table address

        pshi    10                      ; 10 digit
        pshr    $r5
        call    divu
        popr    $r4                     ; $r4 = BCD 10 digit
        nez     $r7                     ; Check whether we've overflown 10,000
        rbrts   3
        call    bcd2ssd                 ; Note we left the remainder on the stack
        rjmp    2
        call    bcd2ssd_p
        popr    $r5                     ; $r5 = SSD 1 digit
        pshr    $r4
        call    bcd2ssd
        popr    $r4                     ; $r4 = SSD 10 digit
        str     $r6, $r4                ; STORE SSD 10 digit
        inc     $r6                     ; $r6++ Bump table address
        str     $r6, $r5                ; STORE SSD 1 digit
        ret

;;; Software arithmetic.
;;; ========================================================

        ;; Multiply two unsigned numbers.
        ;;
        ;;   @param  operand A
        ;;   @param  operand B
        ;;   @return result
        ;;   @reg    $r-$r3
multu:
        popr    $r                      ; $r = Return address
        popr    $r1                     ; $r1 = a
        popr    $r2                     ; $r2 = b
        clr     $r3                     ; $r3 = y = 0
        dec     $r2                     ; $r2 = i = b - 1
        add     $r3, $r3, $r1           ; y += a
        dec     $r2                     ; i--
        nez     $r2                     ; Repeat while i > 0
        rbrts   -3
        pshr    $r3                     ; Push result
        pshr    $r                      ; Push return address
        ret

        ;; Unsigned integer division.
        ;;
        ;;   @param  numerator
        ;;   @param  denominator
        ;;   @return remainder
        ;;   @return result
        ;;   @reg    $r-$r3
divu:
        popr    $r                      ; $r = Return address
        popr    $r1                     ; $r1 = a
        popr    $r2                     ; $r2 = b
        clr     $r3                     ; $r3 = i = 0
        lt      $r1, $r2                ; IF a < b
        rbrts   4                       ; RETURN
        sub     $r1, $r1, $r2           ; ELSE a -= b
        inc     $r3                     ; i++
        rjmp    -4
        pshr    $r1                     ; Push remainder
        pshr    $r3                     ; Push result
        pshr    $r                      ; Push return address
        ret


;;; Sorting algorithms.
;;; ========================================================

        ;; In-place Gnome sort for unsigned integer arrays.
        ;;
        ;;   Best-case performance:  O(n)
        ;;   Worst-case performance: O(n^2)
        ;;   Memory complexity:      O(1)
        ;;
        ;;   @param  No of items in array
        ;;   @param  Start address of array
        ;;   @reg    $r-$r5
sortu:
        popr    $r                      ; $r = No of items in the array
        popr    $r1                     ; $r1 = Start address of array
        add     $r2, $r1, $r            ; $r2 = End address of array
        mov     $r3, $r1                ; $r3 = Iterator
_sortu_2:
        gt      $r3, $r2                ; Finish if we've reached the end
        ret
        breq    $r3, $r1, _sortu_3      ; Skip first iteration
        lddi    $r4, $r3, -1            ; $r4 = d[i - 1]
        ldr     $r5, $r3                ; $r5 = d[i]
        brgte   $r5, $r4, _sortu_3      ; If d[i] > d[i - 1]
        stdi    $r3, -1, $r5            ; Swap array elements
        str     $r3, $r4
        dec     $r3                     ; Decrement address
        jmp     _sortu_2
_sortu_3:
        inc     $r3                     ; Increment address
        jmp     _sortu_2                ; Repeat


        ;; In-place Gnome sort for signed integer arrays.
        ;;
        ;;   Best-case performance:  O(n)
        ;;   Worst-case performance: O(n^2)
        ;;   Memory complexity:      O(1)
        ;;
        ;;   @param  No of items in array
        ;;   @param  Start address of array
        ;;   @reg    $r-$r5
sorts:
        popr    $r                      ; $r = No of items in the array
        popr    $r1                     ; $r1 = Start address of array
        add     $r2, $r1, $r            ; $r2 = End address of array
        mov     $r3, $r1                ; $r3 = Iterator
_sorts_2:
        gts     $r3, $r2                ; Finish if we've reached the end
        ret
        breq    $r3, $r1, _sorts_3      ; Skip first iteration
        lddi    $r4, $r3, -1            ; $r4 = d[i - 1]
        ldr     $r5, $r3                ; $r5 = d[i]
        gtes    $r5, $r4                ; If d[i] > d[i - 1]
        brts    _sorts_3
        stdi    $r3, -1, $r5            ; Swap array elements
        str     $r3, $r4
        dec     $r3                     ; Decrement address
        jmp     _sorts_2
_sorts_3:
        inc     $r3                     ; Increment address
        jmp     _sorts_2                ; Repeat


        ;; In-place recursive Quicksort for unsigned integer arrays.
        ;;
        ;;   Best-case performance:  O(n log n)
        ;;   Worst-case performance: O(n^2)
        ;;   Memory complexity:      O(1)
        ;;
        ;;   @param  No of items in array
        ;;   @param  Start address of array
        ;;   @reg    $r-$r7
qsortu:
        popr    $r                      ; $r = No of items in the array
        popr    $r1                     ; $r1 = Start address of array
        add     $r2, $r1, $r            ; $r2 = End address of array
        clr     $r3                     ; $r3 = lowIndex = 0
        mov     $r4, $r2                ; $r4 = highIndex = last address
        call    _qsortu
        ret
_qsortu:                                ; Recursive Main loop:
        lt      $r3, $r4                ; If lowIndex >= highIndex, return
        rbrts   2
        ret
        pshr    $r3                     ; Store lowIndex,  now $r3 is 'i'
        pshr    $r4                     ; Store highIndex, now $r4 is 'j'
        inc     $r4                     ; j = highIndex + 1
        ldd     $r5, $r1, $r3           ; $r5 = Pivot = d[lowIndex]
_qsortu_2:
        inc     $r3                     ; i++
        brgte   $r3, $r4, _qsortu_3     ; IF i >= j, exit loop
        ldd     $r6, $r1, $r3           ; IF d[i] >= Pivot, exit loop
        brgte   $r6, $r5, _qsortu_3
        jmp     _qsortu_2               ; Go back to the top of this loop
_qsortu_3:
        dec     $r4                     ; j--
        ldd     $r6, $r1, $r4           ; IF d[j] <= Pivot, exit loop
        brlte   $r6, $r5, _qsortu_4
        jmp     _qsortu_3               ; Repeat this loop
_qsortu_4:
        brgte   $r3, $r4, _qsortu_6     ; IF i >= j, end main loop
        ldd     $r6, $r1, $r3           ; ELSE swawp d[i] and d[j]
        ldd     $r7, $r1, $r4
        std     $r6, $r1, $r4
        std     $r7, $r1, $r3
        jmp     _qsortu_2
_qsortu_6:
        popr    $r5                     ; $r5 = highIndex
        popr    $r2                     ; $r2 = lowIndex
        breq    $r2, $r4, _qsortu_7     ; IF lowIndex = j, don't swap
        ldd     $r6, $r1, $r2           ; Else, swap d[lowIndex] and d[j]
        ldd     $r7, $r1, $r4
        std     $r6, $r1, $r4
        std     $r7, $r1, $r2
_qsortu_7:                              ; End quick sort:
        mov     $r3, $r2                ; $r3 = lowIndex
        pshr    $r5                     ; Save the high Index
        pshr    $r4                     ; Save j
        dec     $r4                     ; j--
        call    _qsortu                 ; Recurse: array, lowIndex, j - 1
        popr    $r3                     ; $r3 = j
        inc     $r3                     ; j++
        popr    $r4                     ; $r4 = highIndex
        call    _qsortu                 ; Recurse: array, j+1, highIndex

        ;; In-place recursive Quicksort for signed integer arrays.
        ;;
        ;;   Best-case performance:  O(n log n)
        ;;   Worst-case performance: O(n^2)
        ;;   Memory complexity:      O(1)
        ;;
        ;;   @param  No of items in array
        ;;   @param  Start address of array
        ;;   @reg    $r-$r7
qsorts:
        popr    $r                      ; $r = No of items in the array
        popr    $r1                     ; $r1 = Start address of array
        add     $r2, $r1, $r            ; $r2 = End address of array
        clr     $r3                     ; $r3 = lowIndex = 0
        mov     $r4, $r2                ; $r4 = highIndex = last address
        call    _qsorts
        ret
_qsorts:                                ; Recursive Main loop:
        lt      $r3, $r4                ; If lowIndex >= highIndex, return
        rbrts   2
        ret
        pshr    $r3                     ; Store lowIndex,  now $r3 is 'i'
        pshr    $r4                     ; Store highIndex, now $r4 is 'j'
        inc     $r4                     ; j = highIndex + 1
        ldd     $r5, $r1, $r3           ; $r5 = Pivot = d[lowIndex]
_qsorts_2:
        inc     $r3                     ; i++
        brgte   $r3, $r4, _qsorts_3     ; IF i >= j, exit loop
        ldd     $r6, $r1, $r3           ; IF d[i] >= Pivot, exit loop
        gtes    $r6, $r5
        brts    _qsorts_3
        jmp     _qsorts_2               ; Go back to the top of this loop
_qsorts_3:
        dec     $r4                     ; j--
        ldd     $r6, $r1, $r4           ; IF d[j] <= Pivot, exit loop
        ltes    $r6, $r5
        brts    _qsorts_4
        jmp     _qsorts_3               ; Repeat this loop
_qsorts_4:
        brgte   $r3, $r4, _qsorts_6     ; IF i >= j, end main loop
        ldd     $r6, $r1, $r3           ; ELSE swawp d[i] and d[j]
        ldd     $r7, $r1, $r4
        std     $r6, $r1, $r4
        std     $r7, $r1, $r3
        jmp     _qsorts_2
_qsorts_6:
        popr    $r5                     ; $r5 = highIndex
        popr    $r2                     ; $r2 = lowIndex
        breq    $r2, $r4, _qsorts_7     ; IF lowIndex = j, don't swap
        ldd     $r6, $r1, $r2           ; Else, swap d[lowIndex] and d[j]
        ldd     $r7, $r1, $r4
        std     $r6, $r1, $r4
        std     $r7, $r1, $r2
_qsorts_7:                              ; End quick sort:
        mov     $r3, $r2                ; $r3 = lowIndex
        pshr    $r5                     ; Save the high Index
        pshr    $r4                     ; Save j
        dec     $r4                     ; j--
        call    _qsorts                 ; Recurse: array, lowIndex, j - 1
        popr    $r3                     ; $r3 = j
        inc     $r3                     ; j++
        popr    $r4                     ; $r4 = highIndex
        call    _qsorts                 ; Recurse: array, j+1, highIndex


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
