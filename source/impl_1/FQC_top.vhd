library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MEM_PKG.all;
--Unidad de control de los contadores


entity FQC_top is
    Port ( 
        RESET 		: in std_logic;
        CLK_PORT 	: in std_logic;
        INPUT 		: in std_logic;
        START 		: in std_logic;
        --FRC_ACK 	: in std_logic;
        --FRC_RQ    : out std_logic;
        BUSY_FLAG 	: out std_logic;
		
		COUNT_READ 	: in std_logic;
		COUNT_RDY 	: out std_logic;
        COUNT_OUT 	: out std_logic_vector(7 downto 0)
		
        );
end FQC_top;



architecture FQC_Behavior of FQC_top is
	
	component FQCLK is --PLL for the counters
		port(
			ref_clk_i: in std_logic;
			rst_n_i: in std_logic;
			outcore_o: out std_logic;
			outglobal_o: out std_logic
		);
	end component;


	component FQ1 is
		port(
			RESET : in std_logic;
			FAST_CLK_PORT : in std_logic; 
			INPUT : in std_logic;
	
			ENABLE : in std_logic;
			CLEAR : in std_logic;
			
			--READY : out std_logic;
			COUNT_ACK : in std_logic;
			COUNTER_RDY : out std_logic;
	
			COUNT : out std_logic_vector(31 downto 0)
		);
	end component FQ1;

    type states is (Idle, RunCounter, ReadCounter, SendDma);
	signal current_state, next_state : states;
	signal clk_120_mhz, clk_120_mhz_core : std_logic;
	signal count_clear, count_enable : std_logic;
	signal counter_ready, counter_ack : std_logic;
	
	signal counter_rdy_sync_r1, counter_rdy_sync_r2 : std_logic;
	
	signal count : std_logic_vector(31 downto 0);
	signal count_r1, count_r2, count_r3, count_r4 : std_logic_vector(7 downto 0);
	signal count_ready : std_logic;
	
	signal counter_status_r : std_logic; --Registro que indica quÃƒÂ© contadores estÃƒÂ¡n funcionando
	
	signal bytecounter_sv : unsigned(1 downto 0);
  
    begin
		
		FQ_PLL : FQCLK 
			port map(
				ref_clk_i	   => CLK_PORT,
				rst_n_i		   => RESET,
				outcore_o      => clk_120_mhz_core,
				outglobal_o    => clk_120_mhz
		);
		
		FQ_CTR1 : FQ1
			port map(
				RESET			=> RESET,
				FAST_CLK_PORT 	=> clk_120_mhz,
				INPUT 			=> INPUT,
				CLEAR 			=> count_clear,
				ENABLE 			=> count_enable,
				COUNTER_RDY		=> counter_ready,
				COUNT_ACK 		=> counter_ack,
				COUNT 			=> count
		);
		
		--clear <= not(RESET);
		BUSY_FLAG <= counter_status_r;
		COUNT_RDY <= count_ready;
		
		CTR_TOP_CDC : process(CLK_PORT) -- The same as in the freq counters, we synchronise incoming singnals
		begin
			if CLK_PORT'event and CLK_PORT = '1' then
				counter_rdy_sync_r1 <= counter_ready;
				counter_rdy_sync_r2 <= counter_rdy_sync_r1;
			end if;
		
		end process CTR_TOP_CDC;
	
        CTR_FSM : process(current_state, START, counter_ready, count_ready, counter_ack, bytecounter_sv, COUNT_READ, count_r1, count_r2, count_r3, count_r4)
        begin
			COUNT_OUT <= (others => '0');
            count_clear <= '0';
            count_enable <= '0';
			
			
            case current_state is
                when Idle =>
                    --BUSY_FLAG <= '0';
                    --count_clear <= '1';
                    if START = '1' then 
                        next_state <= RunCounter;
                    elsif counter_ready = '1' and count_ready <= '0' then --Si no se ha guardado la lectura anterior en la ram, no se lee nada
						next_state <= ReadCounter;
					elsif COUNT_READ = '1' then 
						next_state <= SendDma;
					else
                        next_state <= Idle;
                    end if;
				
				when RunCounter =>
					count_enable <= '1';
					next_state <= Idle;
				
                when ReadCounter =>
					if counter_ack = '1' then
                        next_state <= Idle;
                    else
                        next_state <= ReadCounter;
                    end if;
                    
						
				when SendDma =>
					count_clear <= '1';
					case bytecounter_sv is
						when "00" =>
							COUNT_OUT <= count_r1;
						when "01" =>
							COUNT_OUT <= count_r2;
						when "10" =>
							COUNT_OUT <= count_r3;
						when others =>
							COUNT_OUT <= count_r4;
					end case;
						
					if bytecounter_sv = "11" then
						next_state <= Idle;
					else
						next_state <= SendDma;
					end if;

				when others =>
            end case;
        end process CTR_FSM; 
        		
        CTR_Clocking : process(RESET, CLK_PORT)
        begin
            if RESET <= '0' then
                current_state <= Idle;
				count_ready <= '0';
				count_r1 <= (others => '0');
				count_r2 <= (others => '0');
				count_r3 <= (others => '0');
				count_r4 <= (others => '0');
               
            elsif CLK_PORT'event and CLK_PORT = '1' then
                case current_state is
                    when Idle =>
						counter_ack <= '0';
						bytecounter_sv <= "00";
						
                    when RunCounter => -- Nuthin'
                        counter_status_r <= '1';
                    
					when ReadCounter =>
						if counter_ack = '0' then
							count_r1 <= count(7 downto 0);  --Leo la cuenta y la guardo en registros
							count_r2 <= count(15 downto 8);
							count_r3 <= count(23 downto 16);
							count_r4 <= count(31 downto 24);
							
							counter_ack <= '1'; --Paso el handshake
							count_ready <= '1'; --Aviso a la DMA
						end if;
						
					when SendDma =>
                        bytecounter_sv <= bytecounter_sv + 1; --Mantengo valores de ack y ready
						if bytecounter_sv = 3 then
							counter_status_r <= '0';
							count_ready <= '0';
						end if;
				   when others =>
                    
                end case;
				counter_status_r <= counter_ready;
                current_state <= next_state;
            end if;
        end process CTR_Clocking;
        
		
        
    
        --COUNTBUS <= count;

end FQC_Behavior;