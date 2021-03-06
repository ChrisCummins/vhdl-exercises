;;; rom.asm - Safe unlocking program
;;
;; The program requires the user to enter a 4 digit PIN code by
;; setting the switches to the appropriate digit and then pressing
;; the center key to confirm the digit. Once completed, LED 0 or
;; 1 is set to display whether the user entered the correct
;; code (2013) or not.
;;
;; While functionally similar to the ROM program from coursework
;; 2, this program uses the new instructions implemented in the
;; updated EU, although their use is somewhat arbitrary since the
;; actual code path for testing the correct safe unlocking code does
;; not require any ALU or register operations.
;;
;; Generated by http://chriscummins.cc/disassembler and hand-annotated
;; with clearer comments, labels, and data segment. Assembly mnemonics
;; based upon AVR instruction set http://www.atmel.com/images/doc0856.pdf.


;; Program data
.dseg
.org 0x00000042

        foobar:         .BYTE 4         ; RAM[0x42]
        _pad:           .BYTE 20        ; Offset 20 bytes to 0x48
        alice:          .BYTE 4         ; RAM[0x48]
        bob:            .BYTE 4         ; RAM[0x49]
        cat:            .BYTE 4         ; RAM[0x4A]
        dave:           .BYTE 4         ; RAM[0x4B]

;; Start of program code
.cseg
.org 0x00000000

interrupt_vectors:
        jmp     irq0                    ; Interrupt vector 0
        jmp     irq1                    ; Interrupt vector 1
        reti                            ; Interrupt vector 2
        reti                            ; Interrupt vector 3
        reti                            ; Interrupt vector 4
        reti                            ; Interrupt vector 5
        reti                            ; Interrupt vector 6
        reti                            ; Interrupt vector 7

.org 0x00000008

_main:
        jmp     init

a_digit:
        seto    0x00, 0x00, 0x88        ; OUT[0] = (OUT[0] & 0x00) ^ 0x88
        call    c_button_toggle
        tsti    0x00, 0xF0, 0x20        ; Switch 2 high
        brts    a_digit_correct         ; Branch to 0x00000E if SR[T] set
        jmp     a_digit_incorrect       ; Jump to 0x000022
a_digit_correct:
        seto    0x00, 0x0F, 0x40        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x40
        call    c_button_toggle
        tsti    0x00, 0xF0, 0x00        ; All switches off
        brts    b_digit_correct         ; Branch to 0x000013 if SR[T] set
        jmp     b_digit_incorrect       ; Jump to 0x000024
b_digit_correct:
        seto    0x00, 0x0F, 0x20        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x20
        call    c_button_toggle
        tsti    0x00, 0xF0, 0x10        ; Switch 1 high
        brts    c_digit_correct         ; Branch to 0x000018 if SR[T] set
        jmp     c_digit_incorrect       ; Jump to 0x000026
c_digit_correct:
        seto    0x00, 0x0F, 0x10        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x10
        call    c_button_toggle
        tsti    0x00, 0xF0, 0x30        ; Switches 1 and 2 high
        brts    d_digit_correct         ; Branch to 0x00001D if SR[T] set
        jmp     d_digit_incorrect       ; Jump to 0x000028
d_digit_correct:
        seto    0x00, 0x0F, 0x00        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x00
d_digit_correct_confirm:
        tsti    0x01, 0x20, 0x20        ; SR[T] = (OUT[1] & 0x20) ^ 0x20
        brts    d_digit_correct_confirm ; Branch to 0x00001E if SR[T] set
        seto    0x00, 0x0C, 0x01        ; OUT[0] = (OUT[0] & 0x0C) ^ 0x01
        jmp     reset                   ; Jump to 0x00002C
a_digit_incorrect:
        seto    0x00, 0x0F, 0x40        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x40
        call    c_button_toggle
b_digit_incorrect:
        seto    0x00, 0x0F, 0x20        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x20
        call    c_button_toggle
c_digit_incorrect:
        seto    0x00, 0x0F, 0x10        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x10
        call    c_button_toggle
