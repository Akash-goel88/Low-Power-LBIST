library ieee;
use ieee.std_logic_1164.all;

entity plpf1 is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        in_bit  : in  std_logic;
        out_bit : out std_logic
    );
end entity;

architecture rtl of plpf1 is
    signal in_reg : std_logic := '0';
    signal out_reg : std_logic := '0';
begin
    -- register the input and drive a registered output (pass-through)
    process(clk, reset)
    begin
        if reset = '1' then
            in_reg  <= '0';
            out_reg <= '0';
        elsif rising_edge(clk) then
            in_reg  <= in_bit;
            out_reg <= in_reg; -- one-cycle pipeline: output follows previous input
        end if;
    end process;

    out_bit <= out_reg;
end architecture;
