library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.MEM_PKG.all;

entity FQ1 is 
port(
	RESET	: in std_logic;
	FAST_CLK_PORT : in std_logic; -- This will all operate at 120 MHz
	
	INPUT : in std_logic;
	
	ENABLE : in std_logic;
	CLEAR : in std_logic;
	
	TARGET_REG : in std_logic_vector(7 downto 0);
	
	--READY : out std_logic;
	COUNT_ACK : in std_logic;
	COUNTER_RDY : out std_logic;
	
	COUNT : out std_logic_vector(31 downto 0)
);
end FQ1;

architecture Count_Me_Up of FQ1 is

type states is (Idle, Sync, Busy, Done);
signal current_state, next_state : states;

signal busy_flag, busy_flag_reg : std_logic;
signal sync_flag, sync_flag_reg : std_logic;

signal count_r : std_logic_vector(31 downto 0);
--signal count_sg	: unsigned(31 downto 0);
signal count_low, count_mid1, count_mid2, count_high : unsigned(7 downto 0);
signal count_low_done, count_mid1_done, count_mid2_done : std_logic;
signal count_mid1_carry, count_mid2_carry, count_high_carry : unsigned(0 downto 0);

--signal target : unsigned(15 downto 0) := to_unsigned(100, 16);
signal elapsed_periods : unsigned(7 downto 0);

signal count_clear_sync_r1, count_clear_sync_r2 : std_logic;
signal count_enable_sync_r1, count_enable_sync_r2 : std_logic;

signal target_sync_r1, target_sync_r2 : unsigned(7 downto 0);

signal count_ack_sync_r1, count_ack_sync_r2 : std_logic;


--Some directives for synthesis
attribute dont_touch : string;
attribute dont_touch of count_high : signal is "true";
attribute dont_touch of count_mid2 : signal is "true";
attribute dont_touch of count_mid1 : signal is "true";
attribute dont_touch of count_low	  : signal is "true";
begin
		
		CTR_CDC : process(RESET, count_clear_sync_r2, FAST_CLK_PORT) --Process to manage the changes in clock domains (control signals and ack)
		begin
			if RESET = '0' then
				count_enable_sync_r1 <= '0';
				count_enable_sync_r2 <= '0';
				
				count_clear_sync_r1 <= '0';
				count_clear_sync_r2 <= '0';
				
				target_sync_r1 <= to_unsigned(100, 8);
				target_sync_r2 <= to_unsigned(100, 8);
				
			
			elsif FAST_CLK_PORT'event and FAST_CLK_PORT = '1' then
				count_clear_sync_r1 <= CLEAR;
				count_clear_sync_r2 <= count_clear_sync_r1;
			
				count_enable_sync_r1 <= ENABLE;
				count_enable_sync_r2 <= count_enable_sync_r1;
			
				count_ack_sync_r1 <= COUNT_ACK;
				count_ack_sync_r2 <= count_ack_sync_r1;
				
				target_sync_r1 <= unsigned(TARGET_REG);
				target_sync_r2 <= target_sync_r1;
            end if;
		end process CTR_CDC;

		CTR_FSM : process(current_state, count_enable_sync_r2, count_ack_sync_r2, elapsed_periods, count_r, target_sync_r2)
		begin
			busy_flag <= '0';
			sync_flag <= '0';
			case current_state is 
				when Idle =>
					COUNTER_RDY <= '0';
					COUNT <= (others => '0');
					if count_enable_sync_r2 = '1' then 
						next_state <= Sync;
					else
						next_state <= Idle;
					end if;
				
				when Sync =>
					sync_flag <= '1';
					COUNTER_RDY <= '0';
					COUNT <= (others => '0');
					
					if elapsed_periods > 0 then
						next_state <= Busy;
					else
						next_state <= Sync;
					end if;
				
				when Busy =>
					busy_flag <= '1';
					COUNTER_RDY <= '0';
					COUNT <= (others => '0');
					if elapsed_periods > target_sync_r2 then
						next_state <= Done;
					else
						next_state <= Busy;
					end if;
				
				when Done => 
					COUNTER_RDY <= '1';
					COUNT <= count_r;
					if count_ack_sync_r2 = '1' then
						next_state <= Idle;
					else
						next_state <= Done;
					end if;
			end case;
			
		
		end process CTR_FSM;


		CTR_Count : process(RESET, FAST_CLK_PORT)
        begin
            if RESET = '0' then 
				current_state <= Idle;
				count_low <= (others => '0');
				count_mid1 <= (others => '0');
				count_mid2 <= (others => '0');
				count_high <= (others  => '0');
				
				count_low_done <= '0';
				count_mid1_done <= '0';
				count_mid2_done <= '0';
				
				count_mid1_carry <= "0";
				count_mid2_carry <= "0";
				count_high_carry <= "0";
				--count_sg <= (others => '0');
				count_r <= (others => '0');
				
				busy_flag_reg <= '0';
				sync_flag_reg <= '0';
				
			elsif FAST_CLK_PORT'event and FAST_CLK_PORT = '1' then
				if count_clear_sync_r2 = '1' then
					--count_sg <= (others => '0');
					count_low <= (others => '0');
					count_mid1 <= (others => '0');
					count_mid2 <= (others => '0');
					count_high <= (others => '0');
					
					
					count_low_done <= '0';
					count_mid1_done <= '0';
					count_mid2_done <= '0';
					
					count_mid1_carry <= "0";
					count_mid2_carry <= "0";
					count_high_carry <= "0";
									elsif busy_flag_reg = '1' then
					--count_sg <= count_sg + 1;
					
					--Carry management
					if count_low = X"FD" then
						count_low_done <= '1'; -- I check the carry 2 cycles before I should because this flag reaches 2 cycles afterwards
					else
						count_low_done <= '0';
					end if;
					
					if count_mid1 = X"FD" then
						count_mid1_done <= '1';
					else
						count_mid1_done <= '0';
					end if;
					
					if count_mid2 = X"FD" then
						count_mid2_done <= '1';
					else
						count_mid2_done <= '0';
					end if;
					
					count_mid1_carry <= (0 => count_low_done);
					count_mid2_carry <= (0 => count_mid1_done);
					count_high_carry <= (0 => count_mid2_done);
					
					count_low <= count_low + 1; -- Update low counter
					count_mid1 <= count_mid1 + count_mid1_carry;
					count_mid2 <= count_mid2 + count_mid2_carry;
					count_high <= count_high + count_high_carry; --Update high_counter
					
				end if;
				
				count_r(31 downto 24) <= std_logic_vector(count_high);
				count_r(23 downto 16) <= std_logic_vector(count_mid2);
				count_r(15 downto 8) <= std_logic_vector(count_mid1);
				count_r(7 downto 0) <= std_logic_vector(count_low);
				
				--count_r <= std_logic_vector(count_sg);
				-- Move the states
				current_state <= next_state;
				busy_flag_reg <= busy_flag;
				sync_flag_reg <= sync_flag;
			end if;
        end process CTR_Count;
		
		
		
		CTR_Signal : process(RESET, INPUT)
		begin
            if RESET = '0' then
                elapsed_periods <= (others => '0');
            elsif INPUT'event and INPUT = '1' then
                if busy_flag_reg = '1' or sync_flag_reg = '1' then
                    elapsed_periods <= elapsed_periods + 1;
                else
                    elapsed_periods <= (others => '0');
                end if;
            end if;
		end process CTR_Signal;
end Count_Me_Up;