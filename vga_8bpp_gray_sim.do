--
-- generate clocks
--
-- wishbone clock 200MHz
force -freeze vga/clk_i 0 0ns, 1 2.5ns -r {5ns}
-- pixel clock 36MHz
force -freeze vga/pclk 0 0ns, 1 13ns -r {26ns}


--
-- generate resets
--
force -freeze vga/nreset 1 0ns
force -freeze vga/rst_i 1 0ns, 0 100ns


--
-- fill registers
--
-- horizontal timing register thsync: 5pixels, thgdel: 10pixels, thgate 25pixels, this should trigger ERR_O (no 32bit access)
force -freeze /vga/cyc_i 1 118ns, 0 123ns
force -freeze /vga/sel_i 1101 118ns, 0000 123ns
force -freeze /vga/stb_i 1 118ns, 0 123ns
force -freeze /vga/we_i 1 118ns, 0 123ns
force -freeze /vga/adr_i 010 118ns, ZZZ 123ns
force -freeze /vga/sdat_i 16#04090018 118ns, 16#ZZZZZZZZ 123ns

-- horizontal timing register thsync: 5pixels, thgdel: 10pixels, thgate 25pixels, normal cycle
force -freeze /vga/cyc_i 1 128ns, 0 133ns
force -freeze /vga/sel_i 1111 128ns, 0000 133ns
force -freeze /vga/stb_i 1 128ns, 0 133ns
force -freeze /vga/we_i 1 128ns, 0 133ns
force -freeze /vga/adr_i 010 128ns, ZZZ 133ns
force -freeze /vga/sdat_i 16#04090018 128ns, 16#ZZZZZZZZ 133ns

-- vertical timing register tvsync: 5lines, thgdel: 1line, thgate 2lines
force -freeze /vga/cyc_i 1 138ns, 0 143ns
force -freeze /vga/sel_i 1111 138ns, 0000 143ns
force -freeze /vga/stb_i 1 138ns, 0 143ns
force -freeze /vga/we_i 1 138ns, 0 143ns
force -freeze /vga/adr_i 011 138ns, ZZZ 143ns
force -freeze /vga/sdat_i 16#05010002 138ns, 16#ZZZZZZZZ 143ns

-- horizontal/vertical length register: hlen: 45pixels, vlen: 10lines
force -freeze /vga/cyc_i 1 148ns, 0 153ns
force -freeze /vga/sel_i 1111 148ns, 0000 153ns
force -freeze /vga/stb_i 1 148ns, 0 153ns
force -freeze /vga/we_i 1 148ns, 0 153ns
force -freeze /vga/adr_i 100 148ns, ZZZ 153ns
force -freeze /vga/sdat_i 16#002c000A 148ns, 16#ZZZZZZZZ 153ns

-- color lookup table base address 0x20000000
force -freeze /vga/cyc_i 1 158ns, 0 163ns
force -freeze /vga/sel_i 1111 158ns, 0000 163ns
force -freeze /vga/stb_i 1 158ns, 0 163ns
force -freeze /vga/we_i 1 158ns, 0 163ns
force -freeze /vga/adr_i 111 158ns, ZZZ 163ns
force -freeze /vga/sdat_i 16#20000000 158ns, 16#ZZZZZZZZ 163ns

-- video memory base address A: 0x00000000
force -freeze /vga/cyc_i 1 168ns, 0 173ns
force -freeze /vga/sel_i 1111 168ns, 0000 173ns
force -freeze /vga/stb_i 1 168ns, 0 173ns
force -freeze /vga/we_i 1 168ns, 0 173ns
force -freeze /vga/adr_i 101 168ns, ZZZ 173ns
force -freeze /vga/sdat_i 16#00000000 168ns, 16#ZZZZZZZZ 173ns

-- video memory base address A: 0x15000000
force -freeze /vga/cyc_i 1 178ns, 0 183ns
force -freeze /vga/sel_i 1111 178ns, 0000 183ns
force -freeze /vga/stb_i 1 178ns, 0 183ns
force -freeze /vga/we_i 1 178ns, 0 183ns
force -freeze /vga/adr_i 110 178ns, ZZZ 183ns
force -freeze /vga/sdat_i 16#15000000 178ns, 16#ZZZZZZZZ 183ns

-- control register, bl-pos, cl-pos, vs-pos, hs-pos, 8bit gray 8bpp, vbl-2cycle, bs-en, bsi-en, hi-en, vi-en, v-en
force -freeze /vga/cyc_i 1 188ns, 0 193ns
force -freeze /vga/sel_i 1111 188ns, 0000 193ns
force -freeze /vga/stb_i 1 188ns, 0 193ns
force -freeze /vga/we_i 1 188ns, 0 193ns
force -freeze /vga/adr_i 000 188ns, ZZZ 193ns
force -freeze /vga/sdat_i 16#0000009f 188ns, 16#ZZZZZZZZ 193ns

-- present video memory data to vga controller
force -freeze /vga/mdat_i 16#01234567 208ns, 16#89abcdef 213ns, 16#76543210 218ns, 16#fedcba98 223ns
force -freeze /vga/mdat_i 16#01234567 228ns, 16#89abcdef 233ns, 16#76543210 238ns, 16#fedcba98 243ns
force -freeze /vga/mdat_i 16#01234567 248ns, 16#89abcdef 253ns, 16#76543210 258ns
force -freeze /vga/ack_i  0 0ns, 1 208ns, 0 258ns
force -freeze /vga/err_i 0 0ns

-- present color lookup table data to vga controller
force -freeze /vga/mdat_i 16#00112233 265ns, 16#00445566 270ns, 16#00778899 275ns, 16#00aabbcc 280ns
force -freeze /vga/ack_i 1 265ns, 0 285ns

force -freeze /vga/mdat_i 16#00ddeeff 310ns, 16#00332211 315ns, 16#00665544 320ns, 16#00998877 325ns
force -freeze /vga/ack_i 1 310ns, 0 330ns


-- keep ACK_I signal asserted (acknowledge all cycles)
force -freeze /vga/ack_i 1 350ns

-- INTA_O is asserted (horizontal interrupt), clear it
force -freeze /vga/cyc_i 1 1408ns, 0 1413ns
force -freeze /vga/sel_i 1111 1408ns, 0000 1413ns
force -freeze /vga/stb_i 1 1408ns, 0 1413ns
force -freeze /vga/we_i 1 1408ns, 0 1413ns
force -freeze /vga/adr_i 001 1408ns, ZZZ 1413ns
force -freeze /vga/sdat_i 16#00000020 1408ns, 16#ZZZZZZZZ 1413ns





