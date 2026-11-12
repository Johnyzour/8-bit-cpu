library ieee;
use ieee.std_logic_1164.all;

entity tb_pc is
end entity tb_pc;

architecture sim of tb_pc is
    signal tb_clk       : std_logic := '0';
    signal tb_rst       : std_logic := '0';
    signal tb_pc_inc    : std_logic := '0';
    signal tb_pc_load   : std_logic := '0';
    signal tb_jump_addr : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_pc_out    : std_logic_vector (7 downto 0);
begin
    uut : entity work.pc
    port map (
        clk       => tb_clk,
        rst       => tb_rst,
        pc_inc    => tb_pc_inc,
        pc_load   => tb_pc_load,
        jump_addr => tb_jump_addr,
        pc_out    => tb_pc_out
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

        --test1: reset clears the PC
        tb_rst       <= '1';
        tb_pc_load   <= '0';
        tb_pc_inc    <= '0';
        tb_jump_addr <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"00") report "test 1 failed" severity failure;

        --test2a: increment, first cycle
        tb_rst       <= '0';
        tb_pc_load   <= '0';
        tb_pc_inc    <= '1';
        tb_jump_addr <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"01") report "test 2a failed" severity failure;

        --test2b: increment, second cycle (same inputs)
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"02") report "test 2b failed" severity failure;

        --test3: hold when inc and load are 0
        tb_rst       <= '0';
        tb_pc_load   <= '0';
        tb_pc_inc    <= '0';
        tb_jump_addr <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"02") report "test 3 failed" severity failure;

        --test4: load a jump address
        tb_rst       <= '0';
        tb_pc_load   <= '1';
        tb_pc_inc    <= '0';
        tb_jump_addr <= x"2A";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"2A") report "test 4 failed" severity failure;

        --test5: load beats increment
        tb_rst       <= '0';
        tb_pc_load   <= '1';
        tb_pc_inc    <= '1';
        tb_jump_addr <= x"55";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"55") report "test 5 failed" severity failure;

        --test6: increment continues from the loaded value
        tb_rst       <= '0';
        tb_pc_load   <= '0';
        tb_pc_inc    <= '1';
        tb_jump_addr <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"56") report "test 6 failed" severity failure;

        --test7: load the top address
        tb_rst       <= '0';
        tb_pc_load   <= '1';
        tb_pc_inc    <= '0';
        tb_jump_addr <= x"FF";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"FF") report "test 7 failed" severity failure;

        --test8: increment wraps FF to 00
        tb_rst       <= '0';
        tb_pc_load   <= '0';
        tb_pc_inc    <= '1';
        tb_jump_addr <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"00") report "test 8 failed" severity failure;

        --test9: load a value so reset has something to clear
        tb_rst       <= '0';
        tb_pc_load   <= '1';
        tb_pc_inc    <= '0';
        tb_jump_addr <= x"7E";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"7E") report "test 9 failed" severity failure;

        --test10: reset beats load and increment
        tb_rst       <= '1';
        tb_pc_load   <= '1';
        tb_pc_inc    <= '1';
        tb_jump_addr <= x"7E";
        wait until falling_edge(tb_clk);
        assert(tb_pc_out = x"00") report "test 10 failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;