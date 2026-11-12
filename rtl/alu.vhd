library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity alu is
    port ( 
        a       : in  std_logic_vector (7 downto 0);
        b       : in  std_logic_vector (7 downto 0);
        alu_sel : in  std_logic_vector (2 downto 0);
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
            when others  =>
                res_i <= (others => '0');
        end case;    
    end process alu_proc;                
                
    result <= res_i;
    zero <= '1' when res_i = x"00" else '0';             
end architecture rtl;
