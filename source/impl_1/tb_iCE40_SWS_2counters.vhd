library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.RS232_test.ALL;


entity tb_iCE40_SWS_2counters is
end tb_iCE40_SWS_2counters;

architecture Testbench of tb_iCE40_SWS_2counters is
    component iCE40_SWS is
        port(
            --  CLK_SOURCE        : in std_logic; --Uncomment when simulating with external oscillator

            -- User button -- Reset
            BTN               : in std_logic;
    
            -- Communications inteface -RS232
            UART_RX           : in std_logic;
            UART_TX           : out std_logic;
    
            
            -- Frequency input
            FQ_IN             : in std_logic_vector(1 downto 0);
        );
    end component;

    -- Board signals
    signal clk12mhz     : std_logic;
    signal reset        : std_logic;
    signal btn_signal   : std_logic;

    -- UART
    signal td           : std_logic;
	signal rd		   : std_logic;
	--Frequency Mock
	signal fq_mocks : std_logic_vecctor(1 downto 0);
	
    constant clkperiod  : time := 83.33 ns; --12 MHz clock frequency
    constant signalperiod1 : time := 500 ns; --2 MHz mock signal frequency
	constant signalperiod2 : time := 1000 ns; -- 1 MHz mock signal frequency
	
    begin
        -- Component mapping
        Sensor_UT : iCE40_SWS
            port map(
                --CLK_SOURCE      => clk12mhz, --Uncomment when simulating with external oscillator
                BTN             => btn_signal,
                
                UART_RX         => rd,
                UART_TX         => td,

                --LED             => led_signal,
                FQ_IN           => fq_mocks
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
        
        Frequency_Mock1 : process
            begin
                fq_mock(0) <= '0';
                wait for signalperiod1/2;
                fq_mock(0) <= '1';
                wait for signalperiod1/2;
        end process Frequency_Mock1;
		
		Frequency_Mock2 : process
		begin
                fq_mock(1) <= '0';
                wait for signalperiod2/2;
                fq_mock(1) <= '1';
                wait for signalperiod2/2;
        end process Frequency_Mock2;
		
		UART_Comm : process
            begin
                rd <= '1';
                wait for 50 us;
                          
				--Command 1: I-- (Read status)
                Transmit(rd, X"49");
                wait for 50 us;
                Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
			    wait for 500 us;
				
				--Command 2: C 01 01 (Arm 1)
				Transmit(rd, X"43");
				wait for 50 us;
				Transmit(rd, X"01");
                wait for 50 us;
                Transmit(rd, X"01");
			    wait for 200 us;
				
				--Command 3: S-- (Run Counter 1)
                Transmit(rd, X"53");
                wait for 50 us;
                Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
                wait for 1000 us;
				
				--Command 4: C 01 01 (Arm 2)
				Transmit(rd, X"43");
				wait for 50 us;
				Transmit(rd, X"01");
                wait for 50 us;
                Transmit(rd, X"02");
			    wait for 200 us;
				
				--Command 5: S-- (Run Counter 2)
                Transmit(rd, X"53");
                wait for 50 us;
                Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
                wait for 1000 us;
				
				--Command 6: R01 (Read Counter 1)
				Transmit(rd, X"52");
				wait for 50 us;
				Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
				wait for 500 us;
				
				--Command 7: C 03 10 (New objective for ctr 2)
				Transmit(rd, X"43");
				wait for 50 us;
				Transmit(rd, X"03");
                wait for 50 us;
                Transmit(rd, X"05");
			    wait for 200 us;
				
				--Command 8: C 01 11 (ARM 1 & 2)
				Transmit(rd, X"43");
				wait for 50 us;
				Transmit(rd, X"01");
                wait for 50 us;
                Transmit(rd, X"03");
			    wait for 200 us;
				
				--Command 9: Run both
				Transmit(rd, X"53");
                wait for 50 us;
                Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
                wait for 500 us;
				
				--Command 10: R02 (Read Counter 2)
				Transmit(rd, X"52");
				wait for 50 us;
				Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"02");
				wait for 500 us;
				
				--Commands 11, 12: Test both finishing at the same time
				Transmit(rd, X"43");
				wait for 50 us;
				Transmit(rd, X"02");
                wait for 50 us;
                Transmit(rd, X"0A");
			    wait for 200 us;
				
				Transmit(rd, X"53");
                wait for 50 us;
                Transmit(rd, X"30");
                wait for 50 us;
                Transmit(rd, X"01");
                wait;
				
			
				
        end process UART_Comm;
		-- Signal-port assignation
        btn_signal <= not(reset);
	end Testbench;