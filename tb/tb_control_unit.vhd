--------------------------------------------------------------------------------
-- File        : tb_control_unit.vhd
-- Description : Self-checking testbench for the multi-cycle control FSM.
--               Steps every opcode through its state sequence (FETCH1-3,
--               DECODE, EXECUTE, WRITEBACK as applicable), checking the state
--               and all control outputs in each state, including the IR byte
--               loads and the memory address select. Covers each conditional
--               jump taken and not taken, an unused opcode (treated as NOP),
--               and reset in the middle of an instruction.
-- Notes       : The opcode changes only during FETCH1, as the IR would load it.
--               Prints "all tests completed and passed" at 1370 ns.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_control_unit is
end entity tb_control_unit;

architecture sim of tb_control_unit is
    signal tb_clk          : std_logic := '0';
    signal tb_rst          : std_logic := '1';
    signal tb_opcode       : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_z_flag       : std_logic := '0';
    signal tb_c_flag       : std_logic := '0';
    signal tb_reg_wr_en    : std_logic;
    signal tb_wb_sel       : std_logic_vector (1 downto 0);
    signal tb_alu_sel      : std_logic_vector (3 downto 0);
    signal tb_mem_wr_en    : std_logic;
    signal tb_z_load       : std_logic;
    signal tb_c_load       : std_logic;
    signal tb_pc_load      : std_logic;
    signal tb_pc_inc       : std_logic;
    signal tb_ir_load      : std_logic_vector (2 downto 0);
    signal tb_mem_addr_sel : std_logic;
    signal tb_state_out    : state_t;    
