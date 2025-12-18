----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO - UNIVERSIDAD COMPLUTENSE DE MADRID
-- Engineer: MARIO DE MIGUEL DOMÃƒÂNGUEZ
-- 
-- Create Date: 21.04.2025 14:10:01
-- Design Name: SWS MEMORY MODULE
-- Module Name: RAM - RAM_Behavior
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
use work.MEM_pkg.ALL;


entity RAM is
    port(
        CLK_PORT    : in std_logic;
        RESET       : in std_logic;

        WRITE_EN    : in std_logic;
        OE          : in std_logic;

        ADDRESS     : in std_logic_vector(7 downto 0);
        DATABUS     : inout std_logic_vector(7 downto 0)
        
        --LED_STAT    : out std_logic_vector(2 downto 0)
    );
end RAM;

architecture RAM_Behavior of RAM is
    signal contents_ram : array8_ram(15 downto 0);

    begin
        -- Asynchronous reading
        DATABUS <= contents_ram(to_integer(unsigned(ADDRESS))) when OE <= '0' else (others => 'Z');
        
        --Synchronous writing
        RAM_Write : process(CLK_PORT, RESET)
            begin
                if RESET = '0' then
                    contents_ram(to_integer(unsigned(DMA_RX_BUFFER_MSB))) <= X"00";
                    contents_ram(to_integer(unsigned(DMA_RX_BUFFER_MID))) <= X"00";
                    contents_ram(to_integer(unsigned(DMA_RX_BUFFER_LSB))) <= X"00";
                    contents_ram(to_integer(unsigned(NEW_INST))) <= X"00";
                    contents_ram(to_integer(unsigned(DMA_TX_BUFFER_MSB))) <= X"00";
                    contents_ram(to_integer(unsigned(DMA_TX_BUFFER_MI1))) <= X"53";
                    contents_ram(to_integer(unsigned(DMA_TX_BUFFER_MI2))) <= X"53";
                    contents_ram(to_integer(unsigned(DMA_TX_BUFFER_LSB))) <= X"00";
                    --contents_ram((to_integer(unsigned(LED_BASE)) + 2) downto to_integer(unsigned(LED_BASE))) <= (others => X"00"); 

                elsif CLK_PORT'event and CLK_PORT = '1' then
                    if WRITE_EN = '1' then
                        contents_ram(to_integer(unsigned(ADDRESS))) <= DATABUS;
                    end if;
                end if;
        end process RAM_Write;
        
        -- LED signal management
        --LED_STAT(0) <= contents_ram(to_integer(unsigned(LED_BASE)))(0);
        --LED_STAT(1) <= contents_ram(to_integer(unsigned(LED_BASE)) + 1)(0);
        --LED_STAT(2) <= contents_ram(to_integer(unsigned(LED_BASE)) + 2)(0);
end RAM_Behavior;
