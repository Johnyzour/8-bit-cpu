; fib.asm: Fibonacci numbers into memory, then a multiply subroutine
; Assemble with: python3 tools/asm.py programs/fib.asm -o rtl/program.mem
;
; Part 1 writes the first 10 Fibonacci numbers to F0-F9 through a pointer.
; Part 2 loads two of them back and multiplies them with a subroutine
; (repeated addition): MEM[F6] x MEM[F4] = 0D x 05 = 41, stored at FA.
;
; Final state: R0 = 41, R1 = 00, R2 = 0D, R3 = FA, Z = 1, C = 0, SP = F0
;              MEM[F0-FA] = 01 01 02 03 05 08 0D 15 22 37 41

; Part 1: Fibonacci, a = R0, b = R1
        LDI  R0, 01         ; a = 1
        LDI  R1, 01         ; b = 1
        LDI  R3, 0xF0       ; pointer to F0
        LDI  R2, 0A         ; 10 numbers
fib:    STR  R0, [R3]       ; MEM[pointer] = a
        INC  R3             ; next address
        PUSH R1             ; save b
        ADD  R1, R0         ; b = a + b
        POP  R0             ; a = old b
        DEC  R2
        JNZ  fib            ; 10 times

; Part 2: multiply two of them
        ld   r0, F6         ; R0 = 0D (lower case works too)
        LD   R1, F4         ; R1 = 05
        CALL mul            ; R0 = R0 x R1
        ST   R0, FA         ; MEM[FA] = 41
halt:   JMP  halt

; mul: R0 = R0 x R1 by repeated addition
; R1 must be at least 1; uses R2; R1 ends at 0
mul:
        MOV  R2, R0         ; R2 = multiplicand
        LDI  R0, 00         ; R0 = product
mloop:  ADD  R0, R2
        DEC  R1
        JNZ  mloop
        RET
