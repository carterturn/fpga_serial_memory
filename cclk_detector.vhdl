library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity cclk_detector is
  port(clk, rst, cclk : in std_logic; ready : out std_logic);
end cclk_detector;

architecture cclk_detector_basic of cclk_detector is
  signal ready_d, ready_q : std_logic;
  signal ctr_d, ctr_q : std_logic_vector(8 downto 0);
begin
  ready <= ready_q;

  process (ctr_q, cclk) is
  begin
    if cclk = '0' then
      ready_d <= '0';
      ctr_d <= "000000000";
    elsif not (ctr_q = "111111111") then
      ready_d <= '0';
      ctr_d <= std_logic_vector(unsigned(ctr_q) + 1);
    else
      ready_d <= '1';
      ctr_d <= ctr_q;
    end if;
  end process;

  process is
  begin
    wait until clk = '1';
    if rst = '1' then
      ctr_q <= "000000000";
      ready_q <= '0';
    else
      ctr_q <= ctr_d;
      ready_q <= ready_d;
    end if;
  end process;
end architecture cclk_detector_basic;
