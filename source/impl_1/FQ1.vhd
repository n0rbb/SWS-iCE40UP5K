----------------------------------------------------------------------------------
-- Engineer: MARIO DE MIGUEL 
-- Create Date: 21.12.2025 14:12:17
-- Design Name: SWS COUNTER INSTANCE
-- Module Name: FQ1 - Count_Me_Up 
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
	
	TARGET : in std_logic_vector(7 downto 0);
	TARGET_UPDATE : in std_logic;
	TARGET_UPDATE_ACK : out std_logic;
	
	--READY : out std_logic;
	COUNT_ACK : in std_logic;
	COUNTER_RDY : out std_logic;
	COUNTER_READ : in std_logic;
	
	COUNT : out std_logic_vector(31 downto 0)
);
end FQ1;

architecture Count_Me_Up of FQ1 is

type states is (Idle, Sync, Busy, Done);
signal current_state, next_state : states;

signal busy_flag, busy_flag_reg1, busy_flag_reg2, busy_flag_reg3, busy_flag_reg4 : std_logic; --4 Staged
signal start_counter : std_logic;
signal sync_flag, sync_flag_reg : std_logic;

signal count_r : std_logic_vector(31 downto 0);
--signal count_sg	: unsigned(31 downto 0);
signal count_low, count_mid1, count_mid2, count_high : unsigned(7 downto 0);
signal count_low_done, count_mid1_done, count_mid2_done : std_logic;
signal count_mid1_carry, count_mid2_carry, count_high_carry : unsigned(0 downto 0);

--signal target : unsigned(15 downto 0) := to_unsigned(100, 16);
signal elapsed_periods : unsigned(7 downto 0);

signal count_clear_sync_r1, count_clear_sync_r2 : std_logic;
signal count_clear_reg1, count_clear_reg2, count_clear_reg3 : std_logic; --3 Staged
signal count_enable_sync_r1, count_enable_sync_r2 : std_logic;

signal count_read_sync_r1, count_read_sync_r2 : std_logic;

--signal target_sync_r1, target_sync_r2 : unsigned(7 downto 0);
signal target_reg : unsigned(7 downto 0);
signal target_update_r1, target_update_r2 : std_logic;
signal target_update_ack_r : std_logic;
signal target_reached, target_reached_h1, target_reached_h2 : std_logic;

signal count_ack_sync_r1, count_ack_sync_r2 : std_logic;


--Some directives for synthesis
attribute dont_touch : string;
attribute dont_touch of count_high : signal is "true";
attribute dont_touch of count_mid2 : signal is "true";
attribute dont_touch of count_mid1 : signal is "true";
attribute dont_touch of count_low  : signal is "true";

--attribute dont_touch of busy_flag_reg1 : signal is "true";
--attribute dont_touch of busy_flag_reg2 : signal is "true";
--attribute dont_touch of busy_flag_reg3 : signal is "true";

