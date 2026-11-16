; test.asm: system test program for the von Neumann CPU
; Assemble with: python3 tools/asm.py programs/test.asm -o rtl/program.mem
; Final state: R0 = E6, R1 = 54, R2 = 00, R3 = F4, Z = 1, C = 0, SP = F0,
;              MEM[F0-F3] = FF 57 3B 54

; ALU, flags and conditional jumps
        LDI  R0, 0F
        LDI  R1, 3C
        MOV  R2, R1         ; R2 = 3C
        ADD  R2, R0         ; R2 = 4B
        AND  R2, R1         ; R2 = 08
        OR   R2, R0         ; R2 = 0F
        XOR  R2, R0         ; R2 = 00, Z = 1
        JZ   skip1          ; taken
        LDI  R3, FF         ; must be skipped
skip1:  NOT  R2             ; R2 = FF
        ST   R2, F0         ; MEM[F0] = FF
        LD   R3, F0         ; R3 = FF
        SUB  R0, R1         ; R0 = D3, C = 1
        JC   skip2          ; taken
        LDI  R3, 00         ; must be skipped
skip2:  CMP  R3, R2         ; Z = 1, R3 unchanged
        JNZ  halt           ; not taken
        NOP
        INC  R2             ; R2 = 00, Z = 1, C = 1
        DEC  R1             ; R1 = 3B
        SHL  R0             ; R0 = A6, C = 1
        SHR  R0             ; R0 = 53, C = 0

; Stack and subroutines
        CALL sub1           ; SP = EF, MEM[EF] = 45
        PUSH R0             ; SP = EF, MEM[EF] = 54
        POP  R2             ; R2 = 54, SP = F0
        LDI  R3, 03         ; loop counter
loop:   CALL sub2           ; R0 = R0 + 1
        DEC  R3
        JNZ  loop           ; 3 times, then R0 = 57
        JMP  pointers       ; to the register-indirect section

sub1:   PUSH R1             ; SP = EE, MEM[EE] = 3B
        LDI  R1, 77         ; R1 = 77
        CALL sub2           ; nested: SP = ED, MEM[ED] = 63
        POP  R1             ; R1 = 3B, SP = EF
        RET                 ; PC = 45, SP = F0

sub2:   INC  R0
        RET

; Register-indirect: store R0-R2 at F1-F3, then sum them back
pointers:
        LDI  R3, F1         ; pointer
        STR  R0, [R3]       ; MEM[F1] = 57
        INC  R3             ; pointer = F2
        STR  R1, [R3]       ; MEM[F2] = 3B
        INC  R3             ; pointer = F3
        STR  R2, [R3]       ; MEM[F3] = 54
        LDI  R0, 00         ; sum
        LDI  R3, F1         ; pointer back to F1
        LDI  R2, 03         ; counter
sum:    LDR  R1, [R3]       ; R1 = MEM[pointer]
        ADD  R0, R1         ; sum
        INC  R3             ; next byte
        DEC  R2
        JNZ  sum            ; 3 times

halt:   JMP  halt           ; R0 = E6
