/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant enhanced VGA/LCD Core            ////
////  Video source selector / Hardware cursor block              ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/vga_lcd ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Richard Herveille                        ////
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
//  $Id: vga_ssel.v,v 1.1 2002-02-07 05:42:10 rherveille Exp $
//
//  $Date: 2002-02-07 05:42:10 $
//  $Revision: 1.1 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $

`include "timescale.v"

module vga_ssel (clk, rst_i, Thgate, Tvgate, idat, idat_wreq, 
	cursor_xy, cursor_en, cursor_adr, cursor_dat, cursor_we,
	rgb_fifo_wreq, rgb);

	//
	// inputs & outputs
	//

	// wishbone signals
	input         clk;           // master clock input
	input         rst_i;         // synchronous active high reset

	// image size
	input [15:0] Thgate, Tvgate; // horizontal/vertical gate
	// image data
	input [23:0] idat;           // image data input
	input        idat_wreq;      // image data write request

	// cursor data
	input [31:0] cursor_xy;      // cursor (x,y)
	input        cursor_en;      // cursor enable (on/off)
	input [ 8:0] cursor_adr;     // cursor address
	input [31:0] cursor_dat;     // cursor data
	input        cursor_we;      // write enable

	// rgb-fifo connections
	output        rgb_fifo_wreq; // rgb-out write request
	reg        rgb_fifo_wreq;
	output [23:0] rgb;           // rgb data output
	reg [23:0] rgb;

	//
	// variable declarations
	//
	reg         dcursor_en;
	reg  [15:0] xcnt, ycnt;
	wire        xdone, ydone;
	wire [15:0] cursor_x, cursor_y;
	wire        cursor_transparent;
	wire [ 7:0] cursor_r, cursor_g, cursor_b;
	reg         inbox_x, inbox_y;
	wire        inbox;
	reg  [23:0] didat;
	reg         store_one;
	wire [31:0] cmem_q;
	reg  [ 9:0] cmem_ra;
	wire [ 8:0] cmem_a;

	//
	// module body
	//

	// generate x-y counters
	always@(posedge clk)
		if(rst_i || xdone)
			xcnt <= #1 16'h0;
		else if (idat_wreq)
			xcnt <= #1 xcnt + 16'h1;

	assign xdone = (xcnt == Thgate) && idat_wreq;

	always@(posedge clk)
		if(rst_i || ydone)
			ycnt <= #1 16'h0;
		else if (xdone)
			ycnt <= #1 ycnt + 16'h1;

	assign ydone = (ycnt == Tvgate) && idat_wreq;


	// decode cursor (x,y)
	assign cursor_x = cursor_xy[15: 0];
	assign cursor_y = cursor_xy[31:16];


	// generate inbox signals
	always@(posedge clk)
		begin
			inbox_x <= #1 (xcnt >= cursor_x) && (xcnt < (cursor_x +16'h1f) );
			inbox_y <= #1 (ycnt >= cursor_y) && (ycnt < (cursor_y +16'h1f) );
		end

	assign inbox = inbox_x && inbox_y;


	// hookup local cursor memory (generic synchronous single port memory)
	// cursor memory should never be written to/read from at the same time
	generic_spram #(9, 32) cmem(
		.clk(clk),
		.rst(1'b0),       // no reset
		.ce(1'b1),        // always enable memory
		.we(cursor_we),
		.oe(1'b1),        // always output data
		.addr(cmem_a),
		.di(cursor_dat),
		.do(cmem_q)
	);

	assign cmem_a = cursor_we ? cursor_adr : cmem_ra[9:1];


	// decode cursor data
	assign cursor_transparent = cmem_ra[0] ? cmem_q[31] : cmem_q[15];
	assign cursor_r = cmem_ra[0] ? {cmem_q[30:26], 3'h0} : {cmem_q[14:10], 3'h0};
	assign cursor_g = cmem_ra[0] ? {cmem_q[25:21], 3'h0} : {cmem_q[ 9: 5], 3'h0};
	assign cursor_b = cmem_ra[0] ? {cmem_q[20:16], 3'h0} : {cmem_q[ 4: 0], 3'h0};


	// delay image data
	always@(posedge clk)
		if (idat_wreq)
			didat <= #1 idat;


	// generate selection unit
	always@(posedge clk)
		dcursor_en <= #1 cursor_en;

	always@(posedge clk)
		if (idat_wreq)
				if (!dcursor_en || !inbox)
					rgb <= #1 didat;
				else if (cursor_transparent)
					rgb <= #1 didat;
				else
					rgb <= #1 {cursor_r, cursor_g, cursor_b};


	// generate write request signal
	always@(posedge clk)
		if (rst_i)
			store_one <= #1 1'b0;
		else if (idat_wreq)
			store_one <= #1 1'b1;

	always@(posedge clk)
		rgb_fifo_wreq <= #1 idat_wreq & store_one;


	// generate cursor address counter
	always@(posedge clk)
		if (!cursor_en || ydone)
			cmem_ra <= #1 10'h0;
		else if (inbox && idat_wreq)
			cmem_ra <= #1 cmem_ra +10'h1;

endmodule
