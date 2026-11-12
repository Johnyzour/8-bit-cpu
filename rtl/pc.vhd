library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc is
    port ( 
        clk       : in  std_logic;
        rst       : in  std_logic;
        pc_inc    : in  std_logic;
        pc_load   : in  std_logic;
        jump_addr : in  std_logic_vector (7 downto 0);
        pc_out    : out std_logic_vector (7 downto 0)              
    );
end entity pc;

architecture rtl of pc is
    signal pc_reg : unsigned (7 downto 0) := (others => '0');      
begin 
    pc_proc : process (clk)
    begin 
        if rising_edge(clk) then
            if rst = '1' then
                pc_reg <= (others => '0');
            elsif pc_load = '1' then 
                pc_reg <= unsigned(jump_addr);
            elsif pc_inc = '1' then 
                pc_reg <= pc_reg + 1;
            end if;
        end if;     
    end process pc_proc;
    
    pc_out <= std_logic_vector(pc_reg);
          
end architecture rtl;
