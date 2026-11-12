--------------------------------------------------------------------------------
-- File        : mux2.vhd
-- Description : 8-bit 2-to-1 multiplexer, gate-level.
-- Notes       : sel = 0 selects in0, sel = 1 selects in1. Combinational.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity mux2 is
    port (
        in0  : in  std_logic_vector (7 downto 0);
        in1  : in  std_logic_vector (7 downto 0);
        sel  : in  std_logic;
        y    : out std_logic_vector (7 downto 0)
    );
end entity mux2;

architecture rtl of mux2 is
    signal sel_vector : std_logic_vector (7 downto 0); 
begin
    sel_vector <= (others => sel);
    y <= (in0 and not sel_vector) or (in1 and sel_vector);
end architecture rtl;