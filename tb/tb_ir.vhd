--------------------------------------------------------------------------------
-- File        : tb_ir.vhd
-- Description : Self-checking testbench for ir. Tests reset, load, hold, full
--               24-bit width, reset priority and load timing.
-- Notes       : Prints "all tests completed and passed" at 80 ns.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_ir is
end entity tb_ir;

architecture sim of tb_ir is
    signal tb_clk      : std_logic := '0';
    signal tb_rst      : std_logic := '0';
    signal tb_ir_load  : std_logic := '0';
    signal tb_data_in  : std_logic_vector (23 downto 0) := (others => '0');
    signal tb_data_out : std_logic_vector (23 downto 0);
begin
    uut : entity work.ir
    port map (
        clk      => tb_clk,
        rst      => tb_rst,
        ir_load  => tb_ir_load,
        data_in  => tb_data_in,
        data_out => tb_data_out
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
        
        --test1: reset clears from U
        tb_rst     <= '1';
        tb_ir_load <= '0';
        tb_data_in <= x"000000";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"000000") report "test 1 failed" severity failure;
    
        --test2: load
        tb_rst     <= '0';
        tb_ir_load <= '1';
        tb_data_in <= x"01000F";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"01000F") report "test 2 failed" severity failure;

        --test3: holds when ir_load = 0
        tb_rst     <= '0';
        tb_ir_load <= '0';
        tb_data_in <= x"022100";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"01000F") report "test 3 failed" severity failure;

        --test4: loads a new value
        tb_rst     <= '0';
        tb_ir_load <= '1';
        tb_data_in <= x"0C0012";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"0C0012") report "test 4 failed" severity failure;

        --test5: all bits set
        tb_rst     <= '0';
        tb_ir_load <= '1';
        tb_data_in <= x"FFFFFF";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"FFFFFF") report "test 5 failed" severity failure;

        --test6: reset beats load
        tb_rst     <= '1';
        tb_ir_load <= '1';
        tb_data_in <= x"052000";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"000000") report "test 6 failed" severity failure;

        --test7a: load, not visible before the rising edge
        tb_rst     <= '0';
        tb_ir_load <= '1';
        tb_data_in <= x"0B3200";
        wait for 4 ns;
        assert(tb_data_out = x"000000") report "test 7a failed" severity failure;

        --test7b: same inputs, visible after the rising edge
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"0B3200") report "test 7b failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
