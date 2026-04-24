library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Port Register Module: 8 x 8-bit port registers mapped to memory addresses 0xF8-0xFF
--   MR0 (0xF8): D_Word low byte  (7-seg low) -- writable
--   MR1 (0xF9): D_Word high byte (7-seg high) -- writable
--   MR2 (0xFA): LEDs                          -- writable
--   MR3 (0xFB): BTNR input                    -- read-only (loaded from SW on BTNR press)
--   MR4 (0xFC): BTNL input                    -- read-only
--   MR5 (0xFD): BTND input                    -- read-only
--   MR6 (0xFE): BTNU input                    -- read-only
--   MR7 (0xFF): BTNC input                    -- read-only
entity PortReg8x8 is
    port (
        clk        : in  STD_LOGIC;
        MW         : in  STD_LOGIC;
        Data_In    : in  STD_LOGIC_VECTOR(7 downto 0);
        Address_in : in  STD_LOGIC_VECTOR(7 downto 0);
        SW         : in  STD_LOGIC_VECTOR(7 downto 0);
        BTNC       : in  STD_LOGIC;
        BTNU       : in  STD_LOGIC;
        BTNL       : in  STD_LOGIC;
        BTNR       : in  STD_LOGIC;
        BTND       : in  STD_LOGIC;
        MMR        : out STD_LOGIC;
        D_word     : out STD_LOGIC_VECTOR(15 downto 0);
        Data_outR  : out STD_LOGIC_VECTOR(15 downto 0);
        LED        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end PortReg8x8;

architecture PR_Structural of PortReg8x8 is

    component Register8bit is
        Port (
            D     : in  STD_LOGIC_VECTOR(7 downto 0);
            Reset : in  STD_LOGIC;
            Load  : in  STD_LOGIC;
            clk   : in  STD_LOGIC;
            Q     : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    -- Outputs of the eight port registers MR0..MR7
    signal MR0, MR1, MR2, MR3, MR4, MR5, MR6, MR7 : STD_LOGIC_VECTOR(7 downto 0);

    -- Per-register Load enables
    signal L0, L1, L2 : STD_LOGIC;

    -- High when Address_in lies in 0xF8..0xFF (top five bits all '1')
    signal addr_match : STD_LOGIC;

begin

    addr_match <= '1' when Address_in(7 downto 3) = "11111" else '0';
    MMR        <= addr_match;

    -- Write enables for the three writable registers
    L0 <= MW and addr_match when Address_in(2 downto 0) = "000" else '0';
    L1 <= MW and addr_match when Address_in(2 downto 0) = "001" else '0';
    L2 <= MW and addr_match when Address_in(2 downto 0) = "010" else '0';

    -- Writable registers (MR0..MR2): data from Data_In, load from MW+address decode
    U_MR0 : Register8bit port map (D => Data_In, Reset => '0', Load => L0, clk => clk, Q => MR0);
    U_MR1 : Register8bit port map (D => Data_In, Reset => '0', Load => L1, clk => clk, Q => MR1);
    U_MR2 : Register8bit port map (D => Data_In, Reset => '0', Load => L2, clk => clk, Q => MR2);

    -- Button-driven registers (MR3..MR7): data from SW, load on button press
    U_MR3 : Register8bit port map (D => SW, Reset => '0', Load => BTNR, clk => clk, Q => MR3);
    U_MR4 : Register8bit port map (D => SW, Reset => '0', Load => BTNL, clk => clk, Q => MR4);
    U_MR5 : Register8bit port map (D => SW, Reset => '0', Load => BTND, clk => clk, Q => MR5);
    U_MR6 : Register8bit port map (D => SW, Reset => '0', Load => BTNU, clk => clk, Q => MR6);
    U_MR7 : Register8bit port map (D => SW, Reset => '0', Load => BTNC, clk => clk, Q => MR7);

    -- Read multiplexer: select MRn based on low 3 bits of address, zero-extend to 16 bits
    with Address_in(2 downto 0) select
        Data_outR <= x"00" & MR0 when "000",
                     x"00" & MR1 when "001",
                     x"00" & MR2 when "010",
                     x"00" & MR3 when "011",
                     x"00" & MR4 when "100",
                     x"00" & MR5 when "101",
                     x"00" & MR6 when "110",
                     x"00" & MR7 when others;

    D_word <= MR1 & MR0;
    LED    <= MR2;

end PR_Structural;
