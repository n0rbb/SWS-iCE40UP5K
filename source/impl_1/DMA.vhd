----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO - UNIVERSIDAD COMPLUTENSE DE MADRID
-- Engineer: MARIO DE MIGUEL DOMÃNGUEZ
-- 
-- Create Date: 21.04.2025 14:12:17
-- Design Name: SWS DATA MEMORY ACCESS MODULE
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

        DMA_ACK 	: in std_logic;
        SEND_COMM 	: in std_logic;
        DMA_RQ 		: out std_logic;
        READY 		: out std_logic;
		
		COUNT_RDY	: in std_logic;
		COUNT_OUT	: in std_logic_vector(7 downto 0);
		COUNT_READ 	: out std_logic;
		--COUNTER_ACK : out std_logic;
        
        INTERRUPT_ACK : in std_logic;
        DMA_INTERRUPT : out std_logic;

        DATABUS 	: inout std_logic_vector(7 downto 0)
    );
end DMA;

architecture DMA_Behavior of DMA is

    type states is (Idle, ReadFifo, WriteRam, EndWrite, RequestFQC, WriteRamFQC, LoadTransmitter, SendTransmitter, EndTransmitter, Waiting);
    signal current_state, next_state : states;

    signal byte_counter_rx, byte_counter_tx, byte_counter_fq : integer;
   
    begin
        DMA_FSM : process(current_state, byte_counter_rx, byte_counter_tx, byte_counter_fq, COUNT_OUT, RCVD_DATA, RX_EMPTY, TX_RDY, ACK_OUT, SEND_COMM, DMA_ACK, DATABUS, INTERRUPT_ACK)
            begin
                DMA_INTERRUPT <= '0';
                case current_state is
                    when Idle => 
                        DATA_READ   <= '0';
                        VALID_D     <= '1';

                        ADDRESS     <= (others => '0');
                        WRITE_EN    <= '0';
                        OE          <= '1';
						
						COUNT_READ	<= '0';
            
                        DMA_RQ      <= '0';

                        if SEND_COMM = '1' then
                            READY <= '0';
                        else
                            READY <= '1';
                        end if;

                        DATABUS     <= (others => 'Z'); --Pongo en alta impedancia para que la RAM haga lo suyo mientras

                        if RX_EMPTY = '0' then  --Cuando llega algo a la fifo, se escribe a la RAM
                            next_state <= ReadFifo;

                        elsif SEND_COMM = '1' then
                            next_state <= Waiting;
							
						elsif COUNT_RDY = '1' then
							next_state <= RequestFQC;

                        else
                            next_state <= Idle;

                        end if;

                    -- TAREAS DE ESCRITURA EN LA RAM
					-- TAREA DE ATENCIÓN AL RS-232
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
                            next_state <= ReadFifo; --Me parece que aquÃ­ no va a pasar nada hasta que cambie dma ack
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

                    when EndWrite => --Escribe FF en la dirección NEW_INST y genero la interrupción
                        
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

                        if INTERRUPT_ACK = '0' then --ESPERAR A QUE SE CERTIFIQUE LA ATENCIÓN A LA INTERRUPCIÓN
                            next_state <= EndWrite;
                        else 
                            next_state <= Idle; --CAMBIAR A IDLE CUANDO ESTÁ TODO EN ORDEN
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
                            next_state <= RequestFQC; --Me parece que aquÃ­ no va a pasar nada hasta que cambie dma ack
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
							next_state <= WriteRamFQC;
						else
							next_state <= Idle;
						end if;
						
					
					
					
                    -- FIN DE LA TAREA DE ESCRITURA EN RAM. TAREA DE LECTURA DE LA RAM.
                    when Waiting =>  --Estado para comprobar cÃ³mo estÃ¡ el transmisor y preparar la lectura RAM
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
                        elsif (byte_counter_tx < 4) then
                            next_state <= LoadTransmitter;
                        else  --BCTX 4
                            next_state <= EndTransmitter;
                        end if;
            
         
                    when LoadTransmitter => --Ordena la lectura un dato de la memoria al registro de la DMA
                        --Escojo ahora el address y disparo la lectura
                        VALID_D <= '1';
                        DATA_READ <= '0';
                        
						COUNT_READ <= '0';
						
                        case byte_counter_tx is
                            when (0) =>
                                ADDRESS <= DMA_TX_BUFFER_MSB;
                            when (1) =>
                                ADDRESS <= DMA_TX_BUFFER_MI1;
                            when (2) =>
                                ADDRESS <= DMA_TX_BUFFER_MI2;
                            when (3) =>
                                ADDRESS <= DMA_TX_BUFFER_LSB; --Esto pilla para 1 y 2
                            when others =>
                                ADDRESS <= (others => '0'); -- Me libro de este latch
                            
                        end case;

                        OE <= '0';
                        WRITE_EN <= '0';

                        DMA_RQ <= '0';
                        READY <= '0';    
            
                        DATABUS <= (others => 'Z');
                        next_state <= SendTransmitter;
         
                    when SendTransmitter => --Comprueba si el transmisor estÃ¡ ready y manda los datos del registro 
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
            
                    when EndTransmitter =>
                        VALID_D <= '1';
                        DATA_READ <= '0';
            
                        WRITE_EN <= '0';
            
                        OE <= '1';
                        ADDRESS <= (others => '0');

                        DMA_RQ <= '0';
                        READY <= '1';
						
						COUNT_READ <= '0';

                        DATABUS <= (others => 'Z');

                        if SEND_COMM = '0' then
                            next_state <= Idle;
                        else
                            next_state <= EndTransmitter;
                        end if;
                
                end case;
        end process DMA_FSM;

        DMA_Clocking : process(CLK_PORT, RESET)
            begin
                if (RESET = '0') then
                    byte_counter_tx <= 0;
                    byte_counter_rx <= 0;
					byte_counter_fq <= 0;

                    TX_DATA <= (others => '0');
                    current_state <= idle;
        
                    elsif CLK_PORT'event and CLK_PORT = '1' then
                    case current_state is
                        when Idle =>
                            TX_DATA <= (others => '0');
							byte_counter_fq <= 0; --LO HAGO AQUÍ PORQUE NO HAY UN END-STATE PER SE PARA LA RUTINA DE ESCRITURA DEL CONTADOR EN RAM
                        when ReadFifo =>
                            TX_DATA <= (others => '0');

                        when WriteRam =>
                            byte_counter_rx <= byte_counter_rx + 1;

                        when EndWrite =>
                            TX_DATA <= (others => '0');
                            byte_counter_rx <= 0;
						
						when RequestFQC =>
							
							
						when WriteRamFQC =>
							byte_counter_fq <= byte_counter_fq + 1;
						
                        when Waiting => --NO TOCAMOS EL DATO DEL TRANSMISOR

            
                        when LoadTransmitter =>
                            TX_DATA <= DataBus;
                            byte_counter_tx <= byte_counter_tx + 1;
                            
                        --    if (byte_counter_tx < 2) then   --If byte_counter_tx = 0
                        --        byte_counter_tx <= byte_counter_tx + 1;   
                        --    else
                        --        byte_counter_tx <= 0; --No deberÃ­amos llegar nunca
                        --    end if;
               
                        when SendTransmitter => 

                        when EndTransmitter =>
                            TX_DATA <= (others => '0');
                            byte_counter_tx <= 0;
                        end case;

                    current_state <= next_state; 
                end if;

        end process DMA_Clocking;


end DMA_Behavior;