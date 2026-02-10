library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.RS232_test.ALL;


entity tb_iCE40_SWS is
end tb_iCE40_SWS;

architecture Testbench of tb_iCE40_SWS is
    component iCE40_SWS is
        port(
           -- CLK_SOURCE        : in std_logic; --Uncomment when simulating with external oscillator

            -- User button -- Reset
            BTN               : in std_logic;
    
            -- Communications inteface -RS232
            UART_RX           : in std_logic;
            UART_TX           : out std_logic;
    
            -- LEDs for testing and debugging
            --LED               : out std_logic_vector(2 downto 0);
            
            -- Frequency input
            FQ_IN             : in std_logic_vector(1 downto 0)
        );
    end component;

    -- Board signals
    signal clk12mhz     : std_logic;
    signal reset        : std_logic;
    signal btn_signal   : std_logic;
	--signal btn_signal   : std_logic_vector(1 downto 0);
    --signal led_signal   : std_logic_vector(2 downto 0);

    -- UART
    signal td           : std_logic;
	signal rd		   : std_logic;
	--Frequency Mock
    signal fq_mock      : std_logic_vector(1 downto 0);

    constant clkperiod  : time := 83.33 ns; --12 MHz clock frequency
    constant signalperiod : time := 500 ns; --2 MHz mock signal frequency

    begin
        -- Component mapping
        Sensor_UT : iCE40_SWS
            port map(
               -- CLK_SOURCE      => clk12mhz, --Uncomment when simulating with external oscillator
                BTN             => btn_signal,
                
                UART_RX         => rd,
                UART_TX         => td,

                --LED             => led_signal,
                FQ_IN           => fq_mock
            ); 
           
        

        -- Reset generation
        reset <= '1', '0' after 1075 ns, '1' after 2075 ns;

        -- Clock generation
        False_Clock : process
            begin
                clk12mhz <= '1';
                wait for clkperiod/2;
                clk12mhz <= '0';
                wait for clkperiod/2; 
        end process False_Clock;
        
        Frequency_Mock : process
            begin
                fq_mock(0) <= '0';
                wait for signalperiod/2;
                fq_mock(0) <= '1';
                wait for signalperiod/2;
        end process Frequency_Mock;

        -- Input stimuli generation
        UART_Comm : process
            begin
                rd <= '1';
                wait for 50 us;
                          
                --Command 1: EEE (Error)
                Transmit(rd, X"45"); --E
                wait for 50 us;
                Transmit(rd, X"45"); --E
                wait for 50 us;
                Transmit(rd, X"45"); --E
                wait for 1000 us;
                
                --Command 2: S01 (Run Counters (unarmed))
                Transmit(rd, X"53");
                wait for 50 us;
                Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
                wait for 1000 us;
				
				--Command 3: R01 (Read Counter 1)
                Transmit(rd, X"52");
				wait for 50 us;
				Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
			    wait for 500 us;
				
				--Try again
				-- Command 4: C X"01" "01" (Arm Counter 1)
				Transmit(rd, X"43");
				wait for 50 us;
				Transmit(rd, X"01");
                wait for 50 us;
                Transmit(rd, X"01");
			    wait for 200 us;
				
				--Command 4: S01 (Run Counter 1)
                Transmit(rd, X"53");
                wait for 50 us;
                Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
                wait for 1000 us;
				
				--Command 5: R01 (Read Counter 1)
                Transmit(rd, X"52");
				wait for 50 us;
				Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
				wait;
        end process UART_Comm;



        -- Signal-port assignation
        btn_signal <= reset;
        --led_signal <= LED;
        --td <= UART_TX;
        --UART_RX <= rd;
end Testbench;
