
----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO - UNIVERSIDAD COMPLUTENSE DE MADRID
-- Engineer: MARIO DE MIGUEL DOMÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚ÂNGUEZ
-- 
-- Create Date: 21.04.2025 12:23:02
-- Design Name: SPIN-WAVE SENSOR SPARTAN TOP
-- Module Name: SWS_top - SWS_top_Behavior
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
use work.INST_pkg.ALL;


entity SWS_top is
    port (
        CLK_PORT    : in std_logic;
        RESET       : in std_logic;
        
        RS232_RX    : in std_logic;
        RS232_TX    : out std_logic;
        
        --LED_PORT    : out std_logic_vector(2 downto 0);
        INPUT_FRQ   : in std_logic_vector(1 downto 0)
    );
end SWS_top;

architecture SWS_top_Behavior of SWS_top is

    -- Component declaration
    -- RS232
    
    component RS232 is
        port (
            CLK_PORT    : in  std_logic;
            RESET       : in  std_logic;
      
            DATA_IN     : in  std_logic_vector(7 downto 0);
            VALID_D     : in  std_logic;
            ACK_IN      : out std_logic;
            TX_RDY      : out std_logic;
      
            RD          : in  std_logic;
            TD          : out std_logic;

            DATA_READ   : in  std_logic;
            DATA_OUT    : out std_logic_vector(7 downto 0);
            
            FULL        : out std_logic;
            EMPTY       : out std_logic
        );
    end component;

    -- Direct-Memory Access
    component DMA is
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
			SEND_CONF	: in std_logic;
            DMA_RQ 		: out std_logic;
            READY 		: out std_logic;	
			
			COUNT_RDY	: in std_logic;
			COUNT_OUT	: in std_logic_vector(7 downto 0);
			COUNT_READ	: out std_logic;
			COUNT_CFG	: out std_logic_vector(7 downto 0);
			COUNT_REG_ADDR : out std_logic_vector(1 downto 0);
			COUNT_WR_EN	: out std_logic;
            
            INTERRUPT_ACK : in std_logic;
            DMA_INTERRUPT : out std_logic;
			
			WRITE_CFG_EN  : in std_logic;
            DATABUS 	: inout std_logic_vector(7 downto 0)
        );
    end component;

    -- RAM
    --component RAM is
        --port(
            --CLK_PORT    : in std_logic;
            --RESET       : in std_logic;

            --WRITE_EN    : in std_logic;
            --OE          : in std_logic;

            --ADDRESS     : in std_logic_vector(7 downto 0);
            --DATABUS     : inout std_logic_vector(7 downto 0)
            
         --   LED_STAT    : out std_logic_vector(2 downto 0)
        --);
    --end component;
	
	component RAM is
		port(
			clk_i		: in std_logic;
			rst_i		: in std_logic;
			
			wr_en_i		: in std_logic;
			clk_en_i	: in std_logic;
			
			addr_i 		: in std_logic_vector(5 downto 0);
			wr_data_i	: in std_logic_vector(7 downto 0);
			rd_data_o	: out std_logic_vector(7 downto 0)
		);
	end component;

    
    component ALU is
        port(
            CLK_PORT       : in std_logic;
            RESET          : in std_logic;
  
            ALU_OP         : in alu_op_t;
  
            INDEX_REG      : out std_logic_vector(7 downto 0);
            FLAG_Z         : out std_logic;
            FLAG_E         : out std_logic; 
            
            DATABUS        : inout std_logic_vector(7 downto 0)   
        );
    end component;

    -- ROM
    component ROM is
        port(
            INSTRUCTION : out std_logic_vector(11 downto 0);
            PC          : in std_logic_vector(11 downto 0)
        );
    end component;

    -- CPU
    component CPU is
        port(
            CLK_PORT    : in std_logic;
            RESET       : in std_logic;
            
            ROM_INST    : in std_logic_vector(11 downto 0);
            ROM_PC      : out std_logic_vector(11 downto 0);

            RAM_ADDR    : out std_logic_vector(7 downto 0);
            RAM_WRITE   : out std_logic;
            RAM_OE      : out std_logic;
			RAM_READ_RDY : in std_logic;

            DMA_RQ      : in std_logic;
            DMA_READY   : in std_logic;
            DMA_ACK     : out std_logic;
            DMA_SEND    : out std_logic;
			DMA_SCFG	: out std_logic;
            DMA_INTERRUPT : in std_logic;
            INTERRUPT_ACK : out std_logic;
    
            COUNTER_START : out std_logic;
            COUNTER_BUSY  : in std_logic_vector(1 downto 0);

            ALU_OP      : out alu_op_t;
            INDEX_REG   : in std_logic_vector(7 downto 0);
            FLAG_Z      : in std_logic;
            FLAG_E      : in std_logic;

			DMA_WR_EN   : out std_logic;
            DATABUS     : inout std_logic_vector(7 downto 0)
            
        );
    end component;
	
	
	--Frequency counters
    --component FQCLK is
		--port(
			--ref_clk_i: in std_logic;
			--rst_n_i: in std_logic;
			--outcore_o: out std_logic;
			--outglobal_o: out std_logic
		--);
	--end component;

    
    component FQC_top is 
        port ( 
            RESET : in std_logic;
            CLK_PORT : in std_logic;
            --FAST_CLK_PORT : in std_logic;
            INPUT : in std_logic_vector(1 downto 0);
            START : in std_logic;
            BUSY_FLAG : out std_logic_vector(1 downto 0);
			
			COUNT_RDY : out std_logic;
			COUNT_READ : in std_logic;
			COUNT_OUT : out std_logic_vector(7 downto 0);
			CFG_BUS	  : in std_logic_vector(7 downto 0); -- OPTIMISATION => MERGE COUNT_OUT AND CFG_BUS into an inout.
			REG_ADDR  : in std_logic_vector(1 downto 0);
			COUNT_WR_EN	: in std_logic
			
        );
    end component;
    

    -- Signal declaration
    -- General
    signal databus      : std_logic_vector(7 downto 0);
    signal address      : std_logic_vector(7 downto 0);
    signal oe           : std_logic;
    signal write_en     : std_logic;
	
	--RAM read guards
	signal read_ready, read_rdy_dma, read_rdy_cpu : std_logic;

   -- signal led_status   : std_logic_vector(2 downto 0);
    
    -- PLL
    --signal init         : std_logic; --Neg reset, for PLL
    --signal clk_120_mhz_core : std_logic;
    --signal clk_120_mhz  : std_logic;

    -- RS232 <> DMA
    signal tx_data      : std_logic_vector(7 downto 0);
    signal rcvd_data    : std_logic_vector(7 downto 0);
    signal valid_d      : std_logic;
    signal ack_out      : std_logic;
    signal tx_rdy       : std_logic;
    signal data_read    : std_logic;
    signal full         : std_logic;
    signal empty        : std_logic;

    -- DMA <> RAM
    signal write_en_dma : std_logic;
    signal oe_dma       : std_logic;
    signal address_dma  : std_logic_vector(7 downto 0);

    -- CPU <> RAM
    signal write_en_cpu : std_logic;
    signal oe_cpu       : std_logic;
    signal address_cpu  : std_logic_vector(7 downto 0);
	
	-- RAM <> General
	signal ram_rst		: std_logic;
	signal ram_clk_en	: std_logic;
	signal write_data	: std_logic_vector(7 downto 0);
	signal read_data	: std_logic_vector(7 downto 0);

    -- DMA <> CPU
    signal dma_rq       : std_logic;
    signal dma_ack      : std_logic;
    signal send_comm    : std_logic;
	signal send_conf	: std_logic;
    signal ready        : std_logic;
    signal dma_interrupt : std_logic;
    signal interrupt_ack : std_logic;
	signal dma_write_en : std_logic;

    --ROM <> CPU
    signal instruction  : std_logic_vector(11 downto 0);
    signal prog_ctr     : std_logic_vector(11 downto 0);

    --ALU <> CPU
    signal uoperation   : alu_op_t;
    signal index_reg    : std_logic_vector(7 downto 0);
    signal flag_zero    : std_logic;
    signal flag_err     : std_logic;
    
    -- FRC <> CPU
    signal ctr_start    : std_logic;
    signal ctr_busy     : std_logic_vector(1 downto 0);
	
	-- FRC <> DMA
	signal count_ready 	: std_logic;
	signal count_out	: std_logic_vector(7 downto 0);
	signal count_read	: std_logic;
	signal count_cfg	: std_logic_vector(7 downto 0);
	signal count_addr	: std_logic_vector(1 downto 0);
	signal count_wr_en : std_logic;
    
    begin

        -- Component port mapping 
        RS232_CP : RS232
            port map(
                CLK_PORT    => CLK_PORT,
                RESET       => RESET,
          
                DATA_IN     => tx_data,
                VALID_D     => valid_d,
                ACK_IN      => ack_out,
                TX_RDY      => tx_rdy,

                RD          => RS232_RX,
                TD          => RS232_TX,

                DATA_READ   => data_read,
                DATA_OUT    => rcvd_data,
          
                FULL        => full,
                EMPTY       => empty
            );

        DMA_CP  : DMA
            port map(
                CLK_PORT 	=> CLK_PORT,
                RESET 	    => RESET,
             
                RCVD_DATA 	=> rcvd_data,
                RX_FULL 		=> full,
                RX_EMPTY    	=> empty,
             
                DATA_READ 	=> data_read,
             
                ACK_OUT 		=> ack_out,
                TX_RDY 		=> tx_rdy,
             
                VALID_D 		=> valid_d,
                TX_DATA 		=> tx_data,
             
                ADDRESS 		=> address_dma,
                WRITE_EN 	=> write_en_dma,
                OE 			=> oe_dma,
				DMA_READ_RDY 	=> read_rdy_dma,
        
                DMA_ACK 		=> dma_ack,
                SEND_COMM 	=> send_comm,
				SEND_CONF	=> send_conf,
                DMA_RQ 		=> dma_rq,
                READY 		=> ready,
				
				COUNT_RDY 	=> count_ready,
				COUNT_OUT		=> count_out,
				COUNT_READ	=> count_read,
				COUNT_CFG	=> count_cfg,
				COUNT_REG_ADDR => count_addr,
				COUNT_WR_EN => count_wr_en,
                
                DMA_INTERRUPT => dma_interrupt,
                INTERRUPT_ACK => interrupt_ack,
				
				WRITE_CFG_EN => dma_write_en,
                DATABUS 	=> databus

            );

        --RAM_CP  : RAM
            --port map(
                --CLK_PORT    => CLK_PORT,
                --RESET       => RESET,
    
                --WRITE_EN    => write_en,
                --OE          => oe,
    
                --ADDRESS     => address,
                --DATABUS     => databus
                
                --LED_STAT    => led_status
            --);
			
		RAM_CP	: RAM
			port map(
				clk_i		=> CLK_PORT,
				rst_i		=> ram_rst,
				
				wr_en_i		=> write_en,
				clk_en_i	=> ram_clk_en,
				
				addr_i		=> ADDRESS(5 downto 0),
				wr_data_i	=> write_data,
				rd_data_o	=> read_data
			);
        
        ALU_CP  : ALU   
            port map(
                CLK_PORT    => CLK_PORT,
                RESET       => RESET,

                ALU_OP      => uoperation,

                INDEX_REG   => index_reg,
                FLAG_Z      => flag_zero,
                FLAG_E      => flag_err,
                
                DATABUS     => databus

            );

        ROM_CP  : ROM
            port map(
                INSTRUCTION => instruction,
                PC          => prog_ctr
            );
        
        CPU_CP  : CPU
            port map(
            --  CLK_PORT    => CLK_FAST
                CLK_PORT    => CLK_PORT,
                RESET       => RESET,
                
                ROM_INST    => instruction,
                ROM_PC      => prog_ctr,
    
                RAM_ADDR    => address_cpu,
                RAM_WRITE   => write_en_cpu,
                RAM_OE      => oe_cpu,
			    RAM_READ_RDY => read_rdy_cpu,
    
                DMA_RQ      => dma_rq,
                DMA_READY   => ready,
                DMA_ACK     => dma_ack,
                DMA_SEND    => send_comm,
				DMA_SCFG	=> send_conf,
                DMA_INTERRUPT => dma_interrupt,
                INTERRUPT_ACK => interrupt_ack,
				DMA_WR_EN	=> dma_write_en,
                
                COUNTER_START => ctr_start,
                COUNTER_BUSY => ctr_busy,

                ALU_OP      => uoperation,
                INDEX_REG   => index_reg,
                FLAG_Z      => flag_zero,
                FLAG_E      => flag_err,

                DATABUS     => databus

            );
        
		--FC_PLL : FQCLK 
			--port map(
				--ref_clk_i	   => CLK_PORT,
				--rst_n_i		   => RESET,
				--outcore_o      => clk_120_mhz_core,
				--outglobal_o    => clk_120_mhz
			--);
        --FC_MCMM : MCMM_Counters 
            --port map(
                --reset       => init,
                --clk_in1     => CLK_PORT,
                --FAST_CLK_OUT => clk_120_mhz,
                --locked      => locked
            --);
            
        FC0_CP : FQC_top
            port map(
				RESET       => RESET,
				CLK_PORT    => CLK_PORT,
				--FAST_CLK_PORT => clk_120_mhz,
				
				INPUT       => INPUT_FRQ,
				START       => ctr_start,
				BUSY_FLAG   => ctr_busy,
                
				COUNT_READ 	=> count_read,
				COUNT_RDY	=> count_ready,
				COUNT_OUT	=> count_out, 
				CFG_BUS 	=> count_cfg,
				REG_ADDR 	=> count_addr,
				COUNT_WR_EN => count_wr_en
            );
           
		
        
         -- RAM HANDLING
		-- Signals
		ram_rst	<= not(RESET);
		ram_clk_en <= not(oe) or write_en;
		
		-- Processes
        RAM_CONTROL_MUX : process(dma_ack, send_comm, address_dma, oe_dma, write_en_dma, address_cpu, oe_cpu, write_en_cpu, read_ready)
		begin
			if dma_ack = '1' or send_comm = '1' then
				address     <= address_dma;
				oe          <= oe_dma;
				write_en    <= write_en_dma;
				read_rdy_dma <= read_ready;
				read_rdy_cpu <= '0';
			else
				address     <= address_cpu;
				oe          <= oe_cpu;
				write_en    <= write_en_cpu;
				read_rdy_cpu <= read_ready;
				read_rdy_dma <= '0';
			end if;
         end process RAM_CONTROL_MUX;
		
		RAM_DATABUS_MUX: process(write_en, ram_clk_en, read_ready, read_data, address) -- Address in sensitivity list so this runs properly when DMA writes many bytes
		begin
			databus <= (others => 'Z');
			write_data <= (others => '0');
			if write_en = '1' and ram_clk_en = '1' then
				write_data <= databus;
			elsif write_en = '0' and ram_clk_en = '1' and read_ready = '1' then
				databus <= read_data;
			end if;
		end process RAM_DATABUS_MUX;
		
		RAM_READ_GUARD: process(RESET, CLK_PORT)
		begin
			if RESET = '0' then
				read_ready <= '0';
			elsif CLK_PORT'event and CLK_PORT = '1' then
				if oe = '0' then
					read_ready <= '1';
				else
					read_ready <= '0';
				end if;
			end if;
		end process RAM_READ_GUARD;
            
    end SWS_top_Behavior;
