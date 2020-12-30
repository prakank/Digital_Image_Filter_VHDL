----------------------------------------------------------- Prakhar Aggarwal -----------------------------------------------------------
----------------------------------------------------------- 2019CS50441 -----------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use IEEE.numeric_std.all;
    -- use IEEE.std_logic_unsigned.all;

-- This entity will give me clocks of 1Hz, 2Hz frequency
-- clk is of 100Mhz 
entity clock_divider is 
    port(
        clk:in bit;
        clk_1:out bit;
        clk_2:out bit
    );
end clock_divider;

architecture work_clock_divider of clock_divider is
    signal cnt1: integer:=1;
    signal cnt2: integer:=1;
    signal clk1_on: bit:='0';
    signal clk2_on: bit:='0';
begin
    process(clk)
    begin 
        if(rising_edge(clk)) then
            cnt1 <= cnt1 + 1;
            cnt2 <= cnt2 + 1;
            if(cnt1=500000000) then -- Gives me frequency of 1Hz
                cnt1 <= 1;
                clk1_on <= not clk1_on;
            end if;
            if(cnt2=25000000) then -- Gives me frequency of 2Hz
                cnt2 <= 1;
                clk2_on <= not clk2_on;
            end if;
        end if;
        clk_1 <= clk1_on;
        clk_2 <= clk2_on;
    end process;
end work_clock_divider;


-----------------------------------------------------------------start-------------------------------------------------------------


entity clock_functioning_entity is
    port(
        reset: in bit;               --1st Button
        display_mode: in bit;        --2nd Button
        edit_mode_input: in bit;     --3rd Button
        left: in bit;                --4th Button
        increment: in bit;           --5th Button        
        
        clk1: in bit;
        clk2: in bit;
        dot_show: out bit;
        final_hr: out unsigned(4 downto 0);
		final_min:out unsigned(5 downto 0);
        final_sec:out unsigned(5 downto 0);
        final_display_mode:out bit
    );
end clock_functioning;

architecture clock_functioning_architecture of clock_functioning_entity is
    signal temp_hr: unsigned(4 downto 0);
    signal temp_min:unsigned(5 downto 0);
    signal temp_sec:unsigned(5 downto 0);
    signal edit_mode_value: bit:='0';       -- To change edit_mode, we need to press it again
    signal left_value:integer:=0;           -- Will be incremented when left button is pressed
    signal temp_display_mode_hour:bit:='1'; -- default mode is HH:MM and will be '1'
    signal dot:bit:='0';
begin
    process(clk2,reset)
    begin 
        if(rising_edge(clk2)) then
            dot<=not dot;
        end if;
        if(reset='1')then
            dot <= '0';
        end if;
    end process;

    temp_display_mode_hour <= display_mode;

    process(display_mode,reset)
    begin
        temp_display_mode_hour <= not temp_display_mode_hour;
        if (reset='1')then
            temp_display_mode_hour <= '1';
        end if;
    end process;

    process(edit_mode_input,reset)
    begin
        edit_mode_value <= not edit_mode_value;
        if (reset='1')then
            edit_mode_value <= '0';
        end if;
    end process;
    
    process(clk1,reset,diplay_mode,left,increment,edit_mode_value)
    begin
        
        if(rising_edge(reset)) then
            temp_hr <= "00000";
            temp_min <= "000000";
            temp_sec <= "000000";
        end if;
        
        if(edit_mode_value='1') then
            if(left='1') then -- left is input button
                left_value <= left_value + 1;
                if(left_value=4) then
                    left_value<=0;
                end if;
            end if;
            
            if(increment='1') then
                
                if(left_value=3) then
                    if(temp_display_mode_hour='1')then
                        temp_hr <= temp_hr + "01010";  -- incrementing 10 hours
                    else
                        temp_min <= temp_min + "001010"; -- incrementing 10 mins
                    end if;

                elsif(left_value=2) then
                    if(temp_display_mode_hour='1')then
                        temp_hr <= temp_hr + "00001"; -- incrementing 1 hour
                    else
                        temp_min <= temp_min + "000001"; -- incrementing 1 min
                    end if;

                elsif(left_value=1)then
                    if(temp_display_mode_hour='1')then
                        temp_min <= temp_min + "001010"; -- incrementing 10 mins
                    else
                        temp_sec <= temp_sec + "001010"; -- incrementing 10 sec
                    end if;

                else 
                    if(temp_display_mode_hour='1')then
                        temp_min <= temp_min + "000001"; -- incrementing 1 min
                    else
                        temp_sec <= temp_sec + "000001"; -- incrementing 1 sec
                    end if;
                end if;    

            end if;
        else 
            left_value <= 0;
        end if;    

        if(rising_edge(clk1))then
            temp_sec<=temp_sec+"000001";
            if(temp_sec>="111100")then 
                temp_sec <= temp_sec - "111100"; -- subtracting 60 secs from temp_sec
                temp_min <= temp_min + "000001";
            end if;
            if(temp_min>="111100")then
                temp_min <= temp_min - "111100"; -- subtracting 60 mins from temp_min
                temp_hr <= temp_hr + "00001";
            end if;
            if(temp_hr>="11000")then -- If one cycle is completed, I will subtract 24hrs from temp_hr
                temp_hr <= temp_hr - "11000";
            end if;
        end if;        

        dot_show <= dot;
        final_hr <= temp_hr;
        final_min <= temp_min;
        final_sec <= temp_sec;        
        final_display_mode <= temp_display_mode_hour;
    end process;

end clock_functioning_architecture;


-----------------------------------------------------------------start-------------------------------------------------------------


