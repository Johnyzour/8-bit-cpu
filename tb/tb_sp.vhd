--------------------------------------------------------------------------------
-- File        : tb_sp.vhd
-- Description : Self-checking testbench for sp. Checks reset to F0, decrement,
--               increment, hold, decrement-over-increment and reset priority,
--               and update timing.
-- Notes       : Prints "all tests completed and passed" at 100 ns.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_sp is
end entity tb_sp;

architecture sim of tb_sp is
    signal tb_clk    : std_logic := '0';
    signal tb_rst    : std_logic := '0';
    signal tb_sp_inc : std_logic := '0';
    signal tb_sp_dec : std_logic := '0';
    signal tb_sp_out : std_logic_vector (7 downto 0);  
begin
    uut : entity work.sp
    port map (
        clk    => tb_clk,
        rst    => tb_rst,
        sp_inc => tb_sp_inc,
        sp_dec => tb_sp_dec,
        sp_out => tb_sp_out
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

        --test1: reset loads F0
        tb_rst    <= '1';
        tb_sp_dec <= '0';
        tb_sp_inc <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"F0") report "test 1 failed" severity failure;

        --test2: decrement (first PUSH)
        tb_rst    <= '0';
        tb_sp_dec <= '1';
        tb_sp_inc <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"EF") report "test 2 failed" severity failure;

        --test3: decrements again
        tb_rst    <= '0';
        tb_sp_dec <= '1';
        tb_sp_inc <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"EE") report "test 3 failed" severity failure;

        --test4: hold when inc and dec are 0
        tb_rst    <= '0';
        tb_sp_dec <= '0';
        tb_sp_inc <= '0';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"EE") report "test 4 failed" severity failure;

        --test5: increment (POP)
        tb_rst    <= '0';
        tb_sp_dec <= '0';
        tb_sp_inc <= '1';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"EF") report "test 5 failed" severity failure;

        --test6: back to the reset value
        tb_rst    <= '0';
        tb_sp_dec <= '0';
        tb_sp_inc <= '1';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"F0") report "test 6 failed" severity failure;

        --test7: decrement beats increment
        tb_rst    <= '0';
        tb_sp_dec <= '1';
        tb_sp_inc <= '1';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"EF") report "test 7 failed" severity failure;

        --test8: reset beats decrement and increment
        tb_rst    <= '1';
        tb_sp_dec <= '1';
        tb_sp_inc <= '1';
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"F0") report "test 8 failed" severity failure;

        --test9a: decrement, not visible before the rising edge
        tb_rst    <= '0';
        tb_sp_dec <= '1';
        tb_sp_inc <= '0';
        wait for 4 ns;
        assert(tb_sp_out = x"F0") report "test 9a failed" severity failure;

        --test9b: same inputs, visible after the rising edge
        wait until falling_edge(tb_clk);
        assert(tb_sp_out = x"EF") report "test 9b failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
