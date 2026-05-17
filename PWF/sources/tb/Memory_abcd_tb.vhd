library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================================
-- Memory_abcd_tb  --  system-tidsdiagram for sekvenserne A-D
-- =====================================================================
-- Tester PRÆCIS det som WaveDrom-tidsdiagrammet (abcd_timing) viser:
-- den eksterne hukommelsesblok = Zero_Filler_2 + Ram256x16 + PortReg8x8
-- + MUX_MR, koblet nøjagtigt som i Microprocessor.vhd.
--
-- To klokdomæner som på boardet:
--   CLK      -- 100 MHz, driver BRAM (Ram256x16).            (MEM_CLK)
--   CLK_CPU  -- CLK/2 = 50 MHz, driver PortReg8x8.            (CPU_CLK)
-- CLK_CPU toggler på hver CLK-stigende flank (DivClk, TimeP=1).
--
-- Sekvenser (= timingdiagrammet):
--   A: læs 0x45, skriv 0xAA til 0x45, læs 0x45      (RAM, MMR=0)
--   B: skriv 0x55 til 0xF8 (MR0), læs 0xF8          (port, MMR=1)
--   C: skriv 0xCC til 0xFC (MR4), læs 0xFC          (CPU-skriv = no-op)
--   D: SW=0xA5, tryk BTNL (MR4<=0xA5), gentag C     (læs 0xFC -> 0x00A5)
--
-- Bemærk: RAM er initialiseret med addsub_calc; 0x45 ligger uden for
-- programområdet, så første læsning forventes 0x0000 (rapporteres blødt).
-- Skriv/readback og hele portregister-stien tjekkes med harde asserts.
-- TB'en selv-terminerer (sim_done) så "run all" stopper.
-- =====================================================================

entity Memory_abcd_tb is
end Memory_abcd_tb;

architecture TB of Memory_abcd_tb is

    -- Klokker
    signal clk       : STD_LOGIC := '0';                 -- 100 MHz (MEM_CLK)
    signal clk_cpu   : STD_LOGIC := '0';                 -- 50  MHz (CPU_CLK)
    constant CLK_PERIOD : time := 10 ns;                 -- 100 MHz

    -- Stimulus (svarer til CPU-siden / datapath)
    signal RESET       : STD_LOGIC := '1';
    signal MW          : STD_LOGIC := '0';
    signal Address     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal Data_Out_DP : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal SW          : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal BTNL        : STD_LOGIC := '0';

    -- Interne busser (samme navne som i Microprocessor.vhd)
    signal Data_In_RAM  : STD_LOGIC_VECTOR(15 downto 0);
    signal Data_outM    : STD_LOGIC_VECTOR(15 downto 0);
    signal Data_outR    : STD_LOGIC_VECTOR(15 downto 0);
    signal MMR_sig      : STD_LOGIC;
    signal Data_Bus_Out : STD_LOGIC_VECTOR(15 downto 0);
    signal D_Word       : STD_LOGIC_VECTOR(15 downto 0);
    signal LED          : STD_LOGIC_VECTOR(7 downto 0);

    signal sim_done : boolean := false;

    -- Hex-formatter (4 nibbles) til pæne konsol-beskeder.
    function hex4(v : STD_LOGIC_VECTOR(15 downto 0)) return string is
        constant H : string(1 to 16) := "0123456789ABCDEF";
        variable s : string(1 to 4);
        variable n : integer;
    begin
        for i in 0 to 3 loop
            n := to_integer(unsigned(v(15 - i*4 downto 12 - i*4)));
            s(i+1) := H(n + 1);
        end loop;
        return s;
    end function;

