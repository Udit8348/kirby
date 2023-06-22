-- COordinate CONVersion, "COCONV"
-- Udit Subramanya, Yuhan Li
-- July 23 2022

-- SCOMP peripheral that converts a 2D coordinate to an "intuitive" neopixel index
-- Columns and rows are 0 indexed, with (r=0, c=0) being the top left pixel
-- Max row/column are 1 indexed to indicate the "max number of columns"
-- For example, if c_max is 4, valid c_addrs are [0..3] which is a maximum of 4 columns

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity COCONV is
	
	-- Describe the external connections into and out-of the peripheral
	port(
		io_write 		: in    std_logic ;
		col_en			: in    std_logic ;
		row_en			: in    std_logic ;
		max_col_en		: in	  std_logic ;
		max_row_en		: in	  std_logic ;
		neo_idx_read	: in    std_logic ;
		data				: inout std_logic_vector(15 downto 0)
	); 

end entity;

architecture internals of COCONV is

	-- Internal signals for intermediate conversions
	-- signed signal for math is in 2's complement, need 1 extra bit
	signal index				: signed(16 downto 0);
	signal oned_normal      : signed(16 downto 0);
	signal oned_reversed    : signed(16 downto 0);
	signal oned_odd_flipped : signed(16 downto 0);
	signal odd_or_even		: std_logic;
	
	-- Internal signals for row/col data
	-- Initialized to 0
	signal c_addr				: unsigned(7 downto 0) := x"00";
	signal c_max				: unsigned(7 downto 0) := x"00";
	signal c_errno				: unsigned(7 downto 0) := x"00";
	signal r_addr				: unsigned(7 downto 0) := x"00";
	signal r_max				: unsigned(7 downto 0) := x"00";
	signal r_errno				: unsigned(7 downto 0) := x"00";

	
begin
	-- Bus Signal: "data"
		-- ONLY drive the bus when SCOMP is reading (io_write=0) otherwise, undriven
		-- Determine the data to drive based on chip select signals
			-- drive mapped neopixel index 											(neo_idx_read=1)
			-- drive current column address concatenated with column error number	(col_en=1)
			-- drive current row address concatenated with row error number 		(row_en=1)
	data <= std_logic_vector(index)(15 downto 0) when ((neo_idx_read='1') and (io_write='0'))
		else std_logic_vector(c_addr) & std_logic_vector(c_errno) when ((col_en='1') and (io_write='0'))
		else std_logic_vector(r_addr) & std_logic_vector(r_errno) when ((row_en='1') and (io_write='0'))
		else "ZZZZZZZZZZZZZZZZ";
		
	-- Configuration signals: "target column address", "target row address", "maximum column count", "maximum row count"
	-- Signals are correspondingly updated from the bus
	c_addr <= unsigned(data(7 downto 0)) when (col_en='1' and io_write='1');
	r_addr <= unsigned(data(7 downto 0)) when (row_en='1' and io_write='1');
	c_max  <= unsigned(data(7 downto 0)) when (max_col_en='1' and io_write='1');
	r_max  <= unsigned(data(7 downto 0)) when (max_row_en='1' and io_write='1');
	
	process (r_addr, c_addr, r_max, c_max, oned_normal, oned_reversed, oned_odd_flipped, odd_or_even)
	begin
		-- check for a index out of bounds error, and set error number if needed
		-- a non-zero errno indicates an error has occurred
		if (c_addr >= c_max) then
			c_errno <= x"FF";
		else
			c_errno <= x"00";
		end if;
		
		if (r_addr >= r_max) then
			r_errno <= x"FF";
		else
			r_errno <= x"00";
		end if;
		
		-- CONVERSION MAPPING --
		
		-- (row*col_max) + col: maps 2d input into 1d (linear address)
		oned_normal <= ('0' & (signed(r_addr)*signed(c_max))) + signed('0' & x"00" & c_addr);
			
		-- target linear address - (max linear address - 1): effectively moves the origin from the bottom right to the top left
		-- handle negative mappings with an abs
		oned_reversed <= abs(signed(oned_normal) - signed(c_max)*signed(r_max)) - "000000000001";

		-- flip ONLY the even rows (counting from the top): because neopixels have even numbered rows start from the right
		-- effectively unwinds the zig-zagging indexes in the physical neopixel display
		odd_or_even <= r_addr(0);
		if (odd_or_even = '0') then
			-- (r_max*c_max + r_max*c_max - r_addr*c_max - r_addr*c_max - c_max - reversed_linear_address) - 1
			-- tl;dr the math perfoms an in place, symmetric swap of indexes: [1,2,3,4,5] -> [5,4,3,2,1]
			oned_odd_flipped <= signed('0' & (signed(r_max)*signed(c_max) + signed(r_max)*signed(c_max) - signed(r_addr)*signed(c_max) - signed(r_addr)*signed(c_max) - (x"00" & signed(c_max)) - oned_reversed(15 downto 0)) - x"0001");
		else
			oned_odd_flipped <= oned_reversed;
		end if;
		
		-- final mappped index
		index <= oned_odd_flipped;
		
		-- END CONVERSION MAPPING --
	end process;
end internals;
