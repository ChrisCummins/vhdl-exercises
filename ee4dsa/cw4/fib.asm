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

        ;; Our Fibonacci sequence starting inputs:
        .def FIB_A_INIT 4181
        .def FIB_B_INIT 6765

        ;; Data Segment:
        ;; =================================================

        .dseg

bcd_t:          .word UINT_MAX_DIGITS   ; BCD table
ssd_ka_t:       .word UINT_MAX_DIGITS   ; Cathode mask table
ssd_an_t:       .word 4                 ; Anode mask table
p10_t:          .word 10                ; Powers of 10 table
msd:            .word 1                 ; Most significant digit

        ;; Program code:
        ;; =================================================

        .cseg

        ;; Let's start by defining some symbolic names for
        ;; our working registers:
        .def a          r32             ; Fibonacci 'a' operand
        .def b          r33             ; Fibonacci 'b' operand
        .def sum        r34             ; Fibonacci result
        .def msd_r      r35
        .def ssd_ka_r   r36
        .def bcd_r      r37
        .def divisor    r40
        .def bcd        r41
        .def bcd2ssd_r  r42
        .def i          r43

        ;; The main code entry point. Begin by initialising
        ;; register and memory values as required. We do this
        ;; with interrupts disabled since we don't want to
        ;; be accessing uninitialised memory:
_main:
        cli                             ; Disable interrupts
        ldi     bcd_r, bcd_t            ; Set a pointer to the BCD table
        ldi     ssd_ka_r, ssd_ka_t      ; Set a pointer to the cathode table
        ldi     bcd2ssd_r, bcd2ssd_t    ; Set a pointer to the BCD -> SSD table

        ;; Initialise the SSD Anode table
        sti     ssd_an_t,     0x07
        sti     ssd_an_t + 1, 0x0B
        sti     ssd_an_t + 2, 0x0D
        sti     ssd_an_t + 3, 0x0E

        ;; Initialise the SSD Cathode table
        ldi     i, ssd_ka_t + UINT_MAX_DIGITS - 1
        stri    i, SSD_OFF
        dec     i
        gte     i, ssd_ka_r
        rbrts   -3

        ;; Initialise the power of 10 table
        sti     p10_t,              1   ; 10 & 0
        sti     p10_t + 1,         10   ; 10 ^ 1
        sti     p10_t + 2,        100   ; 10 ^ 2
        sti     p10_t + 3,       1000   ; 10 ^ 3
        sti     p10_t + 4,      10000   ; 10 ^ 4
        sti     p10_t + 5,     100000   ; 10 ^ 5
        sti     p10_t + 6,    1000000   ; 10 ^ 6
        sti     p10_t + 7,   10000000   ; 10 ^ 7
        sti     p10_t + 8,  100000000   ; 10 ^ 8
        sti     p10_t + 9, 1000000000   ; 10 ^ 9

        sei                             ; We're all set, so enable interrupts

fib_init:
        ldi     a, FIB_A_INIT
        ldi     b, FIB_B_INIT

fib_iter:                               ; The actual Fibonacci calculation:
        add     sum, a, b               ; sum = a + b
        mov     a, b                    ; a = b
        mov     b, sum                  ; b = sum
        ldil    msd_r, 0                ; Reset msd_r
        ldi     i, UINT_MAX_DIGITS - 1  ; i = MAX - 1

bcd_loop:
        lddi    divisor, i, p10_t       ; divisor = p10[i]
        pshr    divisor                 ; sum /= divisor
        pshr    sum
        call    divu
        popr    bcd
        popr    sum
        eqz     bcd                     ; IF bcd > 0 AND msd = 0, then msd = i+1:
        brts    store_bcd
        nez     msd_r
        brts    store_bcd
        mov     msd_r, i                ; msd_r = i
        inc     msd_r                   ; msd_r = i + 1
store_bcd:                              ; Store BCD digit and store SSD:
        std     bcd_r, i, bcd           ; bcd[i] = bcd
        ldd     bcd, bcd, bcd2ssd_r
        std     ssd_ka_r, i, bcd        ; ssd[i] = ssd
next_bcd_loop:
        eqz     i                       ; If i = 0, exit loop
        brts    _wait_for_next
        dec     i                       ; i--
        jmp     bcd_loop
_wait_for_next:                         ; Wait for button press
        gti     msd_r, 4                ; msd_r = max(msd_r, 4)
        rbrts   2
        ldil    msd_r, 4
        st      msd, msd_r              ; Store msd
        call    btnc_press
        jmp     fib_iter

        ;; Clear up our symbol space:
        .undef a
        .undef b
        .undef sum
        .undef ssd_ka_r
        .undef msd_r
        .undef ssd_ka_r
        .undef bcd_r
        .undef divisor
        .undef bcd
        .undef bcd2ssd_r
        .undef i

;;; Seven Segment Display scroller:
;;; ========================================================

        ;; Data Segment:
        ;; =================================================

        .dseg

msd_v:          .word 1                 ; Most significant visible digit

        ;; Program code:
        ;; =================================================

        .cseg

        ;; Register our interrupt handler:
        .isr ISR_TIMER timer_update

timer_update:
        pshr    r16                     ; Preserve working registers
        pshr    r17
        pshr    r18
        ld      r16, msd                ; r16 = msd
        ld      r17, msd_v              ; r17 = msd_v
        ldi     r18, 4                  ; r18 = 4
        gt      r16, r18                ; IF r16 <= 4, then r17 = 4
        brts    _timer_update
        mov     r17, r18
        jmp     _timer_update3
_timer_update:                          ; Scroll right:
        lte     r17, r18                ; IF r17 >= 4, then r17--
        brts    _timer_update2
        dec     r17
        jmp     _timer_update3
_timer_update2:
        mov     r17, r16                ; ELSE r17 = r16
_timer_update3:
        st      msd_v, r17              ; Store msd_v
        sub     r17, r17, r18           ; msv -= 4
        ldil    r16, 1
        lsl     r16, r16, r17           ; r16 = 1 << (msd_v - 4)
        stio    LEDS, r16               ; LEDS = r16
        popr    r18                     ; Restore working registers
        popr    r17
        popr    r16
        reti


;;; Seven Segment Display driver:
;;; ========================================================

        ;; Data Segment:
        ;; =================================================

        .dseg

ssd_idx:        .word 1                 ; Current digit index

        ;; Program code:
        ;; =================================================

        .cseg

        ;; Register our interrupt handler:
        .isr ISR_SSD ssd_update

        ;; When executed, this routine reads the anode and cathode
        ;; mask of one of the four seven segment display digits
        ;; from memory, and writes out the value to the
        ;; corresponding output port. It then increments and stores
        ;; a counter to determine the next digit to be displayed.
ssd_update:
        pshr    r10                     ; Preserve working registers
        pshr    r11
        pshr    r12
        ld      r10, ssd_idx            ; r10 = i
        lddi    r11, r10, ssd_an_t      ; r11 = an_t[i]
        ld      r12, msd_v              ; r12 = msd_v
        subi    r12, r12, 4             ; r12 -= 4
        add     r12, r12, r10           ; r12 += i
        stio    SSD_AN, r11             ; Write out anode
        lddi    r11, r12, ssd_ka_t      ; r11 = ka_t[msd_v + i - 4]
        stio    SSD_KA, r11             ; Write out cathode
        inc     r10                     ; i++
        lti     r10, 4                  ; IF i < 4
        rbrts   2                       ; THEN RETURN
        ldil    r10, 0                  ; ELSE i = 0
        st      ssd_idx, r10            ; Store i
        popr    r12                     ; Restore working registers
        popr    r11
        popr    r10
        reti
