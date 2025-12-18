----------------------------------------------------------------------------------
-- Company: INSTITUTO DE MAGNETISMO APLICADO - UNIVERSIDAD COMPLUTENSE DE MADRID
-- Engineer: MARIO DE MIGUEL DOMÃƒÆ’Ã‚ÂNGUEZ
-- 
-- Create Date: 21.04.2025 14:12:17
-- Design Name: SWS PROGRAM ROM MODULE
-- Module Name: ROM - ROM_Behavior
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
use work.MEM_pkg.ALL;


entity ROM is
    port(
        INSTRUCTION : out std_logic_vector(11 downto 0);
        PC          : in std_logic_vector(11 downto 0)
    );
end ROM;

architecture ROM_Behavior of ROM is
    -- # INIT (INTERRUPT)
    constant W0  : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_UNCOND;
    constant W1  : std_logic_vector(11 downto 0) := INI;
    
    --constant W7  : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_ACC;
    --constant W8  : std_logic_vector(11 downto 0) := X"000";
    --constant W9  : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    --constant W10 : std_logic_vector(11 downto 0) := X"0" & NEW_INST;
    constant W11 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_A;
    constant W12 : std_logic_vector(11 downto 0) := X"0" & DMA_RX_BUFFER_MSB;
    --constant W13 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_B; 
    --constant W14 : std_logic_vector(11 downto 0) := X"04C"; --L
    --constant W15 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_CMPE;
    --constant W16 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_COND;
    --constant W17 : std_logic_vector(11 downto 0) := LED;
    constant W18 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_B;
    constant W19 : std_logic_vector(11 downto 0) := X"053"; --S
    constant W20 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_CMPE;
    constant W21 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_COND;
    constant W22 : std_logic_vector(11 downto 0) := SFC;
    constant W23 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_B;
    constant W24 : std_logic_vector(11 downto 0) := X"052"; --R
    constant W25 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_CMPE;
    constant W26 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_COND;
    constant W27 : std_logic_vector(11 downto 0) := RFC;
    constant W28 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_UNCOND;
    constant W29 : std_logic_vector(11 downto 0) := ERR;
    
    -- #LED
    --constant W30 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_A;
    --constant W31 : std_logic_vector(11 downto 0) := X"0" & DMA_RX_BUFFER_MID;
    --constant W32 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_ASCII2BIN;
    --constant W33 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_ACC & DST_IDX;
    --constant W34 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_ACC & DST_A;
    --constant W35 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_B;
    --constant W36 : std_logic_vector(11 downto 0) := X"002";
    --constant W37 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_CMPG;
    --constant W38 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_COND;
    --constant W39 : std_logic_vector(11 downto 0) := ERR;
    --constant W40 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_A;
    --constant W41 : std_logic_vector(11 downto 0) := X"0" & DMA_RX_BUFFER_LSB;
    --constant W42 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_ASCII2BIN;
    --constant W43 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_ACC & DST_A;
    --constant W44 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_B;
    --constant W45 : std_logic_vector(11 downto 0) := X"001";
    --constant W46 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_CMPG;
    --constant W47 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_COND;
    --constant W48 : std_logic_vector(11 downto 0) := ERR;
    --constant W49 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_IDX_MEM;
    --constant W50 : std_logic_vector(11 downto 0) := X"0" & LED_BASE;
    --constant W51 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_UNCOND;
    --constant W52 : std_logic_vector(11 downto 0) := SOK;

    -- #SOK
    constant W53 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_ACC;
    constant W54 : std_logic_vector(11 downto 0) := X"03B"; -- ;
    constant W55 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W56 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_MSB;
    constant W57 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_ACC;
    constant W58 : std_logic_vector(11 downto 0) := X"050"; -- P
    constant W59 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W60 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_LSB;
    constant W61 : std_logic_vector(11 downto 0) := X"0" & TYPE_4 & SND & "0000"; 
    constant W62 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_UNCOND;
    constant W63 : std_logic_vector(11 downto 0) := INI;

    
    -- #ERR
    constant W64 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_ACC;
    constant W65 : std_logic_vector(11 downto 0) := X"045"; -- E
    constant W66 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W67 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_MSB;
    constant W68 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_ACC;
    constant W69 : std_logic_vector(11 downto 0) := X"052"; --  R
    constant W70 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W71 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_LSB;
    constant W72 : std_logic_vector(11 downto 0) := X"0" & TYPE_4 & SND & "0000"; 
    constant W73 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_UNCOND;
    constant W74 : std_logic_vector(11 downto 0) := INI;
    
    
    -- #SFC
    constant W75 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_A;
    constant W76 : std_logic_vector(11 downto 0) := X"0" & DMA_RX_BUFFER_MID;	
	constant W77 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_NOP;
    constant W78 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_ASCII2BIN;
    constant W79 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_ACC & DST_A;
    constant W80 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_B;
    constant W81 : std_logic_vector(11 downto 0) := X"000";
    constant W82 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_CMPG;
    constant W83 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_COND;
    constant W84 : std_logic_vector(11 downto 0) := ERR;
    constant W85 : std_logic_vector(11 downto 0) := X"0" & TYPE_4 & RUN & "0000";
    constant W86 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_UNCOND;
    constant W87 : std_logic_vector(11 downto 0) := SOK;
 
    
    -- #RFC 
    constant W88 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_A;
    constant W89 : std_logic_vector(11 downto 0) := X"001";
    constant W90 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_ASCII2BIN;
    constant W91 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_ACC & DST_A;
    constant W92 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_CONST & DST_B;
    constant W93 : std_logic_vector(11 downto 0) := X"000";
    constant W94 : std_logic_vector(11 downto 0) := X"0" & TYPE_1 & ALU_CMPG;
    constant W95 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_COND;
    constant W96 : std_logic_vector(11 downto 0) := ERR;
    constant W97 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_ACC;
    constant W98 : std_logic_vector(11 downto 0) := x"00B";
    constant W99 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W100 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_MSB;
    constant W101 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_ACC;
    constant W102 : std_logic_vector(11 downto 0) := X"00A";
    constant W103 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W104 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_MI1;
    constant W105 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_ACC;
    constant W106 : std_logic_vector(11 downto 0) := X"009";
    constant W107 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W108 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_MI2;
    constant W109 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & LD & SRC_MEM & DST_ACC;
    constant W110 : std_logic_vector(11 downto 0) := X"008";
    constant W111 : std_logic_vector(11 downto 0) := X"0" & TYPE_3 & SW & SRC_ACC & DST_MEM;
    constant W112 : std_logic_vector(11 downto 0) := X"0" & DMA_TX_BUFFER_LSB;
    constant W113 : std_logic_vector(11 downto 0) := X"0" & TYPE_4 & SND & "0000";
    constant W114 : std_logic_vector(11 downto 0) := X"0" & TYPE_2 & JMP_UNCOND;
    constant W115 : std_logic_vector(11 downto 0) := INI;
    



    begin
        with PC select 
            INSTRUCTION <= 
                W0 when X"000",
                W1 when X"001",
