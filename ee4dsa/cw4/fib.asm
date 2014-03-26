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
        .def FIB_A_INIT  0
        .def FIB_B_INIT  1

        ;; The number of iterations before resetting:
        .def FIB_UBOUND  47

        ;; The rate counter for the scrolling display.
        ;; Larger numbers means slower scrolling:
        .def SCROLL_RATE 1

        ;; Data Segment:
        ;; =================================================

        .dseg

        ;; In order to make for easy analysis of program behaviour in
        ;; gtkwave, we'll let the assembler pack our program code into
        ;; the lower addresses, but store our data at a predetermined,
        ;; fixed point in memory: 2000. This means we can set our
        ;; gtkwave view to display those fixed memory addresses
        ;; without having to worry about changes to the program code
        ;; relocating the data segment:
        ;;
        ;;  Addresses:  0 ----------------------- 2000 ------------- 4096
        ;;  Values:     | STDLIB | CODE |  unused | DATA |   unused  |
        ;;
        ;; In order to achieve this, we need to save the current
        ;; address in the assembler, which we do by evaluating the
        ;; dynamic symbol ACTIVE_ADDRESS and assigning it to a
        ;; constant symbol, START_ADDR:
        .def START_ADDR ACTIVE_ADDRESS
        ;; We can now set the data segment to our known fixed address:
        .org 2000
bcd_t:          .word UINT_MAX_DIGITS   ; BCD table
ssd_ka_t:       .word UINT_MAX_DIGITS   ; Cathode mask table
ssd_an_t:       .word 4                 ; Anode mask table
msd:            .word 1                 ; Most significant digit
msd_v:          .word 1                 ; Most significant visible digit
msd_vc:         .word 1                 ; Most significant visible digit counter
ssd_idx:        .word 1                 ; Current digit index
p10_t:          .word 10                ; Powers of 10 table
        ;; Now that we have our fixed address data set, we can continue the
        ;; assembly from the lowest free address:
        .org START_ADDR

        ;; Program code:
        ;; =================================================

        .cseg

        ;; Let's start by defining some symbolic names for
        ;; our working registers:
        .def a          r32             ; Fibonacci 'a' operand
        .def b          r33             ; Fibonacci 'b' operand
        .def sum        r34             ; Fibonacci result
        .def n          r35             ; Fibonacci index counter
        .def n_max      r36             ; Fibonacci index max
        .def msd_r      r37             ; Most significant digit
        .def bcd        r38             ; BCD working register
        .def divisor    r39             ; BCD working register (divisor)
        .def i          r40             ; BCD iterator
        .def i_start    r41             ; BCD iterator starting value
        .def const4     r42             ; Integer constant 4
        .def bcd2ssd_r  r43             ; Pointer to bcd2ssd table
        .def ssd_ka_r   r44             ; Pointer to ssd table
        .def bcd_r      r45             ; Pointer to bcd table
        .def p10_r      r46             ; Pointer to p10 table

        ;; The main code entry point. Begin by initialising
        ;; register and memory values as required. We do this
        ;; with interrupts disabled since we don't want to
        ;; be accessing uninitialised memory:
_main:
        cli                             ; Disable interrupts

        ;; Load register constant values:
        ldi     const4, 4
        ldi     i_start,   UINT_MAX_DIGITS - 1
        ldi     n_max,     FIB_UBOUND
        ldi     bcd_r,     bcd_t
        ldi     ssd_ka_r,  ssd_ka_t
        ldi     bcd2ssd_r, bcd2ssd_t
        ldi     p10_r,     p10_t

        ;; Initialise the SSD Anode table
        sti     ssd_an_t,     0x07
        sti     ssd_an_t + 1, 0x0B
        sti     ssd_an_t + 2, 0x0D
        sti     ssd_an_t + 3, 0x0E
        ;; Overflow the scroll counter
        sti     msd_vc, ~0x00

        ;; Initialise the power of 10 table
        sti     p10_t,              1   ; 10 ^ 0
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
        ;; Set starting series stimuli:
        ldi     a, FIB_A_INIT
        ldi     b, FIB_B_INIT
        ldi     n, 0

        ;; Turn off all SSD digits:
        ldi     i, ssd_ka_t + UINT_MAX_DIGITS - 1
        stri    i, SSD_OFF
        dec     i
        gte     i, ssd_ka_r
        rbrts   -3
