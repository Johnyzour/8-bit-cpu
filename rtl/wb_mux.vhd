library ieee;
use ieee.std_logic_1164.all;

entity wb_mux is
    port ( 
        alu_result : in  std_logic_vector (7 downto 0);
        ram_data   : in  std_logic_vector (7 downto 0);
        imm        : in  std_logic_vector (7 downto 0);
        reg_b      : in  std_logic_vector (7 downto 0);
        sel        : in  std_logic_vector (1 downto 0);
        wb_data    : out std_logic_vector (7 downto 0)     
    );
end entity wb_mux;

architecture structural of wb_mux is
    signal muxa_out : std_logic_vector (7 downto 0);
    signal muxb_out : std_logic_vector (7 downto 0);
begin
    mux_a : entity work.mux2
    port map (
        in0 => alu_result,
        in1 => ram_data,
        sel => sel(0),
        y   => muxa_out              
    );
    
    mux_b : entity work.mux2
    port map (
        in0 => imm,
        in1 => reg_b,
        sel => sel(0),
        y   => muxb_out              
    );
    
    mux_c : entity work.mux2
    port map (
        in0 => muxa_out,
        in1 => muxb_out,
        sel => sel(1),
        y   => wb_data              
    );    
end architecture structural;