begin

    -- ==========================================================
    -- DUT: ekstern hukommelsesblok (som i Microprocessor.vhd)
    -- ==========================================================
    ZF_inst : entity work.Zero_Filler_2
        port map (
            Data_Out => Data_Out_DP,
            Data_ZF  => Data_In_RAM
        );

    RAM_inst : entity work.Ram256x16
        port map (
            clk        => clk,            -- fuld CLK (MEM_CLK)
            Reset      => '0',            -- må ikke nulstille program-INIT
            Data_in    => Data_In_RAM,
            Address_in => Address,
            MW         => MW,
            Data_out   => Data_outM
        );

    PR_inst : entity work.PortReg8x8
        port map (
            clk        => clk_cpu,        -- divideret CLK (CPU_CLK)
            MW         => MW,
            RESET      => RESET,
            Data_In    => Data_In_RAM,
            Address_in => Address,
            SW         => SW,
            BTNC       => '0',
            BTNU       => '0',
            BTNL       => BTNL,
            BTNR       => '0',
            BTND       => '0',
            MMR        => MMR_sig,
            D_word     => D_Word,
            Data_outR  => Data_outR,
            LED        => LED
        );

    MUXMR_inst : entity work.MUX_MR
        port map (
            Data_outM    => Data_outM,
            Data_outR    => Data_outR,
            MMR          => MMR_sig,
            Data_Bus_Out => Data_Bus_Out
        );

    -- ==========================================================
    -- Klokgeneratorer
    -- ==========================================================
    clk_process : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- CLK_CPU = CLK/2 (toggler på hver CLK-stigende flank, som DivClk TimeP=1)
    clk_cpu_process : process
    begin
        while not sim_done loop
            wait until rising_edge(clk);
            clk_cpu <= not clk_cpu;
        end loop;
        wait;
    end process;

    -- ==========================================================
    -- Stimulus: sekvenserne A-D, ét CPU-skridt pr. CLK_CPU-periode
    -- ==========================================================
    stim_process : process
        variable n_fail : integer := 0;

        -- CPU-skrivning: adresse/data/MW sættes på faldende CLK_CPU-flank
        -- (stabilt før stigende kant der latcher i PortReg / fanges af
        -- BRAM på den hurtige CLK).
        procedure bus_write(constant addr : in integer;
                            constant val8 : in integer;
                            constant tag  : in string) is
        begin
            wait until falling_edge(clk_cpu);
            Address     <= std_logic_vector(to_unsigned(addr, 8));
            Data_Out_DP <= std_logic_vector(to_unsigned(val8, 8));
            MW          <= '1';
            wait until rising_edge(clk_cpu);   -- latch (PortReg)
            wait until falling_edge(clk_cpu);
            MW          <= '0';
            report tag & ": skrev 0x"
                 & hex4(std_logic_vector(to_unsigned(val8, 16))) severity note;
        end procedure;

        -- CPU-læsning: adresse sættes, MW=0; sampler efter outputtet er
        -- gyldigt (BRAM efter CLK-flank, PortReg efter delta).
        procedure bus_read(constant addr     : in integer;
                           constant exp_mux  : in integer;
                           constant exp_mmr  : in std_logic;
                           constant hard     : in boolean;
                           constant tag      : in string) is
            variable got : integer;
        begin
            wait until falling_edge(clk_cpu);
            Address <= std_logic_vector(to_unsigned(addr, 8));
            MW      <= '0';
            wait until rising_edge(clk_cpu);
            wait for 2 ns;                     -- lad busserne stabilisere
            got := to_integer(unsigned(Data_Bus_Out));
            if MMR_sig /= exp_mmr then
                report tag & " FAIL: MMR=" & std_logic'image(MMR_sig)
                     & " forventet " & std_logic'image(exp_mmr)
                     severity error;
                n_fail := n_fail + 1;
            end if;
            if hard then
                if got = exp_mux then
                    report tag & " PASS (MUX-MR=0x" & hex4(Data_Bus_Out)
                         & ", MMR=" & std_logic'image(MMR_sig) & ")"
                         severity note;
                else
                    report tag & " FAIL: MUX-MR=0x" & hex4(Data_Bus_Out)
                         & " forventet 0x"
                         & hex4(std_logic_vector(to_unsigned(exp_mux,16)))
                         severity error;
                    n_fail := n_fail + 1;
                end if;
            else
                report tag & " INFO: MUX-MR=0x" & hex4(Data_Bus_Out)
                     & " (RAM-INIT-afhængig, ikke asserteret)" severity note;
            end if;
            wait until falling_edge(clk_cpu);
        end procedure;

        -- Knap-tryk: BTNL høj over en CLK_CPU-flank -> MR4 <= SW.
        procedure press_btnl(constant val8 : in integer;
                             constant tag  : in string) is
        begin
            wait until falling_edge(clk_cpu);
            SW   <= std_logic_vector(to_unsigned(val8, 8));
            BTNL <= '1';
            wait until rising_edge(clk_cpu);   -- MR4 latcher SW
            wait until falling_edge(clk_cpu);
            BTNL <= '0';
            report tag & ": BTNL latchede SW=0x"
                 & hex4(std_logic_vector(to_unsigned(val8,16))) severity note;
        end procedure;

    begin
        -- ---- Init / RESET (nulstil MR0..MR7) ----
        RESET <= '1';
        wait until falling_edge(clk_cpu);
        wait until falling_edge(clk_cpu);
        RESET <= '0';
        wait until falling_edge(clk_cpu);

        -- ============ SEKVENS A : RAM @0x45 ============
        bus_read (16#45#, 16#0000#, '0', false, "A1 read  0x45 (init)");
        bus_write(16#45#, 16#AA#,                 "A2 write 0x45");
        bus_read (16#45#, 16#00AA#, '0', true,  "A3 read  0x45 (back)");

        -- ============ SEKVENS B : MR0 @0xF8 ============
        bus_write(16#F8#, 16#55#,                 "B1 write 0xF8 (MR0)");
        bus_read (16#F8#, 16#0055#, '1', true,  "B2 read  0xF8");
        assert to_integer(unsigned(D_Word)) = 16#0055#
            report "B  FAIL: D_Word=0x" & hex4(D_Word)
                 & " forventet 0x0055" severity error;

        -- ============ SEKVENS C : MR4 @0xFC (CPU-skriv = no-op) ============
        bus_write(16#FC#, 16#CC#,                 "C1 write 0xFC (no-op)");
        bus_read (16#FC#, 16#0000#, '1', true,  "C2 read  0xFC");

        -- ============ SEKVENS D : MR4 via BTNL, gentag C ============
        press_btnl(16#A5#,                        "D1 BTNL  SW=0xA5");
        bus_write(16#FC#, 16#CC#,                 "D2 write 0xFC (no-op)");
        bus_read (16#FC#, 16#00A5#, '1', true,  "D3 read  0xFC");

        -- ---- LED skal være urørt (MR2 aldrig skrevet) ----
        assert to_integer(unsigned(LED)) = 0
            report "FAIL: LED=0x" & hex4(x"00" & LED)
                 & " forventet 0x00" severity error;

        -- ---- Opsummering ----
        report "==== Memory_abcd_tb: " & integer'image(n_fail)
             & " FAIL ====" severity note;
        assert n_fail = 0
            report "Memory_abcd_tb FAILED" severity failure;
        report "==== Memory_abcd_tb: ALLE A-D SEKVENSER BESTAAET ===="
            severity note;

        sim_done <= true;
        wait;
    end process;

end TB;
