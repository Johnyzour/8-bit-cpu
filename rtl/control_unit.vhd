--------------------------------------------------------------------------------
-- File        : control_unit.vhd
-- Description : Multicycle control unit. Moore FSM with six states (FETCH1,
--               FETCH2, FETCH3, DECODE, EXECUTE, WRITEBACK) that drives the
--               datapath control signals from the 8-bit opcode, the current
--               state and the Z/C flags.
-- Notes       : Three processes: state register, next-state logic, output
--               logic. Selects (alu_sel, wb_sel, mem_data_sel, pc_src_sel)
--               depend on the opcode only; enables depend on the state.
--               The three FETCH states read one instruction byte each and
--               increment the PC. The shared memory reads synchronously, so
--               each byte is loaded into the IR one state later: opcode in
--               FETCH2, rd/rs in FETCH3, imm in DECODE.
--               mem_addr_sel selects imm in EXECUTE for LD and ST, SP in
--               EXECUTE for PUSH, POP, CALL and RET, and the PC otherwise.
--               PUSH and CALL decrement SP in DECODE and write in EXECUTE
--               (CALL writes the return address and jumps on the same edge).
--               POP and RET read in EXECUTE, increment SP, and use the byte in
--               WRITEBACK (POP writes rd, RET loads the PC).
--               LDI and MOV skip EXECUTE. NOP, ST, CMP, PUSH, CALL and the
--               jumps skip WRITEBACK. ALU ops, LD, POP and RET take all six
--               states. ADD, SUB, CMP, SHL, SHR, INC and DEC load Z and C;
--               AND, OR, XOR and NOT load Z only.
--               Unused opcodes (18-FF) behave as NOP. Synchronous active-high
--               reset returns to FETCH1.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity control_unit is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;    
        opcode       : in  std_logic_vector (7 downto 0);
        z_flag       : in  std_logic;
        c_flag       : in  std_logic;
        reg_wr_en    : out std_logic;
        wb_sel       : out std_logic_vector (1 downto 0);
        alu_sel      : out std_logic_vector (3 downto 0);
        mem_wr_en    : out std_logic;
        z_load       : out std_logic;
        c_load       : out std_logic;
        pc_load      : out std_logic;
        pc_inc       : out std_logic;
        ir_load      : out std_logic_vector (2 downto 0);
        mem_addr_sel : out std_logic_vector (1 downto 0);
        sp_inc       : out std_logic;
        sp_dec       : out std_logic;
        mem_data_sel : out std_logic;
        pc_src_sel   : out std_logic;
        state_out    : out state_t
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
                state <= S_FETCH1;
            else
                state <= next_state;
            end if;
        end if;        
    end process state_reg;
    
    next_state_logic : process (state, opcode)
    begin
        next_state <= S_FETCH1;
        case state is
            when S_FETCH1 =>
                next_state <= S_FETCH2;
            when S_FETCH2 =>
                next_state <= S_FETCH3;
            when S_FETCH3 =>
                next_state <= S_DECODE;    
            when S_DECODE =>
                if opcode = OP_LDI or opcode = OP_MOV then
                    next_state <= S_WRITEBACK;
                else
                    next_state <= S_EXECUTE;
                end if;
            when S_EXECUTE =>
                case opcode is
                    when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR | OP_NOT | OP_LD | OP_SHL | OP_SHR | OP_INC | OP_DEC | OP_POP | OP_RET =>
                        next_state <= S_WRITEBACK;
                    when others =>
                        next_state <= S_FETCH1;
                end case;
            when S_WRITEBACK =>
                next_state <= S_FETCH1;
        end case;
    end process next_state_logic;
    
    output_logic : process (state, opcode, z_flag, c_flag)
    begin
        ir_load      <= "000";
        pc_inc       <= '0';
        pc_load      <= '0';
        reg_wr_en    <= '0';
        mem_wr_en    <= '0';
        z_load       <= '0';
        c_load       <= '0';
        sp_inc       <= '0';
        sp_dec       <= '0';
        mem_data_sel <= MEMD_REG;
        pc_src_sel   <= PCSRC_IMM;
        alu_sel      <= ALU_ADD;
        mem_addr_sel <= ADDR_PC;
        wb_sel       <= WB_ALU;
        
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
            when OP_SHL =>
                alu_sel <= ALU_SHL;
            when OP_SHR =>
                alu_sel <= ALU_SHR;
            when OP_INC =>
                alu_sel <= ALU_INC;
            when OP_DEC =>
                alu_sel <= ALU_DEC;
            when OP_POP =>
                wb_sel <= WB_RAM;
            when OP_CALL =>
                mem_data_sel <= MEMD_PC;
            when OP_RET =>
                pc_src_sel <= PCSRC_MEM;  
            when others =>
                null;
        end case;
        
        case state is
            when S_FETCH1 =>
                pc_inc <= '1';
            when S_FETCH2 =>
                pc_inc  <= '1';
                ir_load <= "100";
            when S_FETCH3 =>        
                pc_inc  <= '1';
                ir_load <= "010";
            when S_DECODE =>
                ir_load <= "001";
                if opcode = OP_PUSH or opcode = OP_CALL then
                    sp_dec <= '1';
                end if;   
            when S_EXECUTE =>
                case opcode is
                    when OP_ADD | OP_SUB | OP_CMP | OP_SHL | OP_SHR | OP_INC | OP_DEC =>
                        z_load <= '1';
                        c_load <= '1';
                    when OP_AND | OP_OR | OP_XOR | OP_NOT =>
                        z_load <= '1';
                    when OP_LD =>
                        mem_addr_sel <= ADDR_IMM;
                    when OP_ST =>
                        mem_wr_en    <= '1';
                        mem_addr_sel <= ADDR_IMM;
                    when OP_JMP =>
                        pc_load <= '1';
                    when OP_JZ =>
                        pc_load <= z_flag;
                    when OP_JNZ =>
                        pc_load <= not z_flag;
                    when OP_JC =>
                        pc_load <= c_flag;
                    when OP_PUSH =>
                        mem_addr_sel <= ADDR_SP;
                        mem_wr_en <= '1';
                    when OP_POP =>
                        mem_addr_sel <= ADDR_SP;
                        sp_inc <= '1';    
                    when OP_CALL =>
                        mem_addr_sel <= ADDR_SP;
                        mem_wr_en <= '1';
                        pc_load <= '1';
                    when OP_RET =>
                        mem_addr_sel <= ADDR_SP;
                        sp_inc <= '1';
                    when others =>
                        null;
                end case;
            when S_WRITEBACK =>
                case opcode is
                    when OP_RET =>
                        pc_load <='1';
                    when others =>
                        reg_wr_en <= '1';
                end case;
        end case;             
    end process output_logic;
    
    state_out <= state;
end architecture rtl;
