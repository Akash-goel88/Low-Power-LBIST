library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lbist_top is
    generic (
        SCAN_WIDTH  : integer := 32;
        LFSR_WIDTH  : integer := 32;
        MISR_WIDTH  : integer := 32;

        CONTROL_MODE : integer := 1;
        HEAD_LEN     : integer := 16;
        MID_LEN      : integer := 16;
        STEP_SIZE    : integer := 4;

        UNMASK_PERIOD : integer := 16;
        ENABLE_TFF    : boolean := true
    );
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        start          : in  std_logic;
        seed           : in  std_logic_vector(LFSR_WIDTH-1 downto 0);
        inject_fault   : in  std_logic := '0';
        done           : out std_logic;

        lfsr_state       : out std_logic_vector(LFSR_WIDTH-1 downto 0);
        scan_chain_state : out std_logic_vector(SCAN_WIDTH-1 downto 0);
        signature_out    : out std_logic_vector(MISR_WIDTH-1 downto 0);
        direct_outputs   : out std_logic_vector(8 downto 0);

        tff_debug        : out std_logic;
        plpf_sel_dbg     : out std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of lbist_top is

    signal regs         : std_logic_vector(SCAN_WIDTH-1 downto 0) := (others => '0');

    -- LFSR / state
    signal lfsr_bit                : std_logic;
    signal internal_lfsr_state     : std_logic_vector(LFSR_WIDTH-1 downto 0);

    -- controller
    signal shift_in_en, shift_out_en, capture_en : std_logic;
    signal lfsr_advance_sig : std_logic;
    signal controller_done   : std_logic;

    signal serial_out         : std_logic := '0';

    -- DUT signals
    signal a_sig, b_sig        : std_logic_vector(7 downto 0);
    signal cin_sig             : std_logic;
    signal sum_sig             : std_logic_vector(7 downto 0);
    signal cout_sig            : std_logic;

    signal shift_counter       : integer range 0 to SCAN_WIDTH := 0;
    signal start_d             : std_logic := '0';
    signal start_pulse         : std_logic := '0';

    signal misr_reset          : std_logic := '0';

    signal tff_out             : std_logic := '0';

    -- PLPF outputs (single-bit)
    signal plpf1_out, plpf2_out, plpf3_out : std_logic;

    -- selected and pipelined bits
    signal filtered_bit        : std_logic := '0';
    signal filtered_bit_d      : std_logic := '0';

    signal plpf_sel            : std_logic_vector(1 downto 0) := "00";

    -- input to PLPFs (raw)
    signal raw_in_sig          : std_logic := '0';

    signal pattern_count       : integer := 0;
    signal force_unmask        : std_logic := '0';

    signal high_start          : integer range 0 to SCAN_WIDTH-1 := 0;

    constant FAULT_INDEX : integer := 5;

    attribute keep       : boolean;
    attribute mark_debug : boolean;
    attribute keep       of tff_out : signal is true;
    attribute mark_debug of tff_out : signal is true;

