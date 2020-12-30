library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_64Kx8 is
    port (
    clock : in std_logic;
    read_enable, write_enable : in std_logic; -- signals that enable read/write operation
    address : in std_logic_vector(15 downto 0); -- 2^16 = 64K
    data_in : in std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0)
);
end RAM_64Kx8;

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ROM_32x9 is
    port (
    clock : in std_logic;
    read_enable : in std_logic; -- signal that enables read operation
    address : in std_logic_vector(4 downto 0); -- 2^5 = 32
    data_out : out std_logic_vector(8 downto 0)
    );
end ROM_32x9;

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MAC is
    port (
    clock : in std_logic;
    control : in std_logic; -- for initializing the sum
    data_in1, data_in2 : in std_logic_vector(17 downto 0);
    data_out : out std_logic_vector(17 downto 0)
    );
end MAC;

architecture Artix of RAM_64Kx8 is
    type Memory_type is array (0 to 65535) of std_logic_vector (7 downto 0);
    signal Memory_array : Memory_type;
begin
    process (clock) begin
    if rising_edge (clock) then
    if (read_enable = '1') then -- the data read is available after the clock edge
    data_out <= Memory_array (to_integer (unsigned (address)));
    end if;
    if (write_enable = '1') then -- the data is written on the clock edge
    Memory_array (to_integer (unsigned(address))) <= data_in;
    end if;
    end if;
    end process;
end Artix;

architecture Artix of ROM_32x9 is
    type Memory_type is array (0 to 31) of std_logic_vector (8 downto 0);
    signal Memory_array : Memory_type;
begin
    process (clock) begin
    if rising_edge (clock) then
    if (read_enable = '1') then -- the data read is available after the clock edge
    data_out <= Memory_array (to_integer (unsigned (address)));
    end if;
    end if;
    end process;
end Artix;

architecture Artix of MAC is
    signal sum, product : signed (17 downto 0);
begin
    data_out <= std_logic_vector (sum);
    product <= signed (data_in1) * signed (data_in2);
    process (clock) begin
    if rising_edge (clock) then -- sum is available after clock edge
    if (control = '0') then -- initialize the sum with the first product
    sum <= std_logic_vector(product);
    else -- add product to the previous sum
    sum <= std_logic_vector (product + signed (sum));
    end if;
    end if;
end process;
end Artix;


-- Prakhar Aggarwal
-- 2019CS50441
--------------------------------------------------------------Prakhar Aggarwal-------------------------------------------------------------
  ---------------------------------------------------------------2019CS50441-------------------------------------------------------------
    ----------------------------------------------------------------CODE--------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- filter entity will perform 9 operations
entity filter is
    port(        
        switch: in std_logic; -- For deciding the type of filter
        -- If switch is zero -> smoothening filter
        -- If switch is one -> sharpening filter
        clock: in std_logic;
        centre_x: in std_logic_vector(15 downto 0) -- Centre of current 3*3 matrix in process
    );
end filter;

-- Filter will take the centre of 3*3 matrix and will perform the 9 MAC operations. 
architecture arch_filter of filter is
    signal curr_mat: std_logic_vector(15 downto 0):=centre_x;                -- Assigning curr_mat as centre of 3*3 matrix
    signal index_to_write_in_ram: std_logic_vector(15 downto 0):=centre_x;   -- This is the index of final pixel which I need to write in RAM after performing 9 MAC operations
    signal curr_coe: std_logic_vector(4 downto 0);                           -- Will store the index of coefficient matrix and will move according to curr_mat
    signal counter: std_logic_vector(3 downto 0):="0000";                    -- For iterating over cells of 3*3 matrix
    signal col: std_logic_vector(15 downto 0):="0000000010100000";           -- For Input Image - Value to jump to move in next row i.e. 160 (Dimension of column)
    signal col_coe: std_logic_vector(4 downto 0):="00011";                   -- For Correlation Matrix - Value to jump to move in next row i.e. 3 (Dimension of column)
    signal data_mat: std_logic_vector(7 downto 0);                           -- This is only for matching inputs to RAM and stores nothing
    signal data_output_mat: std_logic_vector(7 downto 0);                    -- Output of RAM operation i.e. reading value of input image
    signal data_output_coe: std_logic_vector(8 downto 0);                    -- Output of ROM operation i.e. reading value of correlation coefficient
    signal final_data: std_logic_vector(17 downto 0);                        -- Output of MAC operation (uses output of RAM and ROM operation)
    signal control: std_logic:='0';                                          -- Required for MAC entity (Whether I have to initialize sum or continue to add)
