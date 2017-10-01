library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity pulse is
  port(clk, trigger : in std_logic; output : out std_logic);
end pulse;

architecture pulse_basic of pulse is
  signal pulse_done : std_logic;
  signal output_d, output_q : std_logic;
begin
  output <= output_q;

  process (clk) is
  begin
    if rising_edge(clk) then
      output_d <= '0';
      
      if trigger = '1' and pulse_done = '0' then
	output_d <= '1';
	pulse_done <= '1';
      end if;
      if trigger = '0' then
	pulse_done <= '0';
      end if;

      output_q <= output_d;
    end if;
  end process;
end architecture;
