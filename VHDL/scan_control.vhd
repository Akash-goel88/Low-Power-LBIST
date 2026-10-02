-- -- library ieee;
-- -- use ieee.std_logic_1164.all;
-- -- use ieee.numeric_std.all;

-- -- entity scan_controller is
-- --     port (
-- --         clk           : in  std_logic;  -- System clock
-- --         clk_scan      : in  std_logic;  -- Scan clock (added)
-- --         reset         : in  std_logic;
-- --         start         : in  std_logic;
-- --         scan_width    : in  integer;

-- --         shift_in_en   : out std_logic;
-- --         shift_out_en  : out std_logic;
-- --         capture_en    : out std_logic;
-- --         update_en     : out std_logic;
-- --         done          : out std_logic;
        
-- --         -- New signals for phase shifter coordination
-- --         lfsr_advance  : out std_logic;  -- Signal to advance LFSR
-- --         pattern_loaded : out std_logic  -- Indicates pattern is loaded
-- --     );
-- -- end entity;

-- -- architecture rtl of scan_controller is

-- --     type state_type is (
-- --         IDLE, SHIFT_IN, CAPTURE, UPDATE, SHIFT_OUT, DONE_STATE
-- --     );

-- --     signal state      : state_type := IDLE;
-- --     signal next_state : state_type := IDLE;

-- --     signal cnt : integer := 0;
-- --     signal scan_cycle_cnt : integer := 0;
    
-- --     -- Synchronization signals for dual-clock domain
-- --     signal start_sync : std_logic := '0';
-- --     signal start_pulse : std_logic := '0';

-- -- begin

-- --     --------------------------------------------------------------------
-- --     -- START SIGNAL SYNCHRONIZATION (System clock domain)
-- --     --------------------------------------------------------------------
-- --     process(clk, reset)
-- --     begin
-- --         if reset = '1' then
-- --             start_sync <= '0';
-- --             start_pulse <= '0';
-- --         elsif rising_edge(clk) then
-- --             start_sync <= start;
-- --             start_pulse <= start and not start_sync;  -- Detect rising edge
-- --         end if;
-- --     end process;

-- --     --------------------------------------------------------------------
-- --     -- STATE REGISTER (System clock domain)
-- --     --------------------------------------------------------------------
-- --     process(clk, reset)
-- --     begin
-- --         if reset = '1' then
-- --             state <= IDLE;
-- --             cnt   <= 0;
-- --             scan_cycle_cnt <= 0;
-- --         elsif rising_edge(clk) then
-- --             state <= next_state;

-- --             -- Counter for shift operations (counts system clock cycles)
-- --             if (state = SHIFT_IN) or (state = SHIFT_OUT) then
-- --                 if cnt < scan_width-1 then
-- --                     cnt <= cnt + 1;
-- --                 else
-- --                     cnt <= 0;
-- --                 end if;
-- --             else
-- --                 cnt <= 0;
-- --             end if;
            
-- --             -- Count scan cycles for LFSR advancement
-- --             if state = SHIFT_IN then
-- --                 if scan_cycle_cnt < scan_width-1 then
-- --                     scan_cycle_cnt <= scan_cycle_cnt + 1;
-- --                 else
-- --                     scan_cycle_cnt <= 0;
-- --                 end if;
-- --             else
-- --                 scan_cycle_cnt <= 0;
-- --             end if;
-- --         end if;
-- --     end process;

-- --     --------------------------------------------------------------------
-- --     -- NEXT STATE LOGIC (System clock domain)
-- --     --------------------------------------------------------------------
-- --     process(state, start_pulse, cnt, scan_width)
-- --     begin
-- --         next_state <= state;

-- --         case state is
-- --             when IDLE =>
-- --                 if start_pulse = '1' then
-- --                     next_state <= SHIFT_IN;
-- --                 end if;

-- --             when SHIFT_IN =>
-- --                 if cnt = scan_width-1 then
-- --                     next_state <= CAPTURE;
-- --                 end if;

-- --             when CAPTURE =>
-- --                 next_state <= UPDATE;

-- --             when UPDATE =>
-- --                 next_state <= SHIFT_OUT;

