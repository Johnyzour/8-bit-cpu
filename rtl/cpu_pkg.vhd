--------------------------------------------------------------------------------
-- File        : cpu_pkg.vhd
-- Description : Shared constants and types for the CPU: 8-bit opcodes (OP_*),
--               4-bit ALU codes (ALU_*), 4-bit register numbers (REG0-REG3),
--               writeback selects (WB_*), memory address selects (ADDR_*),
--               memory data selects (MEMD_*), PC source selects (PCSRC_*), the
--               stack pointer reset value and the FSM state type.
-- Notes       : Instruction format (24-bit, byte-aligned): opcode(23:16) |
--               rd(15:12) | rs(11:8) | imm(7:0), stored as three bytes.
--               26 opcodes used (00-19); the rest decode as NOP.
--               Only R0-R3 exist; upper bits of rd/rs are reserved (0).
--               WB_* must match the wb_mux input order.
--               ADDR_* select the memory address (PC, imm, SP or register),
--               MEMD_* the memory write data (register or PC), PCSRC_* the PC
--               jump source (imm or memory). SP_INIT is the stack pointer
--               reset value; the stack grows down from F0, below the data
--               area.
--               state_t has three fetch states, one per instruction byte.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package cpu_pkg is
    constant OP_NOP  : std_logic_vector (7 downto 0) := x"00";
    constant OP_LDI  : std_logic_vector (7 downto 0) := x"01";
    constant OP_MOV  : std_logic_vector (7 downto 0) := x"02";
    constant OP_LD   : std_logic_vector (7 downto 0) := x"03";
    constant OP_ST   : std_logic_vector (7 downto 0) := x"04";
    constant OP_ADD  : std_logic_vector (7 downto 0) := x"05";
    constant OP_SUB  : std_logic_vector (7 downto 0) := x"06";
    constant OP_AND  : std_logic_vector (7 downto 0) := x"07";
    constant OP_OR   : std_logic_vector (7 downto 0) := x"08";
    constant OP_XOR  : std_logic_vector (7 downto 0) := x"09";
    constant OP_NOT  : std_logic_vector (7 downto 0) := x"0A";
    constant OP_CMP  : std_logic_vector (7 downto 0) := x"0B";
    constant OP_JMP  : std_logic_vector (7 downto 0) := x"0C";
    constant OP_JZ   : std_logic_vector (7 downto 0) := x"0D";
    constant OP_JNZ  : std_logic_vector (7 downto 0) := x"0E";
    constant OP_JC   : std_logic_vector (7 downto 0) := x"0F";
    constant OP_SHL  : std_logic_vector (7 downto 0) := x"10";
    constant OP_SHR  : std_logic_vector (7 downto 0) := x"11";
    constant OP_INC  : std_logic_vector (7 downto 0) := x"12";
    constant OP_DEC  : std_logic_vector (7 downto 0) := x"13";
    constant OP_PUSH : std_logic_vector (7 downto 0) := x"14";
    constant OP_POP  : std_logic_vector (7 downto 0) := x"15";
    constant OP_CALL : std_logic_vector (7 downto 0) := x"16";
    constant OP_RET  : std_logic_vector (7 downto 0) := x"17";
    constant OP_LDR  : std_logic_vector (7 downto 0) := x"18";
    constant OP_STR  : std_logic_vector (7 downto 0) := x"19";
    
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
    
    constant ADDR_PC  : std_logic_vector (1 downto 0) := "00";
    constant ADDR_IMM : std_logic_vector (1 downto 0) := "01";
    constant ADDR_SP  : std_logic_vector (1 downto 0) := "10";
    constant ADDR_REG : std_logic_vector (1 downto 0) := "11";
    
    constant MEMD_REG  : std_logic := '0';
    constant MEMD_PC   : std_logic := '1';

    constant PCSRC_IMM : std_logic := '0';
    constant PCSRC_MEM : std_logic := '1';
    
    constant SP_INIT : std_logic_vector (7 downto 0) := x"F0";
    
    type state_t is (S_FETCH1, S_FETCH2, S_FETCH3, S_DECODE, S_EXECUTE, S_WRITEBACK);
end package cpu_pkg;