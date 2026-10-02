library ieee;
use ieee.std_logic_1164.all;

entity plpf2 is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        in_bit  : in  std_logic;
        out_bit : out std_logic
    );
end entity;

architecture rtl of plpf2 is
    signal prev1 : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            prev1 <= '0';
        elsif rising_edge(clk) then
            prev1 <= in_bit;
        end if;
    end process;

    -- BASIC PLPF(n=2): AND(current, previous)
    out_bit <= in_bit AND prev1;
end architecture;
