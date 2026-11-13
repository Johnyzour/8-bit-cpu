--------------------------------------------------------------------------------
-- File        : control_unit.vhd
-- Description : Multi-cycle control FSM. Steps each instruction through
--               FETCH, DECODE, EXECUTE and WRITEBACK and drives the datapath
--               control signals from the state, opcode and stored Z/C flags.
-- Notes       : Three processes: state register (clocked), next-state logic
--               and output logic (both combinational, defaults first so no
--               latches are inferred).
--               Selects (alu_sel, wb_sel) depend on the opcode only; enables
--               depend on the state. LDI/MOV skip EXECUTE; ALU ops and LD use
--               all four states; NOP, ST, CMP and jumps skip WRITEBACK.
--               Synchronous reset returns the FSM to FETCH.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity control_unit is
    port ( 
        clk       : in  std_logic;
        rst       : in  std_logic;    
        opcode    : in  std_logic_vector (3 downto 0);
        z_flag    : in  std_logic;
        c_flag    : in  std_logic;
        reg_wr_en : out std_logic;
        wb_sel    : out std_logic_vector (1 downto 0);
        alu_sel   : out std_logic_vector (2 downto 0);
        ram_wr_en : out std_logic;
        z_load    : out std_logic;
        c_load    : out std_logic;
        pc_load   : out std_logic;
        pc_inc    : out std_logic;
        ir_load   : out std_logic;
        state_out : out state_t
    );
end entity control_unit;

architecture rtl of control_unit is
    signal state      : state_t;
    signal next_state : state_t;
begin
    state_reg : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= S_FETCH;
            else
                state <= next_state;
            end if;
        end if;        
    end process state_reg;
    
    next_state_logic : process (state, opcode)
    begin
        next_state <= S_FETCH;
        case state is
            when S_FETCH =>
                next_state <= S_DECODE;
            when S_DECODE =>
                if opcode = OP_LDI or opcode = OP_MOV then
                    next_state <= S_WRITEBACK;
                else
                    next_state <= S_EXECUTE;
                end if;
            when S_EXECUTE =>
                case opcode is
                    when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR | OP_NOT | OP_LD =>
                        next_state <= S_WRITEBACK;
                    when others =>
                        next_state <= S_FETCH;
                end case;
            when S_WRITEBACK =>
                next_state <= S_FETCH;
        end case;
    end process next_state_logic;
    
    output_logic : process (state, opcode, z_flag, c_flag)
    begin
        ir_load   <= '0';
        pc_inc    <= '0';
        pc_load   <= '0';
        reg_wr_en <= '0';
        ram_wr_en <= '0';
        z_load    <= '0';
        c_load    <= '0';
        alu_sel   <= ALU_ADD;
        wb_sel    <= WB_ALU;
        
        case opcode is
            when OP_SUB | OP_CMP =>
                alu_sel <= ALU_SUB;
            when OP_AND =>
                alu_sel <= ALU_AND;
            when OP_OR =>
                alu_sel <= ALU_OR;
            when OP_XOR =>
                alu_sel <= ALU_XOR;
            when OP_NOT =>
                alu_sel <= ALU_NOT;
            when OP_LDI =>
                wb_sel <= WB_IMM;
            when OP_MOV =>
                wb_sel <= WB_REG;
            when OP_LD =>
                wb_sel <= WB_RAM;
            when others =>
                null;
        end case;
        
        case state is
            when S_FETCH =>
                ir_load <= '1';
                pc_inc  <= '1';
            when S_DECODE =>
                null;
            when S_EXECUTE =>
                case opcode is
                    when OP_ADD | OP_SUB | OP_CMP =>
                        z_load <= '1';
                        c_load <= '1';
                    when OP_AND | OP_OR | OP_XOR | OP_NOT =>
                        z_load <= '1';
                    when OP_ST =>
                        ram_wr_en <= '1';
                    when OP_JMP =>
                        pc_load <= '1';
                    when OP_JZ =>
                        pc_load <= z_flag;
                    when OP_JNZ =>
                        pc_load <= not z_flag;
                    when OP_JC =>
                        pc_load <= c_flag;
                    when others =>
                        null;
                end case;
            when S_WRITEBACK =>
                reg_wr_en <= '1';
        end case;             
    end process output_logic;
    
    state_out <= state;
end architecture rtl;