entity display_inputs is
    port(
        clk: in bit;
        final_display_mode:in bit;
        final_hr: in unsigned(4 downto 0);
		final_min:in unsigned(5 downto 0);
        final_sec:in unsigned(5 downto 0);
        dot_show: in bit;
        anode: out unsigned(3 downto 0);
        cathode: out unsigned(7 downto 0)        
    );
end display_entity;

architecture display_process_ of display_inputs is
    signal hr1:integer:=0;
	signal hr2:integer:=0;
	signal hr_:integer:=0;
	signal min1:integer:=0;
	signal min2:integer:=0;
	signal min_:integer:=0;
	signal sec1:integer:=0;
	signal sec2:integer:=0;
	signal sec_:integer:=0;
    signal led_number: bit_vector(1 downto 0):="00";
    signal anode_on: bit_vector (3 downto 0):="1000";
    signal cnt:integer:=1;
    signal blink:bit:='0';
    signal display_digit:integer:=0;

begin
    process(clk)
    begin
        if(rising_edge(clk))then
            cnt<=cnt+1;
            if(cnt<=100000)then  -- Refresh period of 4ms is used. So, Digit Period will be 1ms. 
                if(led_number="11")then
                    led_number<="00";
                else 
                    led_number<=led_number+1;                
                end if;
                cnt<=1;                
            end if;
        end if;
    end process;

    process(led_number)
    begin
        hr_ <= to_integer(final_hr);
        sec_ <= to_integer(final_sec);
        min_ <= to_integer(final_min);
        
        if(hr_>=20) then
            hr1 <= 2;
            hr_ <= hr_ - 20;
        elsif(hr_>=10)then
            hr1 <= 1;
            hr_ <= hr_ - 10;
        else 
            hr1 <= 0;
        end if;        
        hr2 <= hr_;

        if(min_>=50) then
            min1 <= 5;
            min_ <= min_ - 50;
        elsif(min_>=40)then
            min1 <= 4;
            min_ <= min_ - 40;
        elsif(min_>=30)then
            min1 <= 3;
            min_ <= min_ - 30;
        elsif(min_>=20)then
            min1 <= 2;
            min_ <= min_ - 20;
        elsif(min_>=10)then
            min1 <= 1;
            min_ <= min_ - 10;
        else 
            min1 <= 0;
        end if;        
        min2 <= min_;

        if(sec_>=50) then
            sec1 <= 5;
            sec_ <= sec_ - 50;
        elsif(sec_>=40)then
            sec1 <= 4;
            sec_ <= sec_ - 40;
        elsif(sec_>=30)then
            sec1 <= 3;
            sec_ <= sec_ - 30;
        elsif(sec_>=20)then
            sec1 <= 2;
            sec_ <= sec_ - 20;
        elsif(sec_>=10)then
            sec1 <= 1;
            sec_ <= sec_ - 10;
        else 
            sec1 <= 0;
        end if;        
        sec2 <= sec_;

        blink<='0';

        if(led_number="00")then  -- which led to choose
            anode_on <= "0111";
            if(final_display_mode='1') then
                display_digit <= hr1;
            else 
                display_digit <= min1;
            end if;

        elsif (led_number="01") then
            anode_on <= "1011";
            blink <= '1';                  -- Keeping 2nd decimal point to be always ON to differentiate between two set of numbers
            if(final_display_mode='1') then
                display_digit <= hr2;
            else 
                display_digit <= min2;                
            end if;
        elsif (led_number="10") then
            anode_on <= "1101";
            if(final_display_mode='1') then
                display_digit <= min1;
            else 
                display_digit <= sec1;
            end if;    
        else
            anode_on <= "1110";
            if(final_display_mode='1') then
                display_digit <= min2;
                blink <= dot_show;         -- Flashing dot in HH:MM mode
            else 
                display_digit <= sec2;                
            end if;
        end if;

        case display_digit is   --deciding which segments to ON according to display_digit
            when 0 => cathode <= "0000001" & blink;
            when 1 => cathode <= "1001111" & blink;
            when 2 => cathode <= "0010010" & blink;
            when 3 => cathode <= "0000110" & blink;
            when 4 => cathode <= "1001100" & blink;
            when 5 => cathode <= "0100100" & blink;
            when 6 => cathode <= "0100000" & blink;
            when 7 => cathode <= "0001111" & blink;
            when 8 => cathode <= "0000000" & blink;
            when others => cathode <= "0000100" & blink;
        end case;
    end process;

    anode <= anode_on;
end architecture display_process_;
            
entity final is
    port(
        clk: in bit;
        reset: in bit;               --1st Button
        display_mode: in bit;        --2nd Button
        edit_mode_input: in bit;     --3rd Button
        left: in bit;                --4th Button
        increment: in bit;           --5th Button        
        
        anode: out unsigned(3 downto 0);
        cathode: out unsigned(7 downto 0)
    );
end final;

architecture final_process_ of final is 
    signal clk1:bit:='0';
    signal clk2:bit:='0';
    signal blink:bit:='0';
    signal hr_: unsigned (4 downto 0):="00000";
    signal min_: unsigned (5 downto 0):="000000";
    signal sec_: unsigned (5 downto 0):="000000";
    signal diplay_mode: bit:="1";
begin
    clock_divider_instance : entity work.clock_divider(ssa)
        port map(clk,clk1,clk2);

    clock_functioning_entity_instance : entity work.clock_functioning_entity(ssa)
        port map(reset,display_mode,left,increment,edit_mode_input,clk1,clk2,dot_show,finak_hr,final_min,final_sec,final_display_mode);

    display_inputs_instance : entity work.display_inputs(ssa)
        port map(clk,final_display_mode,final_hr,final_min,final_sec,dot_show,anode,cathode);

end architecture final_process_;
    