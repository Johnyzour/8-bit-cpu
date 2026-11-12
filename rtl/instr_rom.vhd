--------------------------------------------------------------------------------
-- File        : instr_rom.vhd
-- Description : 256 x 16-bit instruction ROM holding the program.
-- Notes       : Asynchronous read. To change the program, edit rom_data; each
--               entry is built as opcode & rd & rs & imm from cpu_pkg constants.
--               Unused addresses hold 0000 (NOP).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity instr_rom is
    port (
        addr  : in  std_logic_vector (7 downto 0);
        instr : out std_logic_vector (15 downto 0)            
    ); 
end entity instr_rom;

architecture rtl of instr_rom is
    type rom_type is array (0 to 255) of std_logic_vector (15 downto 0);
    constant rom_data : rom_type := (
        0  => OP_LDI & REG0 & REG0 & x"0F",   -- LDI R0, 0F
        1  => OP_LDI & REG1 & REG0 & x"3C",   -- LDI R1, 3C
        2  => OP_MOV & REG2 & REG1 & x"00",   -- MOV R2, R1      R2 = 3C
        3  => OP_ADD & REG2 & REG0 & x"00",   -- ADD R2, R0      R2 = 4B
        4  => OP_AND & REG2 & REG1 & x"00",   -- AND R2, R1      R2 = 08
        5  => OP_OR  & REG2 & REG0 & x"00",   -- OR  R2, R0      R2 = 0F
        6  => OP_XOR & REG2 & REG0 & x"00",   -- XOR R2, R0      R2 = 00, Z = 1
        7  => OP_JZ  & REG0 & REG0 & x"09",   -- JZ 9            taken
        8  => OP_LDI & REG3 & REG0 & x"FF",   -- LDI R3, FF      must be skipped
        9  => OP_NOT & REG2 & REG0 & x"00",   -- NOT R2          R2 = FF
        10 => OP_ST  & REG2 & REG0 & x"20",   -- ST R2, 20       RAM[20] = FF
        11 => OP_LD  & REG3 & REG0 & x"20",   -- LD R3, 20       R3 = FF
        12 => OP_SUB & REG0 & REG1 & x"00",   -- SUB R0, R1      R0 = D3, C = 1
        13 => OP_JC  & REG0 & REG0 & x"0F",   -- JC 15           taken
        14 => OP_LDI & REG3 & REG0 & x"00",   -- LDI R3, 00      must be skipped
        15 => OP_CMP & REG3 & REG2 & x"00",   -- CMP R3, R2      Z = 1, R3 unchanged
        16 => OP_JNZ & REG0 & REG0 & x"12",   -- JNZ 18          not taken
        17 => OP_NOP & REG0 & REG0 & x"00",   -- NOP
        18 => OP_JMP & REG0 & REG0 & x"12",   -- JMP 18 (halt)
        others => x"0000"
    );
    
begin

    instr <= rom_data(to_integer(unsigned(addr)));

end architecture rtl;
