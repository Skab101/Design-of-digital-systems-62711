library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- 256 x 16-bit single-port RAM (inferred Block RAM)
--
-- Vivado's syntese udleder Block RAM fra moenstret nedenfor (clocked
-- write + clocked read i samme proces). Til gengaeld for behavioral
-- simulering: data initialiseres deterministisk via init_ram-funktionen,
-- saa xsim ikke har problemer med UNIMACRO/GLBL og BRAM-makroer.
--
-- RAM clocked paa FALDENDE kant saa data er klar paa naeste stigende
-- kant hvor IR i MPC latcher. PWB's IDC asserterer MM=1 og IL=1 i samme
-- INF-cyklus, hvilket forudsaetter ~0-cyklus memory read.
entity Ram256x16 is
    port (
        clk        : in  STD_LOGIC;
        Reset      : in  STD_LOGIC;
        Data_in    : in  STD_LOGIC_VECTOR(15 downto 0);
        Address_in : in  STD_LOGIC_VECTOR(7 downto 0);
        MW         : in  STD_LOGIC;
        Data_out   : out STD_LOGIC_VECTOR(15 downto 0)
    );
end Ram256x16;

architecture RAM_Inferred of Ram256x16 is

    type ram_t is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0);

    -- Microcode-program. Disassembleret fra examples/sum_demo.asm.
    -- PROGRAM_INIT_BEGIN
    function init_ram return ram_t is
        variable r : ram_t := (others => x"0000");
    begin
        r(16#00#) := x"99C7";  -- ldi  R7, 7
        r(16#01#) := x"E038";  -- jmp  R7
        r(16#02#) := x"00FA";  -- .word A_MR2
        r(16#03#) := x"00F8";  -- .word A_MR0
        r(16#04#) := x"00F9";  -- .word A_MR1
        r(16#05#) := x"00FB";  -- .word A_MR3
        r(16#06#) := x"00FC";  -- .word A_MR4
        r(16#07#) := x"9805";  -- ldi  R0, 5
        r(16#08#) := x"20C0";  -- ld   R3, R0
        r(16#09#) := x"9806";  -- ldi  R0, 6
        r(16#0A#) := x"2100";  -- ld   R4, R0
        r(16#0B#) := x"2058";  -- ld   R1, R3
        r(16#0C#) := x"20A0";  -- ld   R2, R4
        r(16#0D#) := x"058A";  -- add  R6, R1, R2
        r(16#0E#) := x"9802";  -- ldi  R0, 2
        r(16#0F#) := x"2140";  -- ld   R5, R0
        r(16#10#) := x"402E";  -- st   R5, R6
        r(16#11#) := x"9803";  -- ldi  R0, 3
        r(16#12#) := x"2140";  -- ld   R5, R0
        r(16#13#) := x"402E";  -- st   R5, R6
        r(16#14#) := x"9804";  -- ldi  R0, 4
        r(16#15#) := x"2140";  -- ld   R5, R0
        r(16#16#) := x"4029";  -- st   R5, R1
        r(16#17#) := x"E038";  -- jmp  R7
        return r;
    end function;
    -- PROGRAM_INIT_END

    signal ram      : ram_t := init_ram;
    signal addr_int : integer range 0 to 255;

begin

    addr_int <= to_integer(unsigned(Address_in));

    -- Falling-edge clocked synchronous RAM med write-first-konvention.
    -- Reset er synkron og nulstiller udelukkende output-latch'en
    -- (RAM-indholdet bevares).
    process(clk)
    begin
        if falling_edge(clk) then
            if Reset = '1' then
                Data_out <= (others => '0');
            else
                if MW = '1' then
                    ram(addr_int) <= Data_in;
                    Data_out      <= Data_in;        -- WRITE_FIRST
                else
                    Data_out      <= ram(addr_int);
                end if;
            end if;
        end if;
    end process;

end RAM_Inferred;
