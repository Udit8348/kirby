-- clk_div.vhd
-- Divides an input clock (ideally 10 MHz) down to several
-- lower frequencies.
-- Kevin Johnson, March 2018

LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY clk_div IS

	PORT
	(
		clock_10MHz      : IN  STD_LOGIC;
		clock_100kHz     : OUT STD_LOGIC;
		clock_10kHz      : OUT STD_LOGIC;
		clock_100Hz      : OUT STD_LOGIC;
		clock_32Hz       : OUT STD_LOGIC;
		clock_10Hz       : OUT STD_LOGIC;
		clock_4Hz        : OUT STD_LOGIC
	);
	
END clk_div;

ARCHITECTURE a OF clk_div IS

	CONSTANT clk_freq    : INTEGER := 10000000;
	CONSTANT half_freq   : INTEGER := clk_freq/2;
	
	SIGNAL count_100kHz     : INTEGER RANGE 0 TO half_freq/100000; 
	SIGNAL count_10kHz      : INTEGER RANGE 0 TO half_freq/10000; 
	SIGNAL count_100Hz      : INTEGER RANGE 0 TO half_freq/100;
	SIGNAL count_32Hz       : INTEGER RANGE 0 TO half_freq/32; 
	SIGNAL count_10Hz       : INTEGER RANGE 0 TO half_freq/10; 
	SIGNAL count_4Hz        : INTEGER RANGE 0 TO half_freq/4; 
	
	SIGNAL clock_100kHz_int : STD_LOGIC; 
	SIGNAL clock_10kHz_int  : STD_LOGIC; 
	SIGNAL clock_100Hz_int  : STD_LOGIC;
	SIGNAL clock_32Hz_int   : STD_LOGIC; 
	SIGNAL clock_10Hz_int   : STD_LOGIC; 
	SIGNAL clock_4Hz_int    : STD_LOGIC; 
	
BEGIN
	PROCESS 
	BEGIN
	WAIT UNTIL RISING_EDGE(clock_10MHz);
	
		clock_100kHz <= clock_100kHz_int;
		clock_10kHz <= clock_10kHz_int;
		clock_100Hz <= clock_100Hz_int;
		clock_32Hz  <= clock_32Hz_int;
		clock_10Hz  <= clock_10Hz_int;
		clock_4Hz  <= clock_4Hz_int;

	--
		IF count_100kHz < (half_freq/100000-1) THEN
			count_100kHz <= count_100kHz + 1;
		ELSE
			count_100kHz <= 0;
			clock_100kHz_int <= NOT(clock_100kHz_int);
		END IF;	
	--
		IF count_10kHz < (half_freq/10000-1) THEN
			count_10kHz <= count_10kHz + 1;
		ELSE
			count_10kHz <= 0;
			clock_10kHz_int <= NOT(clock_10kHz_int);
		END IF;	
	--
		IF count_100Hz < (half_freq/100-1) THEN
			count_100Hz <= count_100Hz + 1;
		ELSE
			count_100Hz <= 0;
			clock_100Hz_int <= NOT(clock_100Hz_int);
		END IF;	
	--
		IF count_32Hz < (half_freq/32-1) THEN
			count_32Hz <= count_32Hz + 1;
		ELSE
			count_32Hz <= 0;
			clock_32Hz_int <= NOT(clock_32Hz_int);
		END IF;
	--
		IF count_10Hz < (half_freq/10-1) THEN
			count_10Hz <= count_10Hz + 1;
		ELSE
			count_10Hz <= 0;
			clock_10Hz_int <= NOT(clock_10Hz_int);
		END IF;
	--
		IF count_4Hz < (half_freq/4-1) THEN
			count_4Hz <= count_4Hz + 1;
		ELSE
			count_4Hz <= 0;
			clock_4Hz_int <= NOT(clock_4Hz_int);
		END IF;
	--
		
	END PROCESS;	
END a;

