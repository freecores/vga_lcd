//
// File fifo.v (universal FIFO)
// Author : Richard Herveille
// rev.: 1.0 August 7th, 2001. Initial Verilog release

`include "timescale.v"

module vga_fifo (clk, aclr, sclr, d, wreq, q, rreq, empty, hfull, full);

	//
	// parameters
	//
	parameter AWIDTH = 7;  // 128 entries
	parameter DWIDTH = 32; // 32bits data

	//
	// inputs & outputs
	//
	input clk; // clock input
	input aclr; // active low asynchronous clear
	input sclr; // active high synchronous clear
	
	input [DWIDTH -1:0] d; // data input
	input wreq;            // write request

	output [DWIDTH -1:0] q; // data output
	reg [DWIDTH -1:0] q;
	input  rreq;            // read request

	output empty;           // fifo is empty
	output hfull;           // fifo is half full
	output full;            // fifo is full


	//
	// variable declarations
	//
	parameter DEPTH = 1 << AWIDTH;

	reg [DWIDTH -1:0] mem [DEPTH -1:0];

	reg [AWIDTH -1:0] rptr, wptr;
	reg [AWIDTH   :0] fifo_cnt;

	//
	// Module body
	//

	// read pointer
	always@(posedge clk or negedge aclr)
		if (!aclr)
			rptr <= #1 0;
		else if (sclr)
			rptr <= #1 0;
		else if (rreq)
			rptr <= #1 rptr + 1;

	// write pointer
	always@(posedge clk or negedge aclr)
		if (!aclr)
			wptr <= #1 0;
		else if (sclr)
			wptr <= #1 0;
		else if (wreq)
			wptr <= #1 wptr + 1;

	// memory array operations
	always@(posedge clk)
		begin
			if (wreq)
				mem[wptr] <= #1 d;
			
			q <= #1 mem[rptr];
		end

	// number of words in fifo
	always@(posedge clk or negedge aclr)
		if (!aclr)
			fifo_cnt <= #1 0;
		else if (sclr)
			fifo_cnt <= #1 0;
		else
			begin
				if (wreq & !rreq)
					fifo_cnt <= #1 fifo_cnt + 1;
				else if (rreq & !wreq)
					fifo_cnt <= #1 fifo_cnt - 1;
			end

	// status flags
	assign empty = !(|fifo_cnt);
	assign hfull = fifo_cnt[AWIDTH -1];
	assign full  = fifo_cnt[AWIDTH];
endmodule