--                W2 when X"002",
--                W3 when X"003",
--                W4 when X"004",
--                W5 when X"005",
--                W6 when X"006",
--                W7 when X"007",
--                W8 when X"008",
--                W9 when X"009",
--                W10 when X"00A",
                W11 when X"010",				
                W12 when X"011",
--                W13 when X"00D",
--                W14 when X"00E",
--                W15 when X"00F",
--                W16 when X"010",
--                W17 when X"011",
                W18 when X"012",
                W19 when X"013",
                W20 when X"014",
                W21 when X"015",
                W22 when X"016",
                W23 when X"017",
                W24 when X"018",
                W25 when X"019",
                W26 when X"01A",
                W27 when X"01B",
                W28 when X"01C",
                W29 when X"01D",
                --W30 when X"01E",
                --W31 when X"01F",
                --W32 when X"020",
                --W33 when X"021",
                --W34 when X"022",
                --W35 when X"023",
                --W36 when X"024",
                --W37 when X"025",
                --W38 when X"026",
                --W39 when X"027",
                --W40 when X"028",
                --W41 when X"029",
                --W42 when X"02A",
                --W43 when X"02B",
                --W44 when X"02C",
                --W45 when X"02D",
                --W46 when X"02E",
                --W47 when X"02F",
                --W48 when X"030",
                --W49 when X"031",
                --W50 when X"032",
                --W51 when X"033",
                --W52 when X"034",
                W53 when X"035",
                W54 when X"036",
                W55 when X"037",
                W56 when X"038",
                W57 when X"039",
                W58 when X"03A",
                W59 when X"03B",
                W60 when X"03C",
                W61 when X"03D",
                W62 when X"03E",
                W63 when X"03F",
                W64 when X"040",
                W65 when X"041",
                W66 when X"042",
                W67 when X"043",
                W68 when X"044",
                W69 when X"045",
                W70 when X"046",
                W71 when X"047",
                W72 when X"048",
                W73 when X"049",
                W74 when X"04A",
                W75 when X"04B",
                W76 when X"04C",
                W77 when X"04D",
                W78 when X"04E",
                W79 when X"04F",
                W80 when X"050",
                W81 when X"051",
                W82 when X"052",
                W83 when X"053",
                W84 when X"054",
                W85 when X"055",
                W86 when X"056",
                W87 when X"057",
                W88 when X"058",
                W89 when X"059",
                W90 when X"05A",
                W91 when X"05B",
                W92 when X"05C",
                W93 when X"05D",
                W94 when X"05E",
                W95 when X"05F",
                W96 when X"060",
                W97 when X"061",
                W98 when X"062",
                W99 when X"063",
                W100 when X"064",
                W101 when X"065",
                W102 when X"066", 
                W103 when X"067",
                W104 when X"068",
                W105 when X"069",
                W106 when X"06A",
                W107 when X"06B", 
                W108 when X"06C",
                W109 when X"06D",
                W110 when X"06E",
                W111 when X"06F",
                W112 when X"070",
                W113 when X"071",
                W114 when X"072",
			    W115 when X"073",
                (others => '0') when others;
end ROM_Behavior;