-- --             when SHIFT_OUT =>
-- --                 if cnt = scan_width-1 then
-- --                     next_state <= DONE_STATE;
-- --                 end if;

-- --             when DONE_STATE =>
-- --                 next_state <= IDLE;

-- --             when others =>
-- --                 next_state <= IDLE;
-- --         end case;
-- --     end process;

-- --     --------------------------------------------------------------------
-- --     -- OUTPUT LOGIC
-- --     --------------------------------------------------------------------
-- --     shift_in_en  <= '1' when state = SHIFT_IN  else '0';
-- --     shift_out_en <= '1' when state = SHIFT_OUT else '0';
-- --     capture_en   <= '1' when state = CAPTURE   else '0';
-- --     update_en    <= '1' when state = UPDATE    else '0';
-- --     done         <= '1' when state = DONE_STATE else '0';
    
-- --     -- Advance LFSR during shift-in operation (every system clock cycle)
-- --     lfsr_advance <= '1' when state = SHIFT_IN else '0';
    
-- --     -- Pattern loaded signal (goes high when shifting is complete)
-- --     pattern_loaded <= '1' when state = CAPTURE or state = UPDATE or 
-- --                                 state = SHIFT_OUT or state = DONE_STATE else '0';

-- -- end architecture;


-- --simpler version:
-- -- scan_controller.vhd
-- library ieee;
-- use ieee.std_logic_1164.all;

-- entity scan_controller is
--     port (
--         clk           : in  std_logic;
--         reset         : in  std_logic;
--         start         : in  std_logic;
--         scan_width    : in  integer;
--         shift_in_en   : out std_logic;
--         shift_out_en  : out std_logic;
--         capture_en    : out std_logic;
--         update_en     : out std_logic;
--         done          : out std_logic;
--         lfsr_advance  : out std_logic
--     );
-- end entity;

-- architecture rtl of scan_controller is
--     type state_type is (IDLE, SHIFT_IN, CAPTURE, SHIFT_OUT, DONE_STATE);
--     signal state : state_type := IDLE;
--     signal cnt : integer := 0;
-- begin
--     process(clk, reset)
--     begin
--         if reset = '1' then
--             state <= IDLE;
--             cnt <= 0;
--         elsif rising_edge(clk) then
--             case state is
--                 when IDLE =>
--                     if start = '1' then
--                         state <= SHIFT_IN;
--                         cnt <= 0;
--                     end if;
                    
--                 when SHIFT_IN =>
--                     if cnt = scan_width-1 then
--                         state <= CAPTURE;
--                         cnt <= 0;
--                     else
--                         cnt <= cnt + 1;
--                     end if;
                    
--                 when CAPTURE =>
--                     state <= SHIFT_OUT;
--                     cnt <= 0;
                    
--                 when SHIFT_OUT =>
--                     if cnt = scan_width-1 then
--                         state <= DONE_STATE;
--                     else
--                         cnt <= cnt + 1;
--                     end if;
                    
--                 when DONE_STATE =>
--                     state <= IDLE;
--             end case;
--         end if;
--     end process;

--     shift_in_en  <= '1' when state = SHIFT_IN else '0';
--     shift_out_en <= '1' when state = SHIFT_OUT else '0';
--     capture_en   <= '1' when state = CAPTURE else '0';
--     update_en    <= '0'; -- Not used in this simplified version
--     done         <= '1' when state = DONE_STATE else '0';
--     lfsr_advance <= '1' when state = SHIFT_IN else '0';
-- end architecture;


-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity scan_controller is
--   port (
--     clk           : in  std_logic;   -- system clock
--     reset         : in  std_logic;   -- synchronous reset
--     start         : in  std_logic;   -- async or sync start; controller syncs it internally
--     scan_width    : in  integer;
--     shift_in_en   : out std_logic;   -- request: set by controller in clk domain
--     shift_out_en  : out std_logic;
--     capture_en    : out std_logic;
--     update_en     : out std_logic;
--     done          : out std_logic;
--     lfsr_advance  : out std_logic;
--     pattern_loaded : out std_logic
--   );
-- end entity;

-- architecture rtl of scan_controller is
--   type state_type is (IDLE, SHIFT_IN, CAPTURE, UPDATE, SHIFT_OUT, DONE_STATE);
--   signal state : state_type := IDLE;
--   signal cnt   : integer := 0;

