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

;;; Main routine:
;;; ========================================================

        ;; Data Segment:
        ;; =================================================

        .dseg

        ;; Seven segment display memory:
        ssd_an_t:       .word 4         ; Anode mask table
        ssd_ka_t:       .word 4         ; Cathode mask table


        ;; Program code:
        ;; =================================================

        .cseg

        ;; Let's start by defining some symbolic names for
        ;; our working registers:
        .def a          r32
        .def b          r33
        .def sum        r34
        .def last       r35
        .def ssd_ka_r   r26

        ;; The main code entry point. Begin by initialising
        ;; register and memory values as required. We do this
        ;; with interrupts disabled since we don't want to
        ;; be accessing uninitialised memory:
_main:
        cli                             ; Disable interrupts
        ldi     ssd_ka_r, ssd_ka_t      ; Set a pointer to the cathode table
        sti     SSD_OFF, ssd_ka_t       ; Zero the cathode table
        sti     SSD_OFF, ssd_ka_t + 1
        sti     SSD_OFF, ssd_ka_t + 2
        sti     SSD_OFF, ssd_ka_t + 3
        sti     0x07,    ssd_an_t       ; Anode table with fixed order
        sti     0x0B,    ssd_an_t + 1
        sti     0x0D,    ssd_an_t + 2
        sti     0x0E,    ssd_an_t + 3
        sei                             ; We're all set, so enable interrupts
reset_fib:
        ldi     a, 0                    ; a = 0
        ldi     b, 1                    ; b = 1
        ldi     last, 0
next_fib:                               ; The actual Fibonacci calculation:
        add     sum, a, b               ; sum = a + b
        mov     a, b                    ; a = b
        mov     b, sum                  ; b = sum
        brlt    sum, last, reset_fib    ; Reset if we have integer overflow
        mov     last, sum               ; last = current
        pshr    ssd_ka_r                ; Update the SSD cathode table
        pshr    sum
        call    bin2ssd_tm
        call    btnc_press              ; Wait for user button press
        jmp     next_fib                ; Rinse and repeat

        ;; Clear up our symbol space:
        .undef a
        .undef b
        .undef sum
        .undef last
        .undef ssd_ka_r

;;; Seven Segment Display driver:
;;; ========================================================

        ;; Data Segment:
        ;; =================================================

        .dseg

        ssd_idx:        .word 1         ; Current digit index

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
        ld      r10, ssd_idx            ; r10 = i
        lddi    r11, r10, ssd_an_t      ; r11 = an_t[i]
        stio    SSD_AN, r11             ; Write out anode
        lddi    r11, r10, ssd_ka_t      ; r11 = ka_t[i]
        stio    SSD_KA, r11             ; Write out cathode
        inc     r10                     ; i++
        lti     r10, 4                  ; IF i < 4
        rbrts   2                       ; THEN RETURN
        ldil    r10, 0                  ; ELSE i = 0
        st      r10, ssd_idx            ; Store i
        popr    r11                     ; Restore working registers
        popr    r10
        reti
