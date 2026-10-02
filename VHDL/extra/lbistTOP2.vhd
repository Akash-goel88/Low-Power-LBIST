library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pure_lbist_top is
    generic (
        SCAN_WIDTH  : integer := 32;
        LFSR_WIDTH  : integer := 32;
        MISR_WIDTH  : integer := 32
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        start      : in  std_logic;
        seed       : in  std_logic_vector(LFSR_WIDTH-1 downto 0);

        done       : out std_logic;

        scan_chain_state : out std_logic_vector(SCAN_WIDTH-1 downto 0);
        lfsr_state       : out std_logic_vector(LFSR_WIDTH-1 downto 0);
        signature_out    : out std_logic_vector(MISR_WIDTH-1 downto 0)
    );
end entity pure_lbist_top;


architecture rtl of pure_lbist_top is

    -------------------------------------------------------------------------
    -- INTERNAL SIGNALS
    -------------------------------------------------------------------------
    signal regs        : std_logic_vector(SCAN_WIDTH-1 downto 0) := (others => '0');
    signal lfsr_vec    : std_logic_vector(LFSR_WIDTH-1 downto 0) := (others => '0');
    signal lfsr_bit    : std_logic := '0';

    signal serial_out  : std_logic := '0';
    signal misr_reset  : std_logic := '0';
    signal misr_en     : std_logic := '0';

    signal start_d     : std_logic := '0';
    signal start_pulse : std_logic := '0';

    signal shift_counter : integer := 0;
    signal done_int      : std_logic := '0';

    -------------------------------------------------------------------------
    -- FSM DECLARATION
    -------------------------------------------------------------------------
    type st_type is (IDLE, SHIFT_IN, CAPTURE, SHIFT_OUT, DONE_STATE);
    signal st : st_type := IDLE;

    -------------------------------------------------------------------------
    -- DUT SIGNALS
    -------------------------------------------------------------------------
    signal a_sig   : std_logic_vector(7 downto 0);
    signal b_sig   : std_logic_vector(7 downto 0);
    signal cin_sig : std_logic;
    signal sum_sig : std_logic_vector(7 downto 0);
    signal cout_sig: std_logic;

begin

    done <= done_int;

    -------------------------------------------------------------------------
    -- LFSR INSTANCE
    -------------------------------------------------------------------------
    LFSR_INST : entity work.lfsr
        generic map (
            WIDTH => LFSR_WIDTH
        )
        port map (
            clk     => clk,
            reset   => reset,
            load    => start_pulse,
            seed    => seed,
            out_bit => lfsr_bit,
            state   => lfsr_vec,
            advance => '1'
        );

    lfsr_state <= lfsr_vec;


    -------------------------------------------------------------------------
    -- MISR INSTANCE
    -------------------------------------------------------------------------
    MISR_INST : entity work.misr
        generic map (
            WIDTH => MISR_WIDTH
        )
        port map (
            clk       => clk,
            reset     => misr_reset,
            en        => misr_en,
            data_in   => serial_out,
            signature => signature_out
        );

    misr_reset <= reset or start_pulse;


    -------------------------------------------------------------------------
    -- START PULSE DETECTOR
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            start_d     <= start;
            start_pulse <= start and not start_d;
        end if;
    end process;


    -------------------------------------------------------------------------
    -- MAP DUT INPUTS FROM SCAN CHAIN
    -------------------------------------------------------------------------
    a_sig   <= regs(7 downto 0);
    b_sig   <= regs(15 downto 8);
    cin_sig <= regs(16);

    -------------------------------------------------------------------------
    -- DUT INSTANCE
    -------------------------------------------------------------------------
    DUT_INST : entity work.dut
        port map (
            a    => a_sig,
            b    => b_sig,
            cin  => cin_sig,
            sum  => sum_sig,
            cout => cout_sig
        );


    -------------------------------------------------------------------------
    -- FSM FOR PURE LBIST
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            if reset = '1' then
                st            <= IDLE;
                shift_counter <= 0;
                done_int      <= '0';
                regs          <= (others => '0');
                misr_en       <= '0';

            else
                case st is

                    -----------------------------------------------------------------
                    when IDLE =>
                        done_int <= '0';
                        misr_en  <= '0';

                        if start_pulse = '1' then
                            shift_counter <= 0;
                            st <= SHIFT_IN;
                        end if;

                    -----------------------------------------------------------------
                    when SHIFT_IN =>
                        regs <= regs(SCAN_WIDTH-2 downto 0) & lfsr_bit;
                        misr_en <= '0';

                        if shift_counter = SCAN_WIDTH - 1 then
                            shift_counter <= 0;
                            st <= CAPTURE;
                        else
                            shift_counter <= shift_counter + 1;
                        end if;

                    -----------------------------------------------------------------
                    when CAPTURE =>
                        -- capture DUT outputs into scan registers
                        regs(7 downto 0) <= sum_sig;
                        regs(8)          <= cout_sig;

                        misr_en <= '0';
                        st <= SHIFT_OUT;

                    -----------------------------------------------------------------
                    when SHIFT_OUT =>
                        serial_out <= regs(SCAN_WIDTH-1);
                        regs <= regs(SCAN_WIDTH-2 downto 0) & '0';

                        misr_en <= '1';

                        if shift_counter = SCAN_WIDTH - 1 then
                            shift_counter <= 0;
                            st <= DONE_STATE;
                        else
                            shift_counter <= shift_counter + 1;
                        end if;

                    -----------------------------------------------------------------
                    when DONE_STATE =>
                        misr_en  <= '0';
                        done_int <= '1';
                        st       <= IDLE;

                end case;
            end if;
        end if;
    end process;


    -------------------------------------------------------------------------
    -- OUTPUT SCAN CHAIN STATE
    -------------------------------------------------------------------------
    scan_chain_state <= regs;

end architecture rtl;
