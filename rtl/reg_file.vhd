--------------------------------------------------------------------------------
-- File        : reg_file.vhd
-- Description : Register file with four 8-bit registers (R0-R3), two read
--               ports and one write port.
-- Notes       : Reads are asynchronous; the write happens on the rising edge
--               when wr_en = 1. Synchronous reset clears all four registers
--               and takes priority over a write.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    port ( 
        clk       : in  std_logic;
        rst       : in  std_logic; 
        wr_en     : in  std_logic;
        wr_sel    : in  std_logic_vector (1 downto 0);
        wr_data   : in  std_logic_vector (7 downto 0);
        rd_sel_a  : in  std_logic_vector (1 downto 0);
        rd_sel_b  : in  std_logic_vector (1 downto 0);
        rd_data_a : out std_logic_vector (7 downto 0);
        rd_data_b : out std_logic_vector (7 downto 0)
    );
end entity reg_file;

architecture rtl of reg_file is
    type reg_array is array (0 to 3) of std_logic_vector (7 downto 0);
    signal regs : reg_array := (others => (others => '0'));
begin
    write_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0'));
            elsif wr_en = '1' then
                regs(to_integer(unsigned(wr_sel))) <= wr_data;
            end if;
        end if;
    end process write_proc;  
    
    rd_data_a <= regs(to_integer(unsigned(rd_sel_a)));
    rd_data_b <= regs(to_integer(unsigned(rd_sel_b)));          
end architecture rtl;
