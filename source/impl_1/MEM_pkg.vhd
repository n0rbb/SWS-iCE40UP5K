----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO
-- Engineer: MARIO DE MIGUEL DOMÃNGUEZ
-- 
-- Create Date: 23.04.2025 10:55:57
-- Design Name: SWS_RAM ADDRESS PACKAGE
-- Module Name: SWS_pkg - Behavioral
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

package MEM_pkg is
    -- Data types
    SUBTYPE item_array8_ram IS std_logic_vector (7 downto 0);
    TYPE array8_ram IS array (integer range <>) of item_array8_ram;

    --Address names
    constant DMA_RX_BUFFER_MSB : std_logic_vector(7 downto 0) := X"00";
    constant DMA_RX_BUFFER_MID : std_logic_vector(7 downto 0) := X"01";
    constant DMA_RX_BUFFER_LSB : std_logic_vector(7 downto 0) := X"02";
    constant NEW_INST          : std_logic_vector(7 downto 0) := X"03";
    constant DMA_TX_BUFFER_MSB : std_logic_vector(7 downto 0) := X"04";
    constant DMA_TX_BUFFER_MI1 : std_logic_vector(7 downto 0) := X"05";
    constant DMA_TX_BUFFER_MI2 : std_logic_vector(7 downto 0) := X"06";
    constant DMA_TX_BUFFER_LSB : std_logic_vector(7 downto 0) := X"07";  
    --constant LED_BASE          : std_logic_vector(7 downto 0) := X"08"; --08, 09, 0A
    constant DATA_BASE         : std_logic_vector(7 downto 0) := X"08";

    

end MEM_pkg;

package body MEM_pkg is
end MEM_pkg;
