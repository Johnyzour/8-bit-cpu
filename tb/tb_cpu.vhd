library ieee;
use ieee.std_logic_1164.all;

entity tb_cpu is
end entity tb_cpu;

architecture sim of tb_cpu is
    signal tb_clk       : std_logic := '0';
    signal tb_rst       : std_logic := '1';
    signal tb_pc_dbg    : std_logic_vector (7 downto 0);
    signal tb_instr_dbg : std_logic_vector (15 downto 0);
    signal tb_reg_a_dbg : std_logic_vector (7 downto 0);
    signal tb_z_dbg     : std_logic;
    signal tb_c_dbg     : std_logic;
begin
    uut : entity work.cpu
    port map (
        clk       => tb_clk,
        rst       => tb_rst,
        pc_dbg    => tb_pc_dbg,
        instr_dbg => tb_instr_dbg,
        reg_a_dbg => tb_reg_a_dbg,
        z_dbg     => tb_z_dbg,
        c_dbg     => tb_c_dbg
    );

    clk_proc : process
    begin
        tb_clk <= '0';
        wait for 5 ns;
        tb_clk <= '1';
        wait for 5 ns;
    end process clk_proc;

    stim_proc : process
    begin
        --test1 (cycle 0): LDI R0, 0F
        wait until falling_edge(tb_clk);
        tb_rst <= '0';
        assert(tb_pc_dbg = x"00")      report "test 1 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"100F") report "test 1 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"00")   report "test 1 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 1 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 1 failed: c_dbg"     severity failure;

        --test2 (cycle 1): LDI R1, 3C
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"01")      report "test 2 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"143C") report "test 2 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"00")   report "test 2 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 2 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 2 failed: c_dbg"     severity failure;

        --test3 (cycle 2): MOV R2, R1
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"02")      report "test 3 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"2900") report "test 3 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"00")   report "test 3 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 3 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 3 failed: c_dbg"     severity failure;

        --test4 (cycle 3): ADD R2, R0
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"03")      report "test 4 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"5800") report "test 4 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"3C")   report "test 4 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 4 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 4 failed: c_dbg"     severity failure;

        --test5 (cycle 4): AND R2, R1
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"04")      report "test 5 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"7900") report "test 5 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"4B")   report "test 5 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 5 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 5 failed: c_dbg"     severity failure;

        --test6 (cycle 5): OR R2, R0
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"05")      report "test 6 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"8800") report "test 6 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"08")   report "test 6 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 6 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 6 failed: c_dbg"     severity failure;

        --test7 (cycle 6): XOR R2, R0
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"06")      report "test 7 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"9800") report "test 7 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"0F")   report "test 7 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 7 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 7 failed: c_dbg"     severity failure;

        --test8 (cycle 7): JZ 9, Z now 1 from the XOR
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"07")      report "test 8 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"D009") report "test 8 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"0F")   report "test 8 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '1')         report "test 8 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 8 failed: c_dbg"     severity failure;

        --test9 (cycle 8): NOT R2, JZ was taken so address 08 skipped
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"09")      report "test 9 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"A800") report "test 9 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"00")   report "test 9 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '1')         report "test 9 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 9 failed: c_dbg"     severity failure;

        --test10 (cycle 9): ST R2, 20
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"0A")      report "test 10 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"4820") report "test 10 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"FF")   report "test 10 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 10 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 10 failed: c_dbg"     severity failure;

        --test11 (cycle 10): LD R3, 20, R3 still 00 proves address 08 never ran
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"0B")      report "test 11 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"3C20") report "test 11 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"00")   report "test 11 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 11 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 11 failed: c_dbg"     severity failure;

        --test12 (cycle 11): SUB R0, R1
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"0C")      report "test 12 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"6100") report "test 12 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"0F")   report "test 12 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 12 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 12 failed: c_dbg"     severity failure;

        --test13 (cycle 12): JC 15, C now 1 from the SUB borrow
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"0D")      report "test 13 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"F00F") report "test 13 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"D3")   report "test 13 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 13 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '1')         report "test 13 failed: c_dbg"     severity failure;

        --test14 (cycle 13): CMP R3, R2, JC taken; R3 = FF proves LD worked
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"0F")      report "test 14 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"BE00") report "test 14 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"FF")   report "test 14 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '0')         report "test 14 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '1')         report "test 14 failed: c_dbg"     severity failure;

        --test15 (cycle 14): JNZ 18, CMP set Z and cleared C
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"10")      report "test 15 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"E012") report "test 15 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"D3")   report "test 15 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '1')         report "test 15 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 15 failed: c_dbg"     severity failure;

        --test16 (cycle 15): NOP, JNZ not taken so it fell through
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"11")      report "test 16 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"0000") report "test 16 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"D3")   report "test 16 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '1')         report "test 16 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 16 failed: c_dbg"     severity failure;

        --test17 (cycle 16): JMP 18
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"12")      report "test 17 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"C012") report "test 17 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"D3")   report "test 17 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '1')         report "test 17 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 17 failed: c_dbg"     severity failure;

        --test18 (cycle 17): halted at 18
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"12")      report "test 18 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"C012") report "test 18 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"D3")   report "test 18 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '1')         report "test 18 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 18 failed: c_dbg"     severity failure;

        --test19 (cycle 18): still halted at 18
        wait until falling_edge(tb_clk);
        assert(tb_pc_dbg = x"12")      report "test 19 failed: pc_dbg"    severity failure;
        assert(tb_instr_dbg = x"C012") report "test 19 failed: instr_dbg" severity failure;
        assert(tb_reg_a_dbg = x"D3")   report "test 19 failed: reg_a_dbg" severity failure;
        assert(tb_z_dbg = '1')         report "test 19 failed: z_dbg"     severity failure;
        assert(tb_c_dbg = '0')         report "test 19 failed: c_dbg"     severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
