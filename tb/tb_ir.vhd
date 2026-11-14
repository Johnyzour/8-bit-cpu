--------------------------------------------------------------------------------
-- File        : tb_ir.vhd
-- Description : Self-checking testbench for ir. Checks reset, each byte load
--               on its own, assembly of a full instruction, hold, independent
--               multi-byte loads, reset priority and load timing.
-- Notes       : Prints "all tests completed and passed" at 110 ns.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_ir is
end entity tb_ir;

architecture sim of tb_ir is
    signal tb_clk      : std_logic := '0';
    signal tb_rst      : std_logic := '0';
    signal tb_ir_load  : std_logic_vector (2 downto 0) := (others => '0');
    signal tb_data_in  : std_logic_vector (7 downto 0) := (others => '0');
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

        --test1: reset clears the IR
        tb_rst     <= '1';
        tb_ir_load <= "000";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"000000") report "test 1 failed" severity failure;

        --test2: byte 2 (opcode) loads alone
        tb_rst     <= '0';
        tb_ir_load <= "100";
        tb_data_in <= x"01";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"010000") report "test 2 failed" severity failure;

        --test3: byte 1 (rd/rs) loads alone, byte 2 kept
        tb_rst     <= '0';
        tb_ir_load <= "010";
        tb_data_in <= x"23";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"012300") report "test 3 failed" severity failure;

        --test4: byte 0 (imm) loads alone, full instruction assembled
        tb_rst     <= '0';
        tb_ir_load <= "001";
        tb_data_in <= x"0F";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"01230F") report "test 4 failed" severity failure;

        --test5: hold when no byte is enabled
        tb_rst     <= '0';
        tb_ir_load <= "000";
        tb_data_in <= x"FF";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"01230F") report "test 5 failed" severity failure;

        --test6: only the middle byte changes
        tb_rst     <= '0';
        tb_ir_load <= "010";
        tb_data_in <= x"45";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"01450F") report "test 6 failed" severity failure;

        --test7: all three bytes load together (independent enables)
        tb_rst     <= '0';
        tb_ir_load <= "111";
        tb_data_in <= x"AA";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"AAAAAA") report "test 7 failed" severity failure;

        --test8: non-adjacent bytes load, middle byte kept
        tb_rst     <= '0';
        tb_ir_load <= "101";
        tb_data_in <= x"5C";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"5CAA5C") report "test 8 failed" severity failure;

        --test9: reset beats every load
        tb_rst     <= '1';
        tb_ir_load <= "111";
        tb_data_in <= x"FF";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"000000") report "test 9 failed" severity failure;

        --test10a: load opcode C3, not visible before the rising edge
        tb_rst     <= '0';
        tb_ir_load <= "100";
        tb_data_in <= x"C3";
        wait for 4 ns;
        assert(tb_data_out = x"000000") report "test 10a failed" severity failure;

        --test10b: same inputs, visible after the rising edge
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"C30000") report "test 10b failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
