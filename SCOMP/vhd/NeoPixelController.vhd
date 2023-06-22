-- WS2812 communication interface peripheral for SCOMP.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity NeoPixelController is

	port(
		clk_10M   : in    std_logic;
		resetn    : in    std_logic;
		io_write  : in    std_logic ;
		cs_addr   : in    std_logic ;
		cs_rgb    : in    std_logic ;
		cs_all    : in    std_logic;
		cs_red    : in    std_logic;
		cs_green  : in    std_logic;
		cs_blue   : in    std_logic;
		data      : inout std_logic_vector(15 downto 0);
		sda       : out   std_logic
	); 

end entity;

architecture internals of NeoPixelController is
	
	-- Signals for the RAM read and write addresses
	signal ram_read_addr, ram_write_addr : std_logic_vector(7 downto 0);
	-- RAM write enable
	signal ram_we : std_logic;
		
	-- Signals for data coming out of memory (port of RAM)
	signal ram_read_data : std_logic_vector(23 downto 0);
	
	-- Signal to store the current output pixel's color data
	signal pixel_buffer : std_logic_vector(23 downto 0);
	
	--Internal signal from memory (port of RAM)
	signal word_out_int : std_logic_vector(23 downto 0);
		
	-- Signal SCOMP will write to before it gets stored into memory
	signal ram_write_buffer : std_logic_vector(23 downto 0);
	
	-- RAM interface state machine signals
	type write_states is (idle, storing, store_noinc, storeAll);
	signal wstate: write_states;

	
