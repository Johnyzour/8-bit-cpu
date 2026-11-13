--------------------------------------------------------------------------------
-- File        : cpu_pkg.vhd
-- Description : Shared constants and types for the CPU: 8-bit opcodes (OP_*),
--               4-bit ALU operation codes (ALU_*), 4-bit register numbers
--               (REG0-REG3), 2-bit writeback-mux selects (WB_*) and the
--               control FSM state type (state_t).
-- Notes       : Instruction format (24-bit, byte-aligned):
--               opcode(23:16) | rd(15:12) | rs(11:8) | imm(7:0).
--               20 opcodes used (00-13); the rest decode as NOP.
--               Only R0-R3 exist; the upper bits of rd/rs are reserved (0).
--               WB_* values must match the input order of wb_mux.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package cpu_pkg is
    constant OP_NOP : std_logic_vector (7 downto 0) := x"00";
    constant OP_LDI : std_logic_vector (7 downto 0) := x"01";
    constant OP_MOV : std_logic_vector (7 downto 0) := x"02";
    constant OP_LD  : std_logic_vector (7 downto 0) := x"03";
    constant OP_ST  : std_logic_vector (7 downto 0) := x"04";
    constant OP_ADD : std_logic_vector (7 downto 0) := x"05";
    constant OP_SUB : std_logic_vector (7 downto 0) := x"06";
    constant OP_AND : std_logic_vector (7 downto 0) := x"07";
    constant OP_OR  : std_logic_vector (7 downto 0) := x"08";
    constant OP_XOR : std_logic_vector (7 downto 0) := x"09";
    constant OP_NOT : std_logic_vector (7 downto 0) := x"0A";
    constant OP_CMP : std_logic_vector (7 downto 0) := x"0B";
    constant OP_JMP : std_logic_vector (7 downto 0) := x"0C";
    constant OP_JZ  : std_logic_vector (7 downto 0) := x"0D";
    constant OP_JNZ : std_logic_vector (7 downto 0) := x"0E";
    constant OP_JC  : std_logic_vector (7 downto 0) := x"0F";
    constant OP_SHL : std_logic_vector (7 downto 0) := x"10";
    constant OP_SHR : std_logic_vector (7 downto 0) := x"11";
    constant OP_INC : std_logic_vector (7 downto 0) := x"12";
    constant OP_DEC : std_logic_vector (7 downto 0) := x"13";
    
    constant ALU_ADD : std_logic_vector (3 downto 0) := "0000";
    constant ALU_SUB : std_logic_vector (3 downto 0) := "0001";
    constant ALU_AND : std_logic_vector (3 downto 0) := "0010";
    constant ALU_OR  : std_logic_vector (3 downto 0) := "0011";
    constant ALU_XOR : std_logic_vector (3 downto 0) := "0100";
    constant ALU_NOT : std_logic_vector (3 downto 0) := "0101";
    constant ALU_SHL : std_logic_vector (3 downto 0) := "0110";
    constant ALU_SHR : std_logic_vector (3 downto 0) := "0111";
    constant ALU_INC : std_logic_vector (3 downto 0) := "1000";
    constant ALU_DEC : std_logic_vector (3 downto 0) := "1001";
    
    constant REG0 : std_logic_vector (3 downto 0) := "0000";
    constant REG1 : std_logic_vector (3 downto 0) := "0001";
    constant REG2 : std_logic_vector (3 downto 0) := "0010";
    constant REG3 : std_logic_vector (3 downto 0) := "0011";
    
    constant WB_ALU : std_logic_vector (1 downto 0) := "00";
    constant WB_RAM : std_logic_vector (1 downto 0) := "01";
    constant WB_IMM : std_logic_vector (1 downto 0) := "10";
    constant WB_REG : std_logic_vector (1 downto 0) := "11";
    
    type state_t is (S_FETCH, S_DECODE, S_EXECUTE, S_WRITEBACK);
end package cpu_pkg;