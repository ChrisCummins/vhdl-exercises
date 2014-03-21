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

        ssd_idx:        .word 1 ; SSD refresh index
        ssd_an_t:       .word 4 ; SSD Anode values
        ssd_ka_t:       .word 4 ; SSD Cathode values


        ;; Program code:
        ;; =================================================

        .cseg

        ;; Working registers
        .def a          r32
        .def b          r33
        .def sum        r34
        .def last       r35
        .def 10reg      r60
        .def 100reg     r61
        .def 1000reg    r62
        .def 10000reg   r63

        .def 1digit     r103
        .def 10digit    r102
        .def 100digit   r101
        .def 1000digit  r100
        .def 10000digit  r99

        .def 1ssd       r107
        .def 10ssd      r106
        .def 100ssd     r105
        .def 1000ssd    r104

        ;; Prepare memory and constant registers
_main:
        cli                     ; Disable interrupts
        st      NULL, ssd_idx   ; SSD counter = 0

        ;; Setup SSD tables
        ldih    r90,  0
        ldil    r90,  0x07
        st      r90,  ssd_an_t
        st      NULL, ssd_ka_t
        ldil    r90,  0x0B
        st      r90,  ssd_an_t + 1
        st      NULL, ssd_ka_t + 1
        ldil    r90,  0x0D
        st      r90,  ssd_an_t + 2
        st      NULL, ssd_ka_t + 2
        ldil    r90,  0x0E
        st      r90,  ssd_an_t + 3
        st      NULL, ssd_ka_t + 3

        ;; Setup constants registers
        ldil    10reg,    10
        ldil    100reg,   100
        ldil    1000reg,  1000
        ldil    10000reg, 10000

        sei                     ; Enable interrupts

        ;; Prepare registers
reset_fib:
        clr     a               ; a = 0
        ldih    b, 0
        ldil    b, 1            ; b = 1
        clr     last

        ;; Fibonacci sequence iteration
next_fib:
        add     sum, a, b       ; sum = a + b
        mov     a, b            ; a = b
        mov     b, sum          ; b = sum

        lt      sum, last       ; IF sum < last
        brts    reset_fib       ; THEN RESET (overflow)
        mov     last, sum       ; last = current

        ;; Binary to BCD conversion
        pshr    10000reg        ; Denominator
        pshr    sum             ; Numerator
        call    div
        popr    10000digit      ; Buffer digit
        popr    r35

        pshr    1000reg         ; Denominator
        pshr    r35             ; Numerator
        call    div
        popr    1000digit       ; Thousand digit
        popr    r35
        pshr    1000digit       ; BCD 2 SSD
        call    bcd2ssd
        popr    1000ssd

        pshr    100reg
        pshr    r35
        call    div
        popr    100digit        ; Hundreds digit
        popr    r35
        pshr    100digit        ; BCD 2 SSD
        call    bcd2ssd
        popr    100ssd

        pshr    10reg
        pshr    r35
        call    div
        popr    10digit         ; Tens digit
        popr    1digit          ; Single digit
        pshr    10digit         ; BCD 2 SSD
        call    bcd2ssd
        popr    10ssd

        pshr    1digit
        lt      sum, 10000reg   ; IF sum < 10000
        brts    next_fib_2      ; THEN bcd2ssd
        call    bcd2ssd_p       ; ELSE bcd2ssd with period
        jmp     next_fib_3
next_fib_2:
        call    bcd2ssd
next_fib_3:
        popr    1ssd

        ;; Write out digits to SSD table
        st      1ssd,    ssd_ka_t
        st      10ssd,   ssd_ka_t + 1
        st      100ssd,  ssd_ka_t + 2
        st      1000ssd, ssd_ka_t + 3

        ;; Wait for next request
        call    btnc_press
        jmp     next_fib

        ;; Clear our symbol space
        .undef a
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

        .isr ISR_SSD ssd_update

ssd_update:
        ;; Preserver registers
        pshr    r10
        pshr    r11

        ;; Prepare registers
        ld      r10, ssd_idx    ; r10 = i
        ldih    r11, 0
        ldil    r11, ssd_an_t   ; r11 = an_t
        ldd     r11, r11, r10   ; r11 = an_t[i]
        stio    SSD_AN, r11

        ldil    r11, ssd_ka_t   ; r11 = ka_t
        ldd     r11, r11, r10   ; r11 = ka_t[i]
        stio    SSD_KA, r11

        ;; Increment index counter
        ldih    r11, 0
        ldil    r11, 4          ; r11 = 4
        inc     r10             ; i++
        lt      r10, r11        ; IF i < 4
        brts    ssd_update_2    ; THEN RETURN
        ldil    r10, 0          ; ELSE i = 0
ssd_update_2:
        st      r10, ssd_idx    ; Memory writes

        ;; Restore register file
        popr    r11
        popr    r10
        reti
