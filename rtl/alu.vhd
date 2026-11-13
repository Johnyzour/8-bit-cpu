--------------------------------------------------------------------------------
-- File        : alu.vhd
-- Description : 8-bit ALU. Operations: ADD, SUB, AND, OR, XOR, NOT, SHL, SHR,
--               INC, DEC (selected by the 4-bit alu_sel). Codes 1010-1111
--               output 00.
-- Notes       : Combinational. Carry: ADD/INC carry out of bit 7; SUB/DEC
--               borrow (1 when the result goes below 00); SHL the bit shifted
--               out of bit 7; SHR the bit shifted out of bit 0. Carry is 0 for
--               AND, OR, XOR and NOT. Zero is 1 when the result is 00.
--               NOT, SHL, SHR, INC and DEC use input a only.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity alu is
    port ( 
        a       : in  std_logic_vector (7 downto 0);
        b       : in  std_logic_vector (7 downto 0);
        alu_sel : in  std_logic_vector (3 downto 0);
        result  : out std_logic_vector (7 downto 0);
        zero    : out std_logic;
        carry   : out std_logic
    );
end entity alu;

architecture rtl of alu is
    signal res_i : std_logic_vector (7 downto 0);
begin
    alu_proc : process (a, b, alu_sel)
    variable wide : unsigned (8 downto 0);
    begin
        carry <= '0';
        
                case alu_sel is
            when ALU_ADD =>
                wide  := ('0' & unsigned(a)) + ('0' & unsigned(b));
                res_i <= std_logic_vector (wide(7 downto 0));
                carry <= wide(8);
            when ALU_SUB =>
                wide  := ('0' & unsigned(a)) - ('0' & unsigned(b));
                res_i <= std_logic_vector (wide(7 downto 0));
                carry <= wide(8);
            when ALU_AND =>
                res_i <= a and b;
            when ALU_OR  =>
                res_i <= a or b;
            when ALU_XOR =>
                res_i <= a xor b;
            when ALU_NOT =>
                res_i <= not a;
            when ALU_SHL =>
                res_i <= a(6 downto 0) & '0';
                carry <= a(7);
            when ALU_SHR =>
                res_i <= '0' & a(7 downto 1);
                carry <= a(0);
            when ALU_INC =>
                wide  := ('0' & unsigned(a)) + 1;
                res_i <= std_logic_vector (wide(7 downto 0));
                carry <= wide(8);
            when ALU_DEC =>
                wide  := ('0' & unsigned(a)) - 1;
                res_i <= std_logic_vector (wide(7 downto 0));
                carry <= wide(8);
            when others  =>
                res_i <= (others => '0');
        end case;                
    end process alu_proc;                
    result <= res_i;
    zero <= '1' when res_i = x"00" else '0';             
end architecture rtl;
