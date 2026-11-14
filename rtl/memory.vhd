--------------------------------------------------------------------------------
-- File        : memory.vhd
-- Description : 256 x 8-bit shared memory holding both the program and the
--               data (von Neumann architecture).
-- Notes       : Synchronous write when wr_en = 1. Synchronous read: data_out
--               shows the byte at addr one clock after the address is applied.
--               A write and a read of the same address on the same edge return
--               the old byte (read-first).
--               Each 24-bit instruction is stored as three bytes at 3n, 3n+1,
--               3n+2: opcode, rd/rs, imm. Code starts at 00; data uses F0-FF;
--               the stack grows down for EF.
--               To change the program, edit the program constant; init_mem
--               splits it into bytes. Unused addresses hold 00 (NOP).
--               No reset: contents survive a CPU reset.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity memory is
    port ( 
        clk      : in  std_logic;
        wr_en    : in  std_logic;
        addr     : in  std_logic_vector (7 downto 0);
        data_in  : in  std_logic_vector (7 downto 0);
        data_out : out std_logic_vector (7 downto 0)
    );
end entity memory;

architecture rtl of memory is
    type mem_type  is array (0 to 255) of std_logic_vector (7 downto 0);
    type prog_type is array (natural range <>) of std_logic_vector (23 downto 0);
    
    constant prog_data : prog_type := (
        0  => OP_LDI  & REG0 & REG0 & x"0F",   -- LDI R0, 0F
        1  => OP_LDI  & REG1 & REG0 & x"3C",   -- LDI R1, 3C
        2  => OP_MOV  & REG2 & REG1 & x"00",   -- MOV R2, R1      R2 = 3C
        3  => OP_ADD  & REG2 & REG0 & x"00",   -- ADD R2, R0      R2 = 4B
        4  => OP_AND  & REG2 & REG1 & x"00",   -- AND R2, R1      R2 = 08
        5  => OP_OR   & REG2 & REG0 & x"00",   -- OR  R2, R0      R2 = 0F
        6  => OP_XOR  & REG2 & REG0 & x"00",   -- XOR R2, R0      R2 = 00, Z = 1
        7  => OP_JZ   & REG0 & REG0 & x"1B",   -- JZ 1B           taken
        8  => OP_LDI  & REG3 & REG0 & x"FF",   -- LDI R3, FF      must be skipped
        9  => OP_NOT  & REG2 & REG0 & x"00",   -- NOT R2          R2 = FF
        10 => OP_ST   & REG2 & REG0 & x"F0",   -- ST R2, F0       MEM[F0] = FF
        11 => OP_LD   & REG3 & REG0 & x"F0",   -- LD R3, F0       R3 = FF
        12 => OP_SUB  & REG0 & REG1 & x"00",   -- SUB R0, R1      R0 = D3, C = 1
        13 => OP_JC   & REG0 & REG0 & x"2D",   -- JC 2D           taken
        14 => OP_LDI  & REG3 & REG0 & x"00",   -- LDI R3, 00      must be skipped
        15 => OP_CMP  & REG3 & REG2 & x"00",   -- CMP R3, R2      Z = 1, R3 unchanged
        16 => OP_JNZ  & REG0 & REG0 & x"57",   -- JNZ 57          not taken
        17 => OP_NOP  & REG0 & REG0 & x"00",   -- NOP
        18 => OP_INC  & REG2 & REG0 & x"00",   -- INC R2          R2 = 00, Z = 1, C = 1
        19 => OP_DEC  & REG1 & REG0 & x"00",   -- DEC R1          R1 = 3B
        20 => OP_SHL  & REG0 & REG0 & x"00",   -- SHL R0          R0 = A6, C = 1
        21 => OP_SHR  & REG0 & REG0 & x"00",   -- SHR R0          R0 = 53, C = 0
        22 => OP_CALL & REG0 & REG0 & x"5A",   -- CALL 5A         SP = EF, MEM[EF] = 45
        23 => OP_PUSH & REG0 & REG0 & x"00",   -- PUSH R0         SP = EF, MEM[EF] = 54
        24 => OP_POP  & REG2 & REG0 & x"00",   -- POP R2          R2 = 54, SP = F0
        25 => OP_LDI  & REG3 & REG0 & x"03",   -- LDI R3, 03      loop counter
        26 => OP_CALL & REG0 & REG0 & x"69",   -- CALL 69         loop: R0 = R0 + 1
        27 => OP_DEC  & REG3 & REG0 & x"00",   -- DEC R3
        28 => OP_JNZ  & REG0 & REG0 & x"4E",   -- JNZ 4E          3 times, then R0 = 57
        29 => OP_JMP  & REG0 & REG0 & x"57",   -- JMP 57 (halt)
        30 => OP_PUSH & REG1 & REG0 & x"00",   -- PUSH R1         SP = EE, MEM[EE] = 3B
        31 => OP_LDI  & REG1 & REG0 & x"77",   -- LDI R1, 77      R1 = 77
        32 => OP_CALL & REG0 & REG0 & x"69",   -- CALL 69         nested: SP = ED, MEM[ED] = 63
        33 => OP_POP  & REG1 & REG0 & x"00",   -- POP R1          R1 = 3B, SP = EF
        34 => OP_RET  & REG0 & REG0 & x"00",   -- RET             PC = 45, SP = F0
        35 => OP_INC  & REG0 & REG0 & x"00",   -- INC R0
        36 => OP_RET  & REG0 & REG0 & x"00"    -- RET
    );

    function init_mem (prog_data : prog_type) return mem_type is
        variable m : mem_type := (others => x"00");
    begin
        for i in prog_data'range loop
            m(3*i)     := prog_data(i)(23 downto 16);
            m(3*i + 1) := prog_data(i)(15 downto 8);
            m(3*i + 2) := prog_data(i)(7 downto 0); 
        end loop;
        
        return m;
    end function init_mem;

    signal mem : mem_type := init_mem(prog_data);
begin
    mem_proc : process (clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                mem(to_integer(unsigned(addr))) <= data_in;
            end if;              
            data_out <= mem(to_integer(unsigned(addr)));
        end if;
    end process mem_proc;
end architecture rtl;
