-- =============================================================================
-- auction_fsm.vhd
-- State Machine หลักของระบบประมูล
-- ควบคุม: การเปลี่ยน state, นับเวลา, เปรียบราคา, วนรอบ 4 ชิ้น, ระบุผู้ชนะ
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.auction_pkg.ALL;

entity auction_fsm is
    Port (
        CLK               : in  STD_LOGIC;
        -- Pulse inputs from edge_detect (1 cycle each)
        R_C               : in  STD_LOGIC; -- BTNC: ยืนยันราคาที่เสนอ
        R_U               : in  STD_LOGIC; -- BTNU: confirm / next item
        R_L               : in  STD_LOGIC; -- BTNL: เริ่ม / กลับ IDLE
        R_R               : in  STD_LOGIC; -- BTNR: reset ทั้งหมด
        -- Switch input
        SW                : in  STD_LOGIC_VECTOR(15 downto 0);
        -- Outputs to display and LED modules
        CURRENT_STATE     : out state_type;
        TIMER_COUNT       : out integer range 0 to 40;
        HIGHEST_DIGITS    : out digit_array;
        PROPOSED_DIGITS   : out digit_array;
        ITEM_BASE         : out item_arr_t;
        WINNER_ID         : out integer range 0 to 4;
        CURRENT_ITEM_IDX  : out integer range 0 to 3
    );
end auction_fsm;

architecture Behavioral of auction_fsm is

    signal state          : state_type  := IDLE;
    signal timer          : integer range 0 to 40 := 40;
    signal highest        : digit_array := (others => "0000");
    signal proposed       : digit_array := (others => "0000");
    signal base_prices    : item_arr_t  := (others => "0000");
    signal winner         : integer range 0 to 4 := 0;
    signal item_idx       : integer range 0 to 3 := 0;
    signal clk_div_1s     : unsigned(26 downto 0) := (others => '0');

