--------------------------------------------------------------------------------
-- File        : tb_cpu.vhd
-- Description : System testbench for the multi-cycle von Neumann cpu. Runs the
--               program in memory (all 26 instructions, including a nested
--               subroutine call, a call inside a loop and a pointer loop using
--               LDR/STR) and checks the FSM state and debug outputs, including
--               the stack pointer, on every clock cycle against the expected
--               trace.
-- Notes       : Reset is held for the first cycle. The PC increments in each
--               FETCH state, so pc_dbg runs ahead of the instruction. The IR
--               fills one byte per state (FETCH2, FETCH3, DECODE), so it mixes
--               new and old bytes until EXECUTE. Results appear in the state
--               after the one that writes them. Prints "all tests completed
--               and passed" at 4140 ns. The expected trace must be updated if
--               the program changes.
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
    signal tb_sp_dbg    : std_logic_vector (7 downto 0);
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
        sp_dbg    => tb_sp_dbg,
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
        -- compares the state and all six debug outputs
        procedure check (
            name  : in string;
            st    : in state_t;
            pc    : in std_logic_vector (7 downto 0);
            sp    : in std_logic_vector (7 downto 0);
            ir    : in std_logic_vector (23 downto 0);
            reg_a : in std_logic_vector (7 downto 0);
            z     : in std_logic;
            c     : in std_logic
        ) is
        begin
            assert(tb_state_dbg = st)    report name & " failed: state is " & state_t'image(tb_state_dbg) severity failure;
            assert(tb_pc_dbg = pc)       report name & " failed: pc_dbg"    severity failure;
            assert(tb_sp_dbg = sp)       report name & " failed: sp_dbg"    severity failure;
            assert(tb_instr_dbg = ir)    report name & " failed: instr_dbg" severity failure;
            assert(tb_reg_a_dbg = reg_a) report name & " failed: reg_a_dbg" severity failure;
            assert(tb_z_dbg = z)         report name & " failed: z_dbg"     severity failure;
            assert(tb_c_dbg = c)         report name & " failed: c_dbg"     severity failure;
        end procedure check;
    begin
        -- reset was applied at the first rising edge; IR holds 000000, SP = F0
        -- during FETCH3 and DECODE the IR mixes new and old bytes (one byte per state)
        -- check order: state, pc, sp, ir, reg_a, z, c
        wait until falling_edge(tb_clk);
        tb_rst <= '0';
        -- LDI R0, 0F
        check("cycle 0",  S_FETCH1,    x"00", x"F0", x"000000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 1",  S_FETCH2,    x"01", x"F0", x"000000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 2",  S_FETCH3,    x"02", x"F0", x"010000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 3",  S_DECODE,    x"03", x"F0", x"010000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 4",  S_WRITEBACK, x"03", x"F0", x"01000F", x"00", '0', '0');

        -- LDI R1, 3C
        wait until falling_edge(tb_clk); check("cycle 5",  S_FETCH1,    x"03", x"F0", x"01000F", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 6",  S_FETCH2,    x"04", x"F0", x"01000F", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 7",  S_FETCH3,    x"05", x"F0", x"01000F", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 8",  S_DECODE,    x"06", x"F0", x"01100F", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 9",  S_WRITEBACK, x"06", x"F0", x"01103C", x"00", '0', '0');

        -- MOV R2, R1
        wait until falling_edge(tb_clk); check("cycle 10", S_FETCH1,    x"06", x"F0", x"01103C", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 11", S_FETCH2,    x"07", x"F0", x"01103C", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 12", S_FETCH3,    x"08", x"F0", x"02103C", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 13", S_DECODE,    x"09", x"F0", x"02213C", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 14", S_WRITEBACK, x"09", x"F0", x"022100", x"00", '0', '0');

        -- ADD R2, R0
        wait until falling_edge(tb_clk); check("cycle 15", S_FETCH1,    x"09", x"F0", x"022100", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 16", S_FETCH2,    x"0A", x"F0", x"022100", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 17", S_FETCH3,    x"0B", x"F0", x"052100", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 18", S_DECODE,    x"0C", x"F0", x"052000", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 19", S_EXECUTE,   x"0C", x"F0", x"052000", x"3C", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 20", S_WRITEBACK, x"0C", x"F0", x"052000", x"3C", '0', '0');

        -- AND R2, R1
        wait until falling_edge(tb_clk); check("cycle 21", S_FETCH1,    x"0C", x"F0", x"052000", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 22", S_FETCH2,    x"0D", x"F0", x"052000", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 23", S_FETCH3,    x"0E", x"F0", x"072000", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 24", S_DECODE,    x"0F", x"F0", x"072100", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 25", S_EXECUTE,   x"0F", x"F0", x"072100", x"4B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 26", S_WRITEBACK, x"0F", x"F0", x"072100", x"4B", '0', '0');

        -- OR R2, R0
        wait until falling_edge(tb_clk); check("cycle 27", S_FETCH1,    x"0F", x"F0", x"072100", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 28", S_FETCH2,    x"10", x"F0", x"072100", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 29", S_FETCH3,    x"11", x"F0", x"082100", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 30", S_DECODE,    x"12", x"F0", x"082000", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 31", S_EXECUTE,   x"12", x"F0", x"082000", x"08", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 32", S_WRITEBACK, x"12", x"F0", x"082000", x"08", '0', '0');

        -- XOR R2, R0 (result 00, Z set in EXECUTE)
        wait until falling_edge(tb_clk); check("cycle 33", S_FETCH1,    x"12", x"F0", x"082000", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 34", S_FETCH2,    x"13", x"F0", x"082000", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 35", S_FETCH3,    x"14", x"F0", x"092000", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 36", S_DECODE,    x"15", x"F0", x"092000", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 37", S_EXECUTE,   x"15", x"F0", x"092000", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 38", S_WRITEBACK, x"15", x"F0", x"092000", x"0F", '1', '0');

        -- JZ 1B (taken: PC jumps over address 18)
        wait until falling_edge(tb_clk); check("cycle 39", S_FETCH1,    x"15", x"F0", x"092000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 40", S_FETCH2,    x"16", x"F0", x"092000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 41", S_FETCH3,    x"17", x"F0", x"0D2000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 42", S_DECODE,    x"18", x"F0", x"0D0000", x"0F", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 43", S_EXECUTE,   x"18", x"F0", x"0D001B", x"0F", '1', '0');

        -- NOT R2
        wait until falling_edge(tb_clk); check("cycle 44", S_FETCH1,    x"1B", x"F0", x"0D001B", x"0F", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 45", S_FETCH2,    x"1C", x"F0", x"0D001B", x"0F", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 46", S_FETCH3,    x"1D", x"F0", x"0A001B", x"0F", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 47", S_DECODE,    x"1E", x"F0", x"0A201B", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 48", S_EXECUTE,   x"1E", x"F0", x"0A2000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 49", S_WRITEBACK, x"1E", x"F0", x"0A2000", x"00", '0', '0');

        -- ST R2, F0 (write to the data area)
        wait until falling_edge(tb_clk); check("cycle 50", S_FETCH1,    x"1E", x"F0", x"0A2000", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 51", S_FETCH2,    x"1F", x"F0", x"0A2000", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 52", S_FETCH3,    x"20", x"F0", x"042000", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 53", S_DECODE,    x"21", x"F0", x"042000", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 54", S_EXECUTE,   x"21", x"F0", x"0420F0", x"FF", '0', '0');

        -- LD R3, F0 (R3 = 00 proves address 18 never ran)
        wait until falling_edge(tb_clk); check("cycle 55", S_FETCH1,    x"21", x"F0", x"0420F0", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 56", S_FETCH2,    x"22", x"F0", x"0420F0", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 57", S_FETCH3,    x"23", x"F0", x"0320F0", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 58", S_DECODE,    x"24", x"F0", x"0330F0", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 59", S_EXECUTE,   x"24", x"F0", x"0330F0", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 60", S_WRITEBACK, x"24", x"F0", x"0330F0", x"00", '0', '0');

        -- SUB R0, R1 (borrow, C set in EXECUTE)
        wait until falling_edge(tb_clk); check("cycle 61", S_FETCH1,    x"24", x"F0", x"0330F0", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 62", S_FETCH2,    x"25", x"F0", x"0330F0", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 63", S_FETCH3,    x"26", x"F0", x"0630F0", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 64", S_DECODE,    x"27", x"F0", x"0601F0", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 65", S_EXECUTE,   x"27", x"F0", x"060100", x"0F", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 66", S_WRITEBACK, x"27", x"F0", x"060100", x"0F", '0', '1');

        -- JC 2D (taken: PC jumps over address 2A)
        wait until falling_edge(tb_clk); check("cycle 67", S_FETCH1,    x"27", x"F0", x"060100", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 68", S_FETCH2,    x"28", x"F0", x"060100", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 69", S_FETCH3,    x"29", x"F0", x"0F0100", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 70", S_DECODE,    x"2A", x"F0", x"0F0000", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 71", S_EXECUTE,   x"2A", x"F0", x"0F002D", x"D3", '0', '1');

        -- CMP R3, R2 (R3 = FF proves LD worked; Z set, C cleared)
        wait until falling_edge(tb_clk); check("cycle 72", S_FETCH1,    x"2D", x"F0", x"0F002D", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 73", S_FETCH2,    x"2E", x"F0", x"0F002D", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 74", S_FETCH3,    x"2F", x"F0", x"0B002D", x"D3", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 75", S_DECODE,    x"30", x"F0", x"0B322D", x"FF", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 76", S_EXECUTE,   x"30", x"F0", x"0B3200", x"FF", '0', '1');

        -- JNZ 99 (not taken: falls through to 33)
        wait until falling_edge(tb_clk); check("cycle 77", S_FETCH1,    x"30", x"F0", x"0B3200", x"FF", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 78", S_FETCH2,    x"31", x"F0", x"0B3200", x"FF", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 79", S_FETCH3,    x"32", x"F0", x"0E3200", x"FF", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 80", S_DECODE,    x"33", x"F0", x"0E0000", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 81", S_EXECUTE,   x"33", x"F0", x"0E0099", x"D3", '1', '0');

        -- NOP
        wait until falling_edge(tb_clk); check("cycle 82", S_FETCH1,    x"33", x"F0", x"0E0099", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 83", S_FETCH2,    x"34", x"F0", x"0E0099", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 84", S_FETCH3,    x"35", x"F0", x"000099", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 85", S_DECODE,    x"36", x"F0", x"000099", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 86", S_EXECUTE,   x"36", x"F0", x"000000", x"D3", '1', '0');

        -- INC R2 (FF wraps to 00: Z and C set in EXECUTE)
        wait until falling_edge(tb_clk); check("cycle 87", S_FETCH1,    x"36", x"F0", x"000000", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 88", S_FETCH2,    x"37", x"F0", x"000000", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 89", S_FETCH3,    x"38", x"F0", x"120000", x"D3", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 90", S_DECODE,    x"39", x"F0", x"122000", x"FF", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 91", S_EXECUTE,   x"39", x"F0", x"122000", x"FF", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 92", S_WRITEBACK, x"39", x"F0", x"122000", x"FF", '1', '1');

        -- DEC R1 (3C to 3B: Z and C cleared)
        wait until falling_edge(tb_clk); check("cycle 93", S_FETCH1,    x"39", x"F0", x"122000", x"00", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 94", S_FETCH2,    x"3A", x"F0", x"122000", x"00", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 95", S_FETCH3,    x"3B", x"F0", x"132000", x"00", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 96", S_DECODE,    x"3C", x"F0", x"131000", x"3C", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 97", S_EXECUTE,   x"3C", x"F0", x"131000", x"3C", '1', '1');
        wait until falling_edge(tb_clk); check("cycle 98", S_WRITEBACK, x"3C", x"F0", x"131000", x"3C", '0', '0');

        -- SHL R0 (D3 to A6: bit 7 into C)
        wait until falling_edge(tb_clk); check("cycle 99", S_FETCH1,    x"3C", x"F0", x"131000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 100", S_FETCH2,    x"3D", x"F0", x"131000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 101", S_FETCH3,    x"3E", x"F0", x"101000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 102", S_DECODE,    x"3F", x"F0", x"100000", x"D3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 103", S_EXECUTE,   x"3F", x"F0", x"100000", x"D3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 104", S_WRITEBACK, x"3F", x"F0", x"100000", x"D3", '0', '1');

        -- SHR R0 (A6 to 53: bit 0 into C, C cleared)
        wait until falling_edge(tb_clk); check("cycle 105", S_FETCH1,    x"3F", x"F0", x"100000", x"A6", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 106", S_FETCH2,    x"40", x"F0", x"100000", x"A6", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 107", S_FETCH3,    x"41", x"F0", x"110000", x"A6", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 108", S_DECODE,    x"42", x"F0", x"110000", x"A6", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 109", S_EXECUTE,   x"42", x"F0", x"110000", x"A6", '0', '1');
        wait until falling_edge(tb_clk); check("cycle 110", S_WRITEBACK, x"42", x"F0", x"110000", x"A6", '0', '0');

        -- CALL 5A (SP-1 in DECODE, return address 45 written to EF, PC = 5A)
        wait until falling_edge(tb_clk); check("cycle 111", S_FETCH1,    x"42", x"F0", x"110000", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 112", S_FETCH2,    x"43", x"F0", x"110000", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 113", S_FETCH3,    x"44", x"F0", x"160000", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 114", S_DECODE,    x"45", x"F0", x"160000", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 115", S_EXECUTE,   x"45", x"EF", x"16005A", x"53", '0', '0');

        -- sub1: PUSH R1 (SP = EE, MEM[EE] = 3B)
        wait until falling_edge(tb_clk); check("cycle 116", S_FETCH1,    x"5A", x"EF", x"16005A", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 117", S_FETCH2,    x"5B", x"EF", x"16005A", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 118", S_FETCH3,    x"5C", x"EF", x"14005A", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 119", S_DECODE,    x"5D", x"EF", x"14105A", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 120", S_EXECUTE,   x"5D", x"EE", x"141000", x"3B", '0', '0');

        -- sub1: LDI R1, 77 (clobber the saved register)
        wait until falling_edge(tb_clk); check("cycle 121", S_FETCH1,    x"5D", x"EE", x"141000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 122", S_FETCH2,    x"5E", x"EE", x"141000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 123", S_FETCH3,    x"5F", x"EE", x"011000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 124", S_DECODE,    x"60", x"EE", x"011000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 125", S_WRITEBACK, x"60", x"EE", x"011077", x"3B", '0', '0');

        -- sub1: CALL 69 (nested: return address 63 written to ED, SP = ED)
        wait until falling_edge(tb_clk); check("cycle 126", S_FETCH1,    x"60", x"EE", x"011077", x"77", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 127", S_FETCH2,    x"61", x"EE", x"011077", x"77", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 128", S_FETCH3,    x"62", x"EE", x"161077", x"77", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 129", S_DECODE,    x"63", x"EE", x"160077", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 130", S_EXECUTE,   x"63", x"ED", x"160069", x"53", '0', '0');

        -- sub2: INC R0
        wait until falling_edge(tb_clk); check("cycle 131", S_FETCH1,    x"69", x"ED", x"160069", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 132", S_FETCH2,    x"6A", x"ED", x"160069", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 133", S_FETCH3,    x"6B", x"ED", x"120069", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 134", S_DECODE,    x"6C", x"ED", x"120069", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 135", S_EXECUTE,   x"6C", x"ED", x"120000", x"53", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 136", S_WRITEBACK, x"6C", x"ED", x"120000", x"53", '0', '0');

        -- sub2: RET (PC from memory, SP + 1)
        wait until falling_edge(tb_clk); check("cycle 137", S_FETCH1,    x"6C", x"ED", x"120000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 138", S_FETCH2,    x"6D", x"ED", x"120000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 139", S_FETCH3,    x"6E", x"ED", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 140", S_DECODE,    x"6F", x"ED", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 141", S_EXECUTE,   x"6F", x"ED", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 142", S_WRITEBACK, x"6F", x"EE", x"170000", x"54", '0', '0');

        -- sub1: POP R1 (R1 = 3B restored, SP = EF)
        wait until falling_edge(tb_clk); check("cycle 143", S_FETCH1,    x"63", x"EE", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 144", S_FETCH2,    x"64", x"EE", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 145", S_FETCH3,    x"65", x"EE", x"150000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 146", S_DECODE,    x"66", x"EE", x"151000", x"77", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 147", S_EXECUTE,   x"66", x"EE", x"151000", x"77", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 148", S_WRITEBACK, x"66", x"EF", x"151000", x"77", '0', '0');

        -- sub1: RET (back to 45, SP = F0)
        wait until falling_edge(tb_clk); check("cycle 149", S_FETCH1,    x"66", x"EF", x"151000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 150", S_FETCH2,    x"67", x"EF", x"151000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 151", S_FETCH3,    x"68", x"EF", x"171000", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 152", S_DECODE,    x"69", x"EF", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 153", S_EXECUTE,   x"69", x"EF", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 154", S_WRITEBACK, x"69", x"F0", x"170000", x"54", '0', '0');

        -- PUSH R0 (SP = EF, MEM[EF] = 54)
        wait until falling_edge(tb_clk); check("cycle 155", S_FETCH1,    x"45", x"F0", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 156", S_FETCH2,    x"46", x"F0", x"170000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 157", S_FETCH3,    x"47", x"F0", x"140000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 158", S_DECODE,    x"48", x"F0", x"140000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 159", S_EXECUTE,   x"48", x"EF", x"140000", x"54", '0', '0');

        -- POP R2 (R2 = 54, SP = F0)
        wait until falling_edge(tb_clk); check("cycle 160", S_FETCH1,    x"48", x"EF", x"140000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 161", S_FETCH2,    x"49", x"EF", x"140000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 162", S_FETCH3,    x"4A", x"EF", x"150000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 163", S_DECODE,    x"4B", x"EF", x"152000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 164", S_EXECUTE,   x"4B", x"EF", x"152000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 165", S_WRITEBACK, x"4B", x"F0", x"152000", x"00", '0', '0');

        -- LDI R3, 03 (loop counter)
        wait until falling_edge(tb_clk); check("cycle 166", S_FETCH1,    x"4B", x"F0", x"152000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 167", S_FETCH2,    x"4C", x"F0", x"152000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 168", S_FETCH3,    x"4D", x"F0", x"012000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 169", S_DECODE,    x"4E", x"F0", x"013000", x"FF", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 170", S_WRITEBACK, x"4E", x"F0", x"013003", x"FF", '0', '0');

        -- CALL 69 (loop: return address 51 written to EF)
        wait until falling_edge(tb_clk); check("cycle 171", S_FETCH1,    x"4E", x"F0", x"013003", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 172", S_FETCH2,    x"4F", x"F0", x"013003", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 173", S_FETCH3,    x"50", x"F0", x"163003", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 174", S_DECODE,    x"51", x"F0", x"160003", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 175", S_EXECUTE,   x"51", x"EF", x"160069", x"54", '0', '0');

        -- sub2: INC R0
        wait until falling_edge(tb_clk); check("cycle 176", S_FETCH1,    x"69", x"EF", x"160069", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 177", S_FETCH2,    x"6A", x"EF", x"160069", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 178", S_FETCH3,    x"6B", x"EF", x"120069", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 179", S_DECODE,    x"6C", x"EF", x"120069", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 180", S_EXECUTE,   x"6C", x"EF", x"120000", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 181", S_WRITEBACK, x"6C", x"EF", x"120000", x"54", '0', '0');

        -- sub2: RET (PC from memory, SP + 1)
        wait until falling_edge(tb_clk); check("cycle 182", S_FETCH1,    x"6C", x"EF", x"120000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 183", S_FETCH2,    x"6D", x"EF", x"120000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 184", S_FETCH3,    x"6E", x"EF", x"170000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 185", S_DECODE,    x"6F", x"EF", x"170000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 186", S_EXECUTE,   x"6F", x"EF", x"170000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 187", S_WRITEBACK, x"6F", x"F0", x"170000", x"55", '0', '0');

        -- DEC R3
        wait until falling_edge(tb_clk); check("cycle 188", S_FETCH1,    x"51", x"F0", x"170000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 189", S_FETCH2,    x"52", x"F0", x"170000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 190", S_FETCH3,    x"53", x"F0", x"130000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 191", S_DECODE,    x"54", x"F0", x"133000", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 192", S_EXECUTE,   x"54", x"F0", x"133000", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 193", S_WRITEBACK, x"54", x"F0", x"133000", x"03", '0', '0');

        -- JNZ 4E
        wait until falling_edge(tb_clk); check("cycle 194", S_FETCH1,    x"54", x"F0", x"133000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 195", S_FETCH2,    x"55", x"F0", x"133000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 196", S_FETCH3,    x"56", x"F0", x"0E3000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 197", S_DECODE,    x"57", x"F0", x"0E0000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 198", S_EXECUTE,   x"57", x"F0", x"0E004E", x"55", '0', '0');

        -- CALL 69 (loop: return address 51 written to EF)
        wait until falling_edge(tb_clk); check("cycle 199", S_FETCH1,    x"4E", x"F0", x"0E004E", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 200", S_FETCH2,    x"4F", x"F0", x"0E004E", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 201", S_FETCH3,    x"50", x"F0", x"16004E", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 202", S_DECODE,    x"51", x"F0", x"16004E", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 203", S_EXECUTE,   x"51", x"EF", x"160069", x"55", '0', '0');

        -- sub2: INC R0
        wait until falling_edge(tb_clk); check("cycle 204", S_FETCH1,    x"69", x"EF", x"160069", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 205", S_FETCH2,    x"6A", x"EF", x"160069", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 206", S_FETCH3,    x"6B", x"EF", x"120069", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 207", S_DECODE,    x"6C", x"EF", x"120069", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 208", S_EXECUTE,   x"6C", x"EF", x"120000", x"55", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 209", S_WRITEBACK, x"6C", x"EF", x"120000", x"55", '0', '0');

        -- sub2: RET (PC from memory, SP + 1)
        wait until falling_edge(tb_clk); check("cycle 210", S_FETCH1,    x"6C", x"EF", x"120000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 211", S_FETCH2,    x"6D", x"EF", x"120000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 212", S_FETCH3,    x"6E", x"EF", x"170000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 213", S_DECODE,    x"6F", x"EF", x"170000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 214", S_EXECUTE,   x"6F", x"EF", x"170000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 215", S_WRITEBACK, x"6F", x"F0", x"170000", x"56", '0', '0');

        -- DEC R3
        wait until falling_edge(tb_clk); check("cycle 216", S_FETCH1,    x"51", x"F0", x"170000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 217", S_FETCH2,    x"52", x"F0", x"170000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 218", S_FETCH3,    x"53", x"F0", x"130000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 219", S_DECODE,    x"54", x"F0", x"133000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 220", S_EXECUTE,   x"54", x"F0", x"133000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 221", S_WRITEBACK, x"54", x"F0", x"133000", x"02", '0', '0');

        -- JNZ 4E
        wait until falling_edge(tb_clk); check("cycle 222", S_FETCH1,    x"54", x"F0", x"133000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 223", S_FETCH2,    x"55", x"F0", x"133000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 224", S_FETCH3,    x"56", x"F0", x"0E3000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 225", S_DECODE,    x"57", x"F0", x"0E0000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 226", S_EXECUTE,   x"57", x"F0", x"0E004E", x"56", '0', '0');

        -- CALL 69 (loop: return address 51 written to EF)
        wait until falling_edge(tb_clk); check("cycle 227", S_FETCH1,    x"4E", x"F0", x"0E004E", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 228", S_FETCH2,    x"4F", x"F0", x"0E004E", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 229", S_FETCH3,    x"50", x"F0", x"16004E", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 230", S_DECODE,    x"51", x"F0", x"16004E", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 231", S_EXECUTE,   x"51", x"EF", x"160069", x"56", '0', '0');

        -- sub2: INC R0
        wait until falling_edge(tb_clk); check("cycle 232", S_FETCH1,    x"69", x"EF", x"160069", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 233", S_FETCH2,    x"6A", x"EF", x"160069", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 234", S_FETCH3,    x"6B", x"EF", x"120069", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 235", S_DECODE,    x"6C", x"EF", x"120069", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 236", S_EXECUTE,   x"6C", x"EF", x"120000", x"56", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 237", S_WRITEBACK, x"6C", x"EF", x"120000", x"56", '0', '0');

        -- sub2: RET (PC from memory, SP + 1)
        wait until falling_edge(tb_clk); check("cycle 238", S_FETCH1,    x"6C", x"EF", x"120000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 239", S_FETCH2,    x"6D", x"EF", x"120000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 240", S_FETCH3,    x"6E", x"EF", x"170000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 241", S_DECODE,    x"6F", x"EF", x"170000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 242", S_EXECUTE,   x"6F", x"EF", x"170000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 243", S_WRITEBACK, x"6F", x"F0", x"170000", x"57", '0', '0');

        -- DEC R3
        wait until falling_edge(tb_clk); check("cycle 244", S_FETCH1,    x"51", x"F0", x"170000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 245", S_FETCH2,    x"52", x"F0", x"170000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 246", S_FETCH3,    x"53", x"F0", x"130000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 247", S_DECODE,    x"54", x"F0", x"133000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 248", S_EXECUTE,   x"54", x"F0", x"133000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 249", S_WRITEBACK, x"54", x"F0", x"133000", x"01", '1', '0');

        -- JNZ 4E
        wait until falling_edge(tb_clk); check("cycle 250", S_FETCH1,    x"54", x"F0", x"133000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 251", S_FETCH2,    x"55", x"F0", x"133000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 252", S_FETCH3,    x"56", x"F0", x"0E3000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 253", S_DECODE,    x"57", x"F0", x"0E0000", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 254", S_EXECUTE,   x"57", x"F0", x"0E004E", x"57", '1', '0');

        -- JMP 6F (on to the register-indirect section)
        wait until falling_edge(tb_clk); check("cycle 255", S_FETCH1,    x"57", x"F0", x"0E004E", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 256", S_FETCH2,    x"58", x"F0", x"0E004E", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 257", S_FETCH3,    x"59", x"F0", x"0C004E", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 258", S_DECODE,    x"5A", x"F0", x"0C004E", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 259", S_EXECUTE,   x"5A", x"F0", x"0C006F", x"57", '1', '0');

        -- LDI R3, F1 (pointer)
        wait until falling_edge(tb_clk); check("cycle 260", S_FETCH1,    x"6F", x"F0", x"0C006F", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 261", S_FETCH2,    x"70", x"F0", x"0C006F", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 262", S_FETCH3,    x"71", x"F0", x"01006F", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 263", S_DECODE,    x"72", x"F0", x"01306F", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 264", S_WRITEBACK, x"72", x"F0", x"0130F1", x"00", '1', '0');

        -- STR R0, [R3] (MEM[F1] = 57)
        wait until falling_edge(tb_clk); check("cycle 265", S_FETCH1,    x"72", x"F0", x"0130F1", x"F1", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 266", S_FETCH2,    x"73", x"F0", x"0130F1", x"F1", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 267", S_FETCH3,    x"74", x"F0", x"1930F1", x"F1", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 268", S_DECODE,    x"75", x"F0", x"1903F1", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 269", S_EXECUTE,   x"75", x"F0", x"190300", x"57", '1', '0');

        -- INC R3 (pointer = F2)
        wait until falling_edge(tb_clk); check("cycle 270", S_FETCH1,    x"75", x"F0", x"190300", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 271", S_FETCH2,    x"76", x"F0", x"190300", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 272", S_FETCH3,    x"77", x"F0", x"120300", x"57", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 273", S_DECODE,    x"78", x"F0", x"123000", x"F1", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 274", S_EXECUTE,   x"78", x"F0", x"123000", x"F1", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 275", S_WRITEBACK, x"78", x"F0", x"123000", x"F1", '0', '0');

        -- STR R1, [R3] (MEM[F2] = 3B)
        wait until falling_edge(tb_clk); check("cycle 276", S_FETCH1,    x"78", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 277", S_FETCH2,    x"79", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 278", S_FETCH3,    x"7A", x"F0", x"193000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 279", S_DECODE,    x"7B", x"F0", x"191300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 280", S_EXECUTE,   x"7B", x"F0", x"191300", x"3B", '0', '0');

        -- INC R3 (pointer = F3)
        wait until falling_edge(tb_clk); check("cycle 281", S_FETCH1,    x"7B", x"F0", x"191300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 282", S_FETCH2,    x"7C", x"F0", x"191300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 283", S_FETCH3,    x"7D", x"F0", x"121300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 284", S_DECODE,    x"7E", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 285", S_EXECUTE,   x"7E", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 286", S_WRITEBACK, x"7E", x"F0", x"123000", x"F2", '0', '0');

        -- STR R2, [R3] (MEM[F3] = 54)
        wait until falling_edge(tb_clk); check("cycle 287", S_FETCH1,    x"7E", x"F0", x"123000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 288", S_FETCH2,    x"7F", x"F0", x"123000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 289", S_FETCH3,    x"80", x"F0", x"193000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 290", S_DECODE,    x"81", x"F0", x"192300", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 291", S_EXECUTE,   x"81", x"F0", x"192300", x"54", '0', '0');

        -- LDI R0, 00 (sum)
        wait until falling_edge(tb_clk); check("cycle 292", S_FETCH1,    x"81", x"F0", x"192300", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 293", S_FETCH2,    x"82", x"F0", x"192300", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 294", S_FETCH3,    x"83", x"F0", x"012300", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 295", S_DECODE,    x"84", x"F0", x"010000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 296", S_WRITEBACK, x"84", x"F0", x"010000", x"57", '0', '0');

        -- LDI R3, F1 (pointer back to F1)
        wait until falling_edge(tb_clk); check("cycle 297", S_FETCH1,    x"84", x"F0", x"010000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 298", S_FETCH2,    x"85", x"F0", x"010000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 299", S_FETCH3,    x"86", x"F0", x"010000", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 300", S_DECODE,    x"87", x"F0", x"013000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 301", S_WRITEBACK, x"87", x"F0", x"0130F1", x"F3", '0', '0');

        -- LDI R2, 03 (counter)
        wait until falling_edge(tb_clk); check("cycle 302", S_FETCH1,    x"87", x"F0", x"0130F1", x"F1", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 303", S_FETCH2,    x"88", x"F0", x"0130F1", x"F1", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 304", S_FETCH3,    x"89", x"F0", x"0130F1", x"F1", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 305", S_DECODE,    x"8A", x"F0", x"0120F1", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 306", S_WRITEBACK, x"8A", x"F0", x"012003", x"54", '0', '0');

        -- loop: LDR R1, [R3] (R1 = MEM[pointer])
        wait until falling_edge(tb_clk); check("cycle 307", S_FETCH1,    x"8A", x"F0", x"012003", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 308", S_FETCH2,    x"8B", x"F0", x"012003", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 309", S_FETCH3,    x"8C", x"F0", x"182003", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 310", S_DECODE,    x"8D", x"F0", x"181303", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 311", S_EXECUTE,   x"8D", x"F0", x"181300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 312", S_WRITEBACK, x"8D", x"F0", x"181300", x"3B", '0', '0');

        -- ADD R0, R1 (sum)
        wait until falling_edge(tb_clk); check("cycle 313", S_FETCH1,    x"8D", x"F0", x"181300", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 314", S_FETCH2,    x"8E", x"F0", x"181300", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 315", S_FETCH3,    x"8F", x"F0", x"051300", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 316", S_DECODE,    x"90", x"F0", x"050100", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 317", S_EXECUTE,   x"90", x"F0", x"050100", x"00", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 318", S_WRITEBACK, x"90", x"F0", x"050100", x"00", '0', '0');

        -- INC R3 (next byte)
        wait until falling_edge(tb_clk); check("cycle 319", S_FETCH1,    x"90", x"F0", x"050100", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 320", S_FETCH2,    x"91", x"F0", x"050100", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 321", S_FETCH3,    x"92", x"F0", x"120100", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 322", S_DECODE,    x"93", x"F0", x"123000", x"F1", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 323", S_EXECUTE,   x"93", x"F0", x"123000", x"F1", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 324", S_WRITEBACK, x"93", x"F0", x"123000", x"F1", '0', '0');

        -- DEC R2
        wait until falling_edge(tb_clk); check("cycle 325", S_FETCH1,    x"93", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 326", S_FETCH2,    x"94", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 327", S_FETCH3,    x"95", x"F0", x"133000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 328", S_DECODE,    x"96", x"F0", x"132000", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 329", S_EXECUTE,   x"96", x"F0", x"132000", x"03", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 330", S_WRITEBACK, x"96", x"F0", x"132000", x"03", '0', '0');

        -- JNZ 8A
        wait until falling_edge(tb_clk); check("cycle 331", S_FETCH1,    x"96", x"F0", x"132000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 332", S_FETCH2,    x"97", x"F0", x"132000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 333", S_FETCH3,    x"98", x"F0", x"0E2000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 334", S_DECODE,    x"99", x"F0", x"0E0000", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 335", S_EXECUTE,   x"99", x"F0", x"0E008A", x"57", '0', '0');

        -- loop: LDR R1, [R3] (R1 = MEM[pointer])
        wait until falling_edge(tb_clk); check("cycle 336", S_FETCH1,    x"8A", x"F0", x"0E008A", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 337", S_FETCH2,    x"8B", x"F0", x"0E008A", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 338", S_FETCH3,    x"8C", x"F0", x"18008A", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 339", S_DECODE,    x"8D", x"F0", x"18138A", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 340", S_EXECUTE,   x"8D", x"F0", x"181300", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 341", S_WRITEBACK, x"8D", x"F0", x"181300", x"57", '0', '0');

        -- ADD R0, R1 (sum)
        wait until falling_edge(tb_clk); check("cycle 342", S_FETCH1,    x"8D", x"F0", x"181300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 343", S_FETCH2,    x"8E", x"F0", x"181300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 344", S_FETCH3,    x"8F", x"F0", x"051300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 345", S_DECODE,    x"90", x"F0", x"050100", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 346", S_EXECUTE,   x"90", x"F0", x"050100", x"57", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 347", S_WRITEBACK, x"90", x"F0", x"050100", x"57", '0', '0');

        -- INC R3 (next byte)
        wait until falling_edge(tb_clk); check("cycle 348", S_FETCH1,    x"90", x"F0", x"050100", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 349", S_FETCH2,    x"91", x"F0", x"050100", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 350", S_FETCH3,    x"92", x"F0", x"120100", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 351", S_DECODE,    x"93", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 352", S_EXECUTE,   x"93", x"F0", x"123000", x"F2", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 353", S_WRITEBACK, x"93", x"F0", x"123000", x"F2", '0', '0');

        -- DEC R2
        wait until falling_edge(tb_clk); check("cycle 354", S_FETCH1,    x"93", x"F0", x"123000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 355", S_FETCH2,    x"94", x"F0", x"123000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 356", S_FETCH3,    x"95", x"F0", x"133000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 357", S_DECODE,    x"96", x"F0", x"132000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 358", S_EXECUTE,   x"96", x"F0", x"132000", x"02", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 359", S_WRITEBACK, x"96", x"F0", x"132000", x"02", '0', '0');

        -- JNZ 8A
        wait until falling_edge(tb_clk); check("cycle 360", S_FETCH1,    x"96", x"F0", x"132000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 361", S_FETCH2,    x"97", x"F0", x"132000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 362", S_FETCH3,    x"98", x"F0", x"0E2000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 363", S_DECODE,    x"99", x"F0", x"0E0000", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 364", S_EXECUTE,   x"99", x"F0", x"0E008A", x"92", '0', '0');

        -- loop: LDR R1, [R3] (R1 = MEM[pointer])
        wait until falling_edge(tb_clk); check("cycle 365", S_FETCH1,    x"8A", x"F0", x"0E008A", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 366", S_FETCH2,    x"8B", x"F0", x"0E008A", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 367", S_FETCH3,    x"8C", x"F0", x"18008A", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 368", S_DECODE,    x"8D", x"F0", x"18138A", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 369", S_EXECUTE,   x"8D", x"F0", x"181300", x"3B", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 370", S_WRITEBACK, x"8D", x"F0", x"181300", x"3B", '0', '0');

        -- ADD R0, R1 (sum)
        wait until falling_edge(tb_clk); check("cycle 371", S_FETCH1,    x"8D", x"F0", x"181300", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 372", S_FETCH2,    x"8E", x"F0", x"181300", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 373", S_FETCH3,    x"8F", x"F0", x"051300", x"54", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 374", S_DECODE,    x"90", x"F0", x"050100", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 375", S_EXECUTE,   x"90", x"F0", x"050100", x"92", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 376", S_WRITEBACK, x"90", x"F0", x"050100", x"92", '0', '0');

        -- INC R3 (next byte)
        wait until falling_edge(tb_clk); check("cycle 377", S_FETCH1,    x"90", x"F0", x"050100", x"E6", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 378", S_FETCH2,    x"91", x"F0", x"050100", x"E6", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 379", S_FETCH3,    x"92", x"F0", x"120100", x"E6", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 380", S_DECODE,    x"93", x"F0", x"123000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 381", S_EXECUTE,   x"93", x"F0", x"123000", x"F3", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 382", S_WRITEBACK, x"93", x"F0", x"123000", x"F3", '0', '0');

        -- DEC R2
        wait until falling_edge(tb_clk); check("cycle 383", S_FETCH1,    x"93", x"F0", x"123000", x"F4", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 384", S_FETCH2,    x"94", x"F0", x"123000", x"F4", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 385", S_FETCH3,    x"95", x"F0", x"133000", x"F4", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 386", S_DECODE,    x"96", x"F0", x"132000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 387", S_EXECUTE,   x"96", x"F0", x"132000", x"01", '0', '0');
        wait until falling_edge(tb_clk); check("cycle 388", S_WRITEBACK, x"96", x"F0", x"132000", x"01", '1', '0');

        -- JNZ 8A
        wait until falling_edge(tb_clk); check("cycle 389", S_FETCH1,    x"96", x"F0", x"132000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 390", S_FETCH2,    x"97", x"F0", x"132000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 391", S_FETCH3,    x"98", x"F0", x"0E2000", x"00", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 392", S_DECODE,    x"99", x"F0", x"0E0000", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 393", S_EXECUTE,   x"99", x"F0", x"0E008A", x"E6", '1', '0');

        -- JMP 99 (halt loop: R0 = E6 = 57 + 3B + 54)
        wait until falling_edge(tb_clk); check("cycle 394", S_FETCH1,    x"99", x"F0", x"0E008A", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 395", S_FETCH2,    x"9A", x"F0", x"0E008A", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 396", S_FETCH3,    x"9B", x"F0", x"0C008A", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 397", S_DECODE,    x"9C", x"F0", x"0C008A", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 398", S_EXECUTE,   x"9C", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 399", S_FETCH1,    x"99", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 400", S_FETCH2,    x"9A", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 401", S_FETCH3,    x"9B", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 402", S_DECODE,    x"9C", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 403", S_EXECUTE,   x"9C", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 404", S_FETCH1,    x"99", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 405", S_FETCH2,    x"9A", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 406", S_FETCH3,    x"9B", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 407", S_DECODE,    x"9C", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 408", S_EXECUTE,   x"9C", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 409", S_FETCH1,    x"99", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 410", S_FETCH2,    x"9A", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 411", S_FETCH3,    x"9B", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 412", S_DECODE,    x"9C", x"F0", x"0C0099", x"E6", '1', '0');
        wait until falling_edge(tb_clk); check("cycle 413", S_EXECUTE,   x"9C", x"F0", x"0C0099", x"E6", '1', '0');

        report "all tests completed and passed" severity note;
        wait;
    end process stim_proc;
end architecture sim;