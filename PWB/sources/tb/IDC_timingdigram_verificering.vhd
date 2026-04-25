library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IDC_timingdiagram_verificering is
end IDC_timingdiagram_verificering;

architecture TB of IDC_timingdiagram_verificering is

    -- Clock
    signal CLK   : std_logic := '0';
    signal RESET : std_logic := '1';

    -- Inputs
    signal IR : std_logic_vector(15 downto 0) := (others => '0');
    signal V, C, N, Z : std_logic := '0';

    -- Outputs
    signal PS : std_logic_vector(1 downto 0);
    signal IL : std_logic;
    signal DX, AX, BX, FS : std_logic_vector(3 downto 0);
    signal MB, MD, RW, MM, MW : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    -- Helper: build IR from opcode (rest don't care)
    function make_ir(opcode : std_logic_vector(6 downto 0))
        return std_logic_vector is
    begin
        return opcode & "000000000";
    end function;

begin

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------
    UUT : entity work.InstructionDecoderController
        port map (
            RESET => RESET,
            CLK   => CLK,
            IR    => IR,
            V => V, C => C, N => N, Z => Z,
            PS => PS,
            IL => IL,
            DX => DX, AX => AX, BX => BX, FS => FS,
            MB => MB, MD => MD, RW => RW, MM => MM, MW => MW
        );

    ------------------------------------------------------------------
    -- Clock generator
    ------------------------------------------------------------------
    clk_process : process
    begin
        CLK <= '0'; wait for CLK_PERIOD/2;
        CLK <= '1'; wait for CLK_PERIOD/2;
    end process;

    ------------------------------------------------------------------
    -- Stimulus: timingdiagram-verifikation
    ------------------------------------------------------------------
stim_process : process
begin
    ----------------------------------------------------------
    -- Initial conditions
    ----------------------------------------------------------
    RESET <= '0';
    IR    <= (others => '0');

    ----------------------------------------------------------
    -- 1) Første clockperiode: SUB kører normalt
    ----------------------------------------------------------
    IR <= "0000101" & "000000000";  -- SUB opcode

    -- Lad første clockperiode (0 -> 10 ns) forløbe
    wait for 10 ns;

    ----------------------------------------------------------
    -- 2) Asynkront reset midt i perioden (11–12 ns)
    ----------------------------------------------------------
    wait for 1 ns;          -- tid = 11 ns
    RESET <= '1';
    wait for 1 ns;          -- tid = 12 ns
    RESET <= '0';

    ----------------------------------------------------------
    -- 3) Skift til ADD og lad systemet køre normalt
    ----------------------------------------------------------
    IR <= "0000010" & "000000000";  -- ADD opcode

    ----------------------------------------------------------
    -- Verifikation efter reset
    ----------------------------------------------------------
    -- Vent til næste rising edge efter reset
    wait until rising_edge(CLK);
    wait for 1 ns;

    -- Efter async reset skal FSM være i INF
    assert IL = '1'
        report "After async reset: IL expected 1 (INF)"
        severity error;

    ----------------------------------------------------------
    -- ADD: EX0-cyklus
    ----------------------------------------------------------
    wait until rising_edge(CLK);
    wait for 1 ns;

    assert RW = '1'
        report "ADD EX0: RW expected 1"
        severity error;
    assert PS = "01"
        report "ADD EX0: PS expected 01"
        severity error;
    assert FS = "0010"
        report "ADD EX0: FS expected 0010"
        severity error;

    ----------------------------------------------------------
    end process;

end TB;