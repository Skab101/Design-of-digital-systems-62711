library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================================
-- Microprocessor testbench -- addsub_calc  (assert-baseret validering)
-- =====================================================================
-- Koerer den FAKTISKE hardware (Datapath + MPC/IDC + RAM + PortReg +
-- MUX_MR) mod addsub_calc-programmet i BRAM -- praecis det der
-- synthesizes til boardet.
--
-- addsub_calc workflow:
--   SW=A, puls BTNR  -> MR3 = A
--   SW=B, puls BTNL  -> MR4 = B
--   SW=mode, puls BTND -> MR5 = mode (0=minus, !=0=plus)
--   D_Word(7:0) = resultatet (8-bit; negativ = 2's-komplement)
--
-- Programmet skal vaere injiceret i RAM (sim: Ram256x16_sim.vhd):
--   python PWF/tools/asm/dsdasm.py asm addsub_calc.asm --vhdl Ram256x16.vhd
--
-- Hver check er en assert med severity error. Til sidst rapporteres
-- antal bestaaede/fejlede; severity failure hvis noget fejlede.
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
    -- Et helt addsub_calc-loop ~= 21 instr a 2 cykler ~= 42 cykler.
    -- Vent rigeligt saa et par loops naar at laese nye latch-vaerdier.
    constant SETTLE : time := CLK_PERIOD * 300;

    -- Saettes true af stim_process naar alle tests er koert. Stopper
    -- klokken saa der ikke er flere events -> "run all" terminerer
    -- selv (ellers koerer den fri-loebende klok i en uendelig loop).
    signal sim_done : boolean := false;

begin

    UUT: entity work.Microprocessor
        port map (
            CLK => CLK, CLK_CPU => CLK, RESET => RESET, SW => SW,
            BTNC => BTNC, BTNU => BTNU, BTNL => BTNL, BTNR => BTNR,
            BTND => BTND, LED => LED, D_Word => D_Word
        );

    clk_process: process
    begin
        while not sim_done loop
            CLK <= '0'; wait for CLK_PERIOD / 2;
            CLK <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;  -- klokken staar stille -> ingen flere events
    end process;

    stim_process: process

        variable n_pass : integer := 0;
        variable n_fail : integer := 0;

        -- Saet SW, hold knap hoej over et par klokkanter -> PortReg
        -- latcher SW i MRx. Slip -> vaerdien fryser (som paa boardet).
        procedure press(signal btn  : out std_logic;
                         constant v  : in  integer) is
        begin
            wait until falling_edge(CLK);
            SW  <= std_logic_vector(to_unsigned(v, 8));
            btn <= '1';
            for i in 0 to 3 loop
                wait until rising_edge(CLK);
            end loop;
            wait for 1 ns;
            btn <= '0';
            wait until falling_edge(CLK);
        end procedure;

        -- Assert-baseret check af D_Word(7:0) mod forventet vaerdi.
        procedure check(constant expected : in integer;
                        constant tag      : in string) is
            variable got : integer;
        begin
            got := to_integer(unsigned(D_Word(7 downto 0)));
            assert got = expected
                report tag & ": FAIL  forventet " & integer'image(expected)
                     & ", fik " & integer'image(got)
                severity error;
            if got = expected then
                n_pass := n_pass + 1;
                report tag & ": PASS (" & integer'image(got) & ")"
                    severity note;
            else
                n_fail := n_fail + 1;
            end if;
        end procedure;

    begin
        -- Reset
        RESET <= '1';
        wait for CLK_PERIOD * 8;
        RESET <= '0';
        wait for CLK_PERIOD * 4;

        -- TEST 1: A=8, B=3, ingen BTND -> default MINUS -> 5
        press(BTNR, 8);
        press(BTNL, 3);
        wait for SETTLE;
        check(5, "T1 8-3 default-minus");

        -- TEST 2: BTND med SW=1 -> PLUS -> 11
        press(BTND, 1);
        wait for SETTLE;
        check(11, "T2 8+3 plus(BTND=1)");

        -- TEST 3: BTND med SW=0 -> MINUS -> 5
        press(BTND, 0);
        wait for SETTLE;
        check(5, "T3 8-3 minus(BTND=0)");

        -- TEST 4: nye operander A=10 B=4, plus -> 14
        press(BTNR, 10);
        press(BTNL, 4);
        press(BTND, 1);
        wait for SETTLE;
        check(14, "T4 10+4 plus");

        -- TEST 5: samme operander, minus -> 6
        press(BTND, 0);
        wait for SETTLE;
        check(6, "T5 10-4 minus");

        -- TEST 6: negativt resultat A=3 B=8 minus -> -5 = 0xFB = 251
        press(BTNR, 3);
        press(BTNL, 8);
        press(BTND, 0);
        wait for SETTLE;
        check(251, "T6 3-8 minus(neg=0xFB)");

        -- TEST 7: sum-wrap A=200 B=100 plus -> 300 mod 256 = 44
        press(BTNR, 200);
        press(BTNL, 100);
        press(BTND, 1);
        wait for SETTLE;
        check(44, "T7 200+100 plus(wrap=44)");

        -- ============================================================
        -- Slut-opsummering
        -- ============================================================
        report "==== addsub_calc: " & integer'image(n_pass)
             & " PASS, " & integer'image(n_fail) & " FAIL ===="
            severity note;
        assert n_fail = 0
            report "addsub_calc TESTBENCH FAILED ("
                 & integer'image(n_fail) & " fejl)"
            severity failure;
        report "==== addsub_calc: ALLE TESTS BESTAAET ====" severity note;
        sim_done <= true;   -- stopper klokken -> "run all" slutter selv
        wait;
    end process;

end TB;
