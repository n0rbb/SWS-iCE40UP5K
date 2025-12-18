----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.04.2025 09:19:45
-- Design Name: 
-- Module Name: RS232_receiver - Receiver_behavior
-- Project Name: 
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

entity RS232_receiver is
    port (
        CLK_PORT    : in  std_logic;
        RESET       : in  std_logic;

        RX_BIT      : in  std_logic;
        VALID_OUT   : out std_logic;
        CODE_OUT    : out std_logic;
        STORE_OUT   : out std_logic
    );
end RS232_receiver;

architecture Receiver_Behavior of RS232_receiver is

    --FSM states
    type states is (Idle, StartBit, RcvData, StopBit);
    signal next_state, current_state : states;
    
    --Counters
    signal data_count       : unsigned(2 downto 0);       -- Contador de bits de datos (8 bits)
    signal halfbit_count    : unsigned(7 downto 0);       -- Contador para retardo al centro del bit inicial
    signal bit_count        : unsigned(7 downto 0);       -- Contador para retardo al centro de los bits de datos
    --Constants 
    constant bit_width      : unsigned(7 downto 0) := to_unsigned(104, 8);   -- PerÃ­odo del bit para 115200 bps con reloj de 100 MHz

    begin
        Receiver_FSM : process(current_state, halfbit_count, bit_count, data_count, RX_BIT)
            begin

                CODE_OUT <= RX_BIT;

                case current_state is
                    when Idle =>
                        VALID_OUT <= '0';
                        STORE_OUT <= '0';

                        if RX_BIT <= '0' then
                            next_state <= StartBit;
                        else
                            next_state <= Idle;
                        end if;
                    
                    when StartBit =>
                        --Output logic
                        if halfbit_count = bit_width/2 then 
                            if RX_BIT <= '0' then --ComprobaciÃ³n de validez del bit
                                VALID_OUT <= '1';
                            else
                                VALID_OUT <= '0';
                            end if;
                        else 
                            VALID_OUT <= '0';
                        end if;
                        STORE_OUT <= '0';
                        
                        -- Transitions logic
                        if halfbit_count = bit_width/2 then 
                            if RX_BIT <= '0' then 
                                next_state <= RcvData;
                            else
                                next_state <= Idle;
                            end if;
                        else 
                            next_state <= StartBit;
                        end if;
                    
                    when RcvData =>
                        if bit_count = bit_width then 
                            VALID_OUT <= '1';
                        else
                            VALID_OUT <= '0';
                        end if;
                        STORE_OUT <= '0';
                        
                        if bit_count = bit_width then 
                            if data_count = 7 then
                                next_state <= StopBit;
                            else
                                next_state <= RcvData;
                            end if;
                        else
                            next_state <= RcvData;
                        end if;
                    
                    when StopBit =>
                        VALID_OUT <= '0';
                        if bit_count = bit_width then 
                            if RX_BIT <= '1' then --Comprobar que el bit de parada es 1, si no, a la porra
                                STORE_OUT <= '1';
                            else
                                STORE_OUT <= '0';
                            end if;
                        else
                            STORE_OUT <= '0';
                        end if;

                        if bit_count = bit_width then
                            next_state <= Idle;
                        else
                            next_state <= StopBit;
                        end if;

                end case;
        end process Receiver_FSM;
        
        Receiver_Clocking : process(CLK_PORT, RESET)
            begin
                if RESET = '0' then
                    -- Estado idle;
                    current_state   <= idle;
                    -- Contadores
                    data_count      <= (others => '0');
                    halfbit_count   <= (others => '0');
                    bit_count       <= (others => '0');

                elsif CLK_PORT'event and CLK_PORT = '1' then
                    
                    case current_state is
                        when Idle =>
                            data_count      <= (others => '0');
                            halfbit_count   <= (others => '0');
                            bit_count       <= (others => '0');

                        when StartBit =>
                        
                            data_count <= (others => '0');
    
                            if halfbit_count = bit_width/2 then
                                halfbit_count <= (others => '0');
                            else
                                halfbit_count <= halfbit_count + 1;
                            end if;

                            bit_count <= (others => '0');

                        when RcvData =>
               
                            halfbit_count <= (others => '0');

                            if bit_count = bit_width then 
                                bit_count <= (others => '0');
                                if data_count = 7 then
                                    data_count <= (others => '0');
                                else
                                    data_count <= data_count + 1;
                                end if;
                            else
                                bit_count <= bit_count + 1; 
                            end if;
                        
                        when StopBit =>
                            data_count <= (others => '0');
                            halfbit_count <= (others => '0');
    
                            if bit_count = bit_width then
                                bit_count <= (others => '0');
                            else
                                bit_count <= bit_count + 1;
                            end if;
                    end case;
                    
                    current_state <= next_state;
                    
                end if;
        end process Receiver_Clocking;


end Receiver_Behavior;