/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant enhanced VGA/LCD Core            ////
////  Wishbone slave interface                                   ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/vga_lcd ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001, 2002 Richard Herveille                  ////
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
//  $Id: vga_wb_slave.v,v 1.6 2002-02-07 05:42:10 rherveille Exp $
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
`include "vga_defines.v"

module vga_wb_slave(CLK_I, RST_I, nRESET, ADR_I, DAT_I, DAT_O, SEL_I, WE_I, STB_I, CYC_I, ACK_O, ERR_O, INTA_O,
		bl, csl, vsl, hsl, pc, cd, vbl, cbsw, vbsw, ven, avmp, acmp, 
		cursor0_en, cursor0_xy, cursor0_ba, cursor0_ld, cursor1_en, cursor1_xy, cursor1_ba, cursor1_ld,
		vbsint_in, cbsint_in, hint_in, vint_in, luint_in, sint_in,
		Thsync, Thgdel, Thgate, Thlen, Tvsync, Tvgdel, Tvgate, Tvlen, VBARa, VBARb, clut_acc, clut_ack, clut_q);

	//
	// inputs & outputs
	//

	// wishbone slave interface
	input         CLK_I;
	input         RST_I;
	input         nRESET;
	input  [11:2] ADR_I;
	input  [31:0] DAT_I;
	output [31:0] DAT_O;
	reg [31:0] DAT_O;
	input  [ 3:0] SEL_I;
	input         WE_I;
	input         STB_I;
	input         CYC_I;
	output        ACK_O;
	reg ACK_O;
	output        ERR_O;
	reg ERR_O;
	output        INTA_O;
	reg INTA_O;

	// control register settings
	output bl;         // blanking level
	output csl;        // composite sync level
	output vsl;        // vsync level
	output hsl;        // hsync level
	output pc;         // pseudo color
	output [1:0] cd;   // color depth
	output [1:0] vbl;  // video memory burst length
	output cbsw;       // clut bank switch enable
	output vbsw;       // video memory bank switch enable
	output ven;        // video system enable

	// hardware cursor settings
	output         cursor0_en;
	output [31: 0] cursor0_xy;
	output [31:11] cursor0_ba;   // cursor0 base address
	output         cursor0_ld;   // reload cursor0 from video memory
	output         cursor1_en;
	output [31: 0] cursor1_xy;
	output [31:11] cursor1_ba;   // cursor1 base address
	output         cursor1_ld;   // reload cursor1 from video memory

	reg [31: 0] cursor0_xy;
	reg [31:11] cursor0_ba;
	reg         cursor0_ld;
	reg [31: 0] cursor1_xy;
	reg [31:11] cursor1_ba;
	reg         cursor1_ld;

	// status register inputs
	input avmp;          // active video memory page
	input acmp;          // active clut memory page
	input vbsint_in;     // bank switch interrupt request
	input cbsint_in;     // clut switch interrupt request
	input hint_in;       // hsync interrupt request
	input vint_in;       // vsync interrupt request
	input luint_in;      // line fifo underrun interrupt request
	input sint_in;       // system error interrupt request

	// Horizontal Timing Register
	output [ 7:0] Thsync;
	output [ 7:0] Thgdel;
	output [15:0] Thgate;
	output [15:0] Thlen;

	// Vertical Timing Register
	output [ 7:0] Tvsync;
	output [ 7:0] Tvgdel;
	output [15:0] Tvgate;
	output [15:0] Tvlen;

	// video base addresses
	output [31:2] VBARa;
	reg [31:2] VBARa;
	output [31:2] VBARb;
	reg [31:2] VBARb;

	// color lookup table signals
	output        clut_acc;
	input         clut_ack;
	input  [23:0] clut_q;


	//
	// variable declarations
	//
	parameter REG_ADR_HIBIT = 3;

	wire [REG_ADR_HIBIT:0] REG_ADR  = ADR_I[REG_ADR_HIBIT +2 : 2];
	wire                   CLUT_ADR = ADR_I[11];

	parameter [REG_ADR_HIBIT : 0] CTRL_ADR  = 4'b0000;
	parameter [REG_ADR_HIBIT : 0] STAT_ADR  = 4'b0001;
	parameter [REG_ADR_HIBIT : 0] HTIM_ADR  = 4'b0010;
	parameter [REG_ADR_HIBIT : 0] VTIM_ADR  = 4'b0011;
	parameter [REG_ADR_HIBIT : 0] HVLEN_ADR = 4'b0100;
	parameter [REG_ADR_HIBIT : 0] VBARA_ADR = 4'b0101;
	parameter [REG_ADR_HIBIT : 0] VBARB_ADR = 4'b0110;
	parameter [REG_ADR_HIBIT : 0] C0XY_ADR  = 4'b1000;
	parameter [REG_ADR_HIBIT : 0] C0BAR_ADR = 4'b1001;
	parameter [REG_ADR_HIBIT : 0] C1XY_ADR  = 4'b1010;
	parameter [REG_ADR_HIBIT : 0] C1BAR_ADR = 4'b1011;


	reg [31:0] ctrl, stat, htim, vtim, hvlen;
	wire hint, vint, vbsint, cbsint, luint, sint;
	wire hie, vie, vbsie, cbsie;
	wire acc, acc32, reg_acc, reg_wacc;


	reg [31:0] reg_dato; // data output from registers

	//
	// Module body
	//

	assign acc      =  CYC_I & STB_I;
	assign acc32    = (SEL_I == 4'b1111);
	assign clut_acc =  CLUT_ADR & acc & acc32;
	assign reg_acc  = !CLUT_ADR & acc & acc32;
	assign reg_wacc =  reg_acc & WE_I;

	always@(posedge CLK_I)
		ACK_O <= #1 ((reg_acc & acc32) | clut_ack) & !ACK_O;

	always@(posedge CLK_I)
		ERR_O <= #1 acc & !acc32;


	// generate registers
	always@(posedge CLK_I or negedge nRESET)
	begin : gen_regs
		if(!nRESET)
			begin
				htim  <= #1 0;
				vtim  <= #1 0;
				hvlen <= #1 0;
				VBARa <= #1 0;
				VBARb <= #1 0;
			end
		else if (RST_I)
			begin
				htim  <= #1 0;
				vtim  <= #1 0;
				hvlen <= #1 0;
				VBARa <= #1 0;
				VBARb <= #1 0;
			end
		else if (reg_wacc)
			case (ADR_I)	// synopsis full_case parallel_case
				HTIM_ADR  : htim       <= #1 DAT_I;
				VTIM_ADR  : vtim       <= #1 DAT_I;
				HVLEN_ADR : hvlen      <= #1 DAT_I;
				VBARA_ADR : VBARa      <= #1 DAT_I[31: 2];
				VBARB_ADR : VBARb      <= #1 DAT_I[31: 2];
				C0XY_ADR  : cursor0_xy <= #1 DAT_I[31: 0];
				C0BAR_ADR : cursor0_ba <= #1 DAT_I[31:11];
				C1XY_ADR  : cursor1_xy <= #1 DAT_I[31: 0];
				C1BAR_ADR : cursor1_ba <= #1 DAT_I[31:11];
			endcase
	end

	always@(posedge CLK_I)
		begin
			cursor0_ld <= #1 reg_wacc && (ADR_I == C0BAR_ADR);
			cursor1_ld <= #1 reg_wacc && (ADR_I == C1BAR_ADR);
		end

	// generate control register
	always@(posedge CLK_I or negedge nRESET)
		if (!nRESET)
			ctrl <= #1 0;
		else if (RST_I)
			ctrl <= #1 0;
		else if (reg_wacc & (REG_ADR == CTRL_ADR) )
			ctrl <= #1 DAT_I;
		else
			begin
				ctrl[6] <= #1 ctrl[6] & !cbsint_in;
				ctrl[5] <= #1 ctrl[5] & !vbsint_in;
			end


	// generate status register
	always@(posedge CLK_I or negedge nRESET)
		if (!nRESET)
			stat <= #1 0;
		else if (RST_I)
			stat <= #1 0;
		else
			begin
				`ifdef VGA_HWC1
					stat[21] <= #1 1'b1;
				`else
					stat[21] <= #1 1'b0;
				`endif
				`ifdef VGA_HWC0
					stat[20] <= #1 1'b1;
				`else
					stat[20] <= #1 1'b0;
				`endif

				stat[17] <= #1 acmp;
				stat[16] <= #1 avmp;

				if (reg_wacc & (REG_ADR == STAT_ADR) )
					begin
						stat[7] <= #1 cbsint_in | (stat[7] & !DAT_I[7]);
						stat[6] <= #1 vbsint_in | (stat[6] & !DAT_I[6]);
						stat[5] <= #1 hint_in   | (stat[5] & !DAT_I[5]);
						stat[4] <= #1 vint_in   | (stat[4] & !DAT_I[4]);
						stat[1] <= #1 luint_in  | (stat[3] & !DAT_I[1]);
						stat[0] <= #1 sint_in   | (stat[0] & !DAT_I[0]);
					end
				else
					begin
						stat[7] <= #1 stat[7] | cbsint_in;
						stat[6] <= #1 stat[6] | vbsint_in;
						stat[5] <= #1 stat[5] | hint_in;
						stat[4] <= #1 stat[4] | vint_in;
						stat[1] <= #1 stat[1] | luint_in;
						stat[0] <= #1 stat[0] | sint_in;
					end
			end


	// decode control register
	assign cursor1_en = ctrl[21];
	assign cursor0_en = ctrl[20];
	assign bl         = ctrl[15];
	assign csl        = ctrl[14];
	assign vsl        = ctrl[13];
	assign hsl        = ctrl[12];
	assign pc         = ctrl[11];
	assign cd         = ctrl[10:9];
	assign vbl        = ctrl[8:7];
	assign cbsw       = ctrl[6];
	assign vbsw       = ctrl[5];
	assign cbsie      = ctrl[4];
	assign vbsie      = ctrl[3];
	assign hie        = ctrl[2];
	assign vie        = ctrl[1];
	assign ven        = ctrl[0];

	// decode status register
	assign cbsint = stat[7];
	assign vbsint = stat[6];
	assign hint   = stat[5];
	assign vint   = stat[4];
	assign luint  = stat[1];
	assign sint   = stat[0];

	// decode Horizontal Timing Register
	assign Thsync = htim[31:24];
	assign Thgdel = htim[23:16];
	assign Thgate = htim[15:0];
	assign Thlen  = hvlen[31:16];

	// decode Vertical Timing Register
	assign Tvsync = vtim[31:24];
	assign Tvgdel = vtim[23:16];
	assign Tvgate = vtim[15:0];
	assign Tvlen  = hvlen[15:0];

	
	// assign output
	always@(REG_ADR or ctrl or stat or htim or vtim or hvlen or VBARa or VBARb or acmp)
	case (REG_ADR) // synopsis full_case parallel_case
		CTRL_ADR  : reg_dato = ctrl;
		STAT_ADR  : reg_dato = stat;
		HTIM_ADR  : reg_dato = htim;
		VTIM_ADR  : reg_dato = vtim;
		HVLEN_ADR : reg_dato = hvlen;
		VBARA_ADR : reg_dato = {VBARa, 2'b0};
		VBARB_ADR : reg_dato = {VBARb, 2'b0};
		C0XY_ADR  : reg_dato = cursor0_xy;
		C0BAR_ADR : reg_dato = {cursor0_ba, 11'h0};
		C1XY_ADR  : reg_dato = cursor1_xy;
		C1BAR_ADR : reg_dato = {cursor1_ba, 11'h0};
		default   : reg_dato = 32'h0000_0000;
	endcase

	always@(posedge CLK_I)
		DAT_O <= #1 reg_acc ? reg_dato : {8'h0, clut_q};

	// generate interrupt request signal
	always@(posedge CLK_I)
		INTA_O <= #1 (hint & hie) | (vint & vie) | (vbsint & vbsie) | (cbsint & cbsie) | luint | sint;
endmodule


