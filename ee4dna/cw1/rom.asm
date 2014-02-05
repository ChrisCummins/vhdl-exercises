;; Generated assembly, see:
;;     http://chriscummins.cc/disassembler
;;

start:
        seto 0x00, 0x00, 0x00   ; Clear all outputs
label0:
        tsti 0x01, 0x20, 0x00   ; Wait until centre button off
        bic label0
        tsti 0x00, 0xF0, 0x00   ; Test ALL switches are off
        bic label1
        buc label2
label1:
        seto 0x00, 0xFF, 0x80   ; Set LED 0 on
label3:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label3
label4:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label4
        tsti 0x00, 0xF0, 0x70   ; Check for ONLY switch 7
        bic label5
        buc label6
label5:
        seto 0x00, 0xFF, 0x40
label7:
        tsti 0x01, 0x20, 0x20
        bic label7
label8:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label8
        tsti 0x00, 0xF0, 0x00   ; Test ALL switches are off
        bic label9
        buc label10
label9:
        seto 0x00, 0xFF, 0x20
label11:
        tsti 0x01, 0x20, 0x20
        bic label11
label12:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label12
        tsti 0x00, 0xF0, 0x20   ; Check for ONLY switch 2
        bic label13
        buc label14
label13:
        seto 0x00, 0xFF, 0x10
label15:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label15
        seto 0x00, 0xFF, 0x01
        buc label16
label2:
        seto 0x00, 0xFF, 0x80   ; Set TODO:
label17:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label17
label18:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label18
label6:
        seto 0x00, 0xFF, 0x40
label19:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label19
label20:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label20
label10:
        seto 0x00, 0xFF, 0x20
label21:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label21
label22:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label22
label14:
        seto 0x00, 0xFF, 0x10
label23:
        tsti 0x01, 0x20, 0x20   ; Wait until centre button pressed
        bic label23
        seto 0x00, 0xFF, 0x02
label16:
        tsti 0x01, 0x40, 0x00
        bic label16
label24:
        tsti 0x01, 0x40, 0x40
        bic label24
        buc start               ; Repeat
        iuc
        iuc
        iuc
        iuc
        iuc

;; End of program code
