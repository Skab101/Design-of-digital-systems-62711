library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================================
-- Microprocessor testbench -- sw_to_led
-- =====================================================================
-- Verificerer at hele systemet (Datapath + MPC + RAM + PortReg + MUX_MR)
-- kører sw_to_led-programmet korrekt:
--   1) Pulse BTNR med en SW-værdi -> MR3 latches
--   2) CPU'en loop'er og kopierer MR3 til MR2 (LED)
--   3) Vi læser LED tilbage og verificerer at det matcher SW
--
-- Programmet er DEC-baseret (bruger ikke SUB), så det virker uanset
-- om Cin = '0' eller Cin = FS_sig(0) i Microprocessor.vhd.
-- Ingen 7-seg writes, så D_Word forbliver 0x0000 hele kørselen.
--
-- Wave-tip: tilføj /Microprocessor_tb/UUT/Address_Out_PC til wave-viewet
-- for at se PC tælle 0,1,2,...,9 og hoppe tilbage til 1 ved JMP.
-- =====================================================================

entity Microprocessor_tb is
end Microprocessor_tb;

architecture TB of Microprocessor_tb is

    signal CLK    : STD_LOGIC := '0';
    signal RESET  : STD_LOGIC := '1';
    signal SW     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal BTNC, BTNU, BTNL, BTNR, BTND : STD_LOGIC := '0';
    signal LED    : STD_LOGIC_VECTOR(7 downto 0);
    signal D_Word : STD_LOGIC_VECTOR(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant LOOP_WAIT  : time := CLK_PERIOD * 100;

begin

    -- I simulering driver vi både CLK og CLK_CPU fra samme signal.
    -- På boardet kører CLK_CPU = CLK/2 (BUFG'et i TOP_MODUL_F).
    UUT: entity work.Microprocessor
        port map (
            CLK     => CLK,
            CLK_CPU => CLK,
            RESET   => RESET,
            SW      => SW,
            BTNC    => BTNC,
            BTNU    => BTNU,
            BTNL    => BTNL,
            BTNR    => BTNR,
            BTND    => BTND,
            LED     => LED,
            D_Word  => D_Word
        );

    clk_process: process
    begin
        CLK <= '0'; wait for CLK_PERIOD / 2;
        CLK <= '1'; wait for CLK_PERIOD / 2;
    end process;

    stim_process: process

        procedure press_button(
            signal btn   : out std_logic;
            constant val : in  std_logic_vector(7 downto 0)
        ) is
        begin
            wait until falling_edge(CLK);
            SW  <= val;
            btn <= '1';
            wait until rising_edge(CLK);
            wait for 1 ns;
            btn <= '0';
        end procedure;

    begin
        -- ============================================================
        -- Reset
        -- ============================================================
        RESET <= '1';
        wait for CLK_PERIOD * 5;
        RESET <= '0';
        wait for CLK_PERIOD * 2;

        assert LED = x"00";
        
        BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;
        BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;BTNC <= '0';
        wait for CLK_PERIOD * 2;
        BTNC <= '1';
        wait for CLK_PERIOD * 10;

        
        wait;
    end process;

end TB;
