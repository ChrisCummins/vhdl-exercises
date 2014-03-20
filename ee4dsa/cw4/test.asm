        .def OFFSET 3

        .cseg
        rjmp    OFFSET
        nop
        nop
        rjmp    -3
        nop
        ldih    r10, 0
        ldil    r10, 10
