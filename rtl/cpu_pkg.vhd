--------------------------------------------------------------------------------
-- File        : control_unit.vhd
-- Description : Multicycle control unit. Moore FSM with six states (FETCH1,
--               FETCH2, FETCH3, DECODE, EXECUTE, WRITEBACK) that drives the
--               datapath control signals from the 8-bit opcode, the current
--               state and the Z/C flags.
-- Notes       : Three processes: state register, next-state logic, output
--               logic. Selects (alu_sel, wb_sel) depend on the opcode only;
--               enables depend on the state.
--               The three FETCH states read one instruction byte each and
--               increment the PC. The shared memory reads synchronously, so
--               each byte is loaded into the IR one state later: opcode in
--               FETCH2, rd/rs in FETCH3, imm in DECODE.
--               mem_addr_sel selects imm in EXECUTE for LD and ST, and the PC
--               otherwise.
--               LDI and MOV skip EXECUTE. NOP, ST, CMP and the jumps skip
--               WRITEBACK. ALU ops (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR,
--               INC, DEC) and LD take all six states. ADD, SUB, CMP, SHL, SHR,
--               INC and DEC load Z and C; AND, OR, XOR and NOT load Z only.
--               Unused opcodes (14-FF) behave as NOP. Synchronous active-high
--               reset returns to FETCH1.
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
    
    constant ADDR_PC  : std_logic := '0';
    constant ADDR_IMM : std_logic := '1';
    
    type state_t is (S_FETCH1, S_FETCH2, S_FETCH3, S_DECODE, S_EXECUTE, S_WRITEBACK);
end package cpu_pkg;