//
// file: wb_slave.v
// project: VGA/LCD controller
// author: Richard Herveille
// rev 1.0 August  6th, 2001. Initial verilog release
//

`include "timescale.v"

module vga_wb_slave(CLK_I, RST_I, nRESET, ADR_I, DAT_I, DAT_O, SEL_I, WE_I, STB_I, CYC_I, ACK_O, ERR_O, INTA_O,
		bl, csl, vsl, hsl, pc, cd, vbl, cbsw, vbsw, ven, avmp, acmp, bsint_in, hint_in, vint_in, luint_in, sint_in,
		Thsync, Thgdel, Thgate, Thlen, Tvsync, Tvgdel, Tvgate, Tvlen, VBARa, VBARb, CBAR);

	//
	// inputs & outputs
	//

	// wishbone slave interface
	input         CLK_I;
	input         RST_I;
	input         nRESET;
	input  [ 4:2] ADR_I;
	input  [31:0] DAT_I;
	output [31:0] DAT_O;
	reg [31:0] DAT_O;
	input  [ 3:0] SEL_I;
	input         WE_I;
	input         STB_I;
	input         CYC_I;
	output        ACK_O;
	output        ERR_O;
	output        INTA_O;

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
	input avmp;     // active video memory page
	input acmp;     // active clut memory page
	input bsint_in; // bank switch interrupt request
	input hint_in;  // hsync interrupt request
	input vint_in;  // vsync interrupt request
	input luint_in; // line fifo underrun interrupt request
	input sint_in;  // system error interrupt request

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

	output [31: 2] VBARa;
	reg [31: 2] VBARa;
	output [31: 2] VBARb;
	reg [31: 2] VBARb;
	output [31:11] CBAR;
	reg [31:11] CBAR;

	//
	// variable declarations
	//
	parameter [2:0] CTRL_ADR  = 3'b000;
	parameter [2:0] STAT_ADR  = 3'b001;
	parameter [2:0] HTIM_ADR  = 3'b010;
	parameter [2:0] VTIM_ADR  = 3'b011;
	parameter [2:0] HVLEN_ADR = 3'b100;
	parameter [2:0] VBARA_ADR = 3'b101;
	parameter [2:0] VBARB_ADR = 3'b110;
	parameter [2:0] CBAR_ADR  = 3'b111;


	reg [31:0] ctrl, stat, htim, vtim, hvlen;
	wire HINT, VINT, BSINT, LUINT, SINT;
	wire hie, vie, bsie;
	wire acc, acc32, reg_acc;

	//
	// Module body
	//

	assign acc     = CYC_I & STB_I;
	assign acc32   = (SEL_I == 4'b1111);
	assign reg_acc = acc & acc32  & WE_I;
	assign ACK_O   = acc &  acc32;
	assign ERR_O   = acc & !acc32;


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
				CBAR  <= #1 0;
			end
		else if (RST_I)
			begin
				htim  <= #1 0;
				vtim  <= #1 0;
				hvlen <= #1 0;
				VBARa <= #1 0;
				VBARb <= #1 0;
				CBAR  <= #1 0;
			end
		else if (reg_acc)
			case (ADR_I)	// synopsis full_case parallel_case
				HTIM_ADR  : htim  <= #1 DAT_I;
				VTIM_ADR  : vtim  <= #1 DAT_I;
				HVLEN_ADR : hvlen <= #1 DAT_I;
				VBARA_ADR : VBARa <= #1 DAT_I[31: 2];
				VBARB_ADR : VBARb <= #1 DAT_I[31: 2];
				CBAR_ADR  : CBAR  <= #1 DAT_I[31:11];
			endcase
	end


	// generate control register
	always@(posedge CLK_I or negedge nRESET)
		if (!nRESET)
			ctrl <= #1 0;
		else if (RST_I)
			ctrl <= #1 0;
		else if (reg_acc & (ADR_I == CTRL_ADR) )
			ctrl <= #1 DAT_I;
		else
			begin
				ctrl[5] <= #1 ctrl[5] & !bsint_in;
				ctrl[4] <= #1 ctrl[4] & !bsint_in;
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
				if (reg_acc & (ADR_I == STAT_ADR) )
					begin
						stat[6] <= #1 bsint_in | (stat[6] & !DAT_I[6]);
						stat[5] <= #1 hint_in  | (stat[5] & !DAT_I[5]);
						stat[4] <= #1 vint_in  | (stat[4] & !DAT_I[4]);
						stat[1] <= #1 luint_in | (stat[3] & !DAT_I[1]);
						stat[0] <= #1 sint_in  | (stat[0] & !DAT_I[0]);
					end
				else
					begin
						stat[6] <= #1 stat[6] | bsint_in;
						stat[5] <= #1 stat[5] | hint_in;
						stat[4] <= #1 stat[4] | vint_in;
						stat[1] <= #1 stat[1] | luint_in;
						stat[0] <= #1 stat[0] | sint_in;
					end
			end


	// decode control register
	assign bl   = ctrl[15];
	assign csl  = ctrl[14];
	assign vsl  = ctrl[13];
	assign hsl  = ctrl[12];
	assign pc   = ctrl[11];
	assign cd   = ctrl[10:9];
	assign vbl  = ctrl[8:7];
	assign cbsw = ctrl[5];
	assign vbsw = ctrl[4];
	assign bsie = ctrl[3];
	assign hie  = ctrl[2];
	assign vie  = ctrl[1];
	assign ven  = ctrl[0];

	// decode status register
	assign BSINT = stat[6];
	assign HINT  = stat[5];
	assign VINT  = stat[4];
	assign LUINT = stat[1];
	assign SINT  = stat[0];

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
	always@(ADR_I or ctrl or stat or htim or vtim or hvlen or VBARa or VBARb or CBAR or acmp)
	case (ADR_I) // synopsis full_case parallel_case
		CTRL_ADR  : DAT_O = ctrl;
		STAT_ADR  : DAT_O = stat;
		HTIM_ADR  : DAT_O = htim;
		VTIM_ADR  : DAT_O = vtim;
		HVLEN_ADR : DAT_O = hvlen;
		VBARA_ADR : DAT_O = {VBARa, 2'b0};
		VBARB_ADR : DAT_O = {VBARb, 2'b0};
		CBAR_ADR  : DAT_O = {CBAR, acmp, 10'b0};
	endcase

	// generate interrupt request signal
	assign INTA_O = (HINT & hie) | (VINT & vie) | (BSINT & bsie) | LUINT | SINT;
endmodule
