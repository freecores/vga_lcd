/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant VGA/LCD Core; Universal Fifo     ////
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
//  $Id: vga_fifo.v,v 1.6 2002-02-07 05:42:10 rherveille Exp $
//
//  $Date: 2002-02-07 05:42:10 $
//  $Revision: 1.6 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $

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
//	reg [DWIDTH -1:0] q;
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
		if (wreq)
			mem[wptr] <= #1 d;

	assign q = mem[rptr];
	
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
	assign hfull = fifo_cnt[AWIDTH -1] | fifo_cnt[AWIDTH];
	assign full  = fifo_cnt[AWIDTH];
endmodule

