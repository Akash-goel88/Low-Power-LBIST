-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity tb_mips_lbist is
-- end entity;

-- architecture sim of tb_mips_lbist is

--     constant CLK_PERIOD : time := 10 ns;

--     signal clk           : std_logic := '0';
--     signal clr           : std_logic := '1';

--     signal din           : std_logic_vector(63 downto 0) := (others => '0');
--     signal ukey          : std_logic_vector(127 downto 0) := (others => '0');
--     signal EorD          : std_logic := '0';

--     signal Reg1, Reg2    : std_logic_vector(31 downto 0);

--     -- LBIST control
--     signal lbist_mode      : std_logic := '0';
--     signal lbist_start     : std_logic := '0';
--     signal lbist_reset     : std_logic := '1';
--     signal lbist_seed      : std_logic_vector(31 downto 0) := x"A5A5A5A5";
--     signal lbist_done      : std_logic;
--     signal lbist_signature : std_logic_vector(31 downto 0);

-- begin

--     -- clock generation
--     clk_process : process
--     begin
--         clk <= '0';
--         wait for CLK_PERIOD/2;
--         clk <= '1';
--         wait for CLK_PERIOD/2;
--     end process;

--     -- DUT instantiation
--     DUT: entity work.MIPSProcessor
--         port map (
--             clk => clk,
--             clr => clr,
--             din => din,
--             ukey => ukey,
--             EorD => EorD,
--             Reg1 => Reg1,
--             Reg2 => Reg2,

--             lbist_mode => lbist_mode,
--             lbist_start => lbist_start,
--             lbist_reset => lbist_reset,
--             lbist_seed => lbist_seed,
--             lbist_done => lbist_done,
--             lbist_signature => lbist_signature
--         );

--     -- Test process without any prints
--     stim_proc : process
--     begin
--         -- reset
--         clr <= '1';
--         lbist_reset <= '1';
--         wait for 100 ns;

--         clr <= '0';
--         lbist_reset <= '0';
--         wait for 20 ns;

--         -- normal CPU running
--         lbist_mode <= '0';
--         wait for 300 ns;

--         -- LBIST run 1
--         lbist_mode <= '1';
--         wait for 20 ns;

--         lbist_start <= '1';
--         wait for CLK_PERIOD;
--         lbist_start <= '0';

--         wait until lbist_done = '1';
--         wait for 20 ns;

--         -- LBIST run 2 (different seed)
--         lbist_seed <= x"5A5A5A5A";
--         wait for 20 ns;

--         lbist_start <= '1';
--         wait for CLK_PERIOD;
--         lbist_start <= '0';

--         wait until lbist_done = '1';
--         wait for 20 ns;

--         wait;
--     end process;

-- end architecture;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mips_lbist is
end entity;

architecture sim of tb_mips_lbist is

    -------------------------------------------------------------------------
    -- DUT signals
    -------------------------------------------------------------------------
    signal clk   : std_logic := '0';
    signal clr   : std_logic := '0';

    signal din   : std_logic_vector(63 downto 0) := (others => '0');
    signal ukey  : std_logic_vector(127 downto 0) := (others => '0');

    signal EorD  : std_logic := '0';
    signal Reg1  : std_logic_vector(31 downto 0);
    signal Reg2  : std_logic_vector(31 downto 0);

    -- LBIST
    signal lbist_mode      : std_logic := '0';
    signal lbist_start     : std_logic := '0';
    signal lbist_reset     : std_logic := '0';
    signal lbist_seed      : std_logic_vector(31 downto 0) := x"A5A5A5A5";
    signal lbist_done      : std_logic;
    signal lbist_signature : std_logic_vector(31 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    -------------------------------------------------------------------------
    -- Clock generation
    -------------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2;

    -------------------------------------------------------------------------
    -- DUT instantiation
    -------------------------------------------------------------------------
    DUT: entity work.MIPSProcessor
        port map (
            clk   => clk,
            clr   => clr,
            din   => din,
            ukey  => ukey,
            EorD  => EorD,
            Reg1  => Reg1,
            Reg2  => Reg2,

            lbist_mode      => lbist_mode,
            lbist_start     => lbist_start,
            lbist_reset     => lbist_reset,
            lbist_seed      => lbist_seed,
            lbist_done      => lbist_done,
            lbist_signature => lbist_signature
        );

    -------------------------------------------------------------------------
    -- Test process
    -------------------------------------------------------------------------
    stim_proc: process
    begin
        ---------------------------------------------------------------------
        -- 0) GLOBAL RESET
        ---------------------------------------------------------------------
        clr <= '1';
        lbist_reset <= '1';
        wait for 50 ns;

        clr <= '0';
        lbist_reset <= '0';
        wait for 50 ns;


        ---------------------------------------------------------------------
        -- 1) RUN CPU IN NORMAL MODE FIRST
        --    Useful to confirm PC, IM, validator, ALU behave normally.
        ---------------------------------------------------------------------
        lbist_mode <= '0';      -- CPU mode

        -- let CPU run for 500 ns
        wait for 500 ns;


        ---------------------------------------------------------------------
        -- 2) NOW ENABLE LBIST MODE
        ---------------------------------------------------------------------
        lbist_mode <= '1';
        wait for 20 ns;

        ---------------------------------------------------------------------
        -- 3) LBIST RESET
        ---------------------------------------------------------------------
        lbist_reset <= '1';
        wait for 30 ns;
        lbist_reset <= '0';
        wait for 50 ns;

        ---------------------------------------------------------------------
        -- 4) START LBIST
        ---------------------------------------------------------------------
        lbist_start <= '1';
        wait for CLK_PERIOD;
        lbist_start <= '0';

        ---------------------------------------------------------------------
        -- 5) Wait until LBIST completes (done = '1')
        ---------------------------------------------------------------------
        wait until lbist_done = '1';
        wait for 40 ns;

        ---------------------------------------------------------------------
        -- 6) End of simulation
        ---------------------------------------------------------------------
        wait;
    end process;

end architecture;
