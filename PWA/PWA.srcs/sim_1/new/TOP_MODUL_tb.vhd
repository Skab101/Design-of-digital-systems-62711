----------------------------------------------------------------------------------
-- Module Name: full_adder_8_bit_tb
-- Description: Testbench for full_adder_8_bit
--              Tests addition, carry propagation, and carry-out
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity full_adder_8_bit_tb is
end full_adder_8_bit_tb;

architecture tb of full_adder_8_bit_tb is

    signal A, B   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal sum     : STD_LOGIC_VECTOR(7 downto 0);
    signal Cout    : STD_LOGIC;

    constant DELAY : time := 20 ns;

begin

    uut: entity work.full_adder_8_bit
        port map (
            A    => A,
            B    => B,
            sum  => sum,
            Cout => Cout
        );

    stim: process
    begin
        -- Test 1: 0 + 0 = 0, Cout=0
        A <= x"00"; B <= x"00";
        wait for DELAY;
        assert sum = x"00" and Cout = '0'
            report "FAIL: 0+0" severity error;

        -- Test 2: 1 + 1 = 2, Cout=0
        A <= x"01"; B <= x"01";
        wait for DELAY;
        assert sum = x"02" and Cout = '0'
            report "FAIL: 1+1" severity error;

        -- Test 3: 15 + 1 = 16 (carry propagation across nibble)
        A <= x"0F"; B <= x"01";
        wait for DELAY;
        assert sum = x"10" and Cout = '0'
            report "FAIL: 0F+01" severity error;

        -- Test 4: 255 + 1 = 0 with Cout=1
        A <= x"FF"; B <= x"01";
        wait for DELAY;
        assert sum = x"00" and Cout = '1'
            report "FAIL: FF+01" severity error;

        -- Test 5: 255 + 255 = 254 with Cout=1
        A <= x"FF"; B <= x"FF";
        wait for DELAY;
        assert sum = x"FE" and Cout = '1'
            report "FAIL: FF+FF" severity error;

        -- Test 6: 128 + 128 = 0 with Cout=1
        A <= x"80"; B <= x"80";
        wait for DELAY;
        assert sum = x"00" and Cout = '1'
            report "FAIL: 80+80" severity error;

        -- Test 7: 170 + 85 = 255 (0xAA + 0x55), Cout=0
        A <= x"AA"; B <= x"55";
        wait for DELAY;
        assert sum = x"FF" and Cout = '0'
            report "FAIL: AA+55" severity error;

        -- Test 8: 100 + 50 = 150 (0x64 + 0x32 = 0x96)
        A <= x"64"; B <= x"32";
        wait for DELAY;
        assert sum = x"96" and Cout = '0'
            report "FAIL: 64+32" severity error;

        -- Test 9: full carry chain - 1 + 127 = 128
        A <= x"01"; B <= x"7F";
        wait for DELAY;
        assert sum = x"80" and Cout = '0'
            report "FAIL: 01+7F" severity error;

        -- Test 10: 200 + 100 = 44 with Cout=1 (0xC8 + 0x64 = 0x12C)
        A <= x"C8"; B <= x"64";
        wait for DELAY;
        assert sum = x"2C" and Cout = '1'
            report "FAIL: C8+64" severity error;

        report "All tests completed." severity note;
        wait;
    end process;

end tb;
