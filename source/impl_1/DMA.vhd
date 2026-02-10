----------------------------------------------------------------------------------
-- Engineer: MARIO DE MIGUEL 
-- Create Date: 21.04.2025 14:12:17
-- Design Name: SWS DIRECT MEMORY ACCESS MODULE
-- Module Name: DMA - DMA_Behavior
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



entity DMA is
    port ( 
        CLK_PORT 	: in std_logic;
        RESET 	    : in std_logic;
     
        RCVD_DATA 	: in std_logic_vector(7 downto 0);
        RX_FULL 	: in std_logic;
        RX_EMPTY    : in std_logic;
     
        DATA_READ 	: out std_logic;
     
        ACK_OUT 	: in std_logic;
        TX_RDY 		: in std_logic;
        VALID_D 	: out std_logic;
        TX_DATA 	: out std_logic_vector(7 downto 0);
     
        ADDRESS 	: out std_logic_vector(7 downto 0);
        WRITE_EN 	: out std_logic;
        OE 			: out std_logic;
		DMA_READ_RDY : in std_logic;

        DMA_ACK 	: in std_logic;
        SEND_COMM 	: in std_logic;
		SEND_CONF	: in std_logic; -- Control signal to update peripheral config
        DMA_RQ 		: out std_logic;
        READY 		: out std_logic;
		
		COUNT_RDY	: in std_logic;
		COUNT_OUT	: in std_logic_vector(7 downto 0);
		COUNT_READ 	: out std_logic;
		--COUNTER_ACK : out std_logic;
		COUNT_CFG	: out std_logic_vector(7 downto 0);
		COUNT_REG_ADDR : out std_logic_vector(1 downto 0);
		COUNT_WR_EN	: out std_logic;
        
        INTERRUPT_ACK : in std_logic;
        DMA_INTERRUPT : out std_logic;

		WRITE_CFG_EN : in std_logic;
        DATABUS 	: inout std_logic_vector(7 downto 0)
    );
end DMA;

