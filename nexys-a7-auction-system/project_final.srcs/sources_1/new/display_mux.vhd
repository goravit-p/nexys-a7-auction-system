-- =============================================================================
-- display_mux.vhd
-- 7-Segment Display Multiplexer (8 หลัก)
-- แสดงผลต่างกันตาม state:
--   SET_PRICE  → ราคาตั้งต้น 4 ชิ้น (เว้นระยะ AN7,5,3,1)
--   BIDDING    → Timer 2 หลักซ้าย + ราคาที่เสนอ + กะพริบหลักที่เลือก
--   SHOW_RESULT→ "P X. YYYYYY" (P=Player, X=winner_id, Y=highest price)
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.auction_pkg.ALL;

entity display_mux is
    Port (
        CLK             : in  STD_LOGIC;
        -- State inputs
        CURRENT_STATE   : in  state_type;
        TIMER_COUNT     : in  integer range 0 to 40;
        HIGHEST_DIGITS  : in  digit_array;
        PROPOSED_DIGITS : in  digit_array;
        ITEM_BASE       : in  item_arr_t;
        WINNER_ID       : in  integer range 0 to 4;
        SW              : in  STD_LOGIC_VECTOR(15 downto 0);
        -- Display outputs
        SEG             : out STD_LOGIC_VECTOR(6 downto 0);
        AN              : out STD_LOGIC_VECTOR(7 downto 0);
        DP              : out STD_LOGIC
    );
end display_mux;

architecture Behavioral of display_mux is

    signal refresh_cnt : unsigned(19 downto 0) := (others => '0');
    signal blink_cnt   : unsigned(24 downto 0) := (others => '0');

begin

    process(CLK)
        variable d_idx : integer;
    begin
        if rising_edge(CLK) then
            refresh_cnt <= refresh_cnt + 1;
            blink_cnt   <= blink_cnt   + 1;

            -- เลือก anode ที่จะเปิด (วนซ้ำ 0-7)
            d_idx := to_integer(refresh_cnt(19 downto 17));

            -- Default: ดับทุกหลัก, ดับ DP
            AN  <= (others => '1');
            DP  <= '1';
            AN(d_idx) <= '0'; -- เปิดเฉพาะหลักที่กำลัง refresh

            case CURRENT_STATE is

                -- -----------------------------------------------------------------
                -- SET_PRICE: แสดงราคาตั้งต้น 4 ชิ้น เว้นช่องว่างระหว่างชิ้น
                -- AN7=item3, AN5=item2, AN3=item1, AN1=item0 (AN6,4,2,0 ว่าง)
                -- -----------------------------------------------------------------
                when SET_PRICE =>
                    case d_idx is
                        when 7      => SEG <= to_seg(ITEM_BASE(3));
                        when 6      => SEG <= "1111111"; -- ว่าง
                        when 5      => SEG <= to_seg(ITEM_BASE(2));
                        when 4      => SEG <= "1111111"; -- ว่าง
                        when 3      => SEG <= to_seg(ITEM_BASE(1));
                        when 2      => SEG <= "1111111"; -- ว่าง
                        when 1      => SEG <= to_seg(ITEM_BASE(0));
                        when 0      => SEG <= "1111111"; -- ว่าง
                        when others => SEG <= "1111111";
                    end case;

                -- -----------------------------------------------------------------
                -- BIDDING: AN7-6 = เวลาถอยหลัง, AN5-0 = ราคาที่เสนอ
                -- หลักที่ SW เปิดอยู่จะกะพริบ (blink_cnt bit 24)
                -- -----------------------------------------------------------------
                when BIDDING =>
                    if d_idx = 7 then
                        -- หลักสิบของ timer
                        SEG <= to_seg(std_logic_vector(to_unsigned(TIMER_COUNT / 10, 4)));
                    elsif d_idx = 6 then
                        -- หลักหน่วยของ timer
                        SEG <= to_seg(std_logic_vector(to_unsigned(TIMER_COUNT mod 10, 4)));
                    else
                        -- ราคาที่เสนอ: กะพริบถ้า SW ของหลักนั้นเปิดอยู่
                        if SW(d_idx) = '1' and blink_cnt(24) = '0' then
                            SEG <= "1111111"; -- ดับ (กะพริบ)
                        else
                            SEG <= to_seg(PROPOSED_DIGITS(d_idx));
                        end if;
                    end if;

                -- -----------------------------------------------------------------
                -- SHOW_RESULT: P X. YYYYYY
                -- AN7 = 'P', AN6 = winner_id (มี decimal point), AN5-0 = ราคาสูงสุด
                -- -----------------------------------------------------------------
                when SHOW_RESULT =>
                    if d_idx = 7 then
                        SEG <= "0001100"; -- ตัว 'P'
                    elsif d_idx = 6 then
                        SEG <= to_seg(std_logic_vector(to_unsigned(WINNER_ID, 4)));
                        DP  <= '0'; -- เปิด decimal point หลังตัวเลข winner
                    else
                        SEG <= to_seg(HIGHEST_DIGITS(d_idx));
                    end if;

                -- -----------------------------------------------------------------
                -- IDLE และ state อื่น: ดับทุกหลัก
                -- -----------------------------------------------------------------
                when others =>
                    SEG <= "1111111";

            end case;
        end if;
    end process;

end Behavioral;