----------------------------------------------------------------------------------
-- Engineer: MARIO DE MIGUEL
-- Create Date: 22.04.2025 09:19:45
-- Design Name: SWS RS232 TRANSMITTER MODULE
-- Module Name: RS232_transmitter - Transmitter_Behavior
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

entity RS232_transmitter is
    port (
        CLK_PORT    : in  std_logic;
        RESET       : in  std_logic;

        START       : in  std_logic;
        DATA        : in  std_logic_vector(7 downto 0);
        EOT         : out std_logic; -- End of transmission signal
        TX_BIT      : out std_logic
    );
end RS232_transmitter;

architecture Transmitter_Behavior of RS232_transmitter is
    
    -- FSM for transmitter
    type states is (Idle, StartBit, SendData, StopBit);
    signal current_state, next_state : states;

    -- Counters
    signal data_count : unsigned(3 downto 0);
    signal pulse_count : unsigned(7 downto 0);

    -- Constants
    constant pulse_width : unsigned(7 downto 0) := to_unsigned(104, 8);  --868 cycles for 100 MHz, 173 for 20 MHz, 104 for 12 MHz
    
    
    begin
        -- Processes
        Transmitter_FSM : process(current_state, pulse_count, data_count, START, DATA)
            begin
                case current_state is
                    when Idle =>
                        TX_BIT  <= '1';
                        EOT     <= '1';

                        if START = '1' then
                            next_state <= StartBit;
                        else
                            next_state <= Idle;
                        end if;
                    
                    when StartBit =>
                        TX_BIT  <= '0';
                        EOT     <= '0';

                        if pulse_count = pulse_width then
                            next_state <= SendData;
                        else
                            next_state <= StartBit;
                        end if;

                    when SendData =>
                        TX_BIT  <= DATA(to_integer(data_count)); --Element data_count (0 - 7) of data byte
                        EOT     <= '0';

                        if pulse_count = pulse_width and data_count = 7 then
                            next_state <= StopBit;
                        else
                            next_state <= SendData;
                        end if;

                    when StopBit =>
                        TX_BIT  <= '1';
                        EOT     <= '0';
                        
                        if pulse_count = pulse_width then
                            next_state <= Idle;
                        else 
                            next_state <= StopBit;
                        end if;
                
                end case;

        end process Transmitter_FSM;

        Transmitter_Clocking : process(CLK_PORT, RESET)
            begin
                if RESET = '0' then 
                    pulse_count <= (others => '0');
                    data_count  <= (others => '0');

                    current_state <= Idle;

                elsif CLK_PORT'event and CLK_PORT = '1' then
                    case current_state is
                        when Idle =>
                            pulse_count <= (others => '0');
                            data_count  <= (others => '0');

                        when StartBit =>
                            if pulse_count = pulse_width then
                                pulse_count <= (others => '0');
                            else
                                pulse_count <= pulse_count + 1;
                            end if;
                            data_count <= (others => '0');
                        
                        when SendData =>
                            if (pulse_count = pulse_width) then
                                pulse_count <= (others => '0');
                                if (data_count = 8) then  --One should never reach this
                                    data_count <= (others => '0');
                                else
                                    data_count <= data_count + 1;
                                end if;
                            else
                                --data_count = data_count 
                                pulse_count <= pulse_count + 1;
                            end if;

                        when StopBit => 
                            if pulse_count = pulse_width then
                                pulse_count <= (others => '0');
                            else
                                pulse_count <= pulse_count + 1;
                            end if;
                            data_count <= (others => '0');
                        
                        end case;

                        current_state <= next_state;
                end if;
        end process Transmitter_Clocking;



end Transmitter_Behavior;