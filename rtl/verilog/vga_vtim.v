/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant VGA/LCD Core; Timing Generator   ////
////  Video Timing Generator                                     ////
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
//  $Id: vga_vtim.v,v 1.6 2002-04-20 10:02:39 rherveille Exp $
//
//  $Date: 2002-04-20 10:02:39 $
//  $Revision: 1.6 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.5  2002/01/28 03:47:16  rherveille
//               Changed counter-library.
//               Changed vga-core.
//               Added 32bpp mode.
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
				go   <= #1 1'b0;
				drst <= #1 1'b1;
			end
		else // if (ena)
			begin
				go   <= #1 Dlen | (!rst & drst);
				drst <= #1 rst;
			end

	// hookup sync counter
	ro_cnt #(8, 1'b0, 8)
		sync_cnt(
			.clk(clk),
			.rst(rst),
			.nReset(1'b1),
			.cnt_en(ena),
			.go(go),
			.d(Tsync),
			.q(),
			.done(Dsync)
		);

	// hookup gate delay counter
	ro_cnt #(8, 1'b0, 8)
		gdel_cnt(
			.clk(clk),
			.rst(rst),
			.nReset(1'b1),
			.cnt_en(ena),
			.go(Dsync),
			.d(Tgdel),
			.q(),
			.done(Dgdel)
		);

	// hookup gate counter
	ro_cnt #(16, 1'b0, 16)
		gate_cnt(
			.clk(clk),
			.rst(rst),
			.nReset(1'b1),
			.cnt_en(ena),
			.go(Dgdel),
			.d(Tgate),
			.q(),
			.done(Dgate)
		);

	// hookup length counter
	ro_cnt #(16, 1'b0, 16)
		len_cnt(
			.clk(clk),
			.rst(rst),
			.nReset(1'b1),
			.cnt_en(ena),
			.go(go),
			.d(Tlen),
			.q(),
			.done(Dlen)
		);

	// generate output signals
	always@(posedge clk)
		if (rst)
			Sync <= #1 1'b0;
		else
			Sync <= #1 (go | Sync) & !Dsync;

	always@(posedge clk)
		if (rst)
			Gate <= #1 1'b0;
		else
			Gate <= #1 (Dgdel | Gate) & !Dgate;

	assign Done = Dlen;
endmodule
