-- =============================================================================
-- edge_detect.vhd
-- จับ Rising Edge 1 clock cycle จากสัญญาณปุ่มกด
-- ป้องกันการนับซ้ำเมื่อกดค้าง
-- =============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detect is
    Port (
        CLK       : in  STD_LOGIC;
        BTN_IN    : in  STD_LOGIC;
        PULSE_OUT : out STD_LOGIC
    );
end edge_detect;

architecture Behavioral of edge_detect is
    signal q_reg : STD_LOGIC := '0';
begin

    process(CLK)
    begin
        if rising_edge(CLK) then
            q_reg     <= BTN_IN;
            PULSE_OUT <= BTN_IN and not q_reg;
        end if;
    end process;

end Behavioral;