library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_alu is
end entity tb_alu;

architecture sim of tb_alu is
    signal tb_a       : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_b       : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_alu_sel : std_logic_vector (2 downto 0) := (others => '0');
    signal tb_result  : std_logic_vector (7 downto 0);
    signal tb_zero    : std_logic;
    signal tb_carry   : std_logic;
begin
    uut : entity work.alu
    port map (
        a       => tb_a,
        b       => tb_b,
        alu_sel => tb_alu_sel,
        result  => tb_result,
        zero    => tb_zero,
        carry   => tb_carry
    );

    stim_proc : process
    begin
        --test1: basic addition
        tb_a       <= x"05";
        tb_b       <= x"03";
        tb_alu_sel <= ALU_ADD;
        wait for 10 ns;
        assert(tb_result = x"08") report "test 1 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 1 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 1 failed: carry"  severity failure;

        --test2: wraps to zero, carry out
        tb_a       <= x"FF";
        tb_b       <= x"01";
        tb_alu_sel <= ALU_ADD;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 2 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 2 failed: zero"   severity failure;
        assert(tb_carry = '1')    report "test 2 failed: carry"  severity failure;

        --test3: carry out of bit 7 with a zero result
        tb_a       <= x"80";
        tb_b       <= x"80";
        tb_alu_sel <= ALU_ADD;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 3 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 3 failed: zero"   severity failure;
        assert(tb_carry = '1')    report "test 3 failed: carry"  severity failure;

        --test4: zero result without a carry
        tb_a       <= x"00";
        tb_b       <= x"00";
        tb_alu_sel <= ALU_ADD;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 4 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 4 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 4 failed: carry"  severity failure;

        --test5: crosses into the top bit, no carry
        tb_a       <= x"7F";
        tb_b       <= x"01";
        tb_alu_sel <= ALU_ADD;
        wait for 10 ns;
        assert(tb_result = x"80") report "test 5 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 5 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 5 failed: carry"  severity failure;

        --test6: equal values, zero flag
        tb_a       <= x"05";
        tb_b       <= x"05";
        tb_alu_sel <= ALU_SUB;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 6 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 6 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 6 failed: carry"  severity failure;

        --test7: basic subtraction
        tb_a       <= x"05";
        tb_b       <= x"03";
        tb_alu_sel <= ALU_SUB;
        wait for 10 ns;
        assert(tb_result = x"02") report "test 7 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 7 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 7 failed: carry"  severity failure;

        --test8: borrow
        tb_a       <= x"03";
        tb_b       <= x"05";
        tb_alu_sel <= ALU_SUB;
        wait for 10 ns;
        assert(tb_result = x"FE") report "test 8 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 8 failed: zero"   severity failure;
        assert(tb_carry = '1')    report "test 8 failed: carry"  severity failure;

        --test9: borrow from zero
        tb_a       <= x"00";
        tb_b       <= x"01";
        tb_alu_sel <= ALU_SUB;
        wait for 10 ns;
        assert(tb_result = x"FF") report "test 9 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 9 failed: zero"   severity failure;
        assert(tb_carry = '1')    report "test 9 failed: carry"  severity failure;

        --test10: no borrow when a > b
        tb_a       <= x"80";
        tb_b       <= x"01";
        tb_alu_sel <= ALU_SUB;
        wait for 10 ns;
        assert(tb_result = x"7F") report "test 10 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 10 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 10 failed: carry"  severity failure;

        --test11: AND, partial overlap
        tb_a       <= x"F0";
        tb_b       <= x"3C";
        tb_alu_sel <= ALU_AND;
        wait for 10 ns;
        assert(tb_result = x"30") report "test 11 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 11 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 11 failed: carry"  severity failure;

        --test12: AND, no overlap
        tb_a       <= x"F0";
        tb_b       <= x"0F";
        tb_alu_sel <= ALU_AND;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 12 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 12 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 12 failed: carry"  severity failure;

        --test13: OR, combines halves
        tb_a       <= x"F0";
        tb_b       <= x"0F";
        tb_alu_sel <= ALU_OR;
        wait for 10 ns;
        assert(tb_result = x"FF") report "test 13 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 13 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 13 failed: carry"  severity failure;

        --test14: OR, zero result
        tb_a       <= x"00";
        tb_b       <= x"00";
        tb_alu_sel <= ALU_OR;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 14 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 14 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 14 failed: carry"  severity failure;

        --test15: XOR, equal values cancel
        tb_a       <= x"FF";
        tb_b       <= x"FF";
        tb_alu_sel <= ALU_XOR;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 15 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 15 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 15 failed: carry"  severity failure;

        --test16: XOR, opposite bits
        tb_a       <= x"AA";
        tb_b       <= x"55";
        tb_alu_sel <= ALU_XOR;
        wait for 10 ns;
        assert(tb_result = x"FF") report "test 16 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 16 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 16 failed: carry"  severity failure;

        --test17: NOT, inverts a and ignores b
        tb_a       <= x"0F";
        tb_b       <= x"55";
        tb_alu_sel <= ALU_NOT;
        wait for 10 ns;
        assert(tb_result = x"F0") report "test 17 failed: result" severity failure;
        assert(tb_zero = '0')     report "test 17 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 17 failed: carry"  severity failure;

        --test18: NOT, all ones gives zero
        tb_a       <= x"FF";
        tb_b       <= x"55";
        tb_alu_sel <= ALU_NOT;
        wait for 10 ns;
        assert(tb_result = x"00") report "test 18 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 18 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 18 failed: carry"  severity failure;

        --test19: spare code 110
        tb_a       <= x"FF";
        tb_b       <= x"FF";
        tb_alu_sel <= "110";
        wait for 10 ns;
        assert(tb_result = x"00") report "test 19 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 19 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 19 failed: carry"  severity failure;

        --test20: spare code 111
        tb_a       <= x"FF";
        tb_b       <= x"FF";
        tb_alu_sel <= "111";
        wait for 10 ns;
        assert(tb_result = x"00") report "test 20 failed: result" severity failure;
        assert(tb_zero = '1')     report "test 20 failed: zero"   severity failure;
        assert(tb_carry = '0')    report "test 20 failed: carry"  severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
