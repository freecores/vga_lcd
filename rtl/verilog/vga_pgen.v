//
// File pgen.v, Video Pixel Generator
// Project: VGA
// Author : Richard Herveille
// rev.: 0.1 July 10th, 2001. Initial Verilog release
//
//

`include "timescale.v"

module vga_pgen (mclk, pclk, ctrl_ven, ctrl_HSyncL, Thsync, Thgdel, Thgate, Thlen,
		ctrl_VSyncL, Tvsync, Tvgdel, Tvgate, Tvlen, ctrl_CSyncL, ctrl_BlankL,
		eoh, eov, gate, Hsync, Vsync, Csync, Blank);

	// inputs & outputs

	input mclk; // master clock
	input pclk; // pixel clock

	input ctrl_ven;           // Video enable signal

	// horiontal timing settings
	input        ctrl_HSyncL; // horizontal sync pulse polarization level (pos/neg)
	input [ 7:0] Thsync;      // horizontal sync pulse width (in pixels)
	input [ 7:0] Thgdel;      // horizontal gate delay (in pixels)
	input [15:0] Thgate;      // horizontal gate length (number of visible pixels per line)
	input [15:0] Thlen;       // horizontal length (number of pixels per line)

	// vertical timing settings
	input        ctrl_VSyncL; // vertical sync pulse polarization level (pos/neg)
	input [ 7:0] Tvsync;      // vertical sync pulse width (in lines)
	input [ 7:0] Tvgdel;      // vertical gate delay (in lines)
	input [15:0] Tvgate;      // vertical gate length (number of visible lines in frame)
	input [15:0] Tvlen;       // vertical length (number of lines in frame)
	
	// composite signals
	input ctrl_CSyncL; // composite sync pulse polarization level
	input ctrl_BlankL; // blank signal polarization level

	// status outputs
	output eoh;        // end of horizontal
	reg eoh;
	output eov;        // end of vertical;
	reg eov;
	output gate;       // vertical AND horizontal gate (logical AND function)

	// pixel control outputs
	output Hsync;      // horizontal sync pulse
	output Vsync;      // vertical sync pulse
	output Csync;      // composite sync: Hsync OR Vsync (logical OR function)
	output Blank;      // blanking signal


	//
	// variable declarations
	//
	reg nVen; // video enable signal (active low)
	wire eol, eof;

	//
	// module body
	//

	// synchronize timing/control settings (from master-clock-domain to pixel-clock-domain)
	always@(posedge pclk)
		nVen    <= #1 !ctrl_ven;

	// hookup video timing generator
	vga_tgen vtgen(.clk(pclk), .rst(nVen), .HSyncL(ctrl_HSyncL), .Thsync(Thsync), .Thgdel(Thgdel), .Thgate(Thgate), .Thlen(Thlen),
		.VSyncL(ctrl_VSyncL), .Tvsync(Tvsync), .Tvgdel(Tvgdel), .Tvgate(Tvgate), .Tvlen(Tvlen), .CSyncL(ctrl_CSyncL), .BlankL(ctrl_BlankL),
		.eol(eol), .eof(eof), .gate(gate), .Hsync(Hsync), .Vsync(Vsync), .Csync(Csync), .Blank(Blank));

	//
	// from pixel-clock-domain to master-clock-domain
	//
	reg seol, seof;   // synchronized end-of-line, end-of-frame
	reg dseol, dseof; // delayed seol, seof

	always@(posedge mclk)
		begin
			seol  <= eol;
			dseol <= seol;

			seof  <= eof;
			dseof <= seof;

			eoh <= seol & !dseol;
			eov <= seof & !dseof;
		end

endmodule
