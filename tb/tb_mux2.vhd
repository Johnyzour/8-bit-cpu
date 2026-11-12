library ieee;
use ieee.std_logic_1164.all;

entity tb_mux2 is
end entity tb_mux2;

architecture sim of tb_mux2 is
    signal tb_in0 : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_in1 : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_sel : std_logic := '0';
    signal tb_y   : std_logic_vector (7 downto 0);
begin
    uut : entity work.mux2
    port map (
        in0 => tb_in0,
        in1 => tb_in1,
        sel => tb_sel,
        y   => tb_y
    );

    stim_proc : process
    begin
        --test1: all zeros vs all ones, sel = 0 picks in0
        tb_in0 <= x"00";
        tb_in1 <= x"FF";
        tb_sel <= '0';
        wait for 10 ns;
        assert(tb_y = x"00") report "test 1 failed" severity failure;

        --test2: all zeros vs all ones, sel = 1 picks in1
        tb_in0 <= x"00";
        tb_in1 <= x"FF";
        tb_sel <= '1';
        wait for 10 ns;
        assert(tb_y = x"FF") report "test 2 failed" severity failure;

        --test3: all ones vs all zeros, sel = 0 picks in0
        tb_in0 <= x"FF";
        tb_in1 <= x"00";
        tb_sel <= '0';
        wait for 10 ns;
        assert(tb_y = x"FF") report "test 3 failed" severity failure;

        --test4: all ones vs all zeros, sel = 1 picks in1
        tb_in0 <= x"FF";
        tb_in1 <= x"00";
        tb_sel <= '1';
        wait for 10 ns;
        assert(tb_y = x"00") report "test 4 failed" severity failure;

        --test5: alternating bits, sel = 0
        tb_in0 <= x"AA";
        tb_in1 <= x"55";
        tb_sel <= '0';
        wait for 10 ns;
        assert(tb_y = x"AA") report "test 5 failed" severity failure;

        --test6: alternating bits, sel = 1
        tb_in0 <= x"AA";
        tb_in1 <= x"55";
        tb_sel <= '1';
        wait for 10 ns;
        assert(tb_y = x"55") report "test 6 failed" severity failure;

        --test7: opposite nibbles, sel = 0
        tb_in0 <= x"0F";
        tb_in1 <= x"F0";
        tb_sel <= '0';
        wait for 10 ns;
        assert(tb_y = x"0F") report "test 7 failed" severity failure;

        --test8: opposite nibbles, sel = 1
        tb_in0 <= x"0F";
        tb_in1 <= x"F0";
        tb_sel <= '1';
        wait for 10 ns;
        assert(tb_y = x"F0") report "test 8 failed" severity failure;

        --test9: equal inputs, sel = 0
        tb_in0 <= x"3C";
        tb_in1 <= x"3C";
        tb_sel <= '0';
        wait for 10 ns;
        assert(tb_y = x"3C") report "test 9 failed" severity failure;

        --test10: equal inputs, sel = 1
        tb_in0 <= x"3C";
        tb_in1 <= x"3C";
        tb_sel <= '1';
        wait for 10 ns;
        assert(tb_y = x"3C") report "test 10 failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;