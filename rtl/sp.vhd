--------------------------------------------------------------------------------
-- File        : sp.vhd
-- Description : 8-bit stack pointer. Points to the last byte pushed; the stack
--               grows down from F0, so the data area F0-FF is not used by it.
-- Notes       : Synchronous. sp_dec decrements (PUSH, CALL), sp_inc increments
--               (POP, RET). Priority: reset > decrement > increment > hold.
--               Synchronous reset loads F0 (SP_INIT). No overflow or
--               underflow detection: the value wraps.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity sp is
    port ( 
        clk    : in  std_logic;
        rst    : in  std_logic;
        sp_inc : in  std_logic;
        sp_dec : in  std_logic; 
        sp_out : out std_logic_vector (7 downto 0)
    );
end entity sp;

architecture rtl of sp is
    signal i_sp : unsigned (7 downto 0);
begin
    sp_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                i_sp <= unsigned(SP_INIT);
            elsif sp_dec = '1' then
                i_sp <= i_sp - 1;
            elsif sp_inc = '1' then
                i_sp <= i_sp + 1;
            end if;
        end if;
    end process sp_proc;
    
    sp_out <= std_logic_vector(i_sp);
end architecture rtl;
