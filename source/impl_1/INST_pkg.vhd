----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO
-- Engineer: MARIO DE MIGUEL DOMÃƒÆ’Ã†â€™Ãƒâ€šÃ‚ÂNGUEZ
-- 
-- Create Date: 25.04.2025 14:48:45
-- Design Name: SWS_INSTRUCTION CONSTANTS PACKAGE
-- Module Name: INST_pkg - Behavioral
-- Project Name: SPIN-WAVE SENSOR - SIGNAL ACQUISITION UNIT
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

package INST_pkg is

    --Constants
    constant ASCII0 : unsigned := to_unsigned(48, 6);

    --JUMP CONSTANTS
    constant INI            : std_logic_vector(11 downto 0) := X"000";
    --constant LED            : std_logic_vector(11 downto 0) := X"01E";
	constant SOK            : std_logic_vector(11 downto 0) := X"034";
	constant ERR            : std_logic_vector(11 downto 0) := X"041";
    constant SFC            : std_logic_vector(11 downto 0) := X"04E";
    constant RFC            : std_logic_vector(11 downto 0) := X"05B";
    
    

    -- TYPE 1 INSTRUCTIONS
    constant TYPE_1         : std_logic_vector(1 downto 0)  := "00";
	
	constant ALU_NOP		: std_logic_vector(5 downto 0)  := "000000";
    constant ALU_CMPE       : std_logic_vector(5 downto 0)  := "000001";
    constant ALU_CMPG       : std_logic_vector(5 downto 0)  := "000010";
    constant ALU_CMPL       : std_logic_vector(5 downto 0)  := "000011";
    constant ALU_ASCII2BIN  : std_logic_vector(5 downto 0)  := "000100";

    -- TYPE 2 INSTRUCTIONS
    constant TYPE_2         : std_logic_vector(1 downto 0)  := "01";
    
    constant JMP_UNCOND     : std_logic_vector(5 downto 0)  := "000000";
    constant JMP_COND       : std_logic_vector(5 downto 0)  := "000001";
	

    -- TYPE 3 INSTRUCTIONS
    constant TYPE_3         : std_logic_vector(1 downto 0)  := "10";
    
    constant LD             : std_logic                     := '0';
    constant SW             : std_logic                     := '1';

    --Source
    constant SRC_ACC        : std_logic_vector(1 downto 0)  := "00";
    constant SRC_CONST      : std_logic_vector(1 downto 0)  := "01";
    constant SRC_MEM        : std_logic_vector(1 downto 0)  := "10";
    constant SRC_IDX_MEM    : std_logic_vector(1 downto 0)  := "11";

    --Destination
    constant DST_ACC        : std_logic_vector(2 downto 0)  := "000";
    constant DST_A          : std_logic_vector(2 downto 0)  := "001";
    constant DST_B          : std_logic_vector(2 downto 0)  := "010";
    constant DST_IDX        : std_logic_vector(2 downto 0)  := "011";
    constant DST_MEM        : std_logic_vector(2 downto 0)  := "100";
    constant DST_IDX_MEM    : std_logic_vector(2 downto 0)  := "101";
	constant DST_DMA		: std_logic_vector(2 downto 0)	:= "110";
	constant DST_FQC		: std_logic_vector(2 downto 0)	:= "111";

 
    -- TYPE 4 INSTRUCTIONS
    constant TYPE_4         : std_logic_vector(1 downto 0)  := "11";
    constant SND            : std_logic_vector(1 downto 0)  := "00";
    constant RUN            : std_logic_vector(1 downto 0)  := "01";
	constant DELAY		    : std_logic_vector(1 downto 0)  := "10";

    --ALU operations
    TYPE alu_op_t IS (
      nop,                                  -- no operation
      op_lda, op_ldb, op_ldacc, op_ldid,    -- external value load
      op_mvacc2id, op_mvacc2a, op_mvacc2b,  -- internal load
    --  op_add, op_sub, op_shiftl, op_shiftr, -- arithmetic operations
    --  op_and, op_or, op_xor,                -- logic operations
      op_cmpe, op_cmpl, op_cmpg,            -- compare operations
      op_ascii2bin, -- op_bin2ascii,           -- conversion operations
      op_oeacc, 
      op_savecontext, op_loadcontext);                            -- output enable

    
end INST_pkg;

package body INST_pkg is
end INST_pkg;