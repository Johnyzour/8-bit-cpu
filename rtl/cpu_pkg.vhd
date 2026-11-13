--------------------------------------------------------------------------------
-- File        : cpu_pkg.vhd
-- Description : Shared constants and types for the CPU: 4-bit opcodes (OP_*),
--               3-bit ALU operation codes (ALU_*), 2-bit register numbers
--               (REG0-REG3), 2-bit writeback-mux selects (WB_*) and the
--               control FSM state type (state_t).
-- Notes       : Instruction format: opcode(15:12) | rd(11:10) | rs(9:8) |
--               imm(7:0).
--               WB_* values must match the input order of wb_mux.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package cpu_pkg is
    constant OP_NOP : std_logic_vector (3 downto 0) := "0000";
    constant OP_LDI : std_logic_vector (3 downto 0) := "0001";
    constant OP_MOV : std_logic_vector (3 downto 0) := "0010";
    constant OP_LD  : std_logic_vector (3 downto 0) := "0011";
    constant OP_ST  : std_logic_vector (3 downto 0) := "0100";
    constant OP_ADD : std_logic_vector (3 downto 0) := "0101";
    constant OP_SUB : std_logic_vector (3 downto 0) := "0110";
    constant OP_AND : std_logic_vector (3 downto 0) := "0111";
    constant OP_OR  : std_logic_vector (3 downto 0) := "1000";
    constant OP_XOR : std_logic_vector (3 downto 0) := "1001";
    constant OP_NOT : std_logic_vector (3 downto 0) := "1010";
    constant OP_CMP : std_logic_vector (3 downto 0) := "1011";
    constant OP_JMP : std_logic_vector (3 downto 0) := "1100";
    constant OP_JZ  : std_logic_vector (3 downto 0) := "1101";
    constant OP_JNZ : std_logic_vector (3 downto 0) := "1110";
    constant OP_JC  : std_logic_vector (3 downto 0) := "1111";
    
    constant ALU_ADD : std_logic_vector (2 downto 0) := "000";
    constant ALU_SUB : std_logic_vector (2 downto 0) := "001";
    constant ALU_AND : std_logic_vector (2 downto 0) := "010";
    constant ALU_OR  : std_logic_vector (2 downto 0) := "011";
    constant ALU_XOR : std_logic_vector (2 downto 0) := "100";
    constant ALU_NOT : std_logic_vector (2 downto 0) := "101";
    
    constant REG0 : std_logic_vector (1 downto 0) := "00";
    constant REG1 : std_logic_vector (1 downto 0) := "01";
    constant REG2 : std_logic_vector (1 downto 0) := "10";
    constant REG3 : std_logic_vector (1 downto 0) := "11";
    
    constant WB_ALU : std_logic_vector (1 downto 0) := "00";
    constant WB_RAM : std_logic_vector (1 downto 0) := "01";
    constant WB_IMM : std_logic_vector (1 downto 0) := "10";
    constant WB_REG : std_logic_vector (1 downto 0) := "11";
    
    type state_t is (S_FETCH, S_DECODE, S_EXECUTE, S_WRITEBACK);
end package cpu_pkg;