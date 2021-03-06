;;; rom.asm - Safe unlocking program
;;
;; The program requires the user to enter a 4 digit PIN code by
;; setting the switches to the appropriate digit and then pressing
;; the center key to confirm the digit. Once completed, LED 0 or
;; 1 is set to display whether the user entered the correct
;; code (4D5A) or not.
;;
;; While functionally identical to the ROM program from coursework
;; 1, this program differs in that the repeated logic to confirm
;; each digit entry with the centre button has been refactored into
;; a subroutine which is called multiple times. This is was not
;; possible in the first coursework as there is no possibility of
;; returning to multiple different addresses using only the branch
;; instructions, achieved by using the stack to store a return address.
;;
;; Generated by http://chriscummins.cc/disassembler and hand-annotated
;; with explanatory comments and clearer label names.

.cseg
.org 0x0000

interrupt_vectors:
        buc    irq0                     ; Interrupt vector 0
        rir                             ; Interrupt vector 1
        rir                             ; Interrupt vector 2
        rir                             ; Interrupt vector 3
        rir                             ; Interrupt vector 4
        rir                             ; Interrupt vector 5
        rir                             ; Interrupt vector 6
        rir                             ; Interrupt vector 7

.org 0x0008

_main:
        cli
        seto   0x00, 0x00, 0x08
        bsr    wait-for-cbtn-release
        tsti   0x00, 0xF0, 0x40         ; Only switch 4 on
        bic    a-correct
        buc    a-incorrect

a-correct:
        seto   0x00, 0xFF, 0x80         ; Toggle LED 7
        bsr    wait-for-cbtn-toggle
        tsti   0x00, 0xF0, 0xD0         ; Only switches 4,3,1 on
        bic    b-correct
        buc    b-incorrect
b-correct:
        seto   0x00, 0xFF, 0x40         ; Toggle LED 6
        bsr    wait-for-cbtn-toggle
        tsti   0x00, 0xF0, 0x50         ; Only switches 4,1 on
        bic    c-correct
        buc    c-incorrect
c-correct:
        seto   0x00, 0xFF, 0x20         ; Toggle LED 5
        bsr    wait-for-cbtn-toggle
        tsti   0x00, 0xF0, 0xA0         ; Only switches 4,2 on
        bic    d-correct
        buc    d-incorrect
d-correct:
        seto   0x00, 0xFF, 0x10         ; Toggle LED 4
d-correct-confirm:
        tsti   0x01, 0x20, 0x20         ; Centre button toggled
        bic    d-correct-confirm
        seto   0x00, 0xFF, 0x01         ; Toggle LED 0
        buc    wait-for-reset

a-incorrect:
        seto   0x00, 0xFF, 0x80         ; Toggle LED 7
        bsr    wait-for-cbtn-toggle
b-incorrect:
        seto   0x00, 0xFF, 0x40         ; Toggle LED 6
        bsr    wait-for-cbtn-toggle
c-incorrect:
        seto   0x00, 0xFF, 0x20         ; Toggle LED 5
        bsr    wait-for-cbtn-toggle
d-incorrect:
        seto   0x00, 0xFF, 0x10         ; Toggle LED 4
d-incorrect-confirm:
        tsti   0x01, 0x20, 0x20
        bic    d-incorrect-confirm
        seto   0x00, 0xFF, 0x02         ; Toggle LED 1

;; End of program:
wait-for-reset:
        tsti   0x01, 0x40, 0x00         ; Down button toggled
        bic    wait-for-reset
wait-for-reset-release:
        tsti   0x01, 0x40, 0x40         ; Down button toggled
        bic    wait-for-reset-release
        buc    _main                    ; Repeat

;; Center button press subroutine:
wait-for-cbtn-toggle:
        tsti   0x01, 0x20, 0x20
        bic    wait-for-cbtn-toggle
wait-for-cbtn-release:
        tsti   0x01, 0x20, 0x00
        bic    wait-for-cbtn-release
        rsr

;; Interrupt vector 0:
irq0:
        seto   0x00, 0xFF, 0x0C         ; Toggle LEDs 0-3
        rir

        iuc
        iuc
        iuc
        iuc
        iuc
        iuc
        iuc
        iuc

;; End of program code
