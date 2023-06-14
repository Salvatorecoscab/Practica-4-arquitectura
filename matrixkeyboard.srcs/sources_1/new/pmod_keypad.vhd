
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
ENTITY pmod_keypad IS
  GENERIC(
    clk_freq    : INTEGER := 100_000_000;  --system clock frequency in Hz
    stable_time : INTEGER := 10);         --time pressed key must remain stable in ms
  PORT(
    clk     :  IN     STD_LOGIC;                           --system clock
    reset_n :  IN     STD_LOGIC;                           --asynchornous active-low reset
    rows    :  IN     STD_LOGIC_VECTOR(1 TO 4);            --row connections to keypad
    columns :  BUFFER STD_LOGIC_VECTOR(1 TO 4) := "1111";  --column connections to keypad
    space    :  OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);          --resultant hex num
    clear,push,pop : in std_logic;
    read: in std_logic;
    segment : out  STD_LOGIC_VECTOR (6 downto 0);
    display : out  STD_LOGIC_VECTOR (3 downto 0));
END pmod_keypad;

ARCHITECTURE logic OF pmod_keypad IS
  SIGNAL rows_int    : STD_LOGIC_VECTOR(1 TO 4);                      --synchronizer flip-flops for row inputs
  SIGNAL keys_int    : STD_LOGIC_VECTOR(0 TO 15) := (OTHERS => '0');  --stores key presses except multiples in the same row
  SIGNAL keys_double : STD_LOGIC_VECTOR(0 TO 15) := (OTHERS => '0');  --stores multiple key presses in the same row
  SIGNAL keys_stored : STD_LOGIC_VECTOR(0 TO 15) := (OTHERS => '0');  --final key press values before debounce
  -- EDIT
  
  SIGNAL keyssignal        : STD_LOGIC_VECTOR(0 TO 15) := (OTHERS => '0');
  SIGNAL hexnumsignal : std_logic_vector(4 downto 0);
  SIGNAL clearsignal,popsignal,pushsignal,popsignalprev,pushsignalprev,reset :std_logic:='0';
  TYPE num is array (0 to 3) of std_logic_vector(0 to 4);
  signal stack_num:num:=(others=>(others=>'0'));
  signal stackunido: std_logic_vector(19 downto 0);
  signal hexnumantes: std_logic_vector(4 downto 0):=(others=>'0');
  signal buffready: std_logic:='0';
  signal datamem: std_logic_vector(15 downto 0);
  signal PUSH_barPOP,enablestack: std_logic;
  signal stack_ptr: integer:=0;
 signal buff_ptr: integer:=0;
signal full,empty:std_logic:='0';
signal prev_PP: std_logic:='0';

  
  --declare debouncer componxent
  type mem_type is array(0 to 255) of std_logic_vector(15 downto 0);
  signal stack_mem:mem_type:=(others=>(others=>'0'));
  COMPONENT debounce IS 
    GENERIC(
      clk_freq    : INTEGER;   --system clock frequency in Hz
      stable_time : INTEGER);  --time button must remain stable in ms
    PORT(
      clk     : IN  STD_LOGIC;   --input clock
      reset_n : IN  STD_LOGIC;   --asynchornous active-low reset
      button  : IN  STD_LOGIC;   --input signal to be debounced
      result  : OUT STD_LOGIC);  --debounced signal
  END COMPONENT;
  COMPONENT decoderkeys is
   port(
    keycode: in std_logic_vector(0 to 15);
    numEn:  out std_logic_vector(4 downto 0)
 );
  end component;
  component hextodisp is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           segment : out  STD_LOGIC_VECTOR (6 downto 0);
           display : out  STD_LOGIC_VECTOR (3 downto 0);
           buff: in  STD_LOGIC_VECTOR (19 downto 0)
           );
end component;



