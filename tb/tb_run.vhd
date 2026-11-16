--------------------------------------------------------------------------------
-- File        : tb_run.vhd
-- Description : Program runner for the CPU (not a self-checking testbench).
--               Runs whatever program memory.vhd loaded from program.mem
--               until it reaches its halt loop, then stops the clock so the
--               simulation ends.
-- Notes       : The halt loop is a JMP to its own address. In each FETCH1 the
--               IR holds the instruction fetched at the previous FETCH1, so
--               the halt is detected when the IR is a JMP whose target equals
--               that previous fetch address (one pass after the first fetch
--               of the halt instruction). A JMP to any other address is not a
--               halt, even though the next fetch is at its target.
--               Prints the cycle count, PC, SP, Z and C. Registers and memory
--               are not visible on the cpu ports; print them with
--               tools/show.tcl, or look at u_reg_file/regs and u_memory/mem in
--               the waveform.
--               Stops with an error if no halt is reached within max_cycles.
--               Run with "run all" (or source tools/show.tcl, which does it).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_run is
    generic (
        max_cycles : natural := 20000
    );
end entity tb_run;

architecture sim of tb_run is
    signal tb_clk       : std_logic := '0';
    signal tb_rst       : std_logic := '1';
    signal tb_pc_dbg    : std_logic_vector (7 downto 0);
    signal tb_sp_dbg    : std_logic_vector (7 downto 0);
    signal tb_instr_dbg : std_logic_vector (23 downto 0);
    signal tb_reg_a_dbg : std_logic_vector (7 downto 0);
    signal tb_z_dbg     : std_logic;
    signal tb_c_dbg     : std_logic;
    signal tb_state_dbg : state_t;
    signal running      : boolean := true;

    -- 8-bit vector as two hex digits, for the report
    function hex (v : std_logic_vector) return string is
        constant digits : string (1 to 16) := "0123456789ABCDEF";
        variable s      : string (1 to v'length / 4);
        variable nib    : std_logic_vector (3 downto 0);
        variable value  : natural;
    begin
        for i in s'range loop
            nib   := v(v'left - 4*(i - 1) downto v'left - 4*(i - 1) - 3);
            value := 0;
            for b in 3 downto 0 loop
                value := value * 2;
                if nib(b) = '1' then
                    value := value + 1;
                end if;
            end loop;
            s(i) := digits(value + 1);
        end loop;
        return s;
    end function hex;
begin
    uut : entity work.cpu
    port map (
        clk       => tb_clk,
        rst       => tb_rst,
        pc_dbg    => tb_pc_dbg,
        sp_dbg    => tb_sp_dbg,
        instr_dbg => tb_instr_dbg,
        reg_a_dbg => tb_reg_a_dbg,
        z_dbg     => tb_z_dbg,
        c_dbg     => tb_c_dbg,
        state_dbg => tb_state_dbg
    );

    -- the clock stops once the program has halted, so "run all" ends
    clk_proc : process
    begin
        while running loop
            tb_clk <= '0';
            wait for 5 ns;
            tb_clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process clk_proc;

    run_proc : process
        variable cycle    : natural := 0;
        variable fetch_pc : std_logic_vector (7 downto 0) := x"00";  -- address of the instruction in the IR
    begin
        -- reset at the first rising edge, as in tb_cpu
        wait until falling_edge(tb_clk);
        tb_rst <= '0';

        loop
            if tb_state_dbg = S_FETCH1 then
                -- halt loop: the IR holds a JMP to its own address
                if cycle > 0 and tb_instr_dbg(23 downto 16) = OP_JMP
                   and tb_instr_dbg(7 downto 0) = fetch_pc then
                    exit;
                end if;
                fetch_pc := tb_pc_dbg;      -- the instruction fetched now starts here
            end if;
            assert cycle < max_cycles
                report "no halt loop within " & integer'image(max_cycles) & " cycles (PC = " & hex(tb_pc_dbg) & ")"
                severity failure;
            wait until falling_edge(tb_clk);
            cycle := cycle + 1;
        end loop;

        report "halted at cycle " & integer'image(cycle) &
               ": PC = " & hex(tb_pc_dbg) & ", SP = " & hex(tb_sp_dbg) &
               ", Z = " & std_logic'image(tb_z_dbg) & ", C = " & std_logic'image(tb_c_dbg)
            severity note;
        running <= false;
        wait;
    end process run_proc;
end architecture sim;
