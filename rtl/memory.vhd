--------------------------------------------------------------------------------
-- File        : memory.vhd
-- Description : 256 x 8-bit shared memory holding both the program and the
--               data (von Neumann architecture).
-- Notes       : Synchronous write when wr_en = 1. Synchronous read: data_out
--               shows the byte at addr one clock after the address is applied.
--               A write and a read of the same address on the same edge return
--               the old byte (read-first).
--               The program is loaded at elaboration from the text file
--               init_file (default program.mem): one 24-bit instruction per
--               line as 6 hex digits, stored as three bytes at 3n, 3n+1,
--               3n+2: opcode, rd/rs, imm. Blank lines and lines that start
--               with a dash (comments, --) are skipped; text after the 6
--               digits is ignored. Lines must not start with spaces. At most
--               85 instructions; a bad line or a longer program stops
--               elaboration with an error.
--               The line is read only with textio read/hread (no indexing),
--               so the same code works in simulation and in synthesis.
--               Code starts at 00; data uses F0-FF; the stack grows down from
--               EF. Unused addresses hold 00 (NOP).
--               No reset: contents survive a CPU reset.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cpu_pkg.all;

entity memory is
    generic (
        init_file : string := "program.mem"
    );
    port ( 
        clk      : in  std_logic;
        wr_en    : in  std_logic;
        addr     : in  std_logic_vector (7 downto 0);
        data_in  : in  std_logic_vector (7 downto 0);
        data_out : out std_logic_vector (7 downto 0)
    );
end entity memory;

architecture rtl of memory is
    type mem_type  is array (0 to 255) of std_logic_vector (7 downto 0);
    
    -- Converts one hex character to 4 bits; ok = false if it is not hex.
    procedure hex_digit (c  : in  character;
                         v  : out std_logic_vector (3 downto 0);
                         ok : out boolean) is
    begin
        ok := true;
        case c is
            when '0'       => v := x"0";
            when '1'       => v := x"1";
            when '2'       => v := x"2";
            when '3'       => v := x"3";
            when '4'       => v := x"4";
            when '5'       => v := x"5";
            when '6'       => v := x"6";
            when '7'       => v := x"7";
            when '8'       => v := x"8";
            when '9'       => v := x"9";
            when 'A' | 'a' => v := x"A";
            when 'B' | 'b' => v := x"B";
            when 'C' | 'c' => v := x"C";
            when 'D' | 'd' => v := x"D";
            when 'E' | 'e' => v := x"E";
            when 'F' | 'f' => v := x"F";
            when others    => v := x"0"; ok := false;
        end case;
    end procedure hex_digit;

    impure function load_mem (file_name : string) return mem_type is
        file     f       : text open read_mode is file_name;
        variable l       : line;
        variable c       : character;
        variable first   : std_logic_vector (3 downto 0);
        variable rest    : std_logic_vector (19 downto 0);
        variable word    : std_logic_vector (23 downto 0);
        variable got_c   : boolean;
        variable ok_c    : boolean;
        variable ok_rest : boolean;
        variable m       : mem_type := (others => x"00");
        variable n       : natural  := 0;
        variable line_no : natural  := 0;
    begin
        while not endfile(f) loop
            readline(f, l);
            line_no := line_no + 1;

            read(l, c, got_c);                  -- first character; false on an empty line

            if got_c and c /= '-' then          -- not blank, not a comment
                hex_digit(c, first, ok_c);      -- first hex digit
                hread(l, rest, ok_rest);        -- remaining 5 hex digits
                assert ok_c and ok_rest
                    report file_name & " line " & integer'image(line_no) & ": bad hex"
                    severity failure;
                assert n < 85
                    report file_name & " line " & integer'image(line_no) & ": program too long (max 85 instructions)"
                    severity failure;

                word := first & rest;
                m(3*n)     := word(23 downto 16);
                m(3*n + 1) := word(15 downto 8);
                m(3*n + 2) := word(7 downto 0);
                n := n + 1;
            end if;
        end loop;

        return m;
    end function load_mem;
          
    signal mem : mem_type := load_mem(init_file);
begin
    mem_proc : process (clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                mem(to_integer(unsigned(addr))) <= data_in;
            end if;              
            data_out <= mem(to_integer(unsigned(addr)));
        end if;
    end process mem_proc;
end architecture rtl;