begin

    -------------------------------------------------------------------------
    -- Feed raw LFSR bit directly to PLPFs (no phase shifter)
    -- choose MSB of internal_lfsr_state for raw bit
    -------------------------------------------------------------------------
    raw_in_sig <= internal_lfsr_state(LFSR_WIDTH-1);

    -------------------------------------------------------------------------
    -- START edge detect
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                start_d <= '0';
                start_pulse <= '0';
            else
                start_d <= start;
                start_pulse <= start and (not start_d);
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Pattern counter & unmask scheduling
    -------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset='1' then
                pattern_count <= 0;
                force_unmask <= '0';
            else
                if start_pulse='1' then
                    if (pattern_count mod UNMASK_PERIOD)=0 then
                        force_unmask <= '1';
                    else
                        force_unmask <= '0';
                    end if;
                    pattern_count <= pattern_count + 1;
                end if;

                if controller_done='1' then
                    force_unmask <= '0';
                end if;

                if start_pulse='1' and CONTROL_MODE=1 then
                    high_start <= (pattern_count * STEP_SIZE) mod SCAN_WIDTH;
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- LFSR instance
    -------------------------------------------------------------------------
    LFSR_INST: entity work.lfsr
      generic map (WIDTH => LFSR_WIDTH)
      port map (
        clk     => clk,
        reset   => reset,
        load    => '0',
        seed    => seed,
        out_bit => lfsr_bit,
        state   => internal_lfsr_state,
        advance => lfsr_advance_sig
      );

    lfsr_state <= internal_lfsr_state;

    -------------------------------------------------------------------------
    -- PLPF INSTANCES (1-bit registered devices)
    -------------------------------------------------------------------------
    PLPF1_INST : entity work.plpf1
      port map (clk=>clk, reset=>reset, in_bit=>raw_in_sig, out_bit=>plpf1_out);

    PLPF2_INST : entity work.plpf2
      port map (clk=>clk, reset=>reset, in_bit=>raw_in_sig, out_bit=>plpf2_out);

    PLPF3_INST : entity work.plpf3
      port map (clk=>clk, reset=>reset, in_bit=>raw_in_sig, out_bit=>plpf3_out);

    -------------------------------------------------------------------------
    -- Scan controller
    -------------------------------------------------------------------------
    CONT: entity work.scan_controller
      port map (
        clk => clk,
        reset => reset,
        start => start,
        scan_width => SCAN_WIDTH,
        shift_in_en => shift_in_en,
        shift_out_en => shift_out_en,
        capture_en => capture_en,
        done => controller_done,
        lfsr_advance => lfsr_advance_sig
      );

    done <= controller_done;

    -------------------------------------------------------------------------
    -- MISR instance
    -------------------------------------------------------------------------
    misr_reset <= reset or start_pulse;

    MISR_INST: entity work.misr
      generic map (WIDTH => MISR_WIDTH)
      port map (
        clk => clk,
        reset => misr_reset,
        en => shift_out_en,
        data_in => serial_out,
        signature => signature_out
      );

    -------------------------------------------------------------------------
    -- MAIN SCAN PROCESS
    -------------------------------------------------------------------------
    process(clk)
        variable bit_in_v  : std_logic;
        variable use_plpf  : std_logic_vector(1 downto 0);
        variable head_len_local : integer := HEAD_LEN;
        variable mid_len_local  : integer := MID_LEN;
        variable high_end : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                regs <= (others=>'0');
                shift_counter <= 0;
                serial_out <= '0';
                tff_out <= '0';
                plpf_sel <= "00";
                filtered_bit <= '0';
                filtered_bit_d <= '0';

            else
                serial_out <= '0';
                bit_in_v := '0';

                -----------------------------------------------------------------
                -- PLPF region selection
                -----------------------------------------------------------------
                if CONTROL_MODE = 0 then
                    if shift_counter < head_len_local then
                        use_plpf := "10"; -- PLPF3
                    elsif shift_counter < (head_len_local + mid_len_local) then
                        use_plpf := "00"; -- PLPF1 (raw)
                    else
                        use_plpf := "10"; -- PLPF3
                    end if;
                else
                    high_end := (high_start + mid_len_local) - 1;
                    if high_end < SCAN_WIDTH then
                        if (shift_counter >= high_start) and (shift_counter <= high_end) then
                            use_plpf := "00";
                        else
                            use_plpf := "10";
                        end if;
                    else
                        if (shift_counter >= high_start) or (shift_counter <= (high_end mod SCAN_WIDTH)) then
                            use_plpf := "00";
                        else
                            use_plpf := "10";
                        end if;
                    end if;
                end if;

                -----------------------------------------------------------------
                -- TFF gating for low-power (unchanged)
                -----------------------------------------------------------------
                if force_unmask='1' then
                    tff_out <= '1';
                elsif ENABLE_TFF then
                    if shift_in_en='1' then
                        tff_out <= not tff_out;
                    end if;
                else
                    tff_out <= '1';
                end if;

                -----------------------------------------------------------------
                -- SHIFT-IN (uses pipelined PLPF output)
                -----------------------------------------------------------------
                if shift_in_en='1' then

                    if shift_counter = 0 then
                        regs <= (others=>'0');
                    end if;

                    case use_plpf is
                        when "00" => filtered_bit <= plpf1_out;
                        when "01" => filtered_bit <= plpf2_out;
                        when "10" => filtered_bit <= plpf3_out;
                        when others => filtered_bit <= plpf1_out;
                    end case;

                    -- apply TFF gating
                    if ENABLE_TFF then
                        bit_in_v := filtered_bit and tff_out;
                    else
                        bit_in_v := filtered_bit;
                    end if;

                    -- fault injection
                    if inject_fault='1' and shift_counter=FAULT_INDEX then
                        bit_in_v := not bit_in_v;
                    end if;

                    -- pipeline the gated/filtered bit so PLPF timing aligns
                    filtered_bit_d <= bit_in_v;

                    -- shift into regs using pipelined bit
                    regs <= regs(SCAN_WIDTH-2 downto 0) & filtered_bit_d;

                    if shift_counter = SCAN_WIDTH-1 then
                        shift_counter <= 0;
                    else
                        shift_counter <= shift_counter + 1;
                    end if;

                    plpf_sel <= use_plpf;

                -----------------------------------------------------------------
                -- CAPTURE
                -----------------------------------------------------------------
                elsif capture_en='1' then
                    regs(7 downto 0) <= sum_sig;
                    regs(8) <= cout_sig;

                -----------------------------------------------------------------
                -- SHIFT-OUT
                -----------------------------------------------------------------
                elsif shift_out_en='1' then
                    serial_out <= regs(SCAN_WIDTH-1);
                    regs <= regs(SCAN_WIDTH-2 downto 0) & '0';

                    if shift_counter = SCAN_WIDTH-1 then
                        shift_counter <= 0;
                    else
                        shift_counter <= shift_counter + 1;
                    end if;

                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Outputs & DUT mapping
    -------------------------------------------------------------------------
    scan_chain_state <= regs;
    tff_debug <= tff_out;
    plpf_sel_dbg <= plpf_sel;

    a_sig <= regs(7 downto 0);
    b_sig <= regs(15 downto 8);
    cin_sig <= regs(16);

    DUT_INST: entity work.dut
        port map (
            a    => a_sig,
            b    => b_sig,
            cin  => cin_sig,
            sum  => sum_sig,
            cout => cout_sig
        );

    direct_outputs <= cout_sig & sum_sig;

end architecture;