BEGIN
  
  --synchronizer flip-flops
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN  --rising edge of system clock
      rows_int <= rows;                 --synchronize the row inputs to the system clock
    END IF;
  END PROCESS;
  
  PROCESS(clk, reset_n)
    VARIABLE count   : INTEGER RANGE 0 TO clk_freq/3_300_000 := 0;  --counter between key press readings
    VARIABLE presses : INTEGER RANGE 0 TO 16 := 0;                  --count simultaneous detected key presses
  BEGIN
    IF(reset_n = '0') THEN                  --reset
      columns <= (OTHERS => '1');             --release column outputs
      keys_int <= (OTHERS => '0');            --clear key press buffer
      keys_double <= (OTHERS => '0');         --clear key press buffer
    ELSIF(clk'EVENT AND clk = '1') THEN     --rising edge of system clock
      IF(count < clk_freq/3_300_000) THEN     --time for polling change not reached (<300ns)
        count := count + 1;                     --increment counter
      ELSE                                    --time for polling change reached (=300ns)
        count := 0;                             --reset counter

        --cycle through columns to poll for key presses
        CASE columns IS
        
          --pause polling and process results of last cycle of polls
          WHEN "1111" =>
            presses := 0;                                         --reset keypress counter
            press_count: FOR i IN 0 TO 15 LOOP                    --count how many keys were detected as pressed
              IF(keys_int(i) = '1' OR keys_double(i) = '1') THEN        
                presses := presses + 1;
              END IF;
            END LOOP press_count;
            IF(presses < 3) THEN                                  --2 or fewer keys pressed
              keys_stored <= keys_int OR keys_double;               --store results for debounce
            ELSE                                                  --more than 2 keys pressed
              keys_stored <= (OTHERS => '0');                       --discard unreliable results
            END IF;
            keys_int <= (OTHERS => '0');                          --clear key press buffer for next polling
            keys_double <= (OTHERS => '0');                       --clear key press buffer for next polling
            columns <= "0111";
            
          --check 1st column single presses per row
          WHEN "0111" =>
            keys_int(1) <= NOT rows_int(1);
            keys_int(4) <= NOT rows_int(2);
            keys_int(7) <= NOT rows_int(3);
            keys_int(0) <= NOT rows_int(4);            
            columns <= "1011";
            
          --check 2nd column single presses per row
          WHEN "1011" =>
            keys_int(2) <= NOT rows_int(1);
            keys_int(5) <= NOT rows_int(2);
            keys_int(8) <= NOT rows_int(3);
            keys_int(15) <= NOT rows_int(4);
            columns <= "1101";
          
          --check 3rd column single presses per row
          WHEN "1101" =>
            keys_int(3) <= NOT rows_int(1);
            keys_int(6) <= NOT rows_int(2);
            keys_int(9) <= NOT rows_int(3);
            keys_int(14) <= NOT rows_int(4);
            columns <= "1110";
          
          --check 4th column single presses per row
          WHEN "1110" =>
            keys_int(10) <= NOT rows_int(1);
            keys_int(11) <= NOT rows_int(2);
            keys_int(12) <= NOT rows_int(3);
            keys_int(13) <= NOT rows_int(4);
            columns <= "0011";
          
          --check 1st and 2nd column dual press per row
          WHEN "0011" =>            
            IF(rows_int(1) = '0' AND keys_int(1) = '0' AND keys_int(2) = '0') THEN
              keys_double(1) <= '1';
              keys_double(2) <= '1';
            END IF;
            IF(rows_int(2) = '0' AND keys_int(4) = '0' AND keys_int(5) = '0') THEN
              keys_double(4) <= '1';
              keys_double(5) <= '1';
            END IF;
            IF(rows_int(3) = '0' AND keys_int(7) = '0' AND keys_int(8) = '0') THEN
              keys_double(7) <= '1';
              keys_double(8) <= '1';
            END IF;
            IF(rows_int(4) = '0' AND keys_int(0) = '0' AND keys_int(15) = '0') THEN
              keys_double(0) <= '1';
              keys_double(15) <= '1';
            END IF;
            columns <= "0101";
          
          --check 1st and 3rd column dual press per row
          WHEN "0101" =>
            IF(rows_int(1) = '0' AND keys_int(1) = '0' AND keys_int(3) = '0') THEN
              keys_double(1) <= '1';
              keys_double(3) <= '1';
            END IF;
            IF(rows_int(2) = '0' AND keys_int(4) = '0' AND keys_int(6) = '0') THEN
              keys_double(4) <= '1';
              keys_double(6) <= '1';
            END IF;
            IF(rows_int(3) = '0' AND keys_int(7) = '0' AND keys_int(9) = '0') THEN
              keys_double(7) <= '1';
              keys_double(9) <= '1';
            END IF;
            IF(rows_int(4) = '0' AND keys_int(0) = '0' AND keys_int(14) = '0') THEN
              keys_double(0) <= '1';
              keys_double(14) <= '1';
            END IF;
            columns <= "0110";
          
          --check 1st and 4th column dual press per row
          WHEN "0110" =>
            IF(rows_int(1) = '0' AND keys_int(1) = '0' AND keys_int(10) = '0') THEN
              keys_double(1) <= '1';
              keys_double(10) <= '1';
            END IF;
            IF(rows_int(2) = '0' AND keys_int(4) = '0' AND keys_int(11) = '0') THEN
              keys_double(4) <= '1';
              keys_double(11) <= '1';
            END IF;
            IF(rows_int(3) = '0' AND keys_int(7) = '0' AND keys_int(12) = '0') THEN
              keys_double(7) <= '1';
              keys_double(12) <= '1';
            END IF;
            IF(rows_int(4) = '0' AND keys_int(0) = '0' AND keys_int(13) = '0') THEN
              keys_double(0) <= '1';
              keys_double(13) <= '1';
            END IF;
            columns <= "1001";
          
          --check 2nd and 3rd column dual press per row
          WHEN "1001" =>
            IF(rows_int(1) = '0' AND keys_int(2) = '0' AND keys_int(3) = '0') THEN
              keys_double(2) <= '1';
              keys_double(3) <= '1';
            END IF;
            IF(rows_int(2) = '0' AND keys_int(5) = '0' AND keys_int(6) = '0') THEN
              keys_double(5) <= '1';
              keys_double(6) <= '1';
            END IF;
            IF(rows_int(3) = '0' AND keys_int(8) = '0' AND keys_int(9) = '0') THEN
              keys_double(8) <= '1';
              keys_double(9) <= '1';
            END IF;
            IF(rows_int(4) = '0' AND keys_int(15) = '0' AND keys_int(14) = '0') THEN
              keys_double(15) <= '1';
              keys_double(14) <= '1';
            END IF;
            columns <= "1010";
          
          --check 2nd and 4th column dual press per row
          WHEN "1010" =>
            IF(rows_int(1) = '0' AND keys_int(2) = '0' AND keys_int(10) = '0') THEN
              keys_double(2) <= '1';
              keys_double(10) <= '1';
            END IF;
            IF(rows_int(2) = '0' AND keys_int(5) = '0' AND keys_int(11) = '0') THEN
              keys_double(5) <= '1';
              keys_double(11) <= '1';
            END IF;
            IF(rows_int(3) = '0' AND keys_int(8) = '0' AND keys_int(12) = '0') THEN
              keys_double(8) <= '1';
              keys_double(12) <= '1';
            END IF;
            IF(rows_int(4) = '0' AND keys_int(15) = '0' AND keys_int(13) = '0') THEN
              keys_double(15) <= '1';
              keys_double(13) <= '1';
            END IF;
            columns <= "1100";
          
          --check 3rd and 4th column dual press per row
          WHEN "1100" =>
            IF(rows_int(1) = '0' AND keys_int(3) = '0' AND keys_int(10) = '0') THEN
              keys_double(3) <= '1';
              keys_double(10) <= '1';
            END IF;
            IF(rows_int(2) = '0' AND keys_int(6) = '0' AND keys_int(11) = '0') THEN
              keys_double(6) <= '1';
              keys_double(11) <= '1';
            END IF;
            IF(rows_int(3) = '0' AND keys_int(9) = '0' AND keys_int(12) = '0') THEN
              keys_double(9) <= '1';
              keys_double(12) <= '1';
            END IF;
            IF(rows_int(4) = '0' AND keys_int(14) = '0' AND keys_int(13) = '0') THEN
              keys_double(14) <= '1';
              keys_double(13) <= '1';
            END IF;
            columns <= "1111";
          
          WHEN OTHERS =>
            columns <= "1111";
        
        END CASE;
        
      END IF;  
    END IF;
  END PROCESS;
   reset<= not reset_n;
  --debounce key press results
  row_debounce: FOR i IN 0 TO 15 GENERATE
    debounce_keys: debounce
      GENERIC MAP(clk_freq => clk_freq, stable_time => stable_time)
      PORT MAP(clk => clk, reset_n => reset_n, button => keys_stored(i), result => keyssignal(i));
  END GENERATE;
  debounce_clear: debounce GENERIC MAP(clk_freq => clk_freq, stable_time => stable_time)
      PORT MAP(clk => clk, reset_n => reset_n, button => clear, result => clearsignal);
  debounce_push: debounce GENERIC MAP(clk_freq => clk_freq, stable_time => stable_time)
      PORT MAP(clk => clk, reset_n => reset_n, button => push, result => pushsignal);
  debounce_pop: debounce GENERIC MAP(clk_freq => clk_freq, stable_time => stable_time)
      PORT MAP(clk => clk, reset_n => reset_n, button => pop, result => popsignal);

  calldecoder: decoderkeys port map(
    keycode=>keyssignal,
    numEn=>hexnumsignal --hexnumsignal has 5 bits one is for enable
 );
 
--hexnum<=hexnumsignal;

addnum2buff: process(clk,clearsignal) is
    variable i:integer;
    begin
        if clearsignal='1' then
        i:=0;
        buffready<='0';
        stack_num(0)<="00000";
        stack_num(1)<="00000";
        stack_num(2)<="00000";
        stack_num(3)<="00000"; 
        
        elsif rising_edge(clk) then
            if hexnumsignal(4) = '1' and hexnumantes(4) = '0' and buff_ptr<4 then
                stack_num(i)<=hexnumsignal;
            elsif hexnumsignal(4) = '0' and hexnumantes(4) = '1' and buff_ptr<4 then
                i:=i+1;
            elsif (i=4) then
                buffready<='1';
            end if;
            hexnumantes <= hexnumsignal;
            buff_ptr<=i;
        end if;
    end process;

  stackunido<=stack_num(0)&stack_num(1)&stack_num(2)&stack_num(3);
  datamem<=stackunido(18 downto 15)&stackunido(13 downto 10)&stackunido(8 downto 5)&stackunido(3 downto 0);
  connectiondisp: hextodisp 
    port map ( clk =>clk,
           rst =>reset,
           segment =>segment,
           display =>display,
           buff =>stackunido
           );
    processtopush: process(clk,pushsignal,reset) is begin
        
    if(reset='1') then
        stack_ptr<=0;
        full<='0';
        empty<='1';
    elsif(rising_edge(clk)) then
        if(stack_ptr=255) then 
                full<='1';
                empty<='0';
        else
                full<='0';
        end if;
        if(stack_ptr=0) then 
                full<='0';
                empty<='1';
        else
                empty<='0';
        end if;        
        
        if(pushsignal='1' and pushsignalprev='0' and buffready='1' and full='0') then
            stack_mem(stack_ptr)<=datamem;
        elsif(pushsignal='0' and pushsignalprev='1') then
            stack_ptr<=stack_ptr+1;
            buffready<='0';
            stack_num(0)<="00000";
            stack_num(1)<="00000";
            stack_num(2)<="00000";
            stack_num(3)<="00000"; 
            buff_ptr<=0;
        end if;
        
        if(popsignal='0' and popsignalprev='1'and empty='0') then
            stack_ptr<=stack_ptr-1;
        end if;
        popsignalprev<=popsignal;
        pushsignalprev<=pushsignal;
    end if;
    end process; 
    
--    processtopop: process(clk,popsignal,reset) is begin
--    if(reset='1') then
--        stack_ptr<=0;
--        full<='0';
--        empty<='1';
--        popsignalprev<='0';
--    elsif(rising_edge(clk)) then
--        if(stack_ptr=0) then 
--                full<='0';
--                empty<='1';
--        else
--                empty<='0';
--        end if;
--        if(popsignal='0' and popsignalprev='1'and empty='0') then
--            stack_ptr<=stack_ptr-1;
--        end if;
--        popsignalprev<=popsignal;
--    end if;
--    end process; 
    
    space<=std_logic_vector(to_unsigned(stack_ptr, 8));
    
    
    
  
   
 
END logic;