begin
    process(clock) begin
        
        if(switch='0')then
            curr_coe <= "00100";
        else 
            curr_coe <= "10100";
        end if;

        if(rising_edge(clock)) then
            -- Case stmt decides which cell to go on and make appropriate changes to current_index of matrix and correlation coefficient
            case counter is
                when "0000" =>
                    curr_mat <= curr_mat-col; -- Will move to the previous row
                    curr_mat <= curr_mat-1;   -- Will move one cell backwards
                    curr_coe <= curr_coe-col_coe; -- Similar change as in input image to find address of correlation matrix cell
                    curr_coe <= curr_coe-1;
                    counter <= counter+1;
                
                when "0001" =>
                    curr_mat <= curr_mat+1;
                    curr_coe <= curr_coe+1;
                    counter <= counter+1;

                when "0010" =>
                    curr_mat <= curr_mat+1;
                    curr_coe <= curr_coe+1;
                    counter <= counter+1;

                when "0011" =>
                    curr_mat <= curr_mat+col; -- Shifting to next row
                    curr_mat <= curr_mat-2;   -- Shifting to 1st cell of next row
                    curr_coe <= curr_coe+col_coe; -- Similar change as in input image to find address of correlation matrix cell
                    curr_coe <= curr_coe-2;
                    counter <= counter+1;

                when "0100" =>
                    curr_mat <= curr_mat+1;
                    curr_coe <= curr_coe+1;
                    counter <= counter+1;

                when "0101" =>
                    curr_mat <= curr_mat+1;
                    curr_coe <= curr_coe+1;
                    counter <= counter+1;

                when "0110" =>
                    curr_mat <= curr_mat+col;
                    curr_mat <= curr_mat-2;
                    curr_coe <= curr_coe+col_coe;
                    curr_coe <= curr_coe-2;
                    counter <= counter+1;

                when "0111" =>
                    curr_mat <= curr_mat+1;
                    curr_coe <= curr_coe+1;
                    counter <= counter+1;

                when "1000" =>   
                    curr_mat <= curr_mat+1;
                    curr_coe <= curr_coe+1;
                    counter <= counter+1;

                when "1001" =>
                    curr_mat <= curr_mat + "1000000000000000";  -- 2^15 = 32678 is added as address of output image starts from 32678
                    counter <= counter+1;

                when others =>
                    counter <= counter;   -- Value of counter won't exceed 10

            end case;
        end if;
    end process;
    
    -- curr_mat is basically the curr_index of my 3*3 matrix
    process(curr_mat)begin
        case counter is 
            when counter<"1010" => -- If counter <=9 then I have to carry on MAC operations
                                    
                RAM_64Kx8_unit: RAM_64Kx8  -- Reads input image value from RAM and stores in data_output_mat
                    port map(clock,'1','0',curr_mat,data_mat,data_output_mat);

                ROM_32x9_unit: ROM_32x9    -- Reads correlation coefficient value from ROM and stores in data_output_coe
                    port map(clock,'1',curr_coe,data_output_coe);

                MAC_unit1: MAC             -- Obtain the product of data_output_mat and data_output_coe 
                    port map(clock,control,std_logic_vector(resize(unsigned(data_output_mat),final_data'length)),std_logic_vector(resize(signed(data_output_coe),final_data'length)),final_data);

                if(counter="0001")then       -- If control = 0, I have to initialize my sum in MAC                    
                    control <= not control;  -- else I will keep on adding to the previously computed sum by MAC in the chain of 9 operations to be executed
                end if;             

            when counter="1010" =>
                index_to_write_in_ram <= curr_mat; -- Objective of this is to not trigger this process again which will execute if curr_mat changes, so I am not changing curr_mat

                if(data_output_mat(0)='1')then    -- If the value to be written is -ve, I will replace it with 0
                    data_output_mat <= "0000000000000000";
                end if;

                RAM_64Kx8_unit:RAM_64Kx8 -- Writing the obtained product in RAM
                    port map(clock,'0','1',index_to_write_in_ram,data_output_mat(14 to 7),data_mat);
                
                counter <= "0000";               -- Making counter 0 for next set of MAC operations
            when others =>                       -- Just in case some other case occurs, it will not result into error and will lead to smooth functioning of my Model
                index_to_write_in_ram <= index_to_write_in_ram;
        end case;
    end process;
end arch_filter;

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main is 
    port(
        push_button: in std_logic; -- Input button to decide when to start filtering process
        switch: in std_logic;      -- To choose between sharpening and smoothening filter
        clock: in std_logic
    );
end main;

architecture arch of main is  
    signal i: std_logic_vector(17 downto 0):="000000000000000001";              -- for Row traversal
    signal j: std_logic_vector(17 downto 0):="000000000000000001";              -- for Column traversal
    signal row_bound: std_logic_vector(17 downto 0):="000000000001110111";      -- if i==row_bound, I have to stop the process i.e. I have completely iterated over my input image     
    signal column_bound: std_logic_vector(17 downto 0):="000000000010011111";   -- if j==column_bound, I will increment i by 1
    signal row: std_logic_vector(17 downto 0):="000000000001111000";            -- Total Number of rows of input image i.e. 120
    signal column: std_logic_vector(17 downto 0):="000000000010100000";         -- Total Number of columns of input image i.e. 160
    signal curr_index: std_logic_vector(17 downto 0):="000000000000000000";     -- Current index to be obtained through current_row*160 + current_column, current column will be added while obtaining curr_index_15dt0
    signal curr_index_15dt0: std_logic_vector(15 downto 0):="0000000000000000"; -- Trim the first 2 bits of curr_index and add column number    
    -- row_bound = 119
    -- column_bound = 159
    signal start: std_logic:='0';                                               -- Start will become 1 when push_button is pressed
    signal read_enable: std_logic:='1';                                         -- To enable read operation
    signal write_enable: std_logic:='0';                                        -- To enable write operation
begin

    process(push_button)begin
        if(rising_edge(push_button))then
            start <= not start;
        end if;
    end process

    process(clock)begin
        if(start='1' and working='1' and row_bound > i) then
            
            MAC_unit0:MAC
                port map(clock,'0',i,row,curr_index); -- i is data_in1, row is data_in2
            -- MAC_unit0 will provide me with the required index without adding the current column no.

            curr_index_15dt0 <= curr_index(15 to 0) + j;            
            --curr_index_15dt0 is the current index of centre of my 3*3 matrix in input image

            filter_unit:filter
                port map(switch,clock,curr_index_15dt0);
            
            j <= j+1;
            if(j=column_bound)then        -- If I reach last column, I will simply shift to the next row (i <= i+1) with again starting from 2nd column or column with index 1
                j <= "000000000000000001";
                i <= i+1;    
            end if;
            if(i=row_bound)then             -- stop the cycle once it has iterated over all valid cells                
                i <= "000000000000000001";  -- i = row_bound is an indication that I have reached last row and hence have no valid matrix to operate on
                j <= "000000000000000001";  -- So, I will initialize i and j to 1, and make start 0 so as to stop the working
                start <= '0';
            end if;
        end if;
    end process;
end architecture;