begin

	-- This is the RAM that will store the pixel data.
	-- It is dual-ported.  SCOMP will access port "A",
	-- and the NeoPixel controller will access port "B".
	pixelRAM : altsyncram
	GENERIC MAP (
		address_reg_b => "CLOCK0",
		clock_enable_input_a => "BYPASS",
		clock_enable_input_b => "BYPASS",
		clock_enable_output_a => "BYPASS",
		clock_enable_output_b => "BYPASS",
		indata_reg_b => "CLOCK0",
		init_file => "pixeldata.mif",
		intended_device_family => "Cyclone V",
		lpm_type => "altsyncram",
		numwords_a => 256,
		numwords_b => 256,
		operation_mode => "BIDIR_DUAL_PORT",
		outdata_aclr_a => "NONE",
		outdata_aclr_b => "NONE",
		outdata_reg_a => "UNREGISTERED",
		outdata_reg_b => "UNREGISTERED",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_mixed_ports => "OLD_DATA",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		read_during_write_mode_port_b => "NEW_DATA_NO_NBE_READ",
		widthad_a => 8,
		widthad_b => 8,
		width_a => 24,
		width_b => 24,
		width_byteena_a => 1,
		width_byteena_b => 1,
		wrcontrol_wraddress_reg_b => "CLOCK0"
	)
	PORT MAP (
		address_a => ram_write_addr,
		address_b => ram_read_addr,
		clock0 => clk_10M,
		data_a => ram_write_buffer,
		data_b => x"000000",
		wren_a => ram_we,
		wren_b => '0',
		q_a => word_out_int,
		q_b => ram_read_data
	);
	
	
	-- 16-bit color readable, and ram_we is a proxy for a busy signal
	data <=
		word_out_int(16 downto 12) & word_out_int(23 downto 18) & word_out_int(7 downto 3) when ((io_write='0') and (cs_rgb='1'))
		else "00000000" & word_out_int(23 downto 16)  when ((io_write='0') and (cs_green='1'))
		else "00000000" & word_out_int(15 downto 8)  when ((io_write='0') and (cs_red='1'))
		else "00000000" & word_out_int(7 downto 0)  when ((io_write='0') and (cs_blue='1'))
		else "000000000000000" & ram_we when ((io_write='0') and (cs_all='1'))
		else "ZZZZZZZZZZZZZZZZ";
	


	-- This process implements the NeoPixel protocol by
	-- using several counters to keep track of clock cycles,
	-- which pixel is being written to, and which bit within
	-- that data is being written.
	process (clk_10M, resetn)
		-- protocol timing values (in 100s of ns)
		constant t1h : integer := 8; -- high time for '1'
		constant t0h : integer := 3; -- high time for '0'
		constant ttot : integer := 12; -- total bit time
		
		constant npix : integer := 256;

		-- which bit in the 24 bits is being sent
		variable bit_count   : integer range 0 to 31;
		-- counter to count through the bit encoding
		variable enc_count   : integer range 0 to 31;
		-- counter for the reset pulse
		variable reset_count : integer range 0 to 1000;
		-- Counter for the current pixel
		variable pixel_count : integer range 0 to 255;
		
	begin
		
		if resetn = '0' then
			-- reset all counters
			bit_count := 23;
			enc_count := 0;
			reset_count := 1000;
			-- set sda inactive
			sda <= '0';

		elsif (rising_edge(clk_10M)) then

			-- This IF block controls the various counters
			if reset_count /= 0 then -- in reset/end-of-frame period
				-- during reset period, ensure other counters are reset
				pixel_count := 0;
				bit_count := 23;
				enc_count := 0;
				-- decrement the reset count
				reset_count := reset_count - 1;
				-- load data from memory
				pixel_buffer <= ram_read_data;
				
			else -- not in reset period (i.e. currently sending data)
				-- handle reaching end of a bit
				if enc_count = (ttot-1) then -- is end of this bit?
					enc_count := 0;
					-- shift to next bit
					pixel_buffer <= pixel_buffer(22 downto 0) & '0';
					if bit_count = 0 then -- is end of this pixels's data?
						bit_count := 23; -- start a new pixel
						pixel_buffer <= ram_read_data;
						if pixel_count = npix-1 then -- is end of all pixels?
							-- begin the reset period
							reset_count := 1000;
						else
							pixel_count := pixel_count + 1;
						end if;
					else
						-- if not end of this pixel's data, decrement count
						bit_count := bit_count - 1;
					end if;
				else
					-- within a bit, count to achieve correct pulse widths
					enc_count := enc_count + 1;
				end if;
			end if;
			
			
			-- This IF block controls the RAM read address to step through pixels
			if reset_count /= 0 then
				ram_read_addr <= x"00";
			elsif (bit_count = 1) AND (enc_count = 0) then
				-- increment the RAM address as each pixel ends
				ram_read_addr <= ram_read_addr + 1;
			end if;
			
			
			-- This IF block controls sda
			if reset_count > 0 then
				-- sda is 0 during reset/latch
				sda <= '0';
			elsif 
				-- sda is 1 in the first part of a bit.
				-- Length of first part depends on if bit is 1 or 0
				( (pixel_buffer(23) = '1') and (enc_count < t1h) )
				or
				( (pixel_buffer(23) = '0') and (enc_count < t0h) )
				then sda <= '1';
			else
				sda <= '0';
			end if;
			
		end if;
	end process;
	
	
	
	process(clk_10M, resetn, cs_addr)
	
	begin

		-- holding reset prevents you from writing to memory
		if resetn = '0' then
			wstate <= idle;
			ram_we <= '0';
			ram_write_buffer <= x"000000";
			ram_write_addr <= x"00";
			--counter := 0;
			-- Note that resetting this device does NOT clear the memory.
			-- Clearing memory would require cycling through each address
			-- and setting them all to 0.
		elsif rising_edge(clk_10M) then
			if (io_write = '1') and (cs_addr='1') and (wstate=idle) then
				-- what is the idle state?
				ram_write_addr <= data(7 downto 0);
			else
				case wstate is
				when idle =>
					-- For 8-bit single colors, insert them into the appropriate part of the word and write to memory.
					if (io_write = '1') and (cs_red = '1') then
						-- word_out_int is a way to pad data so that it takes up 24 bits
						ram_write_buffer <= word_out_int(23 downto 16) & data(7 downto 0) & word_out_int(7 downto 0);
						ram_we <= '1';
						wstate <= store_noinc;
					elsif (io_write = '1') and (cs_green = '1') then
						ram_write_buffer <= data(7 downto 0) & word_out_int(15 downto 8) & word_out_int(7 downto 0);
						ram_we <= '1';
						wstate <= store_noinc;
					elsif (io_write = '1') and (cs_blue = '1') then
						ram_write_buffer <= word_out_int(23 downto 16) & word_out_int(15 downto 8) & data(7 downto 0);
						ram_we <= '1';
						wstate <= store_noinc;
					
					-- for set all, start looping over memory
					elsif (io_write = '1') and (cs_all = '1') then
						ram_write_addr <= x"00";
						ram_write_buffer <= data(10 downto 5) & data(10 downto 9) & data(15 downto 11) & data(15 downto 13) & data(4 downto 0) & data(4 downto 2);
						ram_we <= '1';
						wstate <= storeAll;
						
					-- For 16-bit color, convert RGB565 to 24-bit color and write to memory
					elsif (io_write = '1') and (cs_rgb='1') then
						ram_write_buffer <= data(10 downto 5) & data(10 downto 9) & data(15 downto 11) & data(15 downto 13) & data(4 downto 0) & data(4 downto 2);
						ram_we <= '1';
						wstate <= storing;
					end if;
					
				when storing =>
					ram_write_addr <= ram_write_addr + 1;
					ram_we <= '0';
					wstate <= idle;
					
				when store_noinc =>
					ram_we <= '0';
					wstate <= idle;
					
				when storeAll =>
					ram_write_addr <= ram_write_addr + 1;
					-- terminate at address 255 (closest hex number that is greater than 216)
					-- this means all the pixels have been written to
					if (ram_write_addr = x"FF") then
						ram_we <= '0';
						wstate <= idle;
					end if;

				when others =>
					wstate <= idle;
				end case;
			end if;
		end if;
	end process;

	
	
end internals;