begin

    -- Drive outputs from internal signals
    CURRENT_STATE    <= state;
    TIMER_COUNT      <= timer;
    HIGHEST_DIGITS   <= highest;
    PROPOSED_DIGITS  <= proposed;
    ITEM_BASE        <= base_prices;
    WINNER_ID        <= winner;
    CURRENT_ITEM_IDX <= item_idx;

    -- =========================================================================
    -- Main FSM Process
    -- =========================================================================
    process(CLK)
        variable p_vec : std_logic_vector(23 downto 0);
        variable h_vec : std_logic_vector(23 downto 0);
    begin
        if rising_edge(CLK) then

            -- BTNR: Hard reset - กลับ IDLE ทุก state
            if R_R = '1' then
                state      <= IDLE;
                timer      <= 40;
                item_idx   <= 0;
                clk_div_1s <= (others => '0');

            else
                case state is

                -- -----------------------------------------------------------------
                -- IDLE: รอเริ่มระบบ กด BTNL เพื่อไป SET_PRICE
                -- -----------------------------------------------------------------
                when IDLE =>
                    winner   <= 0;
                    highest  <= (others => "0000");
                    proposed <= (others => "0000");
                    item_idx <= 0;

                    if R_L = '1' then
                        state <= SET_PRICE;
                    end if;

                -- -----------------------------------------------------------------
                -- SET_PRICE: อ่านราคาตั้งต้น 4 ชิ้นจาก SW[15:0]
                -- แบ่ง SW เป็น 4 nibble: SW[3:0]=ชิ้น0, SW[7:4]=ชิ้น1, ...
                -- กด BTNU เพื่อยืนยันและเริ่มประมูลชิ้นแรก
                -- -----------------------------------------------------------------
                when SET_PRICE =>
                    base_prices(0) <= SW(3  downto  0);
                    base_prices(1) <= SW(7  downto  4);
                    base_prices(2) <= SW(11 downto  8);
                    base_prices(3) <= SW(15 downto 12);

                    if R_U = '1' then
                        highest(0) <= SW(3 downto 0); -- โหลดราคาฐานชิ้นแรก
                        state      <= BIDDING;
                        timer      <= 40;
                        item_idx   <= 0;
                    end if;

                -- -----------------------------------------------------------------
                -- BIDDING: ประมูลชิ้นปัจจุบัน
                --   - นับถอยหลัง 40 วินาที
                --   - BTNC: ตั้งราคาที่เสนอจาก SW
                --   - BTNU: ส่งราคา - ถ้าสูงกว่า highest จะบันทึกและรีเซ็ตเวลา
                --   - ถ้า proposed = "FFFFFF" (ทุก digit = F) ตัดจบทันที
                -- -----------------------------------------------------------------
                when BIDDING =>
                    -- Timer: นับ 1 วินาทีต่อ clock 100 MHz
                    clk_div_1s <= clk_div_1s + 1;
                    if clk_div_1s = 99_999_999 then
                        clk_div_1s <= (others => '0');
                        if timer > 0 then
                            timer <= timer - 1;
                        else
                            state <= SHOW_RESULT; -- หมดเวลา
                        end if;
                    end if;

                    -- BTNC: กำหนดราคาที่เสนอ (digit encoder)
                    if R_C = '1' then
                        if SW(7) = '1' then
                            -- SW[7]=1 → ตั้งทุก digit พร้อมกัน (broadcast mode)
                            if    SW(0) = '1' then proposed <= (others => "1010"); -- A
                            elsif SW(1) = '1' then proposed <= (others => "1011"); -- b
                            elsif SW(2) = '1' then proposed <= (others => "1100"); -- C
                            elsif SW(3) = '1' then proposed <= (others => "1101"); -- d
                            elsif SW(4) = '1' then proposed <= (others => "1110"); -- E
                            elsif SW(5) = '1' then proposed <= (others => "1111"); -- F
                            end if;
                        else
                            -- SW[7]=0 → ตั้งทีละ digit
                            -- SW[5:0] เลือก digit ไหน, SW[11:8] คือค่า
                            for i in 0 to 5 loop
                                if SW(i) = '1' then
                                    proposed(i) <= SW(11 downto 8);
                                end if;
                            end loop;
                        end if;
                    end if;

                    -- BTNU: ส่งราคา (bid comparator)
                    if R_U = '1' then
                        -- แปลง digit_array → vector 24 บิตเพื่อเปรียบ
                        p_vec(23 downto 20) := proposed(5);
                        p_vec(19 downto 16) := proposed(4);
                        p_vec(15 downto 12) := proposed(3);
                        p_vec(11 downto  8) := proposed(2);
                        p_vec(7  downto  4) := proposed(1);
                        p_vec(3  downto  0) := proposed(0);

                        h_vec(23 downto 20) := highest(5);
                        h_vec(19 downto 16) := highest(4);
                        h_vec(15 downto 12) := highest(3);
                        h_vec(11 downto  8) := highest(2);
                        h_vec(7  downto  4) := highest(1);
                        h_vec(3  downto  0) := highest(0);

                        -- ราคาสูงกว่า และมีผู้เสนอ (SW[15:12] ≠ 0000)
                        if unsigned(p_vec) > unsigned(h_vec) and SW(15 downto 12) /= "0000" then
                            highest <= proposed;
                            timer   <= 40; -- รีเซ็ตเวลาเมื่อมีการประมูลใหม่

                            -- ระบุผู้ชนะจาก SW[15:12]
                            if    SW(15) = '1' then winner <= 1;
                            elsif SW(14) = '1' then winner <= 2;
                            elsif SW(13) = '1' then winner <= 3;
                            elsif SW(12) = '1' then winner <= 4;
                            end if;

                            -- ราคา F ทุกหลัก = ตัดจบทันที
                            if proposed(0) = "1111" then
                                state <= SHOW_RESULT;
                            end if;
                        end if;
                    end if;

                -- -----------------------------------------------------------------
                -- SHOW_RESULT: แสดงผลการประมูล
                --   - BTNU: ไปชิ้นถัดไป (ถ้ายังมี) หรือกลับ IDLE (ครบ 4 ชิ้น)
                --   - BTNL: กลับ IDLE ทันที
                -- -----------------------------------------------------------------
                when SHOW_RESULT =>
                    if R_U = '1' then
                        if item_idx < 3 then
                            item_idx   <= item_idx + 1;
                            timer      <= 40;
                            highest    <= (others => "0000");
                            highest(0) <= base_prices(item_idx + 1); -- โหลดราคาฐานชิ้นถัดไป
                            proposed   <= (others => "0000");
                            winner     <= 0;
                            state      <= BIDDING;
                        else
                            state <= IDLE; -- ครบ 4 ชิ้น
                        end if;
                    elsif R_L = '1' then
                        state <= IDLE;
                    end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;