----------------------------------------------------------------------------------
-- Engineer: MARIO DE MIGUEL
-- Create Date: 23.04.2025 11:29:38
-- Design Name: ARITHMETIC - LOGIC UNIT
-- Module Name: ALU - ALU_Behavior
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
use IEEE.NUMERIC_STD.ALL;
use work.INST_pkg.ALL;

entity ALU is
     port (
          CLK_PORT       : in std_logic;
          RESET          : in std_logic;

          ALU_OP         : in alu_op_t;

          INDEX_REG      : out std_logic_vector(7 downto 0);
          FLAG_Z         : out std_logic;
          FLAG_E         : out std_logic; 
          
          DATABUS        : inout std_logic_vector(7 downto 0)
     );
end ALU;

architecture ALU_Behavior of ALU is
     signal a, b, acc, index_r                    : std_logic_vector(7 downto 0);
     signal a_reg, b_reg, acc_reg, index_r_reg    : std_logic_vector(7 downto 0);
	 signal sum 								  : std_logic_vector(8 downto 0);
     signal flag_zero, flag_err                   : std_logic;
     signal flag_zero_reg, flag_err_reg           : std_logic;
     
     -- Regs to store context of ALU
     signal a_ctx_r, b_ctx_r, acc_ctx_r, index_r_ctx_r : std_logic_vector(7 downto 0);
     signal flag_zero_ctx_r, flag_err_ctx_r       : std_logic;

    signal databus_signal                         : std_logic_vector(7 downto 0);
     
     begin
          ALU_Core  : process(acc, a_reg, b_reg, acc_reg, index_r_reg, flag_zero_reg, flag_err_reg, sum, ALU_OP, DATABUS)
               begin
               -- Default values of the signals and flags
                    a              <= a_reg;
                    b              <= b_reg;
                    acc            <= acc_reg;
                    index_r        <= index_r_reg;
    
                    flag_zero      <= flag_zero_reg;
                    flag_err       <= flag_err_reg;
                    
					sum 		   <= (others => '0');
					
                    databus_signal        <= (others=>'Z');
    
                    -- Operations
                    case ALU_OP is
                         when nop =>
    
                         when op_lda =>
                              a <= DATABUS;
    
                         when op_ldb =>
                              b <= DATABUS;
                        
                         when op_ldacc =>
                              acc <= DATABUS;
    
                         when op_ldid =>
                              index_r <= DATABUS;
                         
                         when op_mvacc2a =>
                              a <= acc_reg;

                         when op_mvacc2b =>
                              b <= acc_reg;
                         
                         when op_mvacc2id =>
                              index_r <= acc_reg;
    
                         when op_cmpe =>
                              if unsigned(a_reg) = unsigned(b_reg) then --Probar a cargar la resta en el acumulador y tirar el flag de ahÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â­!
                                   flag_zero <= '1';
                              else
                                   flag_zero <= '0';
                              end if;
                        
                         when op_cmpg =>
                             if unsigned(a_reg) > unsigned(b_reg) then 
                                  flag_zero <= '1';
                             else
                                  flag_zero <= '0';
                             end if;
                        
                         when op_cmpl => 
                              if unsigned(a_reg) < unsigned(b_reg) then 
                                   flag_zero <= '1';
                              else
                                   flag_zero <= '0';
                              end if;
                        
                         when op_ascii2bin =>
                              acc <= std_logic_vector(unsigned(a_reg) - ASCII0);
                              if(unsigned(acc) > 9) then --Check acc instead of register
                                   flag_err <= '1';
                              else
                                   flag_err <= '0';
                              end if;
						 
						 when op_add =>
							  sum <= std_logic_vector(unsigned('0' & a_reg) + unsigned('0' & b_reg));
							  acc <= sum(7 downto 0);
							  if sum(8) = '1' then --overflow
									flag_err <= '1';
							  end if;
							  
							  if unsigned(acc) = 0 then
									flag_zero <= '1';
							  end if;
						
						 when op_subt =>
							  sum <= std_logic_vector(unsigned('0' & a_reg) - unsigned('0' & b_reg));
							  acc <= sum(7 downto 0);
							  if sum(8) = '1' then --this got negative
									flag_err <= '1';
							  end if;
			
							  if unsigned(acc) = 0 then
									flag_zero <= '1';
							  end if;
							  
						 when op_shiftl =>
							  acc <= std_logic_vector(shift_left(unsigned(a_reg), to_integer(unsigned(b_reg))));
								
						 
                         when op_oeacc =>
                              databus_signal <= acc_reg;
                        
                         when others =>
    
                    end case;
          end process ALU_Core;

          ALU_Registers : process(CLK_PORT, RESET)
               begin
                    if RESET = '0' then
                         a_reg              <= (others => '0');
                         b_reg              <= (others => '0');
                         acc_reg            <= (others => '0');

                         index_r_reg        <= (others => '0');

                         flag_zero_reg      <= '0';
                         flag_err_reg       <= '0';
                         
                         a_ctx_r            <= (others => '0');
                         b_ctx_r            <= (others => '0');
                         acc_ctx_r          <= (others => '0');
                         
                         index_r_ctx_r      <= (others => '0');
                         

                    elsif CLK_PORT'event and CLK_PORT = '1' then
                         if ALU_OP = op_loadcontext then
                            a_reg           <= a_ctx_r;
                            b_reg           <= b_ctx_r;
                            acc_reg         <= acc_ctx_r;
                            
                            index_r_reg     <= index_r_ctx_r;
                            
                            flag_zero_reg   <= flag_zero_ctx_r;
                            flag_err_reg    <= flag_err_ctx_r;
                            
                         else
                            a_reg           <= a;
                            b_reg           <= b;
                            acc_reg         <= acc;

                            index_r_reg     <= index_r;

                            flag_zero_reg   <= flag_zero;
                            flag_err_reg    <= flag_err;
                            
                         end if;
                         
                         if ALU_OP = op_savecontext then
                            a_ctx_r         <= a_reg;
                            b_ctx_r         <= b_reg;
                            acc_ctx_r       <= acc_reg;
                            
                            index_r_ctx_r   <= index_r_reg;
                            
                            flag_zero_ctx_r <= flag_zero_reg;
                            flag_err_ctx_r  <= flag_err_reg;
                            
                         end if;
                    end if;
          end process ALU_Registers;
          
          -- Combinational output port - signal assignation
          INDEX_REG <= index_r_reg;
          FLAG_Z    <= flag_zero_reg;
          FLAG_E    <= flag_err_reg;
         
          DATABUS   <= databus_signal;

end ALU_Behavior;