//
// File vga_dpm.v (dual ported memory)
// Author : Richard Herveille
// 
//       fifo_dc uses this entity to implement the dual ported RAM of the fifo.
//       Change this file to implement target specific RAM blocks.
//
// rev. 0.1 August  2nd, 2001. Initial Verilog release.
//

//
// dual ported memory, wrapper for target specific RAM blocks
//

`include "timescale.v"

module vga_dpm (rclk, wclk, d, waddr, wreq, q, raddr);
	// parameters
	parameter AWIDTH = 8;
	parameter DWIDTH = 24;

	// inputs & outputs
	input rclk; // read clock
	input wclk; // write clock

	input [DWIDTH -1:0] d; // data input
	input [AWIDTH -1:0] waddr; // write clock address
	input wreq; // write request

	output [DWIDTH -1:0] q; // data output
	reg    [DWIDTH -1:0] q;
	input  [AWIDTH -1:0] raddr; // read clock address

	// generic memory description
	parameter DEPTH = 1 << AWIDTH;
	reg [DWIDTH -1:0] mem [DEPTH -1:0];

	//
	// module body
	//

	//
	// Change the next section(s) for target specific RAM blocks.
	// The functionality as described below must be maintained! Some target specific RAM blocks have an asychronous output. 
	// Insert registers at the output if necessary
	//

	// generic dual ported memory description
	//
	always@(posedge wclk)
		if (wreq)
			mem[waddr] <= #1 d;

	always@(posedge rclk)
		q <= #1 mem[raddr];

endmodule

