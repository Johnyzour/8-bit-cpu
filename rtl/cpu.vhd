--------------------------------------------------------------------------------
-- File        : cpu.vhd
-- Description : Top level of the 8-bit single-cycle Harvard CPU. Instantiates
--               and wires the PC, instruction ROM, control unit, register file,
--               ALU, data RAM, flags register and writeback mux.
-- Notes       : Each instruction completes in one clock: ROM, register and RAM
--               reads settle during the cycle, then the rising edge updates the
--               PC, registers, flags and RAM together.
--               The *_dbg ports expose internal state for the testbench.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity cpu is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        pc_dbg    : out std_logic_vector (7 downto 0);
        instr_dbg : out std_logic_vector (15 downto 0);
        reg_a_dbg : out std_logic_vector (7 downto 0);
        z_dbg     : out std_logic;
        c_dbg     : out std_logic
    );
end entity cpu;

architecture structural of cpu is
    signal pc_val     : std_logic_vector (7 downto 0);
    signal instr      : std_logic_vector (15 downto 0);
    signal reg_a      : std_logic_vector (7 downto 0);
    signal reg_b      : std_logic_vector (7 downto 0);
    signal alu_result : std_logic_vector (7 downto 0);
    signal alu_zero   : std_logic;
    signal alu_carry  : std_logic;
    signal z_flag     : std_logic;
    signal c_flag     : std_logic;
    signal ram_out    : std_logic_vector (7 downto 0);
    signal wb_data    : std_logic_vector (7 downto 0);
    signal reg_wr_en  : std_logic;
    signal ram_wr_en  : std_logic;
    signal z_load     : std_logic;
    signal c_load     : std_logic;
    signal pc_load    : std_logic;    
    signal pc_inc     : std_logic;
    signal wb_sel     : std_logic_vector (1 downto 0);
    signal alu_sel    : std_logic_vector (2 downto 0);
begin
    u_pc : entity work.pc
    port map (
        clk       => clk,
        rst       => rst,
        pc_inc    => pc_inc,
        pc_load   => pc_load,
        jump_addr => instr(7 downto 0),
        pc_out    => pc_val         
    );
    
    u_instr_rom : entity work.instr_rom
    port map (
        addr  => pc_val,
        instr => instr
    );
    
    u_control_unit : entity work.control_unit
    port map (
        opcode    => instr(15 downto 12),
        z_flag    => z_flag,
        c_flag    => c_flag,
        reg_wr_en => reg_wr_en,
        wb_sel    => wb_sel,
        alu_sel   => alu_sel,
        ram_wr_en => ram_wr_en,
        z_load    => z_load,
        c_load    => c_load,
        pc_load   => pc_load,
        pc_inc    => pc_inc
    );
    
    u_reg_file : entity work.reg_file
    port map (
        clk       => clk,
        rst       => rst,
        wr_en     => reg_wr_en,
        wr_sel    => instr(11 downto 10),
        wr_data   => wb_data,
        rd_sel_a  => instr(11 downto 10),
        rd_sel_b  => instr(9 downto 8),
        rd_data_a => reg_a,
        rd_data_b => reg_b
    );
    
    u_alu : entity work.alu
    port map (
        a       => reg_a,
        b       => reg_b,
        alu_sel => alu_sel,
        result  => alu_result,
        zero    => alu_zero,
        carry   => alu_carry
    );
    
    u_data_ram : entity work.data_ram
    port map (
        clk      => clk,
        wr_en    => ram_wr_en,
        addr     => instr(7 downto 0),
        data_in  => reg_a,
        data_out => ram_out
    );
    
    u_flags_reg : entity work.flags_reg
    port map (
        clk    => clk,
        rst    => rst,
        z_load => z_load,
        c_load => c_load,
        z_in   => alu_zero,
        c_in   => alu_carry,
        z_out  => z_flag,
        c_out  => c_flag
    );
    
    u_wb_mux : entity work.wb_mux
    port map (
        alu_result => alu_result,
        ram_data   => ram_out,
        imm        => instr(7 downto 0),
        reg_b      => reg_b,
        sel        => wb_sel,
        wb_data    => wb_data
    );
    
    pc_dbg    <= pc_val; 
    instr_dbg <= instr; 
    reg_a_dbg <= reg_a; 
    z_dbg     <= z_flag; 
    c_dbg     <= c_flag;
     
end architecture structural;
