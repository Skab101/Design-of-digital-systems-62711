library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- =====================================================================
-- Ram256x16_tb  --  dedikeret RAM read/write tidsdiagram-testbench
-- =====================================================================
-- Demonstrerer praecis det opgavebeskrivelsen kraever: ÉT read-transfer
-- og ÉT write-transfer med alle relevante signaler (CLK, Reset,
-- Address_in, Data_in, MW, Data_out).
--
-- Sekvens (hver fase holdes 2 klok-perioder saa waveformen er let at
-- laese manuelt):
--   1) RESET            -> Data_out = 0x0000
--   2) READ  @0x00      -> Data_out = 0x16A0  (foerste program-ord;
--                          RAM'en er initialiseret med addsub_calc)
--   3) READ  @0x64      -> Data_out = 0x0000  (ubrugt RAM-celle)
--   4) WRITE @0x50=ABCD -> M[0x50] <- 0xABCD; WRITE_FIRST: Data_out=ABCD
--   5) READ  @0x50      -> Data_out = 0xABCD  (skrivning persisterede)
--
-- BRAM clockes paa NEGATIV flank (clk_n = not clk), DO_REG=0 (synkron
-- laesning), WRITE_FIRST. Derfor saettes stimulus paa STIGENDE flank,
-- og Data_out er gyldig efter den foelgende FALDENDE flank.
--
-- I Vivado xsim bruges den rigtige PWF/sources/hdl/Ram256x16.vhd
-- (Xilinx BRAM). I GHDL bruges PWF/sources/tb/Ram256x16_sim.vhd.
-- Begge har samme entity + timing.
-- =====================================================================

entity Ram256x16_tb is
end Ram256x16_tb;

architecture TB of Ram256x16_tb is

    signal clk        : STD_LOGIC := '0';
    signal Reset      : STD_LOGIC := '1';
    signal Data_in    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal Address_in : STD_LOGIC_VECTOR(7 downto 0)  := (others => '0');
    signal MW         : STD_LOGIC := '0';
    signal Data_out   : STD_LOGIC_VECTOR(15 downto 0);

    constant CLK_PERIOD : time := 20 ns;
    signal   sim_done   : boolean := false;

    -- Lille VHDL-93-kompatibel hex-formatter (4 nibbles) til paene
    -- konsol-beskeder. Asserterne sammenligner heltal; dette er kun
    -- til laesbar rapportering.
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

    UUT: entity work.Ram256x16
        port map (
            clk        => clk,
            Reset      => Reset,
            Data_in    => Data_in,
            Address_in => Address_in,
            MW         => MW,
            Data_out   => Data_out
        );

    -- Fri-loebende klok, stopper naar testen er faerdig -> "run all"
    -- terminerer selv.
    clk_process: process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_process: process
        variable n_fail : integer := 0;

        -- Saet adresse/MW/data paa stigende flank; vent forbi den
        -- faldende flank (hvor BRAM latcher) + lidt margin; tjek.
        procedure do_read(constant addr : in integer;
                          constant exp  : in integer;
                          constant tag  : in string) is
        begin
            wait until rising_edge(clk);
            Address_in <= std_logic_vector(to_unsigned(addr, 8));
            MW         <= '0';
            wait until falling_edge(clk);
            wait for 2 ns;                        -- Data_out gyldig
            assert to_integer(unsigned(Data_out)) = exp
                report tag & " FAIL: forventet 0x"
                     & hex4(std_logic_vector(to_unsigned(exp, 16)))
                     & " fik 0x" & hex4(Data_out)
                severity error;
            if to_integer(unsigned(Data_out)) /= exp then
                n_fail := n_fail + 1;
            else
                report tag & " PASS (Data_out=0x" & hex4(Data_out) & ")"
                    severity note;
            end if;
            wait until rising_edge(clk);          -- hold 1 ekstra cyklus
        end procedure;

        procedure do_write(constant addr : in integer;
                           constant val  : in integer;
                           constant tag  : in string) is
        begin
            wait until rising_edge(clk);
            Address_in <= std_logic_vector(to_unsigned(addr, 8));
            Data_in    <= std_logic_vector(to_unsigned(val, 16));
            MW         <= '1';
            wait until falling_edge(clk);
            wait for 2 ns;
            -- WRITE_FIRST: Data_out skal vise den netop skrevne vaerdi
            assert to_integer(unsigned(Data_out)) = val
                report tag & " FAIL (WRITE_FIRST): forventet 0x"
                     & hex4(std_logic_vector(to_unsigned(val, 16)))
                     & " fik 0x" & hex4(Data_out)
                severity error;
            if to_integer(unsigned(Data_out)) /= val then
                n_fail := n_fail + 1;
            else
                report tag & " PASS (skrev 0x"
                     & hex4(std_logic_vector(to_unsigned(val, 16)))
                     & ")" severity note;
            end if;
            wait until rising_edge(clk);
            MW <= '0';
        end procedure;

    begin
        -- 1) RESET
        Reset <= '1';
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        wait for 2 ns;
        assert to_integer(unsigned(Data_out)) = 0
            report "RESET FAIL: Data_out skal vaere 0x0000" severity error;
        report "RESET PASS (Data_out=0x0000)" severity note;
        wait until rising_edge(clk);
        Reset <= '0';

        -- 2) READ program-ord @0x00 (RAM init'et med addsub_calc)
        do_read(16#00#, 16#16A0#, "READ  @0x00 (prog-ord)");

        -- 3) READ ubrugt celle @0x64
        do_read(16#64#, 16#0000#, "READ  @0x64 (tom)");

        -- 4) WRITE 0xABCD @0x50
        do_write(16#50#, 16#ABCD#, "WRITE @0x50");

        -- 5) READ-BACK @0x50 -> skrivning persisterede
        do_read(16#50#, 16#ABCD#, "READ  @0x50 (back)");

        -- Opsummering
        report "==== Ram256x16_tb: " & integer'image(4 - n_fail)
             & "/4 OK, " & integer'image(n_fail) & " FAIL ====" severity note;
        assert n_fail = 0
            report "Ram256x16_tb FAILED" severity failure;
        report "==== Ram256x16_tb: ALLE TESTS BESTAAET ====" severity note;

        sim_done <= true;
        wait;
    end process;

end TB;
