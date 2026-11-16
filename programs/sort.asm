; sort.asm: bubble sort of 5 bytes in memory
; Assemble with: python3 tools/asm.py programs/sort.asm -o rtl/program.mem
;
; Writes 5A 13 C7 02 80 to F0-F4, then bubble-sorts them in place into
; ascending (unsigned) order using a pointer, LDR/STR and CMP + JC.
; The pass counter lives in memory at FE, because all four registers are
; busy inside the inner loop.
;
; Final state: R0 = 02 (smallest), R1 = C7 (largest), R2 = 00, R3 = F4,
;              Z = 1, C = 0, SP = F0
;              MEM[F0-F4] = 02 13 5A 80 C7, MEM[FE] = 00

; Unsorted data
        LDI  R0, 5A
        ST   R0, F0
        LDI  R0, 13
        ST   R0, F1
        LDI  R0, C7
        ST   R0, F2
        LDI  R0, 02
        ST   R0, F3
        LDI  R0, 80
        ST   R0, F4

; Bubble sort: 4 passes of 4 compares
        LDI  R2, 04
        ST   R2, FE         ; pass counter = 4
pass:   LDI  R3, F0         ; pointer to the first byte
        LDI  R2, 04         ; compares in this pass
inner:  LDR  R0, [R3]       ; a = MEM[p]
        INC  R3
        LDR  R1, [R3]       ; b = MEM[p + 1]
        CMP  R1, R0         ; b - a: C = 1 if b < a
        JC   swap           ; out of order
next:   DEC  R2
        JNZ  inner
        LD   R2, FE         ; pass counter
        DEC  R2
        ST   R2, FE         ; ST does not change the flags
        JNZ  pass

; Show the smallest and largest
        LD   R0, F0         ; R0 = 02
        LD   R1, F4         ; R1 = C7
halt:   JMP  halt

; swap MEM[p] and MEM[p + 1]; R3 points at p + 1
swap:   STR  R0, [R3]       ; MEM[p + 1] = a
        DEC  R3
        STR  R1, [R3]       ; MEM[p] = b
        INC  R3             ; back to p + 1
        JMP  next