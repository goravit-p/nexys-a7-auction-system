-- =============================================================================
-- auction_top.vhd
-- Top-Level: เชื่อมต่อ component ทั้งหมดเข้าหากัน
-- ไม่มี logic ภายใน - ทำหน้าที่เป็น wiring diagram เท่านั้น
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.auction_pkg.ALL;

entity auction_top is
    Port (
        CLK100MHZ : in  STD_LOGIC;
        BTNC      : in  STD_LOGIC;
        BTNU      : in  STD_LOGIC;
        BTNL      : in  STD_LOGIC;
        BTNR      : in  STD_LOGIC;
        SW        : in  STD_LOGIC_VECTOR(15 downto 0);
        SEG       : out STD_LOGIC_VECTOR(6 downto 0);
        AN        : out STD_LOGIC_VECTOR(7 downto 0);
        DP        : out STD_LOGIC;
        LED       : out STD_LOGIC_VECTOR(15 downto 0)
    );
end auction_top;

architecture Structural of auction_top is

    -- -------------------------------------------------------------------------
    -- Internal signals: เชื่อม edge_detect → fsm
    -- -------------------------------------------------------------------------
    signal pulse_c : STD_LOGIC;
    signal pulse_u : STD_LOGIC;
    signal pulse_l : STD_LOGIC;
    signal pulse_r : STD_LOGIC;

    -- -------------------------------------------------------------------------
    -- Internal signals: เชื่อม fsm → display_mux และ led_ctrl
    -- -------------------------------------------------------------------------
    signal sig_state    : state_type;
    signal sig_timer    : integer range 0 to 40;
    signal sig_highest  : digit_array;
    signal sig_proposed : digit_array;
    signal sig_base     : item_arr_t;
    signal sig_winner   : integer range 0 to 4;
    signal sig_item_idx : integer range 0 to 3;

begin

    -- =========================================================================
    -- 1. Edge Detection - instantiate 4 ครั้งสำหรับแต่ละปุ่ม
    -- =========================================================================
    U_EDGE_C : entity work.edge_detect
        port map (
            CLK       => CLK100MHZ,
            BTN_IN    => BTNC,
            PULSE_OUT => pulse_c
        );

    U_EDGE_U : entity work.edge_detect
        port map (
            CLK       => CLK100MHZ,
            BTN_IN    => BTNU,
            PULSE_OUT => pulse_u
        );

    U_EDGE_L : entity work.edge_detect
        port map (
            CLK       => CLK100MHZ,
            BTN_IN    => BTNL,
            PULSE_OUT => pulse_l
        );

    U_EDGE_R : entity work.edge_detect
        port map (
            CLK       => CLK100MHZ,
            BTN_IN    => BTNR,
            PULSE_OUT => pulse_r
        );

    -- =========================================================================
    -- 2. Auction FSM
    -- =========================================================================
    U_FSM : entity work.auction_fsm
        port map (
            CLK              => CLK100MHZ,
            R_C              => pulse_c,
            R_U              => pulse_u,
            R_L              => pulse_l,
            R_R              => pulse_r,
            SW               => SW,
            CURRENT_STATE    => sig_state,
            TIMER_COUNT      => sig_timer,
            HIGHEST_DIGITS   => sig_highest,
            PROPOSED_DIGITS  => sig_proposed,
            ITEM_BASE        => sig_base,
            WINNER_ID        => sig_winner,
            CURRENT_ITEM_IDX => sig_item_idx
        );

    -- =========================================================================
    -- 3. Display Multiplexer
    -- =========================================================================
    U_DISP : entity work.display_mux
        port map (
            CLK             => CLK100MHZ,
            CURRENT_STATE   => sig_state,
            TIMER_COUNT     => sig_timer,
            HIGHEST_DIGITS  => sig_highest,
            PROPOSED_DIGITS => sig_proposed,
            ITEM_BASE       => sig_base,
            WINNER_ID       => sig_winner,
            SW              => SW,
            SEG             => SEG,
            AN              => AN,
            DP              => DP
        );

    -- =========================================================================
    -- 4. LED Controller
    -- =========================================================================
    U_LED : entity work.led_ctrl
        port map (
            CURRENT_STATE    => sig_state,
            CURRENT_ITEM_IDX => sig_item_idx,
            WINNER_ID        => sig_winner,
            LED              => LED
        );

end Structural;