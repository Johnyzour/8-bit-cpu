--------------------------------------------------------------------------------
-- File        : tb_memory.vhd
-- Description : Self-checking testbench for memory. Checks the program bytes
--               loaded by init_mem, empty and top addresses, read-first
--               writes, writes to both data and code, and read latency.
-- Notes       : Synchronous read: each check sees the address applied in the
--               previous cycle. Prints "all tests completed and passed" at
--               150 ns. Expected program bytes must be updated if the program
--               changes.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_memory is
end entity tb_memory;

architecture sim of tb_memory is
    signal tb_clk      : std_logic := '0';
    signal tb_wr_en    : std_logic := '0';
    signal tb_addr     : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_data_in  : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_data_out : std_logic_vector (7 downto 0);
begin
    uut : entity work.memory
    port map (
        clk      => tb_clk,
        wr_en    => tb_wr_en,
        addr     => tb_addr,
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

        --test1: program loaded, opcode of instruction 0 (LDI)
        tb_wr_en   <= '0';
        tb_addr    <= x"00";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"01") report "test 1 failed" severity failure;

        --test2: rd/rs byte of instruction 0
        tb_wr_en   <= '0';
        tb_addr    <= x"01";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"00") report "test 2 failed" severity failure;

        --test3: imm byte of instruction 0
        tb_wr_en   <= '0';
        tb_addr    <= x"02";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"0F") report "test 3 failed" severity failure;

        --test4: rd/rs byte of instruction 1 (rd = 1)
        tb_wr_en   <= '0';
        tb_addr    <= x"04";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"10") report "test 4 failed" severity failure;

        --test5: opcode of the last instruction (JMP at 3 x 51)
        tb_wr_en   <= '0';
        tb_addr    <= x"99";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"0C") report "test 5 failed" severity failure;

        --test6: imm byte of CALL 5A (instruction 22)
        tb_wr_en   <= '0';
        tb_addr    <= x"44";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"5A") report "test 6 failed" severity failure;

        --test7: first byte after the program is empty
        tb_wr_en   <= '0';
        tb_addr    <= x"9C";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"00") report "test 7 failed" severity failure;

        --test8: top address (catches a too-small array)
        tb_wr_en   <= '0';
        tb_addr    <= x"FF";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"00") report "test 8 failed" severity failure;

        --test9: write AA to F0, read-first returns the old byte
        tb_wr_en   <= '1';
        tb_addr    <= x"F0";
        tb_data_in <= x"AA";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"00") report "test 9 failed" severity failure;

        --test10: the write stored the byte
        tb_wr_en   <= '0';
        tb_addr    <= x"F0";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"AA") report "test 10 failed" severity failure;

        --test11: wr_en = 0 blocks the write
        tb_wr_en   <= '0';
        tb_addr    <= x"F0";
        tb_data_in <= x"77";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"AA") report "test 11 failed" severity failure;

        --test12: code is writable, read-first returns the old opcode
        tb_wr_en   <= '1';
        tb_addr    <= x"00";
        tb_data_in <= x"55";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"01") report "test 12 failed" severity failure;

        --test13: program byte overwritten
        tb_wr_en   <= '0';
        tb_addr    <= x"00";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"55") report "test 13 failed" severity failure;

        --test14a: read address 02, not visible before the rising edge
        tb_wr_en   <= '0';
        tb_addr    <= x"02";
        tb_data_in <= x"00";
        wait for 4 ns;
        assert(tb_data_out = x"55") report "test 14a failed" severity failure;

        --test14b: same inputs, visible after the rising edge
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"0F") report "test 14b failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