architecture DMA_Behavior of DMA is

    type states is (Idle, ReadFifo, WriteRam, EndWrite, RequestFQC, WriteRamFQC, LoadTransmitter, SendTransmitter, ReleaseDma, Waiting, ReadRAMFQC, SendCfg);
    signal current_state, next_state : states;

    signal byte_counter_rx, byte_counter_tx : unsigned(2 downto 0);
	signal byte_counter_fq	: unsigned(2 downto 0);
	signal ctr_addr_offset : unsigned(7 downto 0);
	--signal tmp_reg : std_logic_vector(7 downto 0);  
   
    signal bytes2send_cfg_reg : unsigned(7 downto 0);
	begin
        DMA_FSM : process(current_state, byte_counter_rx, byte_counter_tx, byte_counter_fq, bytes2send_cfg_reg, ctr_addr_offset, COUNT_OUT, COUNT_RDY, RCVD_DATA, RX_EMPTY, TX_RDY, ACK_OUT, SEND_COMM, SEND_CONF, DMA_ACK, DMA_READ_RDY, DATABUS, INTERRUPT_ACK)
            begin
               DMA_INTERRUPT <= '0';
			   COUNT_REG_ADDR <= "01";
			   COUNT_WR_EN <= '0';
			   
                case current_state is
                    when Idle => 
                        DATA_READ   <= '0';
                        VALID_D     <= '1';

                        ADDRESS     <= (others => '0');
                        WRITE_EN    <= '0';
                        OE          <= '1';
						
					   COUNT_READ	<= '0';
            
                        DMA_RQ      <= '0';

                        if SEND_COMM = '1' or SEND_CONF = '1' then
                            READY <= '0';
                        else
                            READY <= '1';
                        end if;

                        DATABUS     <= (others => 'Z'); -- High impedance while RAM's doing its job

                        if RX_EMPTY = '0' then  --As soon as RS232 stores a command on the FIFO, send it to RAM
                            next_state <= ReadFifo;

                        elsif SEND_COMM = '1' then
                            next_state <= Waiting;
						
						elsif SEND_CONF = '1' then
							next_state <= ReadRAMFQC;
						
						elsif COUNT_RDY = '1' then
							next_state <= RequestFQC;

                        else
                            next_state <= Idle;

                        end if;

                    -- RAM WRITING TASKS
					-- RS232 management
                    when ReadFifo => -- Read byte from FIFO (Put it on RCVD_Data))
                        DATA_READ   <= '1';
                        VALID_D     <= '1';

                        ADDRESS     <= (others => '0');
                        WRITE_EN    <= '0';
                        OE          <= '1';
						
					   COUNT_READ	<= '0';

                        DMA_RQ      <= '1';
                        READY       <= '1';

                        DATABUS     <= (others => 'Z');
           
                        if DMA_ACK = '1' then --Stall until CPU allows me to write to RAM 
                            next_state <= WriteRam;
                        else
                            next_state <= ReadFifo; 
                        end if;

                    when WriteRam => -- Set address, wr_en and place data on databus
                        DATA_READ   <= '0';
                        VALID_D     <= '1';
						
						COUNT_READ	<= '0';
						
                        if byte_counter_rx = 0 then
                            ADDRESS      <= DMA_RX_BUFFER_MSB;
                        elsif byte_counter_rx = 1 then
                            ADDRESS      <= DMA_RX_BUFFER_MID;
                        else
                            ADDRESS      <= DMA_RX_BUFFER_LSB;
            
                        end if;
            
                        WRITE_EN    <= '1';
                        OE          <= '1';

                        DMA_RQ      <= '1';
                        READY       <= '1';
          
                        DATABUS     <= RCVD_DATA;

                        if byte_counter_rx = 0 then
                            next_state   <= Idle;
                        elsif byte_counter_rx = 1 then
                            next_state   <= Idle; 
                        else
                            next_state   <= EndWrite;
                        end if;

                    when EndWrite => -- Launch interrupt to CPU to parse command 
                        
                        DMA_INTERRUPT <= '1';
                        
                        DATA_READ    <= '0';
                        VALID_D      <= '1';
						
					    COUNT_READ	<= '0';
                        
                        ADDRESS <= (others => '0');
                        WRITE_EN <= '0';
                        OE <= '1';
            
                        --DMA_RQ <= '1';
                        DMA_RQ <= '0';
                        READY <= '1';
            
                        DATABUS <= (others => 'Z');

                        if INTERRUPT_ACK = '0' then -- Wait until CPU acks the interrupt
                            next_state <= EndWrite;
                        else 
                            next_state <= Idle; 
                        end if;
						
					-- Count data writing task
					when RequestFQC =>
					    DATA_READ   <= '0';
                        VALID_D     <= '1';
						
						--COUNT_READ	<= '0';

                        ADDRESS     <= (others => '0');
                        WRITE_EN    <= '0';
                        OE          <= '1';

                        DMA_RQ      <= '1';
                        READY       <= '1';

                        DATABUS     <= (others => 'Z');
						
					   if DMA_ACK = '1' then 
							 COUNT_READ	<= '1'; -- This signal is triggered one cycle earlier than it should so that counter manager changes state at the same time as the DMA
                             next_state <= WriteRamFQC;
                        else
						     COUNT_READ	<= '0';
                             next_state <= RequestFQC; -- Nothing happens here until DMA_ACK is OK
                        end if;
					
					when WriteRamFQC =>
						DATA_READ   <= '0';
                        VALID_D     <= '1';
						COUNT_READ	<= '1';
						
						if byte_counter_fq > 0 then
							ADDRESS 	<= std_logic_vector(unsigned(DATA_BASE) + byte_counter_fq - 1 + ctr_addr_offset);
							WRITE_EN    <= '1';
							DATABUS <= COUNT_OUT;
						else
							WRITE_EN <= '0';
							ADDRESS <= (others => '0');
							DATABUS <= (others => 'Z');
						end if;

						 OE          <= '1';

						DMA_RQ      <= '1';
						READY       <= '1';
						
						
						
						if byte_counter_fq < 4 then 
							next_state <= WriteRamFQC; -- I need to enable and disable wr_en to write the count bytes correctly
						else
							next_state <= Idle;
						end if;

                    -- END OF RAM WRITING TASKS. RAM READING TASKS.
					
                    when Waiting =>  -- Wait for transmitter to be idle and prepare RAM reading
                        DATA_READ <= '0';
                        VALID_D <= '1';

                        ADDRESS <= (others => '0');
                        WRITE_EN <= '0';
                        OE <= '1';

                        DMA_RQ <= '0';
                        READY <= '0';
						
						COUNT_READ <= '0';
						
                        DATABUS <= (others => 'Z');
            
                        if TX_RDY = '0' or ACK_OUT = '0' then
                            next_state <= waiting;
                        elsif (byte_counter_tx < bytes2send_cfg_reg) then
                            next_state <= LoadTransmitter;
                        else  --BCTX 4
                            next_state <= ReleaseDma;
                        end if;

                    when LoadTransmitter => -- Orders a RAM reading and loads data to transmitter register
                        -- Pick address and trigger reading
                        VALID_D <= '1';
                        DATA_READ <= '0';
                        
						COUNT_READ <= '0';
						
                        case byte_counter_tx is
                            when "000" =>
                                ADDRESS <= DMA_TX_BUFFER_MSB;
                            when "001" =>
                                ADDRESS <= DMA_TX_BUFFER_MI1;
                            when "010" =>
                                ADDRESS <= DMA_TX_BUFFER_MI2;
                            when "011" =>
                                ADDRESS <= DMA_TX_BUFFER_LSB; 
                            when others =>
                                ADDRESS <= (others => '0'); -- We go latch-free
                        end case;

                        OE <= '0';
                        WRITE_EN <= '0';

                        DMA_RQ <= '0';
                        READY <= '0';    
            
                        DATABUS <= (others => 'Z');
						
						if DMA_READ_RDY = '1' then -- Stall the DMA until RAM delivers the data to the databus
							next_state <= SendTransmitter;
						else
							next_state <= LoadTransmitter;
						end if;
         
                    when SendTransmitter => -- Checks if transmitter is ready and load data to its registers
                        VALID_D <= '0'; -- Fire transmitter
                        DATA_READ <= '0';
						
					    COUNT_READ <= '0';

                        ADDRESS <= (others => '0');
                        OE <= '1';
                        WRITE_EN <= '0';

                        DMA_RQ <= '0';
                        READY <= '0';

                        DATABUS <= (others => 'Z');
                        next_state <= Waiting; 
            
                    when ReleaseDma => --EndDMA
                        VALID_D <= '1';
                        DATA_READ <= '0';
            
                        WRITE_EN <= '0';
            
                        OE <= '1';
                        ADDRESS <= (others => '0');

                        DMA_RQ <= '0';
                        READY <= '1';
						
					   COUNT_READ <= '0';

                        DATABUS <= (others => 'Z');

                        if SEND_COMM = '0' and SEND_CONF = '0' then
                            next_state <= Idle;
                        else
                            next_state <= ReleaseDma;
                        end if;
				
					when ReadRAMFQC =>
						VALID_D <= '1';
                        DATA_READ <= '0';
                        
						COUNT_READ <= '0';
						--APPLY_CFG <= '0';
						
                        case byte_counter_tx is
                            when "000" =>
                                ADDRESS <= FQC_ARMED;
                            when "001" =>
                                ADDRESS <= FQ1_LIM;
                            when "010" =>
                                ADDRESS <= FQ2_LIM;
                            when others =>
                                ADDRESS <= (others => '0'); 
                        end case;

                        OE <= '0';
                        WRITE_EN <= '0';

                        DMA_RQ <= '1';
                        READY <= '0';    
            
                        DATABUS <= (others => 'Z');
						
						if DMA_READ_RDY = '1' then 
							next_state <= SendCfg;
						else
							next_state <= ReadRAMFQC;
						end if;
						
					when SendCfg =>
						VALID_D <= '1';
						DATA_READ <= '0';
						
						COUNT_READ <= '0';

						WRITE_EN <= '0';
						COUNT_WR_EN <= '1';
				
						OE <= '1';
						ADDRESS <= (others => '0');
						DATABUS <= (others => 'Z');
						
						case byte_counter_tx is
							when "001" =>
								COUNT_REG_ADDR <= "01";
							when "010" =>
								COUNT_REG_ADDR <= "10";
							when "011" => 
								COUNT_REG_ADDR <= "11";
							when others =>
								COUNT_REG_ADDR <= "01"; -- Never write to 00. 
						end case;
						
						if (byte_counter_tx < bytes2send_cfg_reg) then
							next_state <= ReadRAMFQC;
						else 
							next_state <= ReleaseDma;
						end if;
						DMA_RQ <= '1';
						READY <= '0'; 
                
                end case;
        end process DMA_FSM;

        DMA_Clocking : process(CLK_PORT, RESET)
            begin
                if (RESET = '0') then
                    byte_counter_tx <= "000";
                    byte_counter_rx <= "000";
				   byte_counter_fq <= "000";
				   ctr_addr_offset <= (others => '0'); 
				   COUNT_CFG <= (others => '0');
                    TX_DATA <= (others => '0');
				   bytes2send_cfg_reg <= X"02"; -- 2 byte default
                    current_state <= Idle;
        
                    elsif CLK_PORT'event and CLK_PORT = '1' then
                    case current_state is
                        when Idle =>
                            TX_DATA <= (others => '0');
							byte_counter_fq <= "000"; -- I set it here as RAM-Writing tasks have no such thing as an end-state
							
							if WRITE_CFG_EN = '1' then
								bytes2send_cfg_reg <= unsigned(DATABUS);
							end if;
						
						when ReadFifo =>
                            TX_DATA <= (others => '0');

                        when WriteRam =>
                            byte_counter_rx <= byte_counter_rx + 1;

                        when EndWrite =>
                            TX_DATA <= (others => '0');
                            byte_counter_rx <= "000";
						
						when RequestFQC =>
							
							
						when WriteRamFQC =>
							if byte_counter_fq = 0 then --Check which counter is selected
								ctr_addr_offset <= shift_left(unsigned(COUNT_OUT) - 1, 2);
							end if;
							byte_counter_fq <= byte_counter_fq + 1;
							
						
                        when Waiting => -- Don't touch transmitter data

            
                        when LoadTransmitter =>
						if DMA_READ_RDY = '1' then
                            TX_DATA <= DATABUS;
                            byte_counter_tx <= byte_counter_tx + 1;
						end if;
                        --    if (byte_counter_tx < 2) then   --If byte_counter_tx = 0
                        --        byte_counter_tx <= byte_counter_tx + 1;   
                        --    else
                        --        byte_counter_tx <= 0;
                        --    end if;
               
                        when SendTransmitter => 

                        when ReleaseDma =>
                            TX_DATA <= (others => '0');
                            byte_counter_tx <= "000";
                        
						
						when ReadRAMFQC =>
							if DMA_READ_RDY = '1' then
								COUNT_CFG <= DATABUS;
								byte_counter_tx <= byte_counter_tx + 1;
							end if;
						when SendCfg =>
							
						end case;
				
                    current_state <= next_state; 
                end if;

        end process DMA_Clocking;


end DMA_Behavior;