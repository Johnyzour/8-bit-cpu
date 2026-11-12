library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_wb_mux is
end entity tb_wb_mux;

architecture sim of tb_wb_mux is
    signal tb_alu_result : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_ram_data   : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_imm        : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_reg_b      : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_sel        : std_logic_vector (1 downto 0) := (others => '0');
    signal tb_wb_data    : std_logic_vector (7 downto 0);
begin
    uut : entity work.wb_mux
    port map (
        alu_result => tb_alu_result,
        ram_data   => tb_ram_data,
        imm        => tb_imm,
        reg_b      => tb_reg_b,
        sel        => tb_sel,
        wb_data    => tb_wb_data
    );

    stim_proc : process
    begin
        --test1: ALU path
        tb_alu_result <= x"11";
        tb_ram_data   <= x"22";
        tb_imm        <= x"33";
        tb_reg_b      <= x"44";
        tb_sel        <= WB_ALU;
        wait for 10 ns;
        assert(tb_wb_data = x"11") report "test 1 failed" severity failure;

        --test2: RAM path
        tb_alu_result <= x"11";
        tb_ram_data   <= x"22";
        tb_imm        <= x"33";
        tb_reg_b      <= x"44";
        tb_sel        <= WB_RAM;
        wait for 10 ns;
        assert(tb_wb_data = x"22") report "test 2 failed" severity failure;

        --test3: imm path (catches mux_b wired to sel(1))
        tb_alu_result <= x"11";
        tb_ram_data   <= x"22";
        tb_imm        <= x"33";
        tb_reg_b      <= x"44";
        tb_sel        <= WB_IMM;
        wait for 10 ns;
        assert(tb_wb_data = x"33") report "test 3 failed" severity failure;

        --test4: register path
        tb_alu_result <= x"11";
        tb_ram_data   <= x"22";
        tb_imm        <= x"33";
        tb_reg_b      <= x"44";
        tb_sel        <= WB_REG;
        wait for 10 ns;
        assert(tb_wb_data = x"44") report "test 4 failed" severity failure;

        --test5: output follows a change on the ALU input
        tb_alu_result <= x"AA";
        tb_ram_data   <= x"22";
        tb_imm        <= x"33";
        tb_reg_b      <= x"44";
        tb_sel        <= WB_ALU;
        wait for 10 ns;
        assert(tb_wb_data = x"AA") report "test 5 failed" severity failure;

        --test6: output follows a change on the register input
        tb_alu_result <= x"AA";
        tb_ram_data   <= x"22";
        tb_imm        <= x"33";
        tb_reg_b      <= x"55";
        tb_sel        <= WB_REG;
        wait for 10 ns;
        assert(tb_wb_data = x"55") report "test 6 failed" severity failure;

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;