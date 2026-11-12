library ieee;
use ieee.std_logic_1164.all;

entity flags_reg is
    port ( 
        clk    : in  std_logic;
        rst    : in  std_logic;
        z_load : in  std_logic;
        c_load : in  std_logic;
        z_in   : in  std_logic;
        c_in   : in  std_logic;
        z_out  : out std_logic;
        c_out  : out std_logic  
    );
end entity flags_reg;

architecture rtl of flags_reg is

begin
    reg_proc : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                z_out <= '0';
                c_out <= '0';
            else          
                if z_load = '1' then
                    z_out <= z_in;
                end if;     
                            
                if c_load = '1' then
                    c_out <= c_in;
                end if;
            end if;               
        end if;          
    end process reg_proc;    
end architecture rtl;
