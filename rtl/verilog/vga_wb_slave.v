//
// file: wb_slave.v
// project: VGA/LCD controller
// author: Richard Herveille
// rev. 1.0 August   6th, 2001. Initial verilog release
// rev. 2.0 October  2nd, 2001. Revised core. Moved color lookup-table to color processor. Changed wishbone slave to access clut, made outputs registered.
//

`include "timescale.v"

module vga_wb_slave(CLK_I, RST_I, nRESET, ADR_I, DAT_I, DAT_O, SEL_I, WE_I, STB_I, CYC_I, ACK_O, ERR_O, INTA_O,
		bl, csl, vsl, hsl, pc, cd, vbl, cbsw, vbsw, ven, avmp, acmp, vbsint_in, cbsint_in, hint_in, vint_in, luint_in, sint_in,
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
	output bl;   // blanking level
	output csl;  // composite sync level
	output vsl;  // vsync level
	output hsl;  // hsync level
	output pc;   // pseudo color
	output [1:0] cd;   // color depth
	output [1:0] vbl;  // video memory burst length
	output cbsw; // clut bank switch enable
	output vbsw; // video memory bank switch enable
	output ven;  // vdeio system enable

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
	output [31: 2] VBARa;
	reg [31: 2] VBARa;
	output [31: 2] VBARb;
	reg [31: 2] VBARb;

	// color lookup table signals
	output        clut_acc;
	input         clut_ack;
	input  [23:0] clut_q;


	//
	// variable declarations
	//
	wire [2:0] REG_ADR  = ADR_I[4:2];
	wire       CLUT_ADR = ADR_I[11];

	parameter [2:0] CTRL_ADR  = 3'b000;
	parameter [2:0] STAT_ADR  = 3'b001;
	parameter [2:0] HTIM_ADR  = 3'b010;
	parameter [2:0] VTIM_ADR  = 3'b011;
	parameter [2:0] HVLEN_ADR = 3'b100;
	parameter [2:0] VBARA_ADR = 3'b101;
	parameter [2:0] VBARB_ADR = 3'b110;


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
				HTIM_ADR  : htim  <= #1 DAT_I;
				VTIM_ADR  : vtim  <= #1 DAT_I;
				HVLEN_ADR : hvlen <= #1 DAT_I;
				VBARA_ADR : VBARa <= #1 DAT_I[31: 2];
				VBARB_ADR : VBARb <= #1 DAT_I[31: 2];
			endcase
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
	assign bl    = ctrl[15];
	assign csl   = ctrl[14];
	assign vsl   = ctrl[13];
	assign hsl   = ctrl[12];
	assign pc    = ctrl[11];
	assign cd    = ctrl[10:9];
	assign vbl   = ctrl[8:7];
	assign cbsw  = ctrl[6];
	assign vbsw  = ctrl[5];
	assign cbsie = ctrl[4];
	assign vbsie = ctrl[3];
	assign hie   = ctrl[2];
	assign vie   = ctrl[1];
	assign ven   = ctrl[0];

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
		default   : reg_dato = 32'h0000_0000;
	endcase

	always@(posedge CLK_I)
		DAT_O <= #1 reg_acc ? reg_dato : {8'h0, clut_q};

	// generate interrupt request signal
	always@(posedge CLK_I)
		INTA_O <= #1 (hint & hie) | (vint & vie) | (vbsint & vbsie) | (cbsint & cbsie) | luint | sint;
endmodule

