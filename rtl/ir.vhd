--------------------------------------------------------------------------------
-- File        : ir.vhd
-- Description : 24-bit instruction register, loaded one byte per clock from
--               the 8-bit shared memory. Holds the current instruction while
--               the multi-cycle control unit steps through its states.
-- Notes       : ir_load(2), (1), (0) load data_in into bits 23:16 (opcode),
--               15:8 (rd/rs) and 7:0 (imm) on the rising edge; bytes not
--               enabled keep their value. Synchronous reset clears it to
--               000000 (NOP) and takes priority over the loads.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ir is
    port ( 
        clk      : in  std_logic;
        rst      : in  std_logic;
        ir_load  : in  std_logic_vector (2 downto 0); 
        data_in  : in  std_logic_vector (7 downto 0);
        data_out : out std_logic_vector (23 downto 0)
    );
end entity ir;

architecture rtl of ir is

begin
    ir_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                data_out <= x"000000";
            else   
                if ir_load(2)='1' then
                    data_out(23 downto 16) <= data_in;
                end if;
                
                if ir_load(1)='1' then
                    data_out(15 downto 8)  <= data_in;
                end if;
                
                if ir_load(0)='1' then
                    data_out(7 downto 0)   <= data_in;
                end if;
            end if;      
        end if;        
    end process ir_proc;
end architecture rtl;
