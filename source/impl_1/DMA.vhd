----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO - UNIVERSIDAD COMPLUTENSE DE MADRID
-- Engineer: MARIO DE MIGUEL DOMINGUEZ
-- 
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
		SEND_CONF	: in std_logic; --SeÃƒÂ±al de control de la CPU para configurar el perifÃƒÂ©rico. 
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

    signal byte_counter_rx, byte_counter_tx, byte_counter_fq : unsigned(2 downto 0);
	--signal tmp_reg : std_logic_vector(7 downto 0); --AquÃƒÂ­ voy a capturar el address. 
   
    signal bytes2send_cfg_reg : unsigned(7 downto 0);
	begin
        DMA_FSM : process(current_state, byte_counter_rx, byte_counter_tx, byte_counter_fq, COUNT_OUT, COUNT_RDY, RCVD_DATA, RX_EMPTY, TX_RDY, ACK_OUT, SEND_COMM, SEND_CONF, DMA_ACK, DMA_READ_RDY, DATABUS, INTERRUPT_ACK)
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

                        DATABUS     <= (others => 'Z'); --Pongo en alta impedancia para que la RAM haga lo suyo mientras

                        if RX_EMPTY = '0' then  --Cuando llega algo a la fifo, se escribe a la RAM
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

                    -- TAREAS DE ESCRITURA EN LA RAM
					-- TAREA DE ATENCIÃƒâ€œN AL RS-232
                    when ReadFifo => --Lectura del dato de la fifo (pongo el dato en RCVD_Data al disparar la fifo)
                        DATA_READ   <= '1';
                        VALID_D     <= '1';

                        ADDRESS     <= (others => '0');
                        WRITE_EN    <= '0';
                        OE          <= '1';
						
					   COUNT_READ	<= '0';

                        DMA_RQ      <= '1';
                        READY       <= '1';

                        DATABUS     <= (others => 'Z');
           
                        if DMA_ACK = '1' then --Solo cuando me han concedido los buses, leo y paso a la escritura. Si no, me quedo iterando.
                            next_state <= WriteRam;
                        else
                            next_state <= ReadFifo; --Me parece que aquÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­ no va a pasar nada hasta que cambie dma ack
                        end if;

                    when WriteRam => --Pongo address, write_en y dato del registro en el databus
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
                            next_state   <= Idle; --Cambiar por idle 
                        else
                            next_state   <= EndWrite;
                        end if;

                    when EndWrite => --Escribe FF en la direcciÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â³n NEW_INST y genero la interrupciÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â³n
                        
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

                        if INTERRUPT_ACK = '0' then --ESPERAR A QUE SE CERTIFIQUE LA ATENCIÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“N A LA INTERRUPCIÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“N
                            next_state <= EndWrite;
                        else 
                            next_state <= Idle; --CAMBIAR A IDLE CUANDO ESTÃƒÂ TODO EN ORDEN
                        end if;
						
					-- TAREA DE ESCRITURA DE LOS DATOS DE CUENTA
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
							COUNT_READ	<= '1'; -- Subo esto un flanco antes para que el gestor de contadores cambie de estado a la vez que la dma
                             next_state <= WriteRamFQC;
                        else
						    COUNT_READ	<= '0';
                             next_state <= RequestFQC; --Me parece que aquÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­ no va a pasar nada hasta que cambie dma ack
                        end if;
					
					when WriteRamFQC =>
						DATA_READ   <= '0';
                        VALID_D     <= '1';
						COUNT_READ	<= '1';
						
						ADDRESS 	<= std_logic_vector(unsigned(DATA_BASE) + byte_counter_fq);
                        WRITE_EN    <= '1';
                        OE          <= '1';

                        DMA_RQ      <= '1';
                        READY       <= '1';
						
						DATABUS <= COUNT_OUT;
						
						if byte_counter_fq < 3 then
							next_state <= WriteRamFQC; -- Necesito subir y bajar wr_en para leer correctamente los bytes de cuenta
						else
							next_state <= Idle;
						end if;

                    -- FIN DE LA TAREA DE ESCRITURA EN RAM. TAREA DE LECTURA DE LA RAM.
                    when Waiting =>  --Estado para comprobar cÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â³mo estÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ el transmisor y preparar la lectura RAM
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

                    when LoadTransmitter => --Ordena la lectura un dato de la memoria al registro de la DMA
                        --Escojo ahora el address y disparo la lectura
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
                                ADDRESS <= DMA_TX_BUFFER_LSB; --Esto pilla para 1 y 2
                            when others =>
                                ADDRESS <= (others => '0'); -- Me libro de este latch
                        end case;

                        OE <= '0';
                        WRITE_EN <= '0';

                        DMA_RQ <= '0';
                        READY <= '0';    
            
                        DATABUS <= (others => 'Z');
						
						if DMA_READ_RDY = '1' then --Atasco el estado hasta que sÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â© que la RAM puso el dato en el databus
							next_state <= SendTransmitter;
						else
							next_state <= LoadTransmitter;
						end if;
         
                    when SendTransmitter => --Comprueba si el transmisor estÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ ready y manda los datos del registro 
                        VALID_D <= '0'; --Disparo el transmisor.
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
								COUNT_REG_ADDR <= "01"; -- Nunca escribo en 00. 
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
				   COUNT_CFG <= (others => '0');
                    TX_DATA <= (others => '0');
				   bytes2send_cfg_reg <= X"02"; -- Por defecto dos bytes
                    current_state <= Idle;
        
                    elsif CLK_PORT'event and CLK_PORT = '1' then
                    case current_state is
                        when Idle =>
                            TX_DATA <= (others => '0');
							byte_counter_fq <= "000"; --LO HAGO AQUÍ PORQUE NO HAY UN END-STATE PER SE PARA LA RUTINA DE ESCRITURA DEL CONTADOR EN RAM
							
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
							byte_counter_fq <= byte_counter_fq + 1;
						
                        when Waiting => --NO TOCAMOS EL DATO DEL TRANSMISOR

            
                        when LoadTransmitter =>
						if DMA_READ_RDY = '1' then
                            TX_DATA <= DATABUS;
                            byte_counter_tx <= byte_counter_tx + 1;
						end if;
                        --    if (byte_counter_tx < 2) then   --If byte_counter_tx = 0
                        --        byte_counter_tx <= byte_counter_tx + 1;   
                        --    else
                        --        byte_counter_tx <= 0; --No deberÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­amos llegar nunca
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