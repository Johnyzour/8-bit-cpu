--------------------------------------------------------------------------------
-- File        : tb_control_unit.vhd
-- Description : Self-checking testbench for control_unit. 22 tests: every
--               opcode, and each conditional jump both taken and not taken.
-- Notes       : Prints "all tests completed and passed" at 220 ns.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_control_unit is
end entity tb_control_unit;

architecture sim of tb_control_unit is
    signal tb_opcode    : std_logic_vector (3 downto 0) := (others => '0');
    signal tb_z_flag    : std_logic := '0';
    signal tb_c_flag    : std_logic := '0';
    signal tb_reg_wr_en : std_logic;
    signal tb_wb_sel    : std_logic_vector (1 downto 0);
    signal tb_alu_sel   : std_logic_vector (2 downto 0);
    signal tb_ram_wr_en : std_logic;
    signal tb_z_load    : std_logic;
    signal tb_c_load    : std_logic;
    signal tb_pc_load   : std_logic;
    signal tb_pc_inc    : std_logic;
begin
    uut : entity work.control_unit
    port map (
        opcode    => tb_opcode,
        z_flag    => tb_z_flag,
        c_flag    => tb_c_flag,
        reg_wr_en => tb_reg_wr_en,
        wb_sel    => tb_wb_sel,
        alu_sel   => tb_alu_sel,
        ram_wr_en => tb_ram_wr_en,
        z_load    => tb_z_load,
        c_load    => tb_c_load,
        pc_load   => tb_pc_load,
        pc_inc    => tb_pc_inc
    );

    stim_proc : process
    begin
        --test1: NOP
        tb_opcode <= OP_NOP;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 1 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 1 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 1 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 1 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 1 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 1 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 1 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 1 failed: pc_inc"    severity failure;

        --test2: LDI
        tb_opcode <= OP_LDI;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 2 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_IMM)   report "test 2 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 2 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 2 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 2 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 2 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 2 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 2 failed: pc_inc"    severity failure;

        --test3: MOV
        tb_opcode <= OP_MOV;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 3 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_REG)   report "test 3 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 3 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 3 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 3 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 3 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 3 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 3 failed: pc_inc"    severity failure;

        --test4: LD
        tb_opcode <= OP_LD;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 4 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_RAM)   report "test 4 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 4 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 4 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 4 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 4 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 4 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 4 failed: pc_inc"    severity failure;

        --test5: ST
        tb_opcode <= OP_ST;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 5 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 5 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 5 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '1')   report "test 5 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 5 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 5 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 5 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 5 failed: pc_inc"    severity failure;

        --test6: ADD
        tb_opcode <= OP_ADD;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 6 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 6 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 6 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 6 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 6 failed: z_load"    severity failure;
        assert(tb_c_load = '1')      report "test 6 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 6 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 6 failed: pc_inc"    severity failure;

        --test7: SUB
        tb_opcode <= OP_SUB;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 7 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 7 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_SUB) report "test 7 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 7 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 7 failed: z_load"    severity failure;
        assert(tb_c_load = '1')      report "test 7 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 7 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 7 failed: pc_inc"    severity failure;

        --test8: AND
        tb_opcode <= OP_AND;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 8 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 8 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_AND) report "test 8 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 8 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 8 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 8 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 8 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 8 failed: pc_inc"    severity failure;

        --test9: OR
        tb_opcode <= OP_OR;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 9 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 9 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_OR)  report "test 9 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 9 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 9 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 9 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 9 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 9 failed: pc_inc"    severity failure;

        --test10: XOR
        tb_opcode <= OP_XOR;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 10 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 10 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_XOR) report "test 10 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 10 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 10 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 10 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 10 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 10 failed: pc_inc"    severity failure;

        --test11: NOT
        tb_opcode <= OP_NOT;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 11 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 11 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_NOT) report "test 11 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 11 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 11 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 11 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 11 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 11 failed: pc_inc"    severity failure;

        --test12: CMP (SUB without writeback)
        tb_opcode <= OP_CMP;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 12 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 12 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_SUB) report "test 12 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 12 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 12 failed: z_load"    severity failure;
        assert(tb_c_load = '1')      report "test 12 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 12 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 12 failed: pc_inc"    severity failure;

        --test13: JMP always jumps
        tb_opcode <= OP_JMP;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 13 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 13 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 13 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 13 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 13 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 13 failed: c_load"    severity failure;
        assert(tb_pc_load = '1')     report "test 13 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 13 failed: pc_inc"    severity failure;

        --test14: JZ not taken (z = 0)
        tb_opcode <= OP_JZ;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 14 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 14 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 14 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 14 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 14 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 14 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 14 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 14 failed: pc_inc"    severity failure;

        --test15: JZ taken (z = 1)
        tb_opcode <= OP_JZ;
        tb_z_flag <= '1';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 15 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 15 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 15 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 15 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 15 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 15 failed: c_load"    severity failure;
        assert(tb_pc_load = '1')     report "test 15 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 15 failed: pc_inc"    severity failure;

        --test16: JNZ taken (z = 0)
        tb_opcode <= OP_JNZ;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 16 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 16 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 16 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 16 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 16 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 16 failed: c_load"    severity failure;
        assert(tb_pc_load = '1')     report "test 16 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 16 failed: pc_inc"    severity failure;

        --test17: JNZ not taken (z = 1)
        tb_opcode <= OP_JNZ;
        tb_z_flag <= '1';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 17 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 17 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 17 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 17 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 17 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 17 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 17 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 17 failed: pc_inc"    severity failure;

        --test18: JC not taken (c = 0)
        tb_opcode <= OP_JC;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 18 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 18 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 18 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 18 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 18 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 18 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 18 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 18 failed: pc_inc"    severity failure;

        --test19: JC taken (c = 1)
        tb_opcode <= OP_JC;
        tb_z_flag <= '0';
        tb_c_flag <= '1';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 19 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 19 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 19 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 19 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 19 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 19 failed: c_load"    severity failure;
        assert(tb_pc_load = '1')     report "test 19 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 19 failed: pc_inc"    severity failure;

        --test20: JC ignores z (z = 1, c = 0)
        tb_opcode <= OP_JC;
        tb_z_flag <= '1';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 20 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 20 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 20 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 20 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 20 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 20 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 20 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 20 failed: pc_inc"    severity failure;

        --test21: ADD with both flags set (flags must not affect it)
        tb_opcode <= OP_ADD;
        tb_z_flag <= '1';
        tb_c_flag <= '1';
        wait for 10 ns;
        assert(tb_reg_wr_en = '1')   report "test 21 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 21 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 21 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 21 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '1')      report "test 21 failed: z_load"    severity failure;
        assert(tb_c_load = '1')      report "test 21 failed: c_load"    severity failure;
        assert(tb_pc_load = '0')     report "test 21 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 21 failed: pc_inc"    severity failure;

        --test22: back to JMP, outputs must change
        tb_opcode <= OP_JMP;
        tb_z_flag <= '0';
        tb_c_flag <= '0';
        wait for 10 ns;
        assert(tb_reg_wr_en = '0')   report "test 22 failed: reg_wr_en" severity failure;
        assert(tb_wb_sel = WB_ALU)   report "test 22 failed: wb_sel"    severity failure;
        assert(tb_alu_sel = ALU_ADD) report "test 22 failed: alu_sel"   severity failure;
        assert(tb_ram_wr_en = '0')   report "test 22 failed: ram_wr_en" severity failure;
        assert(tb_z_load = '0')      report "test 22 failed: z_load"    severity failure;
        assert(tb_c_load = '0')      report "test 22 failed: c_load"    severity failure;
        assert(tb_pc_load = '1')     report "test 22 failed: pc_load"   severity failure;
        assert(tb_pc_inc = '1')      report "test 22 failed: pc_inc"    severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;