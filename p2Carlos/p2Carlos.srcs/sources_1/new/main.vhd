library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity main is 
port(
    clkf : in std_logic;
    rst : in std_logic;
    segment : out  STD_LOGIC_VECTOR (6 downto 0);
    display : out  STD_LOGIC_VECTOR (3 downto 0);
    leds_out : out  STD_LOGIC_VECTOR (4 downto 0);
    --leds : out  STD_LOGIC_VECTOR (9 downto 0);
    sel : in std_logic_vector(1 downto 0)
);
end entity;
architecture Behavioral of main is
------------------- Componentes -------------------
component bintodisp is
Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           segment : out  STD_LOGIC_VECTOR (6 downto 0);
           display : out  STD_LOGIC_VECTOR (3 downto 0);
           resaum: in  STD_LOGIC_VECTOR (11 downto 0)
           );
end component;

-----------------------------Funciones---------------------------
--AdderSubstractor
procedure add (a: in std_logic_vector;
               b: in std_logic_vector;
               ctr: in std_logic;
               Z: out std_logic_vector;
               overflow: out std_logic;
               carry: out std_logic)is
    variable sum: std_logic_vector(a'length downto 0);
    variable carryv,bs: std_logic;

begin
   
    sum := (others => '0');
    carryv := ctr;

    for i in 0 to a'length-1 loop
        bs:= ctr xor b(i);
        sum(i) := a(i) xor bs xor carryv;
        carryv := (a(i) and bs) or (a(i) and carryv) or (bs and carryv);
    end loop;
    Z:= sum(a'length-1 downto 0);
    carry:=carryv;
    overflow:= carryv xor sum(a'length-1);
    
end procedure add;
procedure multiply(
    a : in std_logic_vector; 
    b : in std_logic_vector;
    m : out std_logic_vector) is
    variable pv : std_logic_vector(a'length+b'length-1 downto 0);
    variable bp : std_logic_vector(a'length+b'length-1 downto 0);
    variable carry : std_logic;
    variable ov : std_logic;
begin
    pv := (others => '0');
    bp := "00000000"&b;
    for i in 0 to a'length-1 loop
        if a(i) = '1' then
            add(pv, bp, '0',pv,ov,carry);
        end if;
        bp := bp(a'length+b'length-2 downto 0) & '0';
    end loop;
    m := pv;
end procedure multiply;
procedure div8(
    numer: in std_logic_vector(15 downto 0);
    denom: in std_logic_vector(7 downto 0);
    quotient: out std_logic_vector(7 downto 0);
    remainder: out std_logic_vector(7 downto 0)
) is 
variable d, n1: std_logic_vector(8 downto 0);
variable n2: std_logic_vector(7 downto 0);
variable carry: std_logic;
variable overflow: std_logic;
begin
    d := '0' & denom;
    n2 := numer(7 downto 0);
    n1 := '0' & numer(15 downto 8);
    
    for i in 0 to 7 loop
        n1 := n1(7 downto 0) & n2(7);
        n2 := n2(6 downto 0) & '0';
        
        if n1 >= d then
            add(n1, d, '1', n1, carry, overflow);
            n2(0) := '1';
        end if;
    end loop;
    
    quotient := n2;
    remainder := n1(7 downto 0);
end procedure;

procedure div16(
    a: in std_logic_vector(15 downto 0);
    b: in std_logic_vector(7 downto 0);
    d: out std_logic_vector(15 downto 0)) is
variable remh, reml, quoth, qoutl: std_logic_vector(7 downto 0);
begin
    div8("00000000" & a(15 downto 8), b, quoth, remh);
    div8(remh & a(7 downto 0), b, qoutl, reml);
    d(15 downto 8) := quoth;
    d(7 downto 0) := qoutl;
end procedure;

procedure comp1 (
    x: in std_logic;
    y: in std_logic;
    variable gin: in std_logic;
    variable lin: in std_logic;
    variable gout: out std_logic;
    variable lout: out std_logic;
    variable eout: out std_logic
) is

begin
    gout:= (x and not y) or (x and gin) or (not y and gin);
    eout:=(not x and not y and not gin and not lin)or(x and y and not gin and not lin);
    lout:=(not x and y) or (not x and lin) or (y and lin);

end procedure;

procedure comparer (
    variable a : in std_logic_vector;
    variable b : in std_logic_vector;
    variable enable: in std_logic;
    variable gt : out std_logic;
    variable eq : out std_logic;
    variable lt : out std_logic
)is
    variable g,l,e: std_logic_vector(a'length downto 0);

begin
 if(enable = '1')then
    g(0):='0';
    l(0):='0';
    for i in 0 to a'length-1 loop
        comp1(a(i),b(i),g(i),l(i),g(i+1),l(i+1),e(i+1));
    end loop;
    eq:=e(a'length);
    gt:=g(a'length);
    lt:=l(a'length);
    else
    eq:='0';
    gt:='0';
    lt:='0';
    end if;
end procedure;



procedure alu ( a: in std_logic_vector(15 downto 0); 
                b: in std_logic_vector(15 downto 0); 
                F: in std_logic_vector(3 downto 0); 
                Z: out std_logic_vector(15 downto 0); 
                carry : out std_logic;
                overflow: out std_logic;
                Zero: out std_logic; 
                Neg: out std_logic) is
    variable zfv: std_logic;
    variable Zv: std_logic_vector(15 downto 0);
    begin
        carry:='0';
        overflow:='0';
        zfv:='0';
        case F is
            when "0001" => Zv := not a;
            when "0010" => add("0000000000000000",a,'1',Zv,overflow,carry);-- complemento a 2
            when "0011" => Zv := a and b;
            when "0100" => Zv := a or b;
            when "0101" => Zv := a(14 downto 0) & '0';
            when "0110" => Zv := a(a'length-1)&a(a'length-1 downto 1);
            when "0111" => add(a,b,'0',Zv,overflow,carry);--suma
            when "1000" => add(a,b,'1',Zv,overflow,carry);--resta
            when "1001" => multiply(a(7 downto 0), b(7 downto 0),Zv);--multiplicacion 8 bits
            when "1010" => 
            div16(a,b(7 downto 0),Zv); --division 16/8 bits
         
            when others => Zv := (others=>'0');
        end case;
        for i in 0 to 15 loop
            zfv:= zfv or Zv(i);
        end loop;
        Zero:= not zfv;
        Neg:= Zv(15);
        Z := Zv;
    end procedure alu;
    
------------------Maquina de estadoos-----------------------
type ROM_MEMORY_array is array(0 to 255) of std_logic_vector(15 downto 0);
    constant Content: ROM_MEMORY_array:=(
           --programa 1
          0=> "1011000000010100", -- LOAD 13 in r1
          1=> "0000000000000000", -- send r1 to acc
          2=> "1011000000011011", -- LOAD X in r1
          3=> "1001000000000000", -- MULTI acc by X=r1 and store r1
          4=> "1011000100010101", -- LOAD 23 in r2
		  5=> "0000000100000000", -- send r2 to acc
		  6=> "1011000100011100", -- LOAD Y in r2
		  7=> "1001010100000000", --MULTI acc by Y=r2 and store r2
		  8=> "0000000100000000", --send r2 to acc
		  9=> "0111000000000000", --add acc by r1 and store r1	
		  10=>"1011000100010110", -- LOAD 4 in r2	 
		  
		  11=> "0000000100000000", -- send r2 to acc
		  12=> "1011000100011101", -- LOAD W in r2
		  13=> "1010010100000000", -- DIVIDE r2 from acc and store r2
		  14=> "0000000100000000", -- send r2 to acc
		  15=> "1000000000000000", -- substract r1 from acc and store r1
		  
		  16=> "1101000000000000", -- send r1 to display
		  17=> "1111000000000000", -- FIN DEL PROGRAMA
		  -- void
		  18=> "1111000000000000", -- LOAD Zero in r1
		  19=> "1111000000000000", -- send r1 to display
		  -- CONSTANTES
		  20 => "0000000000001101", -- 13
		  21 => "0000000000010111", -- 23
		  22 => "0000000000000100", -- 4 
		  23 => "0000000000000101", -- 5
		  24 => "0000000000011110", -- 30
		  25 => "0000000000000010", -- 2
		  26 => "0000000000000111", -- 7
		  -- VALUES x,y,w,z
		  27=> "0000000000000011",-- X = 3
		  28=> "0000000000000010", -- Y = 2
		  29=> "0000000000001111",  -- W = 15
		  30=> "0000000000001010", -- Z = 10
		  -- Constantes
          31=> "0000000000000000", -- Zero
          32=> "0000000000000001", -- UNO
          33=> "0000000000000001", -- Valor de 
          34=> "0000000000000000", -- Zero
          35=> "0000000000011110", -- 30
          36=> "1111111111111111", -- 65535
		  37=> "1111111111111111", -- 40000
		  
		  -- Programa para un segundo
		  -- USAR R1 y R2 para ciclo de 3 segundos
		  38=> "1011000000100100", -- LOAD DIRECCION MEMORIA 36 in r1
		  39=> "1101001000000000", -- send r3 to display 
		  
		  40=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 2
		  41=> "0000000100000000", -- send r2 to acc
		  42=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          43=> "1101001000000000", -- send r3 to display 
          44=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          45=> "0000000000000000", -- send r1 to acc
          46=> "0111110000000000", -- add acc by r4 and store r1
		  
		  47=> "1100001000101000", -- BNZ2 reg 4 SALTO A 40
		  
		  48=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 3
		  49=> "0000000100000000", -- send r2 to acc
		  50=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          51=> "1101001000000000", -- send r3 to display 
          52=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          53=> "0000000000000000", -- send r1 to acc
          54=> "0111110000000000", -- add acc by r4 and store r1
		  
		  55=> "1100001000110000", -- BNZ2 reg 4 SALTO A 48
		  
		  56=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 4
		  57=> "0000000100000000", -- send r2 to acc
		  58=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          59=> "1101001000000000", -- send r3 to display 
          60=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          61=> "0000000000000000", -- send r1 to acc
          62=> "0111110000000000", -- add acc by r4 and store r1
		  
		  63=> "1100001000111000", -- BNZ2 reg 4 SALTO A 56
		  
		  64=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 5
		  65=> "0000000100000000", -- send r2 to acc
		  66=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          67=> "1101001000000000", -- send r3 to display 
          68=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          69=> "0000000000000000", -- send r1 to acc
          70=> "0111110000000000", -- add acc by r4 and store r1
		  
		  71=> "1100001001000000", -- BNZ2 reg 4 SALTO A 64
		  
		  72=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 6
		  73=> "0000000100000000", -- send r2 to acc
		  74=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          75=> "1101001000000000", -- send r3 to display 
          76=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          77=> "0000000000000000", -- send r1 to acc
          78=> "0111110000000000", -- add acc by r4 and store r1
		  
		  79=> "1100001001001000", -- BNZ2 reg 4 SALTO A 72
		  
		  80=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 7
		  81=> "0000000100000000", -- send r2 to acc
		  82=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          83=> "1101001000000000", -- send r3 to display 
          84=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          85=> "0000000000000000", -- send r1 to acc
          86=> "0111110000000000", -- add acc by r4 and store r1
		  
		  87=> "1100001001010000", -- BNZ2 reg 4 SALTO A 80
		  
		  88=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 8
		  89=> "0000000100000000", -- send r2 to acc
		  90=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          91=> "1101001000000000", -- send r3 to display 
          92=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          93=> "0000000000000000", -- send r1 to acc
          94=> "0111110000000000", -- add acc by r4 and store r1
		  
		  95=> "1100001001011000", -- BNZ2 reg 4 SALTO A 88
		  
		  96=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 9
		  97=> "0000000100000000", -- send r2 to acc
		  98=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          99=> "1101001000000000", -- send r3 to display 
          100=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          101=> "0000000000000000", -- send r1 to acc
          102=> "0111110000000000", -- add acc by r4 and store r1
		  
		  103=> "1100001001100000", -- BNZ2 reg 4 SALTO A 96
		  
		  104=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 10
		  105=> "0000000100000000", -- send r2 to acc
		  106=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          107=> "1101001000000000", -- send r3 to display 
          108=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          109=> "0000000000000000", -- send r1 to acc
          110=> "0111110000000000", -- add acc by r4 and store r1
		  
		  111=> "1100001001101000", -- BNZ2 reg 4 SALTO A 104
		  
		  112=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 11
		  113=> "0000000100000000", -- send r2 to acc
		  114=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          115=> "1101001000000000", -- send r3 to display 
          116=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          117=> "0000000000000000", -- send r1 to acc
          118=> "0111110000000000", -- add acc by r4 and store r1
		  
		  119=> "1100001001110000", -- BNZ2 reg 4 SALTO A 112
		  
		  120=> "1011000100100000", -- LOAD DIRECCION MEMORIA 32 in r2 -- AQUI RETORNA EL BRANCH NOT ZERO 12
		  121=> "0000000100000000", -- send r2 to acc
		  122=> "1000001100000000", -- SUBTRACR R1 - acc and store in r4
          123=> "1101001000000000", -- send r3 to display 
          124=> "1011000000011111", -- LOAD DIRECCION MEMORIA 31 in r1
          125=> "0000000000000000", -- send r1 to acc
          126=> "0111110000000000", -- add acc by r4 and store r1
		  
		  127=> "1100001001111000", -- BNZ2 reg 4 SALTO A 120
		  
		  128=> "1100011000000000", -- RETURN TO REG OF JARL
		  
		  --Programa 3
          
          129=> "1011000000011011", -- LOAD X in r1
          130=> "0000000000000000", -- send r1 to acc
          131=> "1001000000000000", -- MULTI acc by X=r1 and store r1
          132=> "1011000100011010", -- LOAD 7 in r2
          133=> "0000000100000000", -- send r2 to acc
		  134=>"1001000000000000", -- MULTI acc by X=r1 and store r1
		  135=> "1011000100011110", -- LOAD Z in r2
		  136=> "0000000100000000", -- send r2 to acc
		  137=> "1011000100010111", -- LOAD 5 in r2
		  138=> "1001010100000000", -- MULTI acc by 5=r2 and store r2
		  139=> "0000000100000000", -- send r2 to acc	 
		  140=> "0111000000000000", --add acc by r1 and store r1
		  141=> "0010000000000000",-- COMP2 r1 and store r1
		  142=> "1011000100010111", -- LOAD 5 in r2
		  143=> "0000000100000000", -- send r2 to acc
		  144=> "1011000100011101", -- LOAD W in r2
		  145=> "1010010100011001", -- DIVIDE r2 from acc and store r2
		  146=> "0000000100000000", -- send r2 to acc
		  147=> "0111000000000000", -- ADD r1 from acc and store r1
		  148=> "1011001000100000", -- LOAD DIRECCION MEMORIA 32 in r3
		  149=> "1101000000000000", -- send r1 to display
		  
		  
		  -- Hacer un programa que 
		  -- Crear una instruccion de evaluar Esta instruccion va a determinar el rango de el tiempo en segundos de espera
		  -- Despues crear un ciclo de resta
		  
		  -- Que tenga en r2 0 en r3 30 y en r4 1
		  -- voy sumando r2 + r4 y luego hago una resta a r3 y la guarod en r1
		  -- si r1 no es cero se repite el ciclo, y entre cada ciclo espera N segundos.
		  -- Esta espera va a ser otro programa donde calcule la tardanza de un branch
		  -- Y haga esas intrcciones por el tiempo del rango.
		  -- Cuando hago una nueva op en la alu se refrescan la bandaras
		  
		   -- Crear dos registros y un procesos exclusivos para los segundos
		  -- Un registro va a ser para determinar el rango de segundos que vamos a tener, por ejemplo si la ecuacion da 100 o mas su el registro va a tener el nuemro de seugndos
		  -- Y el otro registro es para el conteo de los segundos, va a ir de uno dos tres hasta el limite que es el otro registro.
		  -- cada conteo va a prender la señal led de out, el estado va a hacer esos conteos. Y en el programa tendre una instruccion que
		  -- aumente la cantidad de leds. en el estado va a comparar si son iguales el registro limite con el de la suma. {{
		  -- cuando lo sean se resetea hasta que termine el programa, mientras dependiendo de la suma va a prrender los leds correspondientes.
		  
		  
		  --75=> "1100000001010010", -- SALTO A LA DIRECCION 82 DIRECTO JMP 
		  
		  -- R2 = 30 R3 = 0 R4 = 1
		  150=> "1011001000100010", -- LOAD DIRECCION MEMORIA 34 in r3
		  151=> "1101000000000000", -- send r1 to display 
		  
		  152=> "1011000100100011", -- LOAD DIRECCION MEMORIA 35 in r2
		  153=> "1101000000000000", -- send r1 to display 
		  
          154=> "1011001100100000", -- LOAD DIRECCION MEMORIA 32 in r4 -- AQUI RETORNA EL BRANCH NOT ZERO
		  155=> "1101000000000000", -- send r1 to display 
		  
		  156=> "0000001000000000", -- send r3 to acc	 
		  157=> "0111111000000000", -- add acc by r4 and store r3
		  
		  158=> "0000001000000000", -- send r3 to acc	 
		  159=> "1000011100000000", -- SUBTRACR R2 - acc and store in r4
		  160=> "1101001000000000", -- send r3 to display 
		  
		  161=> "1100011100000000", -- Aumenta uno en LEDS OUT
		  
		  162=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  163=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  164=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  165=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  166=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  167=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  168=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  169=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  
		  170=> "1100011100000000", -- Aumenta uno en LEDS OUT
		  
		  171=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  172=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  173=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  174=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  175=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  176=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  177=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  178=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  
		  179=> "1100011100000000", -- Aumenta uno en LEDS OUT
		  
		  180=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  181=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  182=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  183=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  184=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  185=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  186=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  187=> "1100000100100110", -- JARL LLamando a el programa de un segundo y retorna aqui mas uno de pc
		  
		  188=> "1100100000000000", -- CLEAR LEDS
		  
		  ---- AQUI SE SALE DEL CICLO AL NUEVO CICLO DEL N
		  189=> "1011000100100011", -- LOAD DIRECCION MEMORIA 35 in r2
		  190=> "1101001000000000", -- send r3 to display 
		
		  191=> "0000001000000000", -- send r3 to acc	 
		  192=> "1000011100000000", -- SUBTRACR R2 - acc and store in r4
		  193=> "1101001000000000", -- send r3 to display 
		
		  194=> "1100001010011010", -- BNZ reg 4 SALTO A 154
		  
		  --81=> "1011001000100011", -- LOAD DIRECCION MEMORIA 32 in r2
		  --76=> "1100 0011 01010010", -- BS reg r4 SALTO A LA DIRECCION 82
		  --75=> "1011 0011 00100001", -- LOAD DIRECCION MEMORIA 33 in r4
		  
		  --77=> "0000001100000000", -- send r4 to acc
		  --78=> "1000101000000000", -- SUBTRACR R3 - acc and store in r3
		  --79=> "1101000000000000", -- send r1 to display
		  
		  --80=> "1100001001001011", -- BNZ reg 4
		  
		  --81=> "1011000100100010", -- LOAD DIRECCION MEMORIA 34 in r1
		  195=> "1101000000000000", -- send r1 to display
		  196=> "1111000000000000", -- FIN DEL PROGRAMA
        OTHERS => "0000000000000000"
        );

--------------------Signals----------------------
signal sal: std_logic_vector(15 downto 0);
signal resaum: std_logic_vector(11 downto 0);
signal getsal :std_logic;
signal seld: std_logic_vector(1 downto 0);
signal initialice: std_logic_vector(7 downto 0);
signal rg1,rg2,rg3,rg4: std_logic_vector(15 downto 0);
signal pcsig, ret_sig: std_logic_vector(7 downto 0);
signal equal : std_logic;

signal dato_cmp_1: std_logic_vector(15 downto 0);
signal dato_cmp_2: std_logic_vector(15 downto 0);
signal eq_cmp, lt_cmp, gt_cmp, enable_cmp: std_logic;

signal leds_sig: std_logic_vector(4 downto 0);

 constant division_ratio: integer := 1;--3333;
 signal counter: integer range 0 to division_ratio:=0;
signal clk: std_logic;
type estados is (init, fetch, decode, load,load1,load2, operation,operation1,endprog,send, intruJMP,jmp,jalr,jalr2,comp,bnc,bnz,bnv,move,bs,ret, bnz2, bs2, leds, leds_clear);
signal estado:estados;

begin


process (dato_cmp_1,dato_cmp_2) is
    variable g,l,e: std_logic_vector(dato_cmp_1'length downto 0);
begin
 if(enable_cmp = '1')then
    g(0):='0';
    l(0):='0';
    for i in 0 to 15 loop
        comp1(dato_cmp_1(i),dato_cmp_2(i),g(i),l(i),g(i+1),l(i+1),e(i+1));
    end loop;
    eq_cmp<=e(15);
    gt_cmp<=g(15);
    lt_cmp<=l(15);
    else
    eq_cmp<='0';
    gt_cmp<='0';
    lt_cmp<='0';
    end if;
end process;

process(clkf, rst)
    begin
        if rst = '1' then
            counter <= 0;
            clk <= '0';
        elsif rising_edge(clkf) then
            if counter = division_ratio then
                counter <= 0;
                clk <= not clk;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

process (clkf, rst) is
variable actual, sig: estados;

variable pcvar,dato1,dato2: std_logic_vector(15 downto 0);
variable mdr: std_logic_vector(15 downto 0);

variable res: std_logic_vector(15 downto 0);
variable pcreg,ret_pc: std_logic_vector(7 downto 0);
variable mar: std_logic_vector(7 downto 0);
variable resaum: std_logic_vector(11 downto 0);
variable cir: std_logic_vector(7 downto 0);
variable acc,regA,regB,regC,regD,op1: std_logic_vector(15 downto 0):= "0000000000000000";
variable nu1,nu2,nu3,nu4,eq,gt,lt: std_logic;
variable carry :  std_logic;
variable overflow: std_logic;
variable zero: std_logic;
variable Neg: std_logic;

begin
if rst='1' then
    actual := init;
elsif rising_edge (clkf) then
    
                actual:=sig;
case actual is 
     --              INIT            --
	when init=>
	pcreg:=initialice;
    getsal<='0';
	sig:=fetch;
	--            FETCH            --
	when fetch=>
	mar:=pcreg;
	mdr:= Content(to_integer(unsigned(pcreg)));
	cir:= Content(to_integer(unsigned(pcreg)))(15 downto 8);
	alu("00000000"&pcreg,"0000000000000001","0111",pcvar,nu1,nu2,nu3,nu4); -- Aqui se suma el pcreg
	pcreg:=pcvar(7 downto 0);
	sig:=decode;
	
    --              DECODE          --
    when decode=>
    case cir(7 downto 4) is
    
    when "0000" => -- SEND ACC
    case cir(1 downto 0) is
        when "00"=>acc:=regA;
        when "01"=>acc:=regB;
        when "10"=>acc:=regC;
        when "11"=>acc:=regD;
        when others=>acc:=(others=>'0');
        end case;
    sig:=fetch;
    
    when "0001" => -- NOT A
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "0010" => -- COMP 2
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "0011" => -- AND
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "0100" => -- OR
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "0101" => -- LSR
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "0110" => -- ASR
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "0111" =>     -- ADD
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "1000" => -- SUBTRACT
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "1001" => -- MULTI
    mar:=mdr(7 downto 0);
    sig:=operation;
    
    when "1010" => -- DIVIDE
    mar:=mdr(7 downto 0);
    sig:=operation;
   
    when "1011" => -- LOAD
    mar:=mdr(7 downto 0);
    sig:=load;
    
    when "1100" => -- JUMPS
    sig:=intruJMP;
    
    when "1101" => -- SEND DISP
    case cir(1 downto 0) is
        when "00"=>sal<=regA;
        when "01"=>sal<=regB;
        when "10"=>sal<=regC;
        when "11"=>sal<=regD;
        when others=>sal<=(others=>'0');
        end case;
    sig:=send;
    
    when "1110"=> -- COMPARADOR
    sig:=comp;
    
    when "1111" => -- END PROGRAM
    sig:=endprog;
    when others=>sig:=init;
    end case;
    
    --             EXECUTE            --
    when intruJMP=>
    case cir(3 downto 0) is
        when "0000"=>sig:=jmp;
        when "0001"=>sig:=jalr;
        when "0010"=>sig:=bnz;
        when "0011"=>sig:=bs;
        when "0100"=>sig:=bnc;
        when "0101"=>sig:=bnv;
        when "0110"=>sig:=ret;
        when "0111"=>sig:=leds;
        when "1000"=>sig:=leds_clear;
        when others=>sig:=jmp;
    end case;
    
    
    --              load specific register            ---
    
    when load=>
        mdr:= Content(to_integer(unsigned(mar)));
        sig:=load1;
    when load1=>
        case cir(1 downto 0) is
        when "00"=>regA:=mdr;
        when "01"=>regB:=mdr;
        when "10"=>regC:=mdr;
        when "11"=>regD:=mdr;
        when others=>sig:=init;
        end case;
    sig:=fetch;
    
  
    --                operation             --
    
    when operation=>
        mdr:= Content(to_integer(unsigned(mar)));
        case cir(3 downto 2) is
        when "00"=>op1:=regA;
        when "01"=>op1:=regB;
        when "10"=>op1:=regC;
        when "11"=>op1:=regD;
        when others=>sig:=init;
        end case;
        sig:=operation1;
    when operation1=>
        alu(op1,acc,cir(7 downto 4),res,carry,overflow,zero,Neg);
        mdr:=res;
        sig:=load1;


   --             saltos            --
  --          JUMP            --   -- FUNCIONA
    when jmp=>
        pcreg:=mdr(7 downto 0); 
        sig:=fetch;
    --          JALR           
    when jalr=>
         ret_pc:=pcreg;
         sig:=jalr2;
    when jalr2 => 
         pcreg:=mdr(7 downto 0);
         sig:=fetch;
    when ret=>
        pcreg:= ret_pc;
        --alu("00000000"&ret_pc,"0000000000000001","0111",pcvar,nu1,nu2,nu3,nu4); -- Aqui se suma el pcreg
	    --pcreg:=pcvar(7 downto 0);
        ret_pc:="00000000";
        sig:=fetch;
    --          BNZ      -- Compara registro especifico   -- FUNCIONA  
    when bnz=>
    dato1:= "0000000000000000";
    dato2:= regD;
    enable_cmp <= '1';
    dato_cmp_1 <= dato1;
    dato_cmp_2 <= dato2;
    sig:=bnz2;
    when bnz2 =>
    if(eq_cmp = '1') then 
        sig:=fetch;
    else
        pcreg:=mdr(7 downto 0); 
        sig:=fetch;
    end if;
    enable_cmp <= '0';
    --          BS            -- Compara registro especifico
    when bs=>
    dato2 := regD;--:= "1000000000000001";
    enable_cmp <= '1';
    dato_cmp_1 <= "0000000000000001";
    dato_cmp_2 <= "000000000000000"&dato2(15);
    sig:=bs2;
    when bs2=>
    if(eq_cmp = '1') then
        pcreg:=mdr(7 downto 0); 
        sig:=fetch; 
    else
        sig:=fetch;
    end if;
    enable_cmp <= '0';
     --          BNC            --  Compara la operacion de add anterior si hubo carry
    when bnc=>
    if(carry = '1') then 
        pcreg:=mdr(7 downto 0); 
        carry := '0';
    end if;
    sig:=fetch;
      --          BNV            -- Compara la operacion add anterior si hubo overflow
    when bnv=>
    if(overflow = '1') then 
        pcreg:=mdr(7 downto 0); 
        overflow := '0';
    end if;
    sig:=fetch;
      --          LEDS            -- Compara la operacion add anterior si hubo overflow
    when leds=>
    leds_sig <= leds_sig(4 downto 1) & '1';
    sig:=fetch;
    ---- LEDS CLEAR
    when leds_clear=>
    leds_sig <= "00000";
    sig:=fetch;
    --- CMP
    when comp=>
    case cir(1 downto 0) is
        when "00"=>dato1:=regA;
        when "01"=>dato1:=regB;
        when "10"=>dato1:=regC;
        when "11"=>dato1:=regD;
        when others=>sig:=init;
        end case;
    case cir(3 downto 2) is
        when "00"=>dato2:=regA;
        when "01"=>dato2:=regB;
        when "10"=>dato2:=regC;
        when "11"=>dato2:=regD;
        when others=>sig:=init;
        end case;
    enable_cmp <= '1';
    dato_cmp_1 <= dato1;
    dato_cmp_2 <= dato2;
    enable_cmp <= '0';
    sig:=fetch;
    --              move            --
    when move=>
    sig:=fetch;
    --               sendto disp           --
    when send=>
    
    getsal<='1';
    sig:=fetch;
        
    when endprog=>
    if(sel=seld) then
    sig:=endprog;
    getsal <= '0';
    else 
    sig:=init;
    end if;         
	when others=>sig:=init;
	 	
end case;
  rg1<=regA;  
  rg2<=regB;  
  rg3<=regC;  
  rg4<=regD;  
  pcsig<=pcreg;
  ret_sig<=ret_pc;
  equal<=eq;
  estado<=sig;
               -- clk_30khz <= not clk_30khz;
   
end if;

end process;


leds_out <= leds_sig;


initialicepc: process (sel,clkf) is begin
    if(clkf'event and clkf='1') then
    case sel is
        when "00"=>initialice<="00000000";
        when "01"=>initialice<="00100000";
        
        when "10"=>initialice<="10000001";
        when "11"=>initialice<="10000001";
        when others=>null;
        end case;
        
        seld<=sel;
        end if;
        
    end process;
    
    process (clkf) is begin
    if(clkf'event and clkf='1') then 
    if(getsal='1') then
    resaum<=sal(11 downto 0);
    else
    resaum<=(others=>'0');
    end if;
    end if;
    end process;
    
    
    dispacccon: bintodisp port map(clk=>clkf,rst=>'0',segment=>segment,display=>display,resaum=>resaum);
    end architecture;