;;; Fibonacci iterator:
fib_iter:
        add     sum, a, b               ; sum = a + b
        mov     a, b                    ; a = b
        mov     b, sum                  ; b = sum
        ldil    msd_r, 0                ; Reset msd_r
        mov     i, i_start              ; i = MAX - 1
;;; BCD decoding / SSD encoding loop:
bcd_loop:
        ldd     divisor, p10_r, i       ; divisor = p10[i]
        pshr    divisor                 ; sum /= divisor
        pshr    sum
        call    divu
        popr    bcd
        popr    sum
        eqz     bcd                     ; IF bcd > 0 AND msd = 0, then msd = i+1:
        brts    bcd_loop2
        nez     msd_r
        brts    bcd_loop2
        mov     msd_r, i                ; msd_r = i
        inc     msd_r                   ; msd_r = i + 1
bcd_loop2:                              ; Store BCD digit and store SSD:
        std     bcd_r, i, bcd           ; bcd[i] = bcd
        eqz     msd_r                   ; IF msd = 0, then DON'T store SSD
        brts    bcd_loop_end
        ldd     bcd, bcd2ssd_r, bcd
        std     ssd_ka_r, i, bcd        ; ssd[i] = bcd2ssd[i]
bcd_loop_end:
        eqz     i                       ; If i = 0, exit loop
        brts    fib_iter2
        dec     i                       ; i--
        jmp     bcd_loop
;;; End of BCD loop:
fib_iter2:                              ; Wait for button press
        gt      msd_r, const4           ; msd_r = max(msd_r, 4)
        rbrts   2
        mov     msd_r, const4
        st      msd, msd_r              ; Store msd
        call    btnc_press
        inc     n                       ; Bump our counter
        lte     n, n_max                ; IF n <= n_max, then repeat
        brts    fib_iter
        jmp     fib_init                ; ELSE reset

        ;; Clear up our symbol space:
        .undef a
        .undef b
        .undef sum
        .undef n
        .undef n_max
        .undef msd_r
        .undef bcd
        .undef divisor
        .undef i
        .undef i_start
        .undef const4
        .undef bcd2ssd_r
        .undef ssd_ka_r
        .undef bcd_r
        .undef p10_r


;;; Seven Segment Display scrolling:
;;; ========================================================

        ;; Register our interrupt handler:
        .isr ISR_TIMER timer_update

timer_update:
        pshr    r16                     ; Preserve working register
        ld      r16, msd_vc             ; r16 = msd_vc
        gti     r16, SCROLL_RATE        ; IF msd_vc >= SCROLL_RATE
        brts    timer_update2
        inc     r16
        st      msd_vc, r16             ; THEN store counter and return
        jmp     timer_update6
timer_update2:
        pshr    r17                     ; Preserve working registers
        pshr    r18
        st      msd_vc, NULL            ; ELSE reset counter
        ld      r16, msd                ; r16 = msd
        ld      r17, msd_v              ; r17 = msd_v
        ldi     r18, 4                  ; r18 = 4
        gt      r16, r18                ; IF msd <= 4, then msd_v = 4
        brts    timer_update3
        mov     r17, r18
        jmp     timer_update5
timer_update3:                          ; Scroll right:
        lte     r17, r18                ; IF msd_v >= 4, then msd_v--
        brts    timer_update4
        dec     r17
        jmp     timer_update5
timer_update4:
        mov     r17, r16                ; ELSE msd_v = msd
timer_update5:
        st      msd_v, r17              ; Store msd_v
        sub     r17, r17, r18           ; msd_v -= 4
        ldil    r16, 1
        lsl     r16, r16, r17           ; r16 = 1 << (msd_v - 4)
        popr    r18                     ; Restore working registers
        popr    r17
timer_update6:
        popr    r16                     ; Restore working register
        reti


;;; Seven Segment Display driver:
;;; ========================================================

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
