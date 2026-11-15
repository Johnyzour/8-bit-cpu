--------------------------------------------------------------------------------
-- File        : cpu.vhd
-- Description : Top level of the 8-bit multi-cycle von Neumann CPU.
--               Instantiates and wires the PC, stack pointer, shared memory,
--               memory address and data muxes, PC source mux, instruction
--               register, control FSM, register file, ALU, flags register and
--               writeback mux.
-- Notes       : One 256 x 8 memory holds the program, the data and the stack.
--               The address comes from the PC (fetch), imm (LD/ST), SP
--               (PUSH/POP/CALL/RET) or the rs register (LDR/STR), selected
--               by three mux2 arranged as a 4-to-1 mux. Memory write data is
--               a register, or the PC for CALL; the PC jump address is imm,
--               or the memory output for RET.
--               Instruction format (24-bit): opcode(23:16) | rd(15:12) |
--               rs(11:8) | imm(7:0), stored as three bytes and fetched one
--               byte per clock in FETCH1-3; only bits 13:12 and 9:8 select
--               R0-R3. Each instruction takes 5 or 6 clocks.
--               The *_dbg ports expose internal state for the testbench.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity cpu is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        pc_dbg    : out std_logic_vector (7 downto 0);
        instr_dbg : out std_logic_vector (23 downto 0);
        reg_a_dbg : out std_logic_vector (7 downto 0);
        z_dbg     : out std_logic;
        c_dbg     : out std_logic;
        sp_dbg    : out std_logic_vector (7 downto 0);
        state_dbg : out state_t
    );
end entity cpu;

architecture structural of cpu is
    signal pc_val       : std_logic_vector (7 downto 0);
    signal instr        : std_logic_vector (23 downto 0);
    signal reg_a        : std_logic_vector (7 downto 0);
    signal reg_b        : std_logic_vector (7 downto 0);
    signal alu_result   : std_logic_vector (7 downto 0);
    signal alu_zero     : std_logic;
    signal alu_carry    : std_logic;
    signal z_flag       : std_logic;
    signal c_flag       : std_logic;
    signal mem_out      : std_logic_vector (7 downto 0);
    signal wb_data      : std_logic_vector (7 downto 0);
    signal reg_wr_en    : std_logic;
    signal mem_wr_en    : std_logic;
    signal z_load       : std_logic;
    signal c_load       : std_logic;
    signal pc_load      : std_logic; 
    signal pc_inc       : std_logic;
    signal sp_inc       : std_logic;
    signal sp_dec       : std_logic;
    signal mem_data_sel : std_logic;
    signal pc_src_sel   : std_logic;
    signal wb_sel       : std_logic_vector (1 downto 0);
    signal alu_sel      : std_logic_vector (3 downto 0);
    signal mem_addr     : std_logic_vector (7 downto 0);
    signal mem_addr_sel : std_logic_vector (1 downto 0);
    signal ir_load      : std_logic_vector (2 downto 0);
    signal sp_val       : std_logic_vector (7 downto 0);
    signal addr_a       : std_logic_vector (7 downto 0);
    signal addr_b       : std_logic_vector (7 downto 0);    
    signal mem_data_in  : std_logic_vector (7 downto 0);
    signal jump_addr    : std_logic_vector (7 downto 0);
    signal state        : state_t;
begin
    u_pc : entity work.pc
    port map (
        clk       => clk,
        rst       => rst,
        pc_inc    => pc_inc,
        pc_load   => pc_load,
        jump_addr => jump_addr,
        pc_out    => pc_val
    );
    
    u_memory : entity work.memory
    port map (
        clk      => clk,
        wr_en    => mem_wr_en,
        addr     => mem_addr,
        data_in  => mem_data_in,
        data_out => mem_out
    );
    
    u_ir : entity work.ir
    port map (
        clk      => clk,
        rst      => rst,
        ir_load  => ir_load,
        data_in  => mem_out,
        data_out => instr
    );
    
    u_control_unit : entity work.control_unit
    port map (
        clk          => clk,
        rst          => rst,
        opcode       => instr(23 downto 16),
        z_flag       => z_flag,
        c_flag       => c_flag,
        reg_wr_en    => reg_wr_en,
        wb_sel       => wb_sel,
        alu_sel      => alu_sel,
        mem_wr_en    => mem_wr_en,
        z_load       => z_load,
        c_load       => c_load,
        pc_load      => pc_load,
        pc_inc       => pc_inc,
        ir_load      => ir_load,
        mem_addr_sel => mem_addr_sel,
        sp_inc       => sp_inc,
        sp_dec       => sp_dec,
        mem_data_sel => mem_data_sel,
        pc_src_sel   => pc_src_sel,
        state_out    => state
    );
    
    u_reg_file : entity work.reg_file
    port map (
        clk       => clk,
        rst       => rst,
        wr_en     => reg_wr_en,
        wr_sel    => instr(13 downto 12),
        wr_data   => wb_data,
        rd_sel_a  => instr(13 downto 12),
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
        ram_data   => mem_out,
        imm        => instr(7 downto 0),
        reg_b      => reg_b,
        sel        => wb_sel,
        wb_data    => wb_data
    );
    
    u_addr_mux : entity work.mux2
    port map (
        in0 => pc_val,
        in1 => instr(7 downto 0),
        sel => mem_addr_sel(0),
        y   => addr_a        
    );
    
    u_addr_mux_hi : entity work.mux2
    port map (
        in0 => sp_val,
        in1 => reg_b,
        sel => mem_addr_sel(0),
        y   => addr_b
    );
    
    u_addr_mux_sp : entity work.mux2
    port map (
        in0 => addr_a,
        in1 => addr_b,
        sel => mem_addr_sel(1),
        y   => mem_addr  
    );
    
    u_data_mux : entity work.mux2
    port map (
        in0 => reg_a,
        in1 => pc_val,
        sel => mem_data_sel,
        y   => mem_data_in  
    );
    
    u_pc_src_mux : entity work.mux2
    port map (
        in0 => instr(7 downto 0),
        in1 => mem_out,
        sel => pc_src_sel,
        y   => jump_addr  
    );
    
    u_sp : entity work.sp
    port map (
        clk    => clk,
        rst    => rst,
        sp_inc => sp_inc,
        sp_dec => sp_dec,
        sp_out => sp_val  
    );
    
    pc_dbg    <= pc_val;
    sp_dbg    <= sp_val;
    instr_dbg <= instr;
    reg_a_dbg <= reg_a;
    z_dbg     <= z_flag;
    c_dbg     <= c_flag;
    state_dbg <= state;

end architecture structural;
