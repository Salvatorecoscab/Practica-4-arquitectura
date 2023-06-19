----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2023 01:03:58
-- Design Name: 
-- Module Name: BinaryTo7Segments - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity BinaryTo7Segments is
    Port ( BinaryIn : in  STD_LOGIC_VECTOR (3 downto 0);
           SegmentsOut : out  STD_LOGIC_VECTOR (6 downto 0));
end BinaryTo7Segments;

architecture Behavioral of BinaryTo7Segments is
begin
    process(BinaryIn)
    begin
        case BinaryIn is
            when "0000" => SegmentsOut <= "0000001";  -- 0
            when "0001" => SegmentsOut <= "1001111";  -- 1
            when "0010" => SegmentsOut <= "0010010";  -- 2
            when "0011" => SegmentsOut <= "0000110";  -- 3
            when "0100" => SegmentsOut <= "1001100";  -- 4
            when "0101" => SegmentsOut <= "0100100";  -- 5
            when "0110" => SegmentsOut <= "0100000";  -- 6
            when "0111" => SegmentsOut <= "0001111";  -- 7
            when "1000" => SegmentsOut <= "0000000";  -- 8
            when "1001" => SegmentsOut <= "0001100";  -- 9
            when "1010" => SegmentsOut <= "0001000";  -- A
            when "1011" => SegmentsOut <= "1100000";  -- B
            when "1100" => SegmentsOut <= "0110001";  -- C
            when "1101" => SegmentsOut <= "1000010";  -- D
            when "1110" => SegmentsOut <= "0110000";  -- E
            when "1111" => SegmentsOut <= "0111000";  -- F
            when others => SegmentsOut <= "1111111";  -- Display blank
        end case;
    end process;
end Behavioral;