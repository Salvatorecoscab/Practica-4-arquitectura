----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/12/2023 04:17:50 PM
-- Design Name: 
-- Module Name: decoderkeys - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity decoderkeys is
 port(
    keycode: in std_logic_vector(0 to 15);
    numEn:  out std_logic_vector(4 downto 0)
 );
end decoderkeys;

architecture Behavioral of decoderkeys is

begin
relation:process (keycode) is
    begin
    case keycode is
        when X"0000"=>
            numEn<="00000";
        when X"0001"=>
            numEn<="10000";
        when X"4000"=>
            numEn<="10001";
        when X"2000"=>
            numEn<="10010";
        when X"1000"=>
            numEn<="10011";
        when X"0800"=>
            numEn<="10100";
        when X"0400"=>
            numEn<="10101";
        when X"0200"=>
            numEn<="10110";
        when X"0100"=>
            numEn<="10111";
        when X"0080"=>
            numEn<="11000"; 
        when X"0040"=>
            numEn<="11001";
        when X"0020"=>
            numEn<="11010";
        when X"0010"=>
            numEn<="11011";   
        when X"0008"=>
            numEn<="11100";
       when X"0004"=>
            numEn<="11101";
       when X"0002"=>
            numEn<="11111";
       when X"8000"=>
            numEn<="11110";  
          
        when others=>
            numEn<="00000";
       
    end case;
end process;

end Behavioral;
