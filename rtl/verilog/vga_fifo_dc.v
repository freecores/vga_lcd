/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant VGA/LCD Core; Dual Clocked Fifo  ////
////                                                             ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/vga_lcd ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: vga_fifo_dc.v,v 1.4 2002-01-28 03:47:16 rherveille Exp $
//
//  $Date: 2002-01-28 03:47:16 $
//  $Revision: 1.4 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $


`include "timescale.v"

module vga_fifo_dc (rclk, wclk, aclr, wreq, d, rreq, q, rd_empty, rd_full, wr_empty, wr_full);

	// parameters
	parameter AWIDTH = 7;  //128 entries
	parameter DWIDTH = 16; //16bit databus

	// inputs & outputs
	input rclk;             // read clock
	input wclk;             // write clock
	input aclr;             // active low asynchronous clear
	input wreq;             // write request
	input [DWIDTH -1:0] d;  // data input
	input rreq;             // read request
	output [DWIDTH -1:0] q; // data output

	output rd_empty;        // FIFO is empty, synchronous to read clock
	reg rd_empty;
	output rd_full;         // FIFO is full, synchronous to read clock
	reg rd_full;
	output wr_empty;        // FIFO is empty, synchronous to write clock
	reg wr_empty;
	output wr_full;         // FIFO is full, synchronous to write clock
	reg wr_full;

	// variable declarations
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

	assign tmp2 = (1 << AWIDTH) -3;
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

	// hookup generic dual ported memory
	generic_dpram #(AWIDTH, DWIDTH) fifo_dc_mem(
		.rclk(rclk),
		.rrst(1'b0),
		.rce(1'b1),
		.oe(1'b1),
		.raddr(rptr),
		.do(q),
		.wclk(wclk),
		.wrst(1'b0),
		.wce(1'b1),
		.we(wreq),
		.waddr(wptr),
		.di(d)
	);

endmodule
