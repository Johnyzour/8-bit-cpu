--------------------------------------------------------------------------------
-- File        : tb_flags_reg.vhd
-- Description : Self-checking testbench for flags_reg. Tests reset, loading
--               each flag independently, hold, reset priority and load timing.
-- Notes       : Prints "all tests completed and passed" at 90 ns.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_flags_reg is
end entity tb_flags_reg;

architecture sim of tb_flags_reg is
    signal tb_clk    : std_logic := '0';
    signal tb_rst    : std_logic := '0';
    signal tb_z_load : std_logic := '0';
    signal tb_c_load : std_logic := '0';
    signal tb_z_in   : std_logic := '0';
    signal tb_c_in   : std_logic := '0';
    signal tb_z_out  : std_logic;
    signal tb_c_out  : std_logic;
begin
    uut : entity work.flags_reg
    port map (
        clk    => tb_clk,
        rst    => tb_rst,
        z_load => tb_z_load,
        c_load => tb_c_load,
        z_in   => tb_z_in,
        c_in   => tb_c_in,
        z_out  => tb_z_out,
        c_out  => tb_c_out
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
        wait until falling_edge(tb_clk);

        --test1: reset clears both flags
        tb_rst    <= '1';
        tb_z_load <= '0';
        tb_c_load <= '0';
        tb_z_in   <= '0';
        tb_c_in   <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '0') report "test 1 failed: z_out" severity failure;
        assert(tb_c_out = '0') report "test 1 failed: c_out" severity failure;

        --test2: load both (like ADD/SUB/CMP)
        tb_rst    <= '0';
        tb_z_load <= '1';
        tb_c_load <= '1';
        tb_z_in   <= '1';
        tb_c_in   <= '1';
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '1') report "test 2 failed: z_out" severity failure;
        assert(tb_c_out = '1') report "test 2 failed: c_out" severity failure;

        --test3: both hold when loads are 0
        tb_rst    <= '0';
        tb_z_load <= '0';
        tb_c_load <= '0';
        tb_z_in   <= '0';
        tb_c_in   <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '1') report "test 3 failed: z_out" severity failure;
        assert(tb_c_out = '1') report "test 3 failed: c_out" severity failure;

        --test4: load Z only, C kept (like AND/OR/XOR/NOT)
        tb_rst    <= '0';
        tb_z_load <= '1';
        tb_c_load <= '0';
        tb_z_in   <= '0';
        tb_c_in   <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '0') report "test 4 failed: z_out" severity failure;
        assert(tb_c_out = '1') report "test 4 failed: c_out" severity failure;

        --test5: load C only, Z kept even though z_in = 1
        tb_rst    <= '0';
        tb_z_load <= '0';
        tb_c_load <= '1';
        tb_z_in   <= '1';
        tb_c_in   <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '0') report "test 5 failed: z_out" severity failure;
        assert(tb_c_out = '0') report "test 5 failed: c_out" severity failure;

        --test6: set both again so reset has something to clear
        tb_rst    <= '0';
        tb_z_load <= '1';
        tb_c_load <= '1';
        tb_z_in   <= '1';
        tb_c_in   <= '1';
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '1') report "test 6 failed: z_out" severity failure;
        assert(tb_c_out = '1') report "test 6 failed: c_out" severity failure;

        --test7: reset beats both loads
        tb_rst    <= '1';
        tb_z_load <= '1';
        tb_c_load <= '1';
        tb_z_in   <= '1';
        tb_c_in   <= '1';
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '0') report "test 7 failed: z_out" severity failure;
        assert(tb_c_out = '0') report "test 7 failed: c_out" severity failure;

        --test8a: load both, not visible before the rising edge
        tb_rst    <= '0';
        tb_z_load <= '1';
        tb_c_load <= '1';
        tb_z_in   <= '1';
        tb_c_in   <= '1';
        wait for 4 ns;
        assert(tb_z_out = '0') report "test 8a failed: z_out" severity failure;
        assert(tb_c_out = '0') report "test 8a failed: c_out" severity failure;

        --test8b: same inputs, visible after the rising edge
        wait until falling_edge(tb_clk);
        assert(tb_z_out = '1') report "test 8b failed: z_out" severity failure;
        assert(tb_c_out = '1') report "test 8b failed: c_out" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
