--------------------------------------------------------------------------------
-- File        : tb_cpu.vhd
-- Description : System testbench for the multi-cycle cpu. Runs the program in
--               instr_rom (all 20 instructions) and checks the FSM state and
--               debug outputs on every clock cycle against the expected trace.
-- Notes       : Reset is held for the first cycle. pc_dbg runs one ahead after
--               FETCH, and results appear in the state after the one that
--               writes them. Prints "all tests completed and passed" at 800 ns.
--               The expected trace must be updated if the ROM program changes.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_cpu is
end entity tb_cpu;

architecture sim of tb_cpu is
    signal tb_clk       : std_logic := '0';
    signal tb_rst       : std_logic := '1';
    signal tb_pc_dbg    : std_logic_vector (7 downto 0);
    signal tb_instr_dbg : std_logic_vector (23 downto 0);
    signal tb_reg_a_dbg : std_logic_vector (7 downto 0);
    signal tb_z_dbg     : std_logic;
    signal tb_c_dbg     : std_logic;
    signal tb_state_dbg : state_t;
begin
    uut : entity work.cpu
    port map (
        clk       => tb_clk,
        rst       => tb_rst,
        pc_dbg    => tb_pc_dbg,
        instr_dbg => tb_instr_dbg,
        reg_a_dbg => tb_reg_a_dbg,
        z_dbg     => tb_z_dbg,
        c_dbg     => tb_c_dbg,
        state_dbg => tb_state_dbg
    );

    clk_proc : process
    begin
        tb_clk <= '0';
        wait for 5 ns;
        tb_clk <= '1';
        wait for 5 ns;
    end process clk_proc;

    stim_proc : process
        -- compares the state and all five debug outputs
        procedure check (
            name  : in string;
            st    : in state_t;
            pc    : in std_logic_vector (7 downto 0);
            ir    : in std_logic_vector (23 downto 0);
            reg_a : in std_logic_vector (7 downto 0);
            z     : in std_logic;
            c     : in std_logic
        ) is
        begin
            assert(tb_state_dbg = st)    report name & " failed: state is " & state_t'image(tb_state_dbg) severity failure;
            assert(tb_pc_dbg = pc)       report name & " failed: pc_dbg"    severity failure;
            assert(tb_instr_dbg = ir)    report name & " failed: instr_dbg" severity failure;
            assert(tb_reg_a_dbg = reg_a) report name & " failed: reg_a_dbg" severity failure;
            assert(tb_z_dbg = z)         report name & " failed: z_dbg"     severity failure;
            assert(tb_c_dbg = c)         report name & " failed: c_dbg"     severity failure;
        end procedure check;
    begin
        -- reset was applied at the first rising edge; IR holds 000000
        wait until falling_edge(tb_clk);
        tb_rst <= '0';
        check("cycle 0", S_FETCH, x"00", x"000000", x"00", '0', '0');

        -- LDI R0, 0F
        wait until falling_edge(tb_clk); check("cycle 1",  S_DECODE,    x"01", x"01000F", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 2",  S_WRITEBACK, x"01", x"01000F", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 3",  S_FETCH,     x"01", x"01000F", x"0F", '0', '0');

        -- LDI R1, 3C
        wait until falling_edge(tb_clk); check("cycle 4",  S_DECODE,    x"02", x"01103C", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 5",  S_WRITEBACK, x"02", x"01103C", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 6",  S_FETCH,     x"02", x"01103C", x"3C", '0', '0');

        -- MOV R2, R1
        wait until falling_edge(tb_clk); check("cycle 7",  S_DECODE,    x"03", x"022100", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 8",  S_WRITEBACK, x"03", x"022100", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 9",  S_FETCH,     x"03", x"022100", x"3C", '0', '0');

        -- ADD R2, R0
        wait until falling_edge(tb_clk); check("cycle 10", S_DECODE,    x"04", x"052000", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 11", S_EXECUTE,   x"04", x"052000", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 12", S_WRITEBACK, x"04", x"052000", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 13", S_FETCH,     x"04", x"052000", x"4B", '0', '0');

        -- AND R2, R1
        wait until falling_edge(tb_clk); check("cycle 14", S_DECODE,    x"05", x"072100", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 15", S_EXECUTE,   x"05", x"072100", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 16", S_WRITEBACK, x"05", x"072100", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 17", S_FETCH,     x"05", x"072100", x"08", '0', '0');

        -- OR R2, R0
        wait until falling_edge(tb_clk); check("cycle 18", S_DECODE,    x"06", x"082000", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 19", S_EXECUTE,   x"06", x"082000", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 20", S_WRITEBACK, x"06", x"082000", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 21", S_FETCH,     x"06", x"082000", x"0F", '0', '0');

        -- XOR R2, R0 (result 00, Z set in EXECUTE)
        wait until falling_edge(tb_clk); check("cycle 22", S_DECODE,    x"07", x"092000", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 23", S_EXECUTE,   x"07", x"092000", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 24", S_WRITEBACK, x"07", x"092000", x"0F", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 25", S_FETCH,     x"07", x"092000", x"00", '1', '0');

        -- JZ 09 (taken: PC jumps over address 08)
        wait until falling_edge(tb_clk); check("cycle 26", S_DECODE,    x"08", x"0D0009", x"0F", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 27", S_EXECUTE,   x"08", x"0D0009", x"0F", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 28", S_FETCH,     x"09", x"0D0009", x"0F", '1', '0');

        -- NOT R2
        wait until falling_edge(tb_clk); check("cycle 29", S_DECODE,    x"0A", x"0A2000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 30", S_EXECUTE,   x"0A", x"0A2000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 31", S_WRITEBACK, x"0A", x"0A2000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 32", S_FETCH,     x"0A", x"0A2000", x"FF", '0', '0');

        -- ST R2, 20
        wait until falling_edge(tb_clk); check("cycle 33", S_DECODE,    x"0B", x"042020", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 34", S_EXECUTE,   x"0B", x"042020", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 35", S_FETCH,     x"0B", x"042020", x"FF", '0', '0');

        -- LD R3, 20 (R3 = 00 proves address 08 never ran)
        wait until falling_edge(tb_clk); check("cycle 36", S_DECODE,    x"0C", x"033020", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 37", S_EXECUTE,   x"0C", x"033020", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 38", S_WRITEBACK, x"0C", x"033020", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 39", S_FETCH,     x"0C", x"033020", x"FF", '0', '0');

        -- SUB R0, R1 (borrow, C set in EXECUTE)
        wait until falling_edge(tb_clk); check("cycle 40", S_DECODE,    x"0D", x"060100", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 41", S_EXECUTE,   x"0D", x"060100", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 42", S_WRITEBACK, x"0D", x"060100", x"0F", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 43", S_FETCH,     x"0D", x"060100", x"D3", '0', '1');

        -- JC 0F (taken: PC jumps over address 0E)
        wait until falling_edge(tb_clk); check("cycle 44", S_DECODE,    x"0E", x"0F000F", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 45", S_EXECUTE,   x"0E", x"0F000F", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 46", S_FETCH,     x"0F", x"0F000F", x"D3", '0', '1');

        -- CMP R3, R2 (R3 = FF proves LD worked; Z set, C cleared)
        wait until falling_edge(tb_clk); check("cycle 47", S_DECODE,    x"10", x"0B3200", x"FF", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 48", S_EXECUTE,   x"10", x"0B3200", x"FF", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 49", S_FETCH,     x"10", x"0B3200", x"FF", '1', '0');

        -- JNZ 16 (not taken: falls through to 11)
        wait until falling_edge(tb_clk); check("cycle 50", S_DECODE,    x"11", x"0E0016", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 51", S_EXECUTE,   x"11", x"0E0016", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 52", S_FETCH,     x"11", x"0E0016", x"D3", '1', '0');

        -- NOP
        wait until falling_edge(tb_clk); check("cycle 53", S_DECODE,    x"12", x"000000", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 54", S_EXECUTE,   x"12", x"000000", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 55", S_FETCH,     x"12", x"000000", x"D3", '1', '0');

        -- INC R2 (FF wraps to 00: Z and C set in EXECUTE)
        wait until falling_edge(tb_clk); check("cycle 56", S_DECODE,    x"13", x"122000", x"FF", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 57", S_EXECUTE,   x"13", x"122000", x"FF", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 58", S_WRITEBACK, x"13", x"122000", x"FF", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 59", S_FETCH,     x"13", x"122000", x"00", '1', '1');

        -- DEC R1 (3C to 3B: Z and C cleared)
        wait until falling_edge(tb_clk); check("cycle 60", S_DECODE,    x"14", x"131000", x"3C", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 61", S_EXECUTE,   x"14", x"131000", x"3C", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 62", S_WRITEBACK, x"14", x"131000", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 63", S_FETCH,     x"14", x"131000", x"3B", '0', '0');

        -- SHL R0 (D3 to A6: bit 7 into C)
        wait until falling_edge(tb_clk); check("cycle 64", S_DECODE,    x"15", x"100000", x"D3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 65", S_EXECUTE,   x"15", x"100000", x"D3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 66", S_WRITEBACK, x"15", x"100000", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 67", S_FETCH,     x"15", x"100000", x"A6", '0', '1');

        -- SHR R0 (A6 to 53: bit 0 into C, C cleared)
        wait until falling_edge(tb_clk); check("cycle 68", S_DECODE,    x"16", x"110000", x"A6", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 69", S_EXECUTE,   x"16", x"110000", x"A6", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 70", S_WRITEBACK, x"16", x"110000", x"A6", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 71", S_FETCH,     x"16", x"110000", x"53", '0', '0');

        -- JMP 16 (halt loop: PC alternates 17, 17, 16)
        wait until falling_edge(tb_clk); check("cycle 72", S_DECODE,    x"17", x"0C0016", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 73", S_EXECUTE,   x"17", x"0C0016", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 74", S_FETCH,     x"16", x"0C0016", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 75", S_DECODE,    x"17", x"0C0016", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 76", S_EXECUTE,   x"17", x"0C0016", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 77", S_FETCH,     x"16", x"0C0016", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 78", S_DECODE,    x"17", x"0C0016", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 79", S_EXECUTE,   x"17", x"0C0016", x"53", '0', '0');               
            
        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;