--And for the FSM not to have too much delay with the setting of the next_state
--attribute enum_encoding : string;
--attribute enum_encoding of states : type is "0001 0010 0100 1000"; 
begin
		
		CTR_CDC : process(RESET, FAST_CLK_PORT) --Process to manage the changes in clock domains (control signals and ack)
		begin
			if RESET = '0' then
				count_enable_sync_r1 <= '0';
				count_enable_sync_r2 <= '0';
				
				count_clear_sync_r1 <= '0';
				count_clear_sync_r2 <= '0';
				
				target_reg <= to_unsigned(100, 8);
				--target_sync_r2 <= to_unsigned(100, 8);
				target_update_ack_r <= '0';
				
				target_update_r1 <= '0';
				target_update_r2 <= '0';
				
			
			elsif FAST_CLK_PORT'event and FAST_CLK_PORT = '1' then
				count_clear_sync_r1 <= CLEAR;
				count_clear_sync_r2 <= count_clear_sync_r1;
			
				count_enable_sync_r1 <= ENABLE;
				count_enable_sync_r2 <= count_enable_sync_r1;
			
				count_ack_sync_r1 <= COUNT_ACK;
				count_ack_sync_r2 <= count_ack_sync_r1;
				
				--target_sync_r1 <= unsigned(TARGET_REG);
				
				-- Update targets
				target_update_r1 <= TARGET_UPDATE;
				target_update_r2 <= target_update_r1;
				
				if target_update_r2 = '1' and target_update_ack_r = '0' then
					target_reg <= unsigned(TARGET);
					target_update_ack_r <= '1';
				elsif target_update_r2 = '0' and target_update_ack_r = '1' then
					target_update_ack_r <= '0';
				end if;
				
            end if;
		end process CTR_CDC;

		CTR_FSM : process(current_state, count_read_sync_r2, count_enable_sync_r2, count_ack_sync_r2, elapsed_periods, count_r, target_reached, target_update_ack_r)
		begin
			TARGET_UPDATE_ACK <= target_update_ack_r;
			busy_flag <= '0';
			sync_flag <= '0';
			case current_state is 
				when Idle =>
					COUNTER_RDY <= '0';
					COUNT <= (others => 'Z');
					if count_enable_sync_r2 = '1' then 
						next_state <= Sync;
					else
						next_state <= Idle;
					end if;
				
				when Sync =>
					sync_flag <= '1';
					COUNTER_RDY <= '0';
					COUNT <= (others => 'Z');
					
					if elapsed_periods > 0 then
						next_state <= Busy;
					else
						next_state <= Sync;
					end if;
				
				when Busy =>
					busy_flag <= '1';
					COUNTER_RDY <= '0';
					COUNT <= (others => 'Z');
					if target_reached = '1' then
						next_state <= Done;
					else
						next_state <= Busy;
					end if;
				
				when Done => 
					COUNTER_RDY <= '1';
					
					if count_read_sync_r2 = '1' then 
						COUNT <= count_r;
					else
						COUNT <= (others => 'Z');
					end if;
					
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
				
				busy_flag_reg1 <= '0';
				busy_flag_reg2 <= '0';
				busy_flag_reg3 <= '0';
				busy_flag_reg4 <= '0';
				
				sync_flag_reg <= '0';
				
				count_read_sync_r1 <= '0';
				count_read_sync_r2 <= '0';
				
				target_reached <= '0';
				target_reached_h1 <= '0';
				target_reached_h2 <= '0';
				
			elsif FAST_CLK_PORT'event and FAST_CLK_PORT = '1' then
				if count_clear_sync_r2 = '1' then
					--count_sg <= (others => '0');
					count_low <= (others => '0');
					count_low_done <= '0';
					count_mid1_carry <= "0";
					
				end if;	
				
				if count_clear_reg1 = '1' then
					count_mid1 <= (others => '0');
					count_mid1_done <= '0';
					count_mid2_carry <= "0";
					
				end if;	
				
				if count_clear_reg2 = '1' then
					count_mid2 <= (others => '0');
					count_mid2_done <= '0';
					count_high_carry <= "0";
				end if;
				
				if count_clear_reg3 = '1' then
					count_high <= (others => '0');
					
					target_reached <= '0';
					target_reached_h1 <= '0';
					target_reached_h2 <= '0';
				end if;
				
				if busy_flag_reg1 = '1' and start_counter = '1' then --Force 2 clock cycle delay on start for the count to end correctly when target is reached
					--count_sg <= count_sg + 1;
					count_low <= count_low + 1; -- Update low counter
					
					--Carry management
					if count_low = X"FD" then
						count_low_done <= '1'; -- I check the carry 2 cycles before I should because this flag reaches 2 cycles afterwards
					else
						count_low_done <= '0';
					end if;
					
					count_mid1_carry <= (0 => count_low_done);
				end if;
				
				if busy_flag_reg2 = '1' then
					count_mid1 <= count_mid1 + count_mid1_carry;
					
					if count_mid1 = X"FD" then
						count_mid1_done <= '1';
					else
						count_mid1_done <= '0';
					end if;
					
					count_mid2_carry <= (0 => count_mid1_done);
				end if;
					
				if busy_flag_reg3 = '1' then  --High end of counter
					
					count_mid2 <= count_mid2 + count_mid2_carry;
					
					if count_mid2 = X"FD" then
						count_mid2_done <= '1';
					else
						count_mid2_done <= '0';
					end if;
					
					count_high_carry <= (0 => count_mid2_done);
				end if;
				
				if busy_flag_reg4 = '1' then
					
					count_high <= count_high + count_high_carry; --Update high_counter
					
				-- Target checking management
					if elapsed_periods(3 downto 0) > target_reg(3 downto 0) then
						target_reached_h1 <= '1';
					else
						target_reached_h1 <= '0';
					end if;	
					
					if elapsed_periods(7 downto 4) = target_reg(7 downto 4) then
						target_reached_h2 <= '1';
					else
						target_reached_h2 <= '0';
					end if;
					
					if target_reached_h1 = '1' and target_reached_h2 = '1' then
						target_reached <= '1';
					else
						target_reached <= '0';
					end if;
				end if;
						
				count_r(31 downto 24) <= std_logic_vector(count_high);
				count_r(23 downto 16) <= std_logic_vector(count_mid2);
				count_r(15 downto 8) <= std_logic_vector(count_mid1);
				count_r(7 downto 0) <= std_logic_vector(count_low);
				
				--count_r <= std_logic_vector(count_sg);
				-- Move the states
				current_state <= next_state;
				busy_flag_reg1 <= busy_flag;
				busy_flag_reg2 <= busy_flag_reg1;
				busy_flag_reg3 <= busy_flag_reg2;
				busy_flag_reg4 <= busy_flag_reg3;
				sync_flag_reg <= sync_flag;
				
				start_counter <= busy_flag_reg2;
				
				count_clear_reg1 <= count_clear_sync_r2;
				count_clear_reg2 <= count_clear_reg1;
				count_clear_reg3 <= count_clear_reg2;
				
				count_read_sync_r1 <= COUNTER_READ;
				count_read_sync_r2 <= count_read_sync_r1;
				
			end if;
        end process CTR_Count;
		
		
		
		CTR_Signal : process(RESET, INPUT)
		begin
            if RESET = '0' then
                elapsed_periods <= (others => '0');
            elsif INPUT'event and INPUT = '1' then
                if busy_flag_reg1 = '1' or sync_flag_reg = '1' then
                    elapsed_periods <= elapsed_periods + 1;
                else
                    elapsed_periods <= (others => '0');
                end if;
            end if;
		end process CTR_Signal;
end Count_Me_Up;