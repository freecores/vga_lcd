--
-- Wishbone compliant cycle shared memory
-- author: Richard Herveille
-- 
-- rev.: 1.0  june  19th, 2001. Initial release
--
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity cycle_shared_mem is
	generic(
		DWIDTH : natural := 32; -- databus width
		AWIDTH : natural := 8   -- addressbus width
	);
	port(
		-- SYSCON signals
		CLKx2_I : in std_logic; -- memory clock, 2x wishbone clock
		CLK_I   : in std_logic; -- wishbone clock input
		RST_I   : in std_logic; -- synchronous active high reset
		nRESET  : in std_logic; -- asynchronous active low reset

		-- wishbone slave0 connections
		ADR0_I : in unsigned(AWIDTH -1 downto 0);              -- address input
		DAT0_I : in std_logic_vector(DWIDTH -1 downto 0);      -- data input
		DAT0_O : out std_logic_vector(DWIDTH -1 downto 0);     -- data output
		SEL0_I : in std_logic_vector( (DWIDTH/8) -1 downto 0); -- byte select input
		WE0_I : in std_logic;                                  -- write enable input
		STB0_I : in std_logic;                                 -- strobe input
		CYC0_I : in std_logic;                                 -- valid bus cycle input
		ACK0_O : out std_logic;                                -- acknowledge output
		ERR0_O : out std_logic;                                -- error output

		-- wishbone slave1 connections
		ADR1_I : in unsigned(AWIDTH -1 downto 0);              -- address input
		DAT1_I : in std_logic_vector(DWIDTH -1 downto 0);      -- data input
		DAT1_O : out std_logic_vector(DWIDTH -1 downto 0);     -- data output
		SEL1_I : in std_logic_vector( (DWIDTH/8) -1 downto 0); -- byte select input
		WE1_I : in std_logic;                                  -- write enable input
		STB1_I : in std_logic;                                 -- strobe input
		CYC1_I : in std_logic;                                 -- valid bus cycle input
		ACK1_O : out std_logic;                                -- acknowledge output
		ERR1_O : out std_logic                                 -- error output
	);
end entity cycle_shared_mem;

architecture structural of cycle_shared_mem is
	-- define memory array
	type mem_array is array(2**AWIDTH -1 downto 0) of std_logic_vector(DWIDTH -1 downto 0);
	signal mem : mem_array;

	-- clock enable / multiplexor select signal
	signal ena : std_logic;
	
	-- multiplexed memory busses / signals
	signal mem_adr, mem_radr : unsigned(AWIDTH -1 downto 0);
	signal mem_dati, mem_dato : std_logic_vector(DWIDTH -1 downto 0);
	signal mem_we : std_logic;

	-- delayed NOT WE_I
	-- acknowledge generation
	signal wr_ack0, wr_ack1 : std_logic;
	signal rd_ack0, rd_ack1 : std_logic;

	-- error generation
	signal all_ones : std_logic_vector( (DWIDTH/8) -1 downto 0);

begin
	-- generate clock enable signal
	gen_ena: process(CLKx2_I, nReset)
	begin
		if (nReset = '0') then
			ena <= '0';
		elsif (CLKx2_I'event and CLKx2_I = '1') then
			if (RST_I = '1') then
				ena <= '0';
			else
				ena <= not ena;
			end if;
		end if;
	end process gen_ena;


	-- multiplex memory bus
	gen_muxs: process(CLKx2_I)
	begin
		if (CLKx2_I'event and CLKx2_I = '1') then
			if (ena = '0') then
				mem_adr  <= adr0_i;
				mem_dati <= dat0_i;
				mem_we   <= we0_i and cyc0_i and stb0_i;
			else
				mem_adr  <= adr1_i;
				mem_dati <= dat1_i;
				mem_we   <= we1_i and cyc1_i and stb1_i;
			end if;
		end if;
	end process gen_muxs;

	-- memory access
	gen_mem: process(CLKx2_I)
	begin
		if (CLKx2_I'event and CLKx2_I = '1') then
			-- write operation
			if (mem_we = '1') then
				mem(conv_integer(mem_adr)) <= mem_dati;
			end if;

			-- read operation
			mem_radr <= mem_adr; -- altera flex rams require synchronous read address
			mem_dato <= mem(conv_integer(mem_radr));
		end if;		
	end process gen_mem;

	-- assign DAT_O outputs
	gen_dato: process(CLKx2_I)
	begin
		if (CLKx2_I'event and CLKx2_I = '1') then
			if (ena = '0') then
				DAT1_O <= mem_dato;
			else
				DAT0_O <= mem_dato;
			end if;
		end if;
	end process gen_dato;

	-- assign ACK_O outputs
	gen_dnwe: process(CLK_I, cyc0_i, stb0_i, we0_i, cyc1_i, stb1_i, we1_i)
		variable rack0, rack1 : std_logic;
	begin
		if (CLK_I'event and CLK_I = '1') then
			rd_ack0 <= rack0 and not rd_ack0;--  and cyc0_i and stb0_i;
			rd_ack1 <= rack1 and not rd_ack1; -- and cyc1_i and stb1_i;

			rack0 := not we0_i and cyc0_i and stb0_i and not rd_ack0;
			rack1 := not we1_i and cyc1_i and stb1_i and not rd_ack1;
		end if;
	end process gen_dnwe;
	wr_ack0 <= cyc0_i and stb0_i and we0_i;
	wr_ack1 <= cyc1_i and stb1_i and we1_i;
 
	ACK0_O <= wr_ack0 or rd_ack0;
	ACK1_O <= wr_ack1 or rd_ack1;

	all_ones <= (others => '1'); -- all ones
	ERR0_O <= '1' when ((CYC0_I = '1') and (STB0_I = '1') and (SEL0_I /= all_ones)) else '0';
	ERR1_O <= '1' when ((CYC1_I = '1') and (STB1_I = '1') and (SEL1_I /= all_ones)) else '0';

end architecture;
