/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant VGA/LCD Core; Pixel Generator    ////
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
//  $Id: vga_pgen.v,v 1.5 2002-04-05 06:24:35 rherveille Exp $
//
//  $Date: 2002-04-05 06:24:35 $
//  $Revision: 1.5 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.4  2002/01/28 03:47:16  rherveille
//               Changed counter-library.
//               Changed vga-core.
//               Added 32bpp mode.
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
		if (!ctrl_ven)
			begin
				seol  <= #1 1'b0;
				dseol <= #1 1'b0;

				seof  <= #1 1'b0;
				dseof <= #1 1'b0;

				eoh   <= #1 1'b0;
				eov   <= #1 1'b0;
			end
		else
			begin
				seol  <= #1 eol;
				dseol <= #1 seol;

				seof  <= #1 eof;
				dseof <= #1 seof;

				eoh   <= #1 seol & !dseol;
				eov   <= #1 seof & !dseof;
			end

endmodule