d_digit_incorrect:
        seto    0x00, 0x0F, 0x00        ; OUT[0] = (OUT[0] & 0x0F) ^ 0x00
d_digit_incorrect_confirm:
        tsti    0x01, 0x20, 0x20        ; SR[T] = (OUT[1] & 0x20) ^ 0x20
        brts    d_digit_incorrect_confirm ; Branch to 0x000029 if SR[T] set
        seto    0x00, 0x0C, 0x02        ; OUT[0] = (OUT[0] & 0x0C) ^ 0x02
reset:
        tsti    0x01, 0x40, 0x00        ; SR[T] = (OUT[1] & 0x40) ^ 0x00
        brts    reset                   ; Branch to 0x00002C if SR[T] set
reset_release:
        tsti    0x01, 0x40, 0x40        ; SR[T] = (OUT[1] & 0x40) ^ 0x40
        brts    reset_release           ; Branch to 0x00002E if SR[T] set
        jmp     init                    ; Jump to 0x000054

;; Digit confirmation routine
c_button_toggle:
        tsti    0x01, 0x20, 0x20        ; Wait until centre button pressed
        brts    c_button_toggle
c_button_release:
        tsti    0x01, 0x20, 0x00        ; Wait until centre button released
        brts    c_button_release
        mtr     r32, foobar             ; r32 = foobar
        ldl     r33, 0x0008             ; r33L = 0x0008
        imtr    r34, r32, r33           ; r34 = RAM[r32 + r33]
        rtm     r34, foobar             ; foobar = r34
        ret

.org 0x00000040

;; Interrupt 0 - toggle LEDs 1 & 2.
irq0:
        seto    0x00, 0xFF, 0x0C        ; OUT[0] = (OUT[0] & 0xFF) ^ 0x0C
        reti

.org 0x00000054

;; Initialisation routine:
init:
        sei                             ; Global interrupt enable
        ldl     r32, 0x0048             ; r32L = 0x0048
        rtm     r32, foobar             ; foobar = r32
        ldl     r32, 0x0020             ; r32L = 0x0020
        rtm     r32, alice              ; alice = r32
        rtm     r32, bob                ; bob = r32
        rtm     r32, cat                ; cat = r32
        rtm     r32, dave               ; dave = r32
        call    test_stack              ; Call 0x000081
        jmp     a_digit                 ; Jump to 0x000009

.org 0x00000081

test_stack:
        pshr    SP                      ; Push register SP to stack
        popr    NULL                    ; Pop stack to register NULL
        pshr    NULL                    ; Push register NULL to stack
        popr    NULL                    ; Pop stack to register NULL
        pshr    SREG                    ; Push register SREG to stack
        popr    NULL                    ; Pop stack to register NULL
        pshr    r3                      ; Push register r3 to stack
        popr    NULL                    ; Pop stack to register NULL
        ret

.org 0x00000090

;; Interrupt 1 - thrashes the register file a bit and writes a couple of ports
irq1:
        mtr     r16, 0x000043           ; r16 = RAM[0x000043]
        ldl     r17, 0x0004             ; r17L = 0x0004
        ldl     r18, 0x0008             ; r18L = 0x0008
        imtr    r19, r16, r17           ; r19 = RAM[r16 + r17]
        imtr    r20, r16, r18           ; r20 = RAM[r16 + r18]
        ldl     r21, 0x0060             ; r21L = 0x0060
        imtr    r22, r21, r19           ; r22 = RAM[r21 + r19]
        iotr    r23, 0x00               ; r23 = OUT[0]
        srlr    r24, r23, r4            ; r24 = r23 >> r4
        mtr     r25, foobar             ; r25 = foobar
        rtim    r25, NULL, r24          ; RAM[NULL + r24] = r25
        rtio    0x01, r20               ; OUT[1] = r20
        rtio    0x02, r22               ; OUT[2] = r22
        imtr    r20, r16, NULL          ; r20 = RAM[r16 + NULL]
        rtm     r20, 0x000043           ; RAM[0x000043] = r20

;; End of program code
