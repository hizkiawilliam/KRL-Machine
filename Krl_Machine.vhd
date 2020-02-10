LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY krl_machine IS
PORT(	buy	: IN STD_LOGIC;
	cin	: IN STD_LOGIC;
	money	: IN INTEGER := 0;
	clk	: IN STD_LOGIC := '1';
	dest	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
	exc	: OUT INTEGER;
	card	: OUT STD_LOGIC);
END krl_machine;


ARCHITECTURE fsm OF krl_machine IS
	SIGNAL sc : STD_LOGIC := '1';
	SIGNAL cost, sum : INTEGER := 0;
	SIGNAL numcard2, procnum : STD_LOGIC_VECTOR (4 DOWNTO 0) := "00000";
	SIGNAL addr : STD_LOGIC_VECTOR (0 DOWNTO 0) := "0";
	SIGNAL avail, lcard, ldest, lmoney, check, echange, dec, wren, ex : STD_LOGIC;
	SIGNAL numcard1	: STD_LOGIC_VECTOR (4 DOWNTO 0) := "10100";
	TYPE tstate IS (Boot, Idle, CheckCard, Exchange, DestMoney, Output);
	SIGNAL state, nstate : tstate;
	
BEGIN
	Memory_Inst:
	ENTITY WORK.Memory PORT MAP (
		address	 => addr,
		clock	 => clk,
		data	 => numcard1,
		wren	 => wren,
		q	 => numcard2
	);
	
	PROCESS
	BEGIN
		WAIT UNTIL clk = '1' AND clk'EVENT;
		state <= nstate;
		
		IF lmoney = '1' THEN sum <= sum + money;
		ELSE sum <= 0;
		END IF;
							
		IF lcard = '1' THEN procnum <= numcard2;
		END IF;
		
		IF sc = '1' THEN numcard1 <= numcard1;
		ELSIF dec = '1' THEN numcard1 <= procnum - "00001";
		ELSIF ex = '1' THEN numcard1 <= procnum + "00001";
		END IF;
		
	END PROCESS;
	
	PROCESS (state, avail, buy, check, cin)
	BEGIN
		CASE state IS
		
			WHEN Boot =>
				nstate <= Idle;
				
			WHEN Idle =>
				IF buy = '1' THEN nstate <= CheckCard;
				ELSIF cin = '1' THEN nstate <= Exchange;
				ELSE nstate <= Idle;
				END IF;
				
			WHEN CheckCard =>
				IF avail = '1' THEN nstate <= DestMoney;
				ELSE nstate <= Output;
				END IF;
				
			WHEN Exchange =>
				nstate <= Output;
				
			WHEN DestMoney =>
				IF check = '1' THEN nstate <= Output;
				ELSE nstate <= DestMoney;
				END IF;
				
			WHEN Output =>
				nstate <= Idle;
			END CASE;
			
	END PROCESS;
	
	PROCESS (state, avail, buy, check)
	BEGIN
		CASE state IS
		
			WHEN Boot =>
				wren <= '1';
				sc <= '1';
				
			WHEN Idle =>
				IF buy = '1' THEN lcard <= '1';
				END IF;
				sc <= '0';
				wren <= '0';
				
			WHEN CheckCard =>
				lcard <= '0';
				
			WHEN Exchange =>
				ex <= '1';
				lcard <= '1';
				
			WHEN DestMoney =>
				IF check = '1' THEN echange <= '1';
				card <= '1';
				dec <= '1';
				END IF;
				lmoney <= '1';
				ldest <= '1';
				
			WHEN Output =>
				wren <= '1';
				dec <= '0';
				echange <= '0';
				lcard <= '0';
				ex <= '0';
				lmoney <= '0';
			END CASE;
			
	END PROCESS;
	
	check <= '0' WHEN sum < cost ELSE '1';
		
	avail <= '1' WHEN procnum > "00000" ELSE '0';	
		
					
	WITH ldest&dest SELECT
	cost <= 13000 WHEN "100",
			  14000 WHEN "101",
			  15000 WHEN "110",
			  16000 WHEN "111",
			  0 WHEN OTHERS;
	
	exc <= sum - cost WHEN echange = '1' ELSE
			 10000 WHEN ex = '1' ELSE 0;
	
END fsm;
	