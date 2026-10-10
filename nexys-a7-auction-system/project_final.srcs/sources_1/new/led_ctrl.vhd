-- =============================================================================
-- led_ctrl.vhd
-- ควบคุม LED 16 ดวง
--   LED[15:8] = ดับเสมอ (ไม่ใช้)
--   LED[7:4]  = แสดงชิ้นที่กำลังประมูล (เฉพาะ BIDDING และ SHOW_RESULT)
--   LED[3:0]  = หมายเลขผู้ชนะ (binary 1-4)
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.auction_pkg.ALL;

entity led_ctrl is
    Port (
        CURRENT_STATE    : in  state_type;
        CURRENT_ITEM_IDX : in  integer range 0 to 3;
        WINNER_ID        : in  integer range 0 to 4;
        LED              : out STD_LOGIC_VECTOR(15 downto 0)
    );
end led_ctrl;

architecture Behavioral of led_ctrl is
begin

    -- LED[15:8]: ดับเสมอ
    LED(15 downto 8) <= (others => '0');

    -- LED[3:0]: แสดง winner_id ในรูปแบบ binary
    LED(3 downto 0) <= std_logic_vector(to_unsigned(WINNER_ID, 4));

    -- LED[7:4]: บอกชิ้นที่กำลังประมูล (one-hot)
    process(CURRENT_STATE, CURRENT_ITEM_IDX)
    begin
        LED(7 downto 4) <= "0000"; -- default: ดับ

        if CURRENT_STATE = BIDDING or CURRENT_STATE = SHOW_RESULT then
            case CURRENT_ITEM_IDX is
                when 0 => LED(4) <= '1';
                when 1 => LED(5) <= '1';
                when 2 => LED(6) <= '1';
                when 3 => LED(7) <= '1';
            end case;
        end if;
    end process;

end Behavioral;