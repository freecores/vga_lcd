//
// File tgen.v, Video Horizontal and Vertical Timing Generator
// Project: VGA
// Author : Richard Herveille
// rev.: 0.1 July 9th, 2001. Initial Verilog release.
//
//

`include "timescale.v"

module vga_tgen(clk, rst, HSyncL, Thsync, Thgdel, Thgate, Thlen, VSyncL, Tvsync, Tvgdel, Tvgate, Tvlen, CSyncL, BlankL,
		eol, eof, gate, Hsync, Vsync, Csync, Blank);
	// inputs & outputs
	input clk;
	input rst;
	// horizontal timing settings inputs
	input        HSyncL; // horizontal sync pulse polarization level (pos/neg)
	input [ 7:0] Thsync; // horizontal sync pule width (in pixels)
	input [ 7:0] Thgdel; // horizontal gate delay
	input [15:0] Thgate; // horizontal gate (number of visible pixels per line)
	input [15:0] Thlen;  // horizontal length (number of pixels per line)
	// vertical timing settings inputs
	input        VSyncL; // vertical sync pulse polarization level (pos/neg)
	input [ 7:0] Tvsync; // vertical sync pule width (in pixels)
	input [ 7:0] Tvgdel; // vertical gate delay
	input [15:0] Tvgate; // vertical gate (number of visible pixels per line)
	input [15:0] Tvlen;  // vertical length (number of pixels per line)

	input        CSyncL; // composite sync level (pos/neg)
	input        BlankL; // blanking level

	// outputs
	output eol;  // end of line
	output eof;  // end of frame
	output gate; // vertical AND horizontal gate (logical AND function)

	output Hsync; // horizontal sync pulse
	output Vsync; // vertical sync pulse
	output Csync; // composite sync
	output Blank; // blank signal	

	//
	// variable declarations
	//
	wire Hgate, Vgate;
	wire Hdone;
	wire iHsync, iVsync;

	//
	// module body
	//

	// hookup horizontal timing generator
	vga_vtim hor_gen(
		.clk(clk),
		.ena(1'b1),
		.rst(rst),
		.Tsync(Thsync),
		.Tgdel(Thgdel),
		.Tgate(Thgate),
		.Tlen(Thlen),
		.Sync(iHsync),
		.Gate(Hgate),
		.Done(Hdone));


	// hookup vertical timing generator
	vga_vtim ver_gen(
		.clk(clk),
		.ena(Hdone),
		.rst(rst),
		.Tsync(Tvsync),
		.Tgdel(Tvgdel),
		.Tgate(Tvgate),
		.Tlen(Tvlen),
		.Sync(iVsync),
		.Gate(Vgate),
		.Done(eof));

	// assign outputs
	assign eol  = Hdone;
	assign gate = Hgate & Vgate;

	assign Hsync = iHsync ^ HSyncL;
	assign Vsync = iVsync ^ VSyncL;
	assign Csync = (iHsync | iVsync) ^ CSyncL;
	assign Blank = !(gate ^ BlankL);
endmodule
