----------------------------------------------------------------------------------
-- Module Name: RegisterR16
-- Description: 16 x 8-bit register block
--              LOAD(15:0) selects which register captures D_Data on CLK edge
--              All 16 register outputs exposed (R0..R15)
--              Built structurally from flip_flop using for...generate
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegisterR16 is
    Port (
        RESET  : in  STD_LOGIC;
        CLK    : in  STD_LOGIC;
        LOAD   : in  STD_LOGIC_VECTOR(15 downto 0);
        D_Data : in  STD_LOGIC_VECTOR(7 downto 0);
        R0, R1, R2, R3   : out STD_LOGIC_VECTOR(7 downto 0);
        R4, R5, R6, R7     : out STD_LOGIC_VECTOR(7 downto 0);
        R8, R9, R10, R11   : out STD_LOGIC_VECTOR(7 downto 0);
        R12, R13, R14, R15 : out STD_LOGIC_VECTOR(7 downto 0)
    );
end RegisterR16;

architecture R16_Structural of RegisterR16 is

    -- Komponent deklaration for 8-bit register
     component Register8bit is
        Port (
            D     : in  STD_LOGIC_VECTOR(7 downto 0);
            Reset : in  STD_LOGIC;
            Load  : in  STD_LOGIC;
            clk   : in  STD_LOGIC;
            Q     : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;
   
    -- Disse to linjer generer en type af array af std_logic_vector(7 downto 0), og danner 16 signaler af denne type som bruges til at holde registerværdierne
    type reg_array is array (15 downto 0) of std_logic_vector(7 downto 0);
    signal Rs : reg_array;


begin

    -- Genere 16 x 8-bit registre ved hjælp af for...generate, registrene er konstrueret i file 8bit_Register.vhd
    R16_Registers: for i in 0 to 15 generate
        Reg_inst: Register8bit port map (
            D => D_Data,
            Reset => RESET,
            Load => LOAD(i),
            clk => CLK,
            Q => Rs(i)
        );
    end generate;

    -- Forbinder de interne signaler til output porte, så R0..R15 er tilgængelige udenfor modulet
    R0  <= Rs(0);   R1  <= Rs(1);   R2  <= Rs(2);   R3  <= Rs(3);
    R4  <= Rs(4);   R5  <= Rs(5);   R6  <= Rs(6);   R7  <= Rs(7);
    R8  <= Rs(8);   R9  <= Rs(9);   R10 <= Rs(10);  R11 <= Rs(11);
    R12 <= Rs(12);  R13 <= Rs(13);  R14 <= Rs(14);  R15 <= Rs(15);

end R16_Structural;
