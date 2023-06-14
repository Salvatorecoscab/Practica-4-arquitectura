----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/12/2023 07:07:22 PM
-- Design Name: 
-- Module Name: stack - Behavioral
-- Project Name: 
-- Target Devices: 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity stack is port(  Clk:in std_logic; --Clockforthestack.
                    Reset:in std_logic;--activehighreset.
                    Enable:in std_logic; --Enablethestack.Otherwiseneitherpushnorpopwillhappen. 
                    Data_In:in std_logic_vector(15 downto 0); --Datatobepushedtostack
                    Data_Out:out std_logic_vector(7 downto 0); --position of the pointer in binary. 
                    PUSH_barPOP:in std_logic; --activelowforPOPandactivehighforPUSH. 
                    Stack_Full:out std_logic; --Goeshighwhenthestackisfull.
                    Stack_Empty:out std_logic --Goeshighwhenthestackisempty.
                    );
end stack;
architecture Behavioral of stack is 
type mem_type is array(0 to 255) of std_logic_vector(15 downto 0);
signal stack_mem:mem_type:=(others=>(others=>'0'));
signal full,empty:std_logic:='0';
signal prev_PP: std_logic:='0';
signal SP:integer:=0; --forsimulationanddebugging.
begin
Stack_Full<=full; 
Stack_Empty<=empty;--PUSHandPOPprocessforthestack. 
    PUSH:process(Clk,reset)
    variable stack_ptr:integer:=255;
    begin
    if(reset='1') then 
    stack_ptr:=255; --stack grows downwards. 
    full<='0';
    empty<='0';
--    Data_out<=(others=>'0');
    prev_PP<='0';
    elsif(rising_edge(Clk)) then--value of PUSH_barPOP with one clock cycle delay.
    if(Enable='1') then 
    prev_PP<=PUSH_barPOP;
    else
    prev_PP<='0';
    end if;--POP section.
    if(Enable='1' and PUSH_barPOP='0'and empty='0') then--settingemptyflag.
        if(stack_ptr=255) then 
        full<='0';
        empty<='1';
        else
        full<='0';
        empty<='0';
        end if;--when the push becomes pop,before stack is full.
        if(prev_PP='1' and full='0') then 
        stack_ptr:=stack_ptr+1;
        end if;--Data has to be taken from the next highest address(empty descending types tack).
--        Data_Out<=stack_mem(stack_ptr);
        if(stack_ptr/=255) then 
        stack_ptr:=stack_ptr+1;
        end if;
        end if;--PUSH section.
        if(Enable='1'and PUSH_barPOP='1'and full='0') then--settingfullflag.
            if(stack_ptr=0) then 
            full<='1';
            empty<='0';
            else
            full<='0';
            empty<='0';
            end if;--whenthepopbecomespush,beforestackisempty.
            if(prev_PP='0'and empty='0')then 
            stack_ptr:=stack_ptr-1;
            end if;--Datapushedtothecurrentaddress. 
            stack_mem(stack_ptr)<=Data_In;
            if(stack_ptr/=0) then 
            stack_ptr:=stack_ptr-1;
            end if;
            end if;
            Data_out<=std_logic_vector(to_unsigned(stack_ptr, 8));
--            SP<=stack_ptr; --fordebugging/simulation.
            end if;
            end process;
            end Behavioral;