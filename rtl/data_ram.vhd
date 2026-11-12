library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_ram is
    port ( 
        clk      : in  std_logic;
        wr_en    : in  std_logic;
        addr     : in  std_logic_vector (7 downto 0);
        data_in  : in  std_logic_vector (7 downto 0);
        data_out : out std_logic_vector (7 downto 0)
    );
end entity data_ram;

architecture rtl of data_ram is
    type ram_type is array (0 to 255) of std_logic_vector (7 downto 0);
    signal ram_data : ram_type := (others => x"00");
begin
    write_proc : process (clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                ram_data(to_integer(unsigned(addr))) <= data_in;
            end if;
        end if;
    end process write_proc;        

    data_out <= ram_data(to_integer(unsigned(addr)));

end architecture rtl;
