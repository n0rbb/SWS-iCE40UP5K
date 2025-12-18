----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO - UNIVERSIDAD COMPLUTENSE DE MADRID
-- Engineer: MARIO DE MIGUEL DOMÍNGUEZ
-- 
-- Create Date: 21.04.2025 14:12:17
-- Design Name: SWS UART RS232 INTERFACE 
-- Module Name: RS232 - RS232_Behavior
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


entity RS232 is
    port (
        CLK_PORT    : in  std_logic;
        RESET       : in  std_logic;
  
        DATA_IN     : in  std_logic_vector(7 downto 0);
        VALID_D     : in  std_logic;
        ACK_IN      : out std_logic;
        TX_RDY      : out std_logic;
  
        RD          : in  std_logic;
        TD          : out std_logic;

        DATA_READ   : in  std_logic;
        DATA_OUT    : out std_logic_vector(7 downto 0);
        
        FULL        : out std_logic;
        EMPTY       : out std_logic
    );
end RS232;

architecture RS232_Behavior of RS232 is
    -- Component declaration

    -- Transmission block
    -- Transmitter
    component RS232_transmitter is
        port (
            CLK_PORT    : in  std_logic;
            RESET       : in  std_logic;

            START       : in  std_logic;
            DATA        : in  std_logic_vector(7 downto 0);
            EOT         : out std_logic;
            TX_BIT      : out std_logic
        );
    end component;

    -- Reception blocks
    -- Receiver
    component RS232_receiver is
        port (
            CLK_PORT    : in  std_logic;
            RESET       : in  std_logic;

            RX_BIT      : in  std_logic;
            VALID_OUT   : out std_logic;
            CODE_OUT    : out std_logic;
            STORE_OUT   : out std_logic
        );
    end component;

    -- Shift Register
    component RS232_shiftregister is
        port (
            CLK_PORT    : in std_logic;
            RESET       : in std_logic;

            ENABLE      : in std_logic;
            D           : in std_logic;
            Q           : out std_logic_vector(7 downto 0)
        );
    end component;

    -- FIFO
    component RS232_fifo is
        port (
            RESET      	: in  std_logic;
            CLK_PORT  	: in  std_logic;

            WR_EN      	: in  std_logic;
            DIN       	: in  std_logic_VECTOR(7 downto 0);

            RD_EN     	: in  std_logic;
            DOUT      	: out std_logic_VECTOR(7 downto 0);

            FULL      	: out std_logic;
            EMPTY      	: out std_logic
        );
    end component;

    -- Signal declaration
    -- Transmitter
    signal data_tx    : std_logic_vector(7 downto 0); --Input data for transmitter
    signal start_tx   : std_logic;  -- start signal for transmitter
    signal tx_rdy_i   : std_logic;
    
    -- Receiver
    signal linerd_in  : std_logic;  -- internal RX line
    signal valid_out  : std_logic;  -- valid bit at the receiver
    signal code_out   : std_logic;  -- bit at the receiver output

    -- FIFO
   -- signal sinit      : std_logic;  -- fifo reset
    signal fifo_in    : std_logic_vector(7 downto 0);
    signal fifo_write : std_logic;
    signal fifo_read  : std_logic;
    signal fifo_out   : std_logic_vector(7 downto 0);

    begin
        -- Component port mapping
        Transmitter : RS232_transmitter
            port map(
                CLK_PORT    => CLK_PORT,
                RESET       => RESET,
    
                START       => start_tx,
                DATA        => data_tx,
                EOT         => tx_rdy_i,
                TX_BIT      => TD
            );
        
        Receiver : RS232_receiver
            port map(
                CLK_PORT    => CLK_PORT,
                RESET       => RESET,
    
                RX_BIT      => RD,
                VALID_OUT   => valid_out,
                CODE_OUT    => code_out,
                STORE_OUT   => fifo_write
            );
        
        Shift_Register : RS232_shiftregister
            port map(
                CLK_PORT    => CLK_PORT,
                RESET       => RESET,

                ENABLE      => valid_out,
                D           => code_out,
                Q           => fifo_in
            );

        FIFO : RS232_fifo
            port map(
                RESET       => RESET,
                CLK_PORT    => CLK_PORT,

                WR_EN       => fifo_write,
                DIN         => fifo_in,
            
                RD_EN       => fifo_read,
                DOUT        => fifo_out,
            
                FULL        => FULL,
                EMPTY       => EMPTY
            );
        
        -- Signal assignation
        --sinit <= not(RESET); 
        
        TX_RDY <= tx_rdy_i;

        fifo_read <= DATA_READ;
        DATA_OUT <= fifo_out;
        
        
        -- Processes
        RS232_Clocking : process(CLK_PORT, RESET)
        begin
            if RESET = '0' then
                --linerd_in   <= '1';
                data_tx     <= (others => '0');
                ACK_IN      <= '1';
                start_tx <= '0';
                
            elsif CLK_PORT'event and CLK_PORT = '1' then
                --linerd_in <= RD;
                
                if valid_d <= '0' and tx_rdy_i <= '1' then
                    data_tx <= DATA_IN;
                    ACK_IN <= '0';
                    start_tx <= '1';
                else 
                    ACK_IN <= '1';
                    start_tx <= '0';
                end if;
            end if;

        end process RS232_Clocking;


end RS232_Behavior;