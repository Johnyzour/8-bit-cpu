library ieee;
use ieee.std_logic_1164.all;

entity tb_reg_file is
end entity tb_reg_file;

architecture sim of tb_reg_file is
    signal tb_clk       : std_logic := '0';
    signal tb_rst       : std_logic := '0';
    signal tb_wr_en     : std_logic := '0';
    signal tb_wr_sel    : std_logic_vector (1 downto 0) := (others => '0');
    signal tb_wr_data   : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_rd_sel_a  : std_logic_vector (1 downto 0) := (others => '0');
    signal tb_rd_sel_b  : std_logic_vector (1 downto 0) := (others => '0');
    signal tb_rd_data_a : std_logic_vector (7 downto 0);
    signal tb_rd_data_b : std_logic_vector (7 downto 0);
begin
    uut : entity work.reg_file
    port map (
        clk       => tb_clk,
        rst       => tb_rst,
        wr_en     => tb_wr_en,
        wr_sel    => tb_wr_sel,
        wr_data   => tb_wr_data,
        rd_sel_a  => tb_rd_sel_a,
        rd_sel_b  => tb_rd_sel_b,
        rd_data_a => tb_rd_data_a,
        rd_data_b => tb_rd_data_b
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

        --test1a: reset clears R0, R1
        tb_rst      <= '1';
        tb_wr_en    <= '0';
        tb_wr_sel   <= "00";
        tb_wr_data  <= x"00";
        tb_rd_sel_a <= "00";
        tb_rd_sel_b <= "01";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"00") report "test 1a failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"00") report "test 1a failed: rd_data_b" severity failure;

        --test1b: reset clears R2, R3
        tb_rst      <= '1';
        tb_wr_en    <= '0';
        tb_wr_sel   <= "00";
        tb_wr_data  <= x"00";
        tb_rd_sel_a <= "10";
        tb_rd_sel_b <= "11";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"00") report "test 1b failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"00") report "test 1b failed: rd_data_b" severity failure;

        --test2: write A5 to R0
        tb_rst      <= '0';
        tb_wr_en    <= '1';
        tb_wr_sel   <= "00";
        tb_wr_data  <= x"A5";
        tb_rd_sel_a <= "00";
        tb_rd_sel_b <= "00";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"A5") report "test 2 failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"A5") report "test 2 failed: rd_data_b" severity failure;

        --test3: write 3C to R1, R0 unchanged
        tb_rst      <= '0';
        tb_wr_en    <= '1';
        tb_wr_sel   <= "01";
        tb_wr_data  <= x"3C";
        tb_rd_sel_a <= "01";
        tb_rd_sel_b <= "00";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"3C") report "test 3 failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"A5") report "test 3 failed: rd_data_b" severity failure;

        --test4a: write F0 to R2, R3 still 00
        tb_rst      <= '0';
        tb_wr_en    <= '1';
        tb_wr_sel   <= "10";
        tb_wr_data  <= x"F0";
        tb_rd_sel_a <= "10";
        tb_rd_sel_b <= "11";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"F0") report "test 4a failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"00") report "test 4a failed: rd_data_b" severity failure;

        --test4b: write 0F to R3
        tb_rst      <= '0';
        tb_wr_en    <= '1';
        tb_wr_sel   <= "11";
        tb_wr_data  <= x"0F";
        tb_rd_sel_a <= "10";
        tb_rd_sel_b <= "11";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"F0") report "test 4b failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"0F") report "test 4b failed: rd_data_b" severity failure;

        --test5: wr_en = 0 blocks the write to R1
        tb_rst      <= '0';
        tb_wr_en    <= '0';
        tb_wr_sel   <= "01";
        tb_wr_data  <= x"FF";
        tb_rd_sel_a <= "01";
        tb_rd_sel_b <= "00";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"3C") report "test 5 failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"A5") report "test 5 failed: rd_data_b" severity failure;

        --test6: overwrite R0 with 11
        tb_rst      <= '0';
        tb_wr_en    <= '1';
        tb_wr_sel   <= "00";
        tb_wr_data  <= x"11";
        tb_rd_sel_a <= "00";
        tb_rd_sel_b <= "01";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"11") report "test 6 failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"3C") report "test 6 failed: rd_data_b" severity failure;

        --test7: R2, R3 untouched
        tb_rst      <= '0';
        tb_wr_en    <= '0';
        tb_wr_sel   <= "00";
        tb_wr_data  <= x"00";
        tb_rd_sel_a <= "10";
        tb_rd_sel_b <= "11";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"F0") report "test 7 failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"0F") report "test 7 failed: rd_data_b" severity failure;

        --test8: both ports read R2
        tb_rst      <= '0';
        tb_wr_en    <= '0';
        tb_wr_sel   <= "00";
        tb_wr_data  <= x"00";
        tb_rd_sel_a <= "10";
        tb_rd_sel_b <= "10";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"F0") report "test 8 failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"F0") report "test 8 failed: rd_data_b" severity failure;

        --test9a: reset beats write (write aimed at R2)
        tb_rst      <= '1';
        tb_wr_en    <= '1';
        tb_wr_sel   <= "10";
        tb_wr_data  <= x"FF";
        tb_rd_sel_a <= "00";
        tb_rd_sel_b <= "01";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"00") report "test 9a failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"00") report "test 9a failed: rd_data_b" severity failure;

        --test9b: R2 and R3 cleared too
        tb_rst      <= '1';
        tb_wr_en    <= '0';
        tb_wr_sel   <= "00";
        tb_wr_data  <= x"00";
        tb_rd_sel_a <= "10";
        tb_rd_sel_b <= "11";
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"00") report "test 9b failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"00") report "test 9b failed: rd_data_b" severity failure;

        --test10a: write 77 to R1, not visible before the rising edge
        tb_rst      <= '0';
        tb_wr_en    <= '1';
        tb_wr_sel   <= "01";
        tb_wr_data  <= x"77";
        tb_rd_sel_a <= "01";
        tb_rd_sel_b <= "01";
        wait for 4 ns;
        assert(tb_rd_data_a = x"00") report "test 10a failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"00") report "test 10a failed: rd_data_b" severity failure;

        --test10b: same inputs, visible after the rising edge
        wait until falling_edge(tb_clk);
        assert(tb_rd_data_a = x"77") report "test 10b failed: rd_data_a" severity failure;
        assert(tb_rd_data_b = x"77") report "test 10b failed: rd_data_b" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
