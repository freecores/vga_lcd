//
// File vga_fifo_dc.v (dual clocked fifo)
// Author : Richard Herveille
//          
//          WARNING: DO NOT CHANGE THIS FILE
//                   CHANGE "DPM.V" FOR TARGET SPECIFIC MEMORY BLOCKS
//
// rev. 0.1 August  2nd, 2001. Initial Verilog release
//

`include "timescale.v"

module vga_fifo_dc (rclk, wclk, aclr, wreq, rreq, rd_empty,
		rd_full, wr_empty, wr_full, rptr, wptr);
	// parameters
	parameter AWIDTH = 7; //128 entries

	// inputs & outputs
	input rclk;             // read clock
	input wclk;             // write clock
	input aclr;             // active low asynchronous clear
	input wreq;             // write request
	input rreq;             // read request

	output rd_empty;        // FIFO is empty, synchronous to read clock
	output rd_full;         // FIFO is full, synchronous to read clock
	output wr_empty;        // FIFO is empty, synchronous to write clock
	output wr_full;         // FIFO is full, synchronous to write clock

	// Dualported Memory Interface
	output [AWIDTH -1:0] rptr, wptr;

	reg rd_empty;
	reg rd_full;
	reg wr_empty;
	reg wr_full;

	// variable declarations
	parameter DEPTH = 1 << AWIDTH;

	reg [AWIDTH -1:0] rptr, wptr;
	wire ifull, iempty;
	reg rempty, rfull, wempty, wfull;

	//
	// module body
	//


	//
	// Pointers
	//
	// read pointer
	always@(posedge rclk or negedge aclr)
		if (~aclr)
			rptr <= #1 0;
		else if (rreq)
			rptr <= #1 rptr + 1;

	// write pointer
	always@(posedge wclk or negedge aclr)
		if (~aclr)
			wptr <= #1 0;
		else if (wreq)
			wptr <= #1 wptr +1;

	//
	// status flags
	//
	wire [AWIDTH -1:0] tmp;
	wire [AWIDTH -1:0] tmp2;
	assign tmp = wptr - rptr;
	assign iempty = (rptr == wptr) ? 1'b1 : 1'b0;

	assign tmp2 = DEPTH -3;
	assign ifull  = ( tmp >= tmp2 ) ? 1'b1 : 1'b0;

	// rdclk flags
	always@(posedge rclk or negedge aclr)
		if (~aclr)
			begin
				rempty   <= #1 1'b1;
				rfull    <= #1 1'b0;
				rd_empty <= #1 1'b1;
				rd_full  <= #1 1'b0;
			end
		else
			begin
				rempty   <= #1 iempty;
				rfull    <= #1 ifull;
				rd_empty <= #1 rempty;
				rd_full  <= #1 rfull;
			end

	// wrclk flags
	always@(posedge wclk or negedge aclr)
		if (~aclr)
			begin
				wempty   <= #1 1'b1;
				wfull    <= #1 1'b0;
				wr_empty <= #1 1'b1;
				wr_full  <= #1 1'b0;
			end
		else
			begin
				wempty   <= #1 iempty;
				wfull    <= #1 ifull;
				wr_empty <= #1 wempty;
				wr_full  <= #1 wfull;
			end

endmodule


