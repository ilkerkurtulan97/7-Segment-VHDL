----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.05.2020 20:03:27
-- Design Name: 
-- Module Name: UPDOWN_COUNTER - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UPDOWN_COUNTER is
    Port ( clk: in std_logic; -- clock input
           Rst : in std_logic;
           switch : in std_logic_vector (12 downto 0);
           up_count: in std_logic; -- up input 
		   down_count: in std_logic; -- down input
           
           seg : out std_logic_vector(6 downto 0);--output for 7 segment display (cathode value)
            Anode_Activate : out std_logic_vector(7 downto 0)--output for controlling 7 segment display
     );
end UPDOWN_COUNTER;

architecture Behavioral of UPDOWN_COUNTER is
component binary_bcd
    generic(N: positive := 16);
    port(clk, reset: in std_logic;
        binary_in: in std_logic_vector(N-1 downto 0);
        bcd0, bcd1, bcd2, bcd3, bcd4: out std_logic_vector(3 downto 0));
  end component;
-----------------------Signal------
signal counter: std_logic_vector(7 downto 0); -- output 7-bit counter
signal LED_BCD: STD_LOGIC_VECTOR (3 downto 0);
signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
--signal refresh_counter: STD_LOGIC_VECTOR (1 downto 0);
-- creating 10.5ms refresh period
signal LED_activating_counter: std_logic_vector(1 downto 0);
signal displayed_number_in: STD_LOGIC_VECTOR (15 downto 0);
signal displayed_number: STD_LOGIC_VECTOR (15 downto 0);
signal counter_updown: std_logic_vector(7 downto 0):="00000000";

signal slow_clock:std_logic:='0';
signal slow_clock_counter:integer:=0;
----signal for clock --------
signal clk_one_hz : std_logic :='0';
signal counter_CLK : integer range 0 to 50000000 :=0;--2500000
signal divideFactor_CLK : integer :=49999999;--divide factor = [(50MHz/(1/0.1sec))/2]-1 --2499999
begin
-----clock generation--
process(clk)--work on board clock
begin
if(clk'event and clk='1')then
if(counter_CLK >= divideFactor_CLK) then--counter counts the value and if counter value greater than a factor that is calculated through formula
clk_one_hz<= not clk_one_hz;--invert the clock, new clock set here that is 0.1 sec clock
counter_CLK<=0;-- counter set to 0 for next interval
else
counter_CLK<=counter_CLK+1;--if counter < divide factor than increase a value in counter
end if;
end if;
end process;

--PROCESS FOR INITIAL VALUE

process(clk_one_hz)
begin
if(rising_edge (clk_one_hz)) then
   if(Rst = '1')then
       counter_updown <= "00000000";
    else
       if (down_count = '0' and up_count = '0') then --when counter is not activated
              if   (switch(0) = '1' )then--sw2
               counter_updown <= "00000010";--2
              elsif(switch(1) = '1' )then--sw3
               counter_updown <= "00000011";--3
              elsif(switch(2) = '1' )then--sw4
               counter_updown <= "00000100";--4
              elsif(switch(3) = '1' )then--sw5
               counter_updown <= "00000101";--5
              elsif(switch(4) = '1' )then--sw6
               counter_updown <= "00000011";--6
              elsif(switch(5) = '1' )then--sw7
               counter_updown <= "00000111";--7
              elsif(switch(6) = '1' )then--sw8
               counter_updown <= "00001000";--8
              elsif(switch(7) = '1' )then--sw9
               counter_updown <= "00001001";--9
               elsif(switch(8) = '1' )then--sw10
               counter_updown <= "00001010";--10
               elsif(switch(9) = '1' )then--sw11
               counter_updown <= "00001011";--11
               elsif(switch(10) = '1' )then--sw12
               counter_updown <= "00001100";--12
               elsif(switch(11) = '1' )then--sw13
               counter_updown <= "00001101";--13
               elsif(switch(12) = '1' )then--sw14
               counter_updown <= "00001110";--14
               else 
               counter_updown <= "00000000";
              end if;
               -------end if -----
        elsif (down_count='1') then
                if(counter_updown > "00000000") then
                  counter_updown <= counter_updown - "00000001";
              end if;
        elsif (up_count='1') then
                if(counter_updown < "11111111") then
                  counter_updown <= counter_updown + "00000001";
              end if;
              
        end if;
    end if;       
end if;
end process;
 counter <= counter_updown;
 
 ----------7 segment ---------
 displayed_number_in <="00000000"& counter_updown;
U1: binary_bcd
  generic map (N   => 16)
  port map    (clk => clk, reset=>Rst,
        binary_in => displayed_number_in(15 downto 0),
        bcd0 =>displayed_number(3 downto 0), bcd1 =>displayed_number(7 downto 4), 
        bcd2 =>displayed_number(11 downto 8), bcd3 =>displayed_number(15 downto 12), bcd4 =>open);
        
        ----------------------------
        process(clk,Rst)
begin 
    if(Rst='1') then
        refresh_counter <= (others => '0');
    elsif(rising_edge(clk)) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;
 LED_activating_counter <= refresh_counter(19 downto 18);
 --LED_activating_counter <= refresh_counter;
 
-- 4-to-1 MUX to generate anode activating signals for 4 LEDs 
process(LED_activating_counter)
begin
    case LED_activating_counter is
    when "00" =>
        Anode_Activate (3 downto 0) <= "0111"; 
        -- activate LED1 and Deactivate LED2, LED3, LED4
        LED_BCD <= displayed_number(15 downto 12);
        -- the first hex digit of the 16-bit number
    when "01" =>
        Anode_Activate(3 downto 0) <= "1011"; 
        -- activate LED2 and Deactivate LED1, LED3, LED4
        LED_BCD <= displayed_number(11 downto 8);
        -- the second hex digit of the 16-bit number
    when "10" =>
        Anode_Activate(3 downto 0) <= "1101"; 
        -- activate LED3 and Deactivate LED2, LED1, LED4
        LED_BCD <= displayed_number(7 downto 4);
        -- the third hex digit of the 16-bit number
    when "11" =>
        Anode_Activate(3 downto 0) <= "1110"; 
        -- activate LED4 and Deactivate LED2, LED3, LED1
        LED_BCD <= displayed_number(3 downto 0);
        -- the fourth hex digit of the 16-bit number  
    when others =>
       Null;  
    end case;
end process;
Anode_Activate (7 downto 4)<="1111"; 
-------------------------------------------------------
process(LED_BCD)
begin
    case LED_BCD is
    when "0000" => seg <= "0000001"; -- "0"     
    when "0001" => seg <= "1001111"; -- "1" 
    when "0010" => seg <= "0010010"; -- "2" 
    when "0011" => seg <= "0000110"; -- "3" 
    when "0100" => seg <= "1001100"; -- "4" 
    when "0101" => seg <= "0100100"; -- "5" 
    when "0110" => seg <= "0100000"; -- "6" 
    when "0111" => seg <= "0001111"; -- "7" 
    when "1000" => seg <= "0000000"; -- "8"     
    when "1001" => seg <= "0000100"; -- "9" 
    when "1010" => seg <= "0000010"; -- a
    when "1011" => seg <= "1100000"; -- b
    when "1100" => seg <= "0110001"; -- C
    when "1101" => seg <= "1000010"; -- d
    when "1110" => seg <= "0110000"; -- E
    when "1111" => seg <= "0111000"; -- F
    when others =>
        Null;
    end case;
end process;   

end Behavioral;

