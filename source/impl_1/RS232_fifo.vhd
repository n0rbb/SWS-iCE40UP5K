----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO
-- Engineer: MARIO DE MIGUEL DOMÃNGUEZ
-- 
-- Create Date: 25.06.2025 12:05:27
-- Design Name: RS232-FIFO Memory module
-- Module Name: RS232_fifo - FIFO_behavior
-- Project Name: SWS 
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
use work.MEM_pkg.ALL; -- Solo voy a usar los tipos para hacer un array de bytes

entity RS232_fifo is
	port(
	        RESET      	: in  std_logic;
            CLK_PORT  	: in  std_logic;

            WR_EN      	: in  std_logic;
            DIN       	: in  std_logic_VECTOR(7 downto 0);

            RD_EN     	: in  std_logic;
            DOUT      	: out std_logic_VECTOR(7 downto 0);

            FULL      	: out std_logic;
            EMPTY      	: out std_logic
		);
end RS232_fifo;

architecture Fifo_Behaviour of RS232_fifo is
	signal count : unsigned(2 downto 0);
	signal contents_fifo : array8_regs(3 downto 0);
	signal write_ptr, read_ptr : unsigned(1 downto 0);
	signal full_s, empty_s : std_logic;
	begin 
        Fifo_status : process(count) -- Generar Flags
        begin 
            empty_s <= '0';
            full_s <= '0';
            if count = 0 then
                empty_s <= '1';
                
            elsif count = 4 then
                full_s <= '1';
            end if;
            
        end process Fifo_status;
        
        FULL <= full_s;
        EMPTY <= empty_s;
        
        Fifo_RW : process(RESET, CLK_PORT)
        begin
            if RESET = '0' then
                DOUT <= (others => '0');
                count <= (others => '0');
                write_ptr <= "00";
                read_ptr <= "00";
                contents_fifo(0) <= X"00";
                contents_fifo(1) <= X"00";
                contents_fifo(2) <= X"00";
                contents_fifo(3) <= X"00";
                
            elsif CLK_PORT'event and CLK_PORT = '1' then
            
                if WR_EN = '1' and RD_EN = '1' then
                    contents_fifo(to_integer(write_ptr)) <= DIN;
                    DOUT <= contents_fifo(to_integer(read_ptr));
                    write_ptr <= (write_ptr + 1) and "11";
                    read_ptr  <= (read_ptr + 1) and "11";
                    
                elsif WR_EN = '1' and full_s = '0' then
                    -- Overwrite at write_pointer
                    contents_fifo(to_integer(write_ptr)) <= DIN;
                    write_ptr <= (write_ptr + 1) and "11"; -- write_ptr + 1 % 4
                    
                    -- Modificar cuenta
                    if count = 4 then
                        count <= "100";
                    else 
                        count <= count + 1;
                    end if;
                
                elsif RD_EN = '1' and empty_s = '0' then 
                    --Sacar 1 dato de la FIFO
                    DOUT <= contents_fifo(to_integer(read_ptr));
                    read_ptr <= (read_ptr + 1) and "11";
                    
                    --Actualizar contadores
                    if count = 0 then
                        count <= (others => '0');
                    else 
                        count <= count - 1;
                    end if;
                end if;
            end if;
        end process Fifo_RW;
end Fifo_Behaviour;
 