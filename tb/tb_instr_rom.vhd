--------------------------------------------------------------------------------
-- File        : tb_instr_rom.vhd
-- Description : Self-checking testbench for instr_rom. Checks selected program
--               words against hand-encoded hex, plus empty and top addresses.
-- Notes       : Prints "all tests completed and passed" at 80 ns.
--               Expected values must be updated if the ROM program changes.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_instr_rom is
end entity tb_instr_rom;

architecture sim of tb_instr_rom is
    signal tb_addr  : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_instr : std_logic_vector (23 downto 0);
begin
    uut : entity work.instr_rom
    port map (
        addr  => tb_addr,
        instr => tb_instr
    );

    stim_proc : process
    begin
        --test1: first instruction (LDI R0, 0F)
        tb_addr <= x"00";
        wait for 10 ns;
        assert(tb_instr = x"01000F") report "test 1 failed" severity failure;

        --test2: MOV R2, R1 (rd and rs both non-zero)
        tb_addr <= x"02";
        wait for 10 ns;
        assert(tb_instr = x"022100") report "test 2 failed" severity failure;

        --test3: JZ 9 (jump target in imm)
        tb_addr <= x"07";
        wait for 10 ns;
        assert(tb_instr = x"0D0009") report "test 3 failed" severity failure;

        --test4: CMP R3, R2
        tb_addr <= x"0F";
        wait for 10 ns;
        assert(tb_instr = x"0B3200") report "test 4 failed" severity failure;

        --test5: last instruction (JMP 22 halt)
        tb_addr <= x"16";
        wait for 10 ns;
        assert(tb_instr = x"0C0016") report "test 5 failed" severity failure;

        --test6: first address after the program is empty
        tb_addr <= x"17";
        wait for 10 ns;
        assert(tb_instr = x"000000") report "test 6 failed" severity failure;

        --test7: top address (catches a too-small array)
        tb_addr <= x"FF";
        wait for 10 ns;
        assert(tb_instr = x"000000") report "test 7 failed" severity failure;

        --test8: INC R2 (new 8-bit opcode)
        tb_addr <= x"12";
        wait for 10 ns;
        assert(tb_instr = x"122000") report "test 8 failed" severity failure;
        
        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;