--   -- synchronizer for start (makes start safe even if driven async)
--   signal start_sync0 : std_logic := '0';
--   signal start_sync1 : std_logic := '0';
--   signal start_prev  : std_logic := '0';
-- begin

--   -- start synchronizer (two-flop) and rising-edge detect, all in clk domain
--   process(clk)
--   begin
--     if rising_edge(clk) then
--       if reset = '1' then
--         start_sync0 <= '0';
--         start_sync1 <= '0';
--         start_prev  <= '0';
--       else
--         start_sync0 <= start;
--         start_sync1 <= start_sync0;
--         start_prev  <= start_sync1;
--       end if;
--     end if;
--   end process;

--   process(clk)
--   begin
--     if rising_edge(clk) then
--       if reset = '1' then
--         state <= IDLE;
--         cnt <= 0;
--       else
--         case state is
--           when IDLE =>
--             -- detect rising edge of start_sync1
--             if (start_sync1 = '1') and (start_prev = '0') then
--               state <= SHIFT_IN;
--               cnt <= 0;
--             end if;

--           when SHIFT_IN =>
--             if cnt >= scan_width-1 then
--               state <= CAPTURE;
--               cnt <= 0;
--             else
--               cnt <= cnt + 1;
--             end if;

--           when CAPTURE =>
--             state <= UPDATE;

--           when UPDATE =>
--             state <= SHIFT_OUT;

--           when SHIFT_OUT =>
--             if cnt >= scan_width-1 then
--               state <= DONE_STATE;
--               cnt <= 0;
--             else
--               cnt <= cnt + 1;
--             end if;

--           when DONE_STATE =>
--             state <= IDLE;

--           when others =>
--             state <= IDLE;
--         end case;
--       end if;
--     end if;
--   end process;

--   shift_in_en  <= '1' when state = SHIFT_IN else '0';
--   shift_out_en <= '1' when state = SHIFT_OUT else '0';
--   capture_en   <= '1' when state = CAPTURE else '0';
--   update_en    <= '1' when state = UPDATE else '0';
--   lfsr_advance <= '1' when state = SHIFT_IN else '0';
--   done         <= '1' when state = DONE_STATE else '0';
--   pattern_loaded <= '1' when state /= SHIFT_IN else '0';

-- end architecture;

--simple but generalized :
library ieee;
use ieee.std_logic_1164.all;

entity scan_controller is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;       -- synchronous reset
        start         : in  std_logic;
        scan_width    : in  integer;
        shift_in_en   : out std_logic;
        shift_out_en  : out std_logic;
        capture_en    : out std_logic;
        done          : out std_logic;
        lfsr_advance  : out std_logic
    );
end entity;

architecture rtl of scan_controller is
    type state_type is (IDLE, SHIFT_IN, CAPTURE, SHIFT_OUT, DONE_STATE);
    signal state : state_type := IDLE;
    signal cnt : integer := 0;
    signal start_reg : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                cnt <= 0;
                start_reg <= '0';
            else
                start_reg <= start;
                case state is
                    when IDLE =>
                        cnt <= 0;
                        if start = '1' and start_reg = '0' then
                            state <= SHIFT_IN;
                            cnt <= 0;
                        end if;

                    when SHIFT_IN =>
                        if cnt = scan_width-1 then
                            state <= CAPTURE;
                            cnt <= 0;
                        else
                            cnt <= cnt + 1;
                        end if;

                    when CAPTURE =>
                        state <= SHIFT_OUT;
                        cnt <= 0;

                    when SHIFT_OUT =>
                        if cnt = scan_width-1 then
                            state <= DONE_STATE;
                            cnt <= 0;
                        else
                            cnt <= cnt + 1;
                        end if;

                    when DONE_STATE =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

    shift_in_en  <= '1' when state = SHIFT_IN  else '0';
    shift_out_en <= '1' when state = SHIFT_OUT else '0';
    capture_en   <= '1' when state = CAPTURE   else '0';
    done         <= '1' when state = DONE_STATE else '0';
    lfsr_advance <= '1' when state = SHIFT_IN  else '0';
end architecture;
