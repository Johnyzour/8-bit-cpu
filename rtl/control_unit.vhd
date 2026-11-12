library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity control_unit is
    port ( 
        opcode    : in  std_logic_vector (3 downto 0);
        z_flag    : in  std_logic;
        c_flag    : in  std_logic;
        reg_wr_en : out std_logic;
        wb_sel    : out std_logic_vector (1 downto 0);
        alu_sel   : out std_logic_vector (2 downto 0);
        ram_wr_en : out std_logic;
        z_load    : out std_logic;
        c_load    : out std_logic;
        pc_load   : out std_logic;
        pc_inc    : out std_logic
    );
end entity control_unit;

architecture rtl of control_unit is
    
begin
    main_proc : process (opcode, z_flag, c_flag)
    begin
        reg_wr_en <= '0';
        wb_sel    <= WB_ALU;
        alu_sel   <= ALU_ADD;
        ram_wr_en <= '0';
        z_load    <= '0';
        c_load    <= '0';
        pc_load   <= '0';
        pc_inc    <= '1';
        
        case opcode is
            when OP_NOP =>
                null;
            when OP_LDI =>
                reg_wr_en <= '1';
                wb_sel    <= WB_IMM;
            when OP_MOV =>
                reg_wr_en <= '1';
                wb_sel    <= WB_REG;
            when OP_LD =>
                reg_wr_en <= '1';
                wb_sel    <= WB_RAM;
            when OP_ST =>
                ram_wr_en <= '1';
            when OP_ADD =>
                reg_wr_en <= '1';
                alu_sel   <= ALU_ADD;
                z_load    <= '1';
                c_load    <= '1';
            when OP_SUB =>
                reg_wr_en <= '1';
                alu_sel   <= ALU_SUB;
                z_load    <= '1';
                c_load    <= '1';
            when OP_AND =>
                reg_wr_en <= '1';
                alu_sel   <= ALU_AND;
                z_load    <= '1';
            when OP_OR =>
                reg_wr_en <= '1';
                alu_sel   <= ALU_OR;
                z_load    <= '1';
            when OP_XOR =>
                reg_wr_en <= '1';
                alu_sel   <= ALU_XOR;
                z_load    <= '1';
            when OP_NOT =>
                reg_wr_en <= '1';
                alu_sel   <= ALU_NOT;
                z_load    <= '1';
            when OP_CMP =>
                alu_sel   <= ALU_SUB;
                z_load    <= '1';
                c_load    <= '1';
            when OP_JMP =>
                pc_load <= '1';
            when OP_JZ =>
                pc_load <= z_flag;
            when OP_JNZ =>
                pc_load <= not z_flag;
            when OP_JC =>
                pc_load <= c_flag;
            when others =>
                null;    
        end case;        
    end process main_proc;    
end architecture rtl;
