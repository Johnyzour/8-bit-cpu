--------------------------------------------------------------------------------
-- File        : tb_data_ram.vhd
-- Description : Self-checking testbench for data_ram. Tests initial contents,
--               writes, the top address, blocked writes and write timing.
-- Notes       : Prints "all tests completed and passed" at 90 ns.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_data_ram is
end entity tb_data_ram;

architecture sim of tb_data_ram is
    signal tb_clk      : std_logic := '0';
    signal tb_wr_en    : std_logic := '0';
    signal tb_addr     : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_data_in  : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_data_out : std_logic_vector (7 downto 0);
begin
    uut : entity work.data_ram
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

        --test1: initial contents are 00
        tb_wr_en   <= '0';
        tb_addr    <= x"00";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"00") report "test 1 failed" severity failure;

        --test2: write A5 to address 00
        tb_wr_en   <= '1';
        tb_addr    <= x"00";
        tb_data_in <= x"A5";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"A5") report "test 2 failed" severity failure;

        --test3: write 3C to top address FF
        tb_wr_en   <= '1';
        tb_addr    <= x"FF";
        tb_data_in <= x"3C";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"3C") report "test 3 failed" severity failure;

        --test4: address 00 kept its value
        tb_wr_en   <= '0';
        tb_addr    <= x"00";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"A5") report "test 4 failed" severity failure;

        --test5: wr_en = 0 blocks the write
        tb_wr_en   <= '0';
        tb_addr    <= x"00";
        tb_data_in <= x"FF";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"A5") report "test 5 failed" severity failure;

        --test6a: write 77 to address 10, not visible before the rising edge
        tb_wr_en   <= '1';
        tb_addr    <= x"10";
        tb_data_in <= x"77";
        wait for 4 ns;
        assert(tb_data_out = x"00") report "test 6a failed" severity failure;

        --test6b: same inputs, visible after the rising edge
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"77") report "test 6b failed" severity failure;

        --test7: address FF still holds its value
        tb_wr_en   <= '0';
        tb_addr    <= x"FF";
        tb_data_in <= x"00";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"3C") report "test 7 failed" severity failure;

        --test8: overwrite address 00 with 11
        tb_wr_en   <= '1';
        tb_addr    <= x"00";
        tb_data_in <= x"11";
        wait until falling_edge(tb_clk);
        assert(tb_data_out = x"11") report "test 8 failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;