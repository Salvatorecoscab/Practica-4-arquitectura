library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hextodisp is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           segment : out  STD_LOGIC_VECTOR (6 downto 0);
           display : out  STD_LOGIC_VECTOR (3 downto 0);
           buff: in  STD_LOGIC_VECTOR (19 downto 0)
           );
end hextodisp;

architecture Behavioral of hextodisp is


component BinaryTo7Segments is port ( 
            enable: in std_logic;
            BinaryIn : in  STD_LOGIC_VECTOR (3 downto 0);
           SegmentsOut : out  STD_LOGIC_VECTOR (6 downto 0));
end component;


    signal count: integer range 0 to 100000;
    signal selection: std_logic_vector(1 downto 0):="00";
    signal show: std_logic_vector(3 downto 0):="0000";
    signal num1,num2, num3, num4: std_logic_vector(6 downto 0);
  
begin
    Count_clk:process (clk, rst)
    begin
        if(rst = '1') then
            count <= 0;
        elsif(rising_edge(clk)) then
            if(count = 100000) then
                count <= 0;
                selection <= selection + 1;
            else
                count <= count + 1;
            end if;
        end if;
    end process;
    
    
    Selection_of_display:process (selection,show)
    begin
        case selection is
            when "00" => show <= "1110";
            when "01" => show <= "1101";
            when "10" => show <= "1011";
            when "11" => show <= "0111";
            when others => show <= "1111";
        end case;
        case show is
            when "1110" => segment <= num1;
            when "1101" => segment <= num2;
            when "1011" => segment <= num3;
            when "0111" => segment <= num4;
            when others => segment <= "1111111";
        end case;
    end process;
display <= show;



--Conections with the 7 segments and the BCD converter


 
unity: BinaryTo7Segments port map(
    enable=>buff(4),
   BinaryIn=>buff(3 downto 0),
   SegmentsOut=>num1);
tens: BinaryTo7Segments port map(
   enable=>buff(9),
   BinaryIn=>buff(8 downto 5),
   SegmentsOut=>num2);
hund: BinaryTo7Segments port map(
    enable=>buff(14),
   BinaryIn=>buff(13 downto 10),
   SegmentsOut=>num3);
mil: BinaryTo7Segments port map(
    enable=>buff(19),
   BinaryIn=>buff(18 downto 15),
   SegmentsOut=>num4);
 



end Behavioral;