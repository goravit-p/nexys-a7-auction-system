library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package auction_pkg is

    -- State machine states
    type state_type is (IDLE, SET_PRICE, BIDDING, SHOW_RESULT);

    -- Array of 6 BCD digits for price display
    type digit_array is array(0 to 5) of STD_LOGIC_VECTOR(3 downto 0);

    -- Array of 4 base prices (one per auction item)
    type item_arr_t is array(0 to 3) of STD_LOGIC_VECTOR(3 downto 0);

    -- Convert 4-bit value to 7-segment encoding (active low)
    function to_seg(d : std_logic_vector(3 downto 0)) return std_logic_vector;

end package auction_pkg;

-- =============================================================================

package body auction_pkg is

    function to_seg(d : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case d is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when "1010" => return "0001000"; -- A
            when "1011" => return "0000011"; -- b
            when "1100" => return "1000110"; -- C
            when "1101" => return "0100001"; -- d
            when "1110" => return "0000110"; -- E
            when "1111" => return "0001110"; -- F
            when others => return "1111111"; -- blank
        end case;
    end function;

end package body auction_pkg;