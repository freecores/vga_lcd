//
// File vtim.v, Video Timing Generator
// Project: VGA
// Author : Richard Herveille
// rev.: 0.1 July  9th, 2001. Initial Verilog release
//

`include "timescale.v"

module vga_vtim(clk, ena, rst, Tsync, Tgdel, Tgate, Tlen, Sync, Gate, Done);
	// inputs & outputs
	input clk; // master clock
	input ena; // count enable
	input rst; // synchronous active high reset

	input [ 7:0] Tsync; // sync duration
	input [ 7:0] Tgdel; // gate delay
	input [15:0] Tgate; // gate length
	input [15:0] Tlen;  // line time / frame time

	output Sync; // synchronization pulse
	output Gate; // gate
	output Done; // done with line/frame
	reg Sync;
	reg Gate;


	//
	// variable declarations
	//

	wire Dsync, Dgdel, Dgate, Dlen;
	reg go, drst;

	//
	// module body
	//

	// generate go signal
	always@(posedge clk)
		if (rst)
			begin
				go <= 1'b0;
				drst <= 1'b1;
			end
		else if (ena)
			begin
				go <= Dlen | (!rst & drst);
				drst <= rst;
			end

	// hookup sync counter
	ro_cnt #(8) sync_cnt (.clk(clk), .rst(rst), .nReset(1'b1), .cnt_en(ena), .go(go), .d(Tsync), .id(Tsync), .q(), .done(Dsync));

	// hookup gate delay counter
	ro_cnt #(8) gdel_cnt (.clk(clk), .rst(rst), .nReset(1'b1), .cnt_en(ena), .go(Dsync), .d(Tgdel), .id(Tgdel), .q(), .done(Dgdel));

	// hookup gate counter
	ro_cnt #(16) gate_cnt (.clk(clk), .rst(rst), .nReset(1'b1), .cnt_en(ena), .go(Dgdel), .d(Tgate), .id(Tgate), .q(), .done(Dgate));

	// hookup gate counter
	ro_cnt #(16) len_cnt (.clk(clk), .rst(rst), .nReset(1'b1), .cnt_en(ena), .go(go), .d(Tlen), .id(Tlen), .q(), .done(Dlen));

	// generate output signals
	always@(posedge clk)
		if (rst)
			Sync <= 1'b0;
		else
			Sync <= (go | Sync)  & !Dsync;

	always@(posedge clk)
		if (rst)
			Gate <= 1'b0;
		else
			Gate <= (Dgdel | Gate) & !Dgate;

	assign Done = Dlen;
endmodule
