library ieee;
use ieee.std_logic_1164.all;

entity plpf3 is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        in_bit  : in  std_logic;
        out_bit : out std_logic
    );
end entity;

architecture rtl of plpf3 is
    signal in_reg  : std_logic := '0';
    signal prev1   : std_logic := '0';
    signal prev2   : std_logic := '0';
    signal out_reg : std_logic := '0';
begin
    -- sample input and maintain two-bit history; output is registered
    process(clk, reset)
    begin
        if reset = '1' then
            in_reg  <= '0';
            prev1   <= '0';
            prev2   <= '0';
            out_reg <= '0';
        elsif rising_edge(clk) then
            -- rotate history
            prev2   <= prev1;
            prev1   <= in_reg;
            in_reg  <= in_bit;

            -- basic strong smoothing (n=3): AND of three successive inputs reduces toggles strongly
            out_reg <= in_reg AND prev1 AND prev2;
        end if;
    end process;

    out_bit <= out_reg;
end architecture;