begin
    uut : entity work.control_unit
    port map (
        clk          => tb_clk,
        rst          => tb_rst,
        opcode       => tb_opcode,
        z_flag       => tb_z_flag,
        c_flag       => tb_c_flag,
        reg_wr_en    => tb_reg_wr_en,
        wb_sel       => tb_wb_sel,
        alu_sel      => tb_alu_sel,
        mem_wr_en    => tb_mem_wr_en,
        z_load       => tb_z_load,
        c_load       => tb_c_load,
        pc_load      => tb_pc_load,
        pc_inc       => tb_pc_inc,
        ir_load      => tb_ir_load,
        mem_addr_sel => tb_mem_addr_sel,
        state_out    => tb_state_out
    );
    
    clk_proc : process
    begin
        tb_clk <= '0';
        wait for 5 ns;
        tb_clk <= '1';
        wait for 5 ns;
    end process clk_proc;
        
    stim_proc : process
        -- core check: compares the state and all 10 control outputs
        procedure check (
            name    : in string;
            st      : in state_t;
            ir_ld   : in std_logic_vector (2 downto 0);
            pc_i    : in std_logic;
            pc_l    : in std_logic;
            reg_we  : in std_logic;
            mem_we  : in std_logic;
            z_ld    : in std_logic;
            c_ld    : in std_logic;
            alu     : in std_logic_vector (3 downto 0);
            wb      : in std_logic_vector (1 downto 0);
            mem     : in std_logic;
            chk_sel : in boolean
        ) is
        begin
            assert(tb_state_out = st)     report name & " failed: state is " & state_t'image(tb_state_out) severity failure;
            assert(tb_ir_load = ir_ld)    report name & " failed: ir_load"      severity failure;
            assert(tb_pc_inc = pc_i)      report name & " failed: pc_inc"       severity failure;
            assert(tb_pc_load = pc_l)     report name & " failed: pc_load"      severity failure;
            assert(tb_reg_wr_en = reg_we) report name & " failed: reg_wr_en"    severity failure;
            assert(tb_mem_wr_en = mem_we) report name & " failed: mem_wr_en"    severity failure;
            assert(tb_z_load = z_ld)      report name & " failed: z_load"       severity failure;
            assert(tb_c_load = c_ld)      report name & " failed: c_load"       severity failure;
            assert(tb_mem_addr_sel = mem) report name & " failed: mem_addr_sel" severity failure;
            if chk_sel then
                assert(tb_alu_sel = alu)  report name & " failed: alu_sel"      severity failure;
                assert(tb_wb_sel = wb)    report name & " failed: wb_sel"       severity failure;        
            end if;
        end procedure check;

        -- one wrapper per state: only the values that vary are passed in
        procedure fetch1 (name : in string) is
        begin
            check(name & " fetch1", S_FETCH1, "000", '1', '0', '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC, false);
        end procedure fetch1;

        procedure fetch2 (name : in string) is
        begin
            check(name & " fetch2", S_FETCH2, "100", '1', '0', '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC, false);
        end procedure fetch2;

        procedure fetch3 (name : in string) is
        begin
            check(name & " fetch3", S_FETCH3, "010", '1', '0', '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC, false);
        end procedure fetch3;

        procedure decode (name : in string; alu : in std_logic_vector (3 downto 0); wb : in std_logic_vector (1 downto 0)) is
        begin
            check(name & " decode", S_DECODE, "001", '0', '0', '0', '0', '0', '0', alu, wb, ADDR_PC, true);
        end procedure decode;

        procedure execute (name : in string; pc_l, mem_we, z_ld, c_ld : in std_logic;
                           alu : in std_logic_vector (3 downto 0); wb : in std_logic_vector (1 downto 0);
                           mem : in std_logic) is
        begin
            check(name & " execute", S_EXECUTE, "000", '0', pc_l, '0', mem_we, z_ld, c_ld, alu, wb, mem, true);
        end procedure execute;

        procedure writeback (name : in string; alu : in std_logic_vector (3 downto 0); wb : in std_logic_vector (1 downto 0)) is
        begin
            check(name & " writeback", S_WRITEBACK, "000", '0', '0', '1', '0', '0', '0', alu, wb, ADDR_PC, true);
        end procedure writeback;

    begin
        -- reset was applied at the first rising edge
        wait until falling_edge(tb_clk);
        tb_rst <= '0';
        fetch1("reset");

        --test1: NOP (F1 F2 F3 D E)
        tb_opcode <= OP_NOP; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 1 NOP");
        wait until falling_edge(tb_clk); fetch3("test 1 NOP");
        wait until falling_edge(tb_clk); decode("test 1 NOP", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 1 NOP", '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 1 NOP");

        --test2: LDI (F1 F2 F3 D W, skips EXECUTE)
        tb_opcode <= OP_LDI; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 2 LDI");
        wait until falling_edge(tb_clk); fetch3("test 2 LDI");
        wait until falling_edge(tb_clk); decode("test 2 LDI", ALU_ADD, WB_IMM);
        wait until falling_edge(tb_clk); writeback("test 2 LDI", ALU_ADD, WB_IMM);
        wait until falling_edge(tb_clk); fetch1("test 2 LDI");

        --test3: MOV (F1 F2 F3 D W, skips EXECUTE)
        tb_opcode <= OP_MOV; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 3 MOV");
        wait until falling_edge(tb_clk); fetch3("test 3 MOV");
        wait until falling_edge(tb_clk); decode("test 3 MOV", ALU_ADD, WB_REG);
        wait until falling_edge(tb_clk); writeback("test 3 MOV", ALU_ADD, WB_REG);
        wait until falling_edge(tb_clk); fetch1("test 3 MOV");

        --test4: LD (F1 F2 F3 D E W, memory address = imm in EXECUTE)
        tb_opcode <= OP_LD; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 4 LD");
        wait until falling_edge(tb_clk); fetch3("test 4 LD");
        wait until falling_edge(tb_clk); decode("test 4 LD", ALU_ADD, WB_RAM);
        wait until falling_edge(tb_clk); execute("test 4 LD", '0', '0', '0', '0', ALU_ADD, WB_RAM, ADDR_IMM);
        wait until falling_edge(tb_clk); writeback("test 4 LD", ALU_ADD, WB_RAM);
        wait until falling_edge(tb_clk); fetch1("test 4 LD");

        --test5: ST (F1 F2 F3 D E, write at address imm)
        tb_opcode <= OP_ST; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 5 ST");
        wait until falling_edge(tb_clk); fetch3("test 5 ST");
        wait until falling_edge(tb_clk); decode("test 5 ST", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 5 ST", '0', '1', '0', '0', ALU_ADD, WB_ALU, ADDR_IMM);
        wait until falling_edge(tb_clk); fetch1("test 5 ST");

        --test6: ADD (F1 F2 F3 D E W)
        tb_opcode <= OP_ADD; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 6 ADD");
        wait until falling_edge(tb_clk); fetch3("test 6 ADD");
        wait until falling_edge(tb_clk); decode("test 6 ADD", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 6 ADD", '0', '0', '1', '1', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 6 ADD", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 6 ADD");

        --test7: SUB (F1 F2 F3 D E W)
        tb_opcode <= OP_SUB; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 7 SUB");
        wait until falling_edge(tb_clk); fetch3("test 7 SUB");
        wait until falling_edge(tb_clk); decode("test 7 SUB", ALU_SUB, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 7 SUB", '0', '0', '1', '1', ALU_SUB, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 7 SUB", ALU_SUB, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 7 SUB");

        --test8: AND (F1 F2 F3 D E W, Z only)
        tb_opcode <= OP_AND; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 8 AND");
        wait until falling_edge(tb_clk); fetch3("test 8 AND");
        wait until falling_edge(tb_clk); decode("test 8 AND", ALU_AND, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 8 AND", '0', '0', '1', '0', ALU_AND, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 8 AND", ALU_AND, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 8 AND");

        --test9: OR (F1 F2 F3 D E W, Z only)
        tb_opcode <= OP_OR; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 9 OR");
        wait until falling_edge(tb_clk); fetch3("test 9 OR");
        wait until falling_edge(tb_clk); decode("test 9 OR", ALU_OR, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 9 OR", '0', '0', '1', '0', ALU_OR, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 9 OR", ALU_OR, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 9 OR");

        --test10: XOR (F1 F2 F3 D E W, Z only)
        tb_opcode <= OP_XOR; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 10 XOR");
        wait until falling_edge(tb_clk); fetch3("test 10 XOR");
        wait until falling_edge(tb_clk); decode("test 10 XOR", ALU_XOR, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 10 XOR", '0', '0', '1', '0', ALU_XOR, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 10 XOR", ALU_XOR, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 10 XOR");

        --test11: NOT (F1 F2 F3 D E W, Z only)
        tb_opcode <= OP_NOT; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 11 NOT");
        wait until falling_edge(tb_clk); fetch3("test 11 NOT");
        wait until falling_edge(tb_clk); decode("test 11 NOT", ALU_NOT, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 11 NOT", '0', '0', '1', '0', ALU_NOT, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 11 NOT", ALU_NOT, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 11 NOT");

        --test12: CMP (F1 F2 F3 D E, flags but no writeback)
        tb_opcode <= OP_CMP; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 12 CMP");
        wait until falling_edge(tb_clk); fetch3("test 12 CMP");
        wait until falling_edge(tb_clk); decode("test 12 CMP", ALU_SUB, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 12 CMP", '0', '0', '1', '1', ALU_SUB, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 12 CMP");

        --test13: JMP (F1 F2 F3 D E, always taken)
        tb_opcode <= OP_JMP; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 13 JMP");
        wait until falling_edge(tb_clk); fetch3("test 13 JMP");
        wait until falling_edge(tb_clk); decode("test 13 JMP", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 13 JMP", '1', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 13 JMP");

        --test14: JZ taken (z = 1)
        tb_opcode <= OP_JZ; tb_z_flag <= '1'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 14 JZ");
        wait until falling_edge(tb_clk); fetch3("test 14 JZ");
        wait until falling_edge(tb_clk); decode("test 14 JZ", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 14 JZ", '1', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 14 JZ");

        --test15: JZ not taken (z = 0)
        tb_opcode <= OP_JZ; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 15 JZ");
        wait until falling_edge(tb_clk); fetch3("test 15 JZ");
        wait until falling_edge(tb_clk); decode("test 15 JZ", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 15 JZ", '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 15 JZ");

        --test16: JNZ taken (z = 0)
        tb_opcode <= OP_JNZ; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 16 JNZ");
        wait until falling_edge(tb_clk); fetch3("test 16 JNZ");
        wait until falling_edge(tb_clk); decode("test 16 JNZ", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 16 JNZ", '1', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 16 JNZ");

        --test17: JNZ not taken (z = 1)
        tb_opcode <= OP_JNZ; tb_z_flag <= '1'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 17 JNZ");
        wait until falling_edge(tb_clk); fetch3("test 17 JNZ");
        wait until falling_edge(tb_clk); decode("test 17 JNZ", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 17 JNZ", '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 17 JNZ");

        --test18: JC taken (c = 1)
        tb_opcode <= OP_JC; tb_z_flag <= '0'; tb_c_flag <= '1';
        wait until falling_edge(tb_clk); fetch2("test 18 JC");
        wait until falling_edge(tb_clk); fetch3("test 18 JC");
        wait until falling_edge(tb_clk); decode("test 18 JC", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 18 JC", '1', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 18 JC");

        --test19: JC ignores z (z = 1, c = 0)
        tb_opcode <= OP_JC; tb_z_flag <= '1'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 19 JC");
        wait until falling_edge(tb_clk); fetch3("test 19 JC");
        wait until falling_edge(tb_clk); decode("test 19 JC", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 19 JC", '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 19 JC");

        --test20: SHL (F1 F2 F3 D E W, Z and C)
        tb_opcode <= OP_SHL; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 20 SHL");
        wait until falling_edge(tb_clk); fetch3("test 20 SHL");
        wait until falling_edge(tb_clk); decode("test 20 SHL", ALU_SHL, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 20 SHL", '0', '0', '1', '1', ALU_SHL, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 20 SHL", ALU_SHL, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 20 SHL");

        --test21: SHR (F1 F2 F3 D E W, Z and C)
        tb_opcode <= OP_SHR; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 21 SHR");
        wait until falling_edge(tb_clk); fetch3("test 21 SHR");
        wait until falling_edge(tb_clk); decode("test 21 SHR", ALU_SHR, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 21 SHR", '0', '0', '1', '1', ALU_SHR, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 21 SHR", ALU_SHR, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 21 SHR");

        --test22: INC (F1 F2 F3 D E W, Z and C)
        tb_opcode <= OP_INC; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 22 INC");
        wait until falling_edge(tb_clk); fetch3("test 22 INC");
        wait until falling_edge(tb_clk); decode("test 22 INC", ALU_INC, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 22 INC", '0', '0', '1', '1', ALU_INC, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 22 INC", ALU_INC, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 22 INC");

        --test23: DEC (F1 F2 F3 D E W, Z and C)
        tb_opcode <= OP_DEC; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 23 DEC");
        wait until falling_edge(tb_clk); fetch3("test 23 DEC");
        wait until falling_edge(tb_clk); decode("test 23 DEC", ALU_DEC, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 23 DEC", '0', '0', '1', '1', ALU_DEC, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); writeback("test 23 DEC", ALU_DEC, WB_ALU);
        wait until falling_edge(tb_clk); fetch1("test 23 DEC");

        --test24: unused opcode FF behaves as NOP (F1 F2 F3 D E, no enables)
        tb_opcode <= x"FF"; tb_z_flag <= '1'; tb_c_flag <= '1';
        wait until falling_edge(tb_clk); fetch2("test 24 unused");
        wait until falling_edge(tb_clk); fetch3("test 24 unused");
        wait until falling_edge(tb_clk); decode("test 24 unused", ALU_ADD, WB_ALU);
        wait until falling_edge(tb_clk); execute("test 24 unused", '0', '0', '0', '0', ALU_ADD, WB_ALU, ADDR_PC);
        wait until falling_edge(tb_clk); fetch1("test 24 unused");

        --test25: reset during DECODE returns to FETCH1, then resumes
        tb_opcode <= OP_ADD; tb_z_flag <= '0'; tb_c_flag <= '0';
        wait until falling_edge(tb_clk); fetch2("test 25 ADD");
        wait until falling_edge(tb_clk); fetch3("test 25 ADD");
        wait until falling_edge(tb_clk); decode("test 25 ADD", ALU_ADD, WB_ALU);
        tb_rst <= '1';
        wait until falling_edge(tb_clk); fetch1("test 25 reset");
        tb_rst <= '0';
        wait until falling_edge(tb_clk); fetch2("test 25 resume");

        report "all tests completed and passed" severity note;        
        wait;
    end process stim_proc;
end architecture sim;