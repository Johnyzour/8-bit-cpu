--------------------------------------------------------------------------------
-- File        : ir.vhd
-- Description : 16-bit instruction register. Holds the current instruction
--               while the multi-cycle control unit steps through its states.
-- Notes       : Loads data_in on the rising edge when ir_load = 1 (FETCH
--               state). Synchronous reset clears it to 0000 (NOP) and takes
--               priority over the load.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ir is
    port ( 
        clk      : in  std_logic;
        rst      : in  std_logic;
        ir_load  : in  std_logic; 
        data_in  : in  std_logic_vector (15 downto 0);
        data_out : out std_logic_vector (15 downto 0)
    );
end entity ir;

architecture rtl of ir is

begin
    ir_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                data_out <= x"0000";
            elsif ir_load = '1' then
                data_out <= data_in;
            end if;
        end if;        
    end process ir_proc;
end architecture rtl;
