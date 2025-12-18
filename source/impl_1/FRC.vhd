library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MEM_pkg.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Descanse en Paz el profesor Mario Garrido

entity FRC is
    Port ( 
        RESET : in std_logic;
        CLK_PORT : in std_logic;
        FAST_CLK_PORT : in std_logic;
        INPUT : in std_logic;
        START : in std_logic;
        FRC_ACK : in std_logic;
        FRC_RQ : out std_logic;
        BUSY_FLAG : out std_logic;
        --COUNTBUS : out std_logic_vector(31 downto 0);
        -- RAM task
        ADDRESS : out std_logic_vector(7 downto 0);
        DATABUS : inout std_logic_vector(7 downto 0);
        WRITE_EN : out std_logic
        );
end FRC;

architecture Counter_Behavior of FRC is
    type states is (Idle, Sync, Busy, Done, WriteRam);
    signal current_state, next_state : states;
    signal count_high, count_low : std_logic_vector(15 downto 0);
	--signal count_cross_r, count_cross_r2 : std_logic_vector(31 downto 0);
    signal count_clear : std_logic;
    signal count_enable : std_logic; --SeÃ±ales de control para la cuenta
    signal elapsed_periods : unsigned(15 downto 0);
    
	constant target : unsigned(15 downto 0) := to_unsigned(100, 16);
    
	signal bytecounter_sv : unsigned(1 downto 0);
	
	-- Doble ff para la sincronización del cruce de dominios de reloj (12 MHz -> 120 MHz)
	signal count_clear_sync_r1, count_clear_sync_r2 : std_logic;
	signal count_enable_sync_r1, count_enable_sync_r2 : std_logic;
	
	-- Doble ff y flags secuenciales para sincronización del cruce de dominios de reloj (120MHz -> 12 MHz)
	signal count_r, count_sync_r : std_logic_vector(31 downto 0);
	signal datasync_ready, datasync_ack : std_logic;
        
    begin
        CTR_FSM : process(current_state, START, elapsed_periods, FRC_ACK, bytecounter_sv, count_sync_r, datasync_ack)
        begin
            DATABUS <= (others => 'Z');
            WRITE_EN <= '0';
            ADDRESS <= (others => '0');
            count_clear <= '0';
            count_enable <= '0';
			
            case current_state is
                when Idle =>
                    BUSY_FLAG <= '0';
                    FRC_RQ <= '0';
                    count_clear <= '1';
                    if START = '1' then 
                        next_state <= Sync;
                    else
                        next_state <= Idle;
                    end if;
					
                when Sync =>
					BUSY_FLAG <= '0';
					FRC_RQ <= '0';
					if elapsed_periods = 0 then
						next_state <= Sync;
					else
						next_state <= Busy;
					end if;
					
                when Busy =>
                    BUSY_FLAG <= '1';
                    FRC_RQ <= '0';
                    count_enable <= '1';
                    if elapsed_periods < target + 1 then
                        next_state <= Busy;
                    else
                        next_state <= Done;
                    end if;
                                    
                when Done =>
                    BUSY_FLAG <= '1'; 
                    FRC_RQ <= '1';
                    if FRC_ACK = '1' and datasync_ack = '1' then
                        next_state <= WriteRam;
                    else
                        next_state <= Done;
                    end if;
                    
                when WriteRam =>
                    BUSY_FLAG <= '1';
                    FRC_RQ <= '1';
                    WRITE_EN <= '1';
                    case bytecounter_sv is
                        when "00" =>
                            ADDRESS <= DATA_BASE;
                            DATABUS <= count_sync_r(31 downto 24);
                            next_state <= WriteRam;
                        when "01" =>
                            ADDRESS <= std_logic_vector(unsigned(DATA_BASE) + 1);
                            DATABUS <= count_sync_r(23 downto 16);
                            next_state <= WriteRam;
                        when "10" =>
                            ADDRESS <= std_logic_vector(unsigned(DATA_BASE) + 2);
                            DATABUS <= count_sync_r(15 downto 8);
                            next_state <= WriteRam;
                        when "11" =>
                            ADDRESS <= std_logic_vector(unsigned(DATA_BASE) + 3);
                            DATABUS <= count_sync_r(7 downto 0);
                            next_state <= Idle;
                        when others => 
                    end case; --Generar la interrupción en el ciclo de bajada de BUSY_FLAG
                
                    
            end case;
        end process CTR_FSM; 
        		
        CTR_Clocking : process(RESET, CLK_PORT)
        begin
            if RESET <= '0' then
                current_state <= Idle;
				--count_cross_r <= (others => '0');
				--count_cross_r2 <= (others => '0');
				count_sync_r <= (others => '0');
               
            elsif CLK_PORT'event and CLK_PORT = '1' then
                case current_state is
                    when Idle =>
                        bytecounter_sv <= "00";
					   datasync_ack <= '0';
					   datasync_ready <= '1'; -- Reseteo los flags del sincronizador de 2 flipflops 
                    when Busy =>
                        bytecounter_sv <= "00";
                    when Done =>
						if datasync_ready = '1' then
							count_sync_r <= count_r; -- Puedo hacer aquí el paso con el handshake
							datasync_ack <= '1';
							datasync_ready <= '0';
						end if;
					when WriteRam =>
                        bytecounter_sv <= bytecounter_sv + 1; --Mantengo valores de ack y ready
				   when others =>
                    
                end case;
                current_state <= next_state;
            end if;
        end process CTR_Clocking;
        
		
        CTR_Count : process(RESET, FAST_CLK_PORT)
        begin
            if RESET <= '0' then
                count_high <= (others => '0');
			    count_low <= (others => '0');
				
				count_enable_sync_r1 <= '0';
				count_enable_sync_r2 <= '0';
				
				count_clear_sync_r1 <= '0';
				count_clear_sync_r2 <= '0';
				
            elsif FAST_CLK_PORT'event and FAST_CLK_PORT = '1' then
                 if count_enable_sync_r2 = '1' then
					count_low <= std_logic_vector(unsigned(count_low) + 1);
					if count_low = X"1111" then
						count_high <= std_logic_vector(unsigned(count_high) + 1);
					end if;
				elsif count_clear_sync_r2 = '1' then
					count_high <= (others => '0');
					count_low <= (others => '0');
				end if;
				-- Sincronizaciones
				count_r(31 downto 16) <= count_high;
				count_r(15 downto 0) <= count_low;
				
				count_enable_sync_r1 <= count_enable;
				count_enable_sync_r2 <= count_enable_sync_r1;
				
				count_clear_sync_r1 <= count_clear;
				count_clear_sync_r2 <= count_clear_sync_r1;
            end if;
        end process CTR_Count;
		
		
		
        CTR_Signal : process(RESET, INPUT)
        begin
            if RESET <= '0' then
                elapsed_periods <= (others => '0');
            elsif INPUT'event and INPUT = '1' then
                if current_state = Busy or current_state = Sync then
                    elapsed_periods <= elapsed_periods + 1;
                else
                    elapsed_periods <= (others => '0');
                end if;
            end if;
        end process CTR_Signal;
    
        --COUNTBUS <= count;

end Counter_Behavior;