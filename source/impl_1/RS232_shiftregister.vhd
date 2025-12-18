----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO - UNIVERSIDAD COMPLUTENSE DE MADRID
-- Engineer: MARIO DE MIGUEL DOMÍNGUEZ
-- 
-- Create Date: 22.04.2025 09:19:45
-- Design Name: SWS RS232 SHIFT REGISTER
-- Module Name: RS232_shiftregister - SR_Behavior
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

entity RS232_shiftregister is
    port (
        CLK_PORT    : in std_logic;
        RESET       : in std_logic;

        ENABLE      : in std_logic;
        D           : in std_logic;
        Q           : out std_logic_vector(7 downto 0)
    );
end RS232_shiftregister;

architecture SR_Behavior of RS232_shiftregister is
    
    signal Q_buffer : std_logic_vector(7 downto 0);
    
    begin
    
    Q <= Q_buffer;
    
    SR_Clocking : process(CLK_PORT, RESET)
        begin
            if RESET = '0' then
                Q_buffer <= (others => '0');
            elsif CLK_PORT'event and CLK_PORT = '1' then
                if ENABLE = '1' then
                    Q_buffer <= D & Q_buffer(7 downto 1);
                end if;
            end if;
            
    end process SR_Clocking;

end SR_Behavior;
