/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant VGA/LCD Core; Timing Generator   ////
////  Horizontal and Vertical Timing Generator                   ////
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
//  $Id: vga_tgen.v,v 1.4 2002-01-28 03:47:16 rherveille Exp $
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
