//
// file: vga.v
// project: VGA/LCD controller
// author: Richard Herveille
//
// rev 1.0 August  6th, 2001. Initial Verilog release

`include "timescale.v"

module vga_top (wb_clk_i, wb_rst_i, rst_nreset_i, wb_inta_o, 
		wb_adr_i, wb_sdat_i, wb_sdat_o, wb_sel_i, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_err_o, 
		wb_adr_o,	wb_mdat_i, wb_cab_o,  wb_sel_o, wb_we_o, wb_stb_o, wb_cyc_o, wb_ack_i, wb_err_i,
		clk_pclk_i, vga_hsync_pad_o, vga_vsync_pad_o, vga_csync_pad_o, vga_blank_pad_o,
		vga_r_pad_o, vga_g_pad_o, vga_b_pad_o,
		line_fifo_dpm_wreq, line_fifo_dpm_d, line_fifo_dpm_q, line_fifo_dpm_wptr, line_fifo_dpm_rptr);

	//
	// parameters
	//
	parameter LINE_FIFO_AWIDTH = 7;

	//
	// inputs & outputs
	//

	// syscon interface
	input wb_clk_i;     // wishbone clock input
	input wb_rst_i;     // synchronous active high reset
	input rst_nreset_i; // asynchronous active low reset
	output wb_inta_o;   // interrupt request output

	// slave signals
	input  [ 4:2] wb_adr_i;      // addressbus input (only 32bit databus accesses supported)
	input  [31:0] wb_sdat_i;     // Slave databus output
	output [31:0] wb_sdat_o;     // Slave databus input
	input  [ 3:0] wb_sel_i;      // byte select inputs
	input         wb_we_i;       // write enabel input
	input         wb_stb_i;      // strobe/select input
	input         wb_cyc_i;      // valid bus cycle input
	output        wb_ack_o;      // bus cycle acknowledge output
	output        wb_err_o;      // bus cycle error output
		
	// master signals
	output [31:2] wb_adr_o;      // addressbus output
	input  [31:0] wb_mdat_i;     // Master databus input
	output [ 3:0] wb_sel_o;      // byte select outputs
	output        wb_we_o;       // write enable output
	output        wb_stb_o;      // strobe output
	output        wb_cyc_o;      // valid bus cycle output
	output        wb_cab_o;      // continuos address burst output
	input         wb_ack_i;      // bus cycle acknowledge input
	input         wb_err_i;      // bus cycle error input

	// VGA signals
	input         clk_pclk_i;                            // pixel clock
	output        vga_hsync_pad_o;                       // horizontal sync
	reg vga_hsync_pad_o;
	output        vga_vsync_pad_o;                       // vertical sync
	reg vga_vsync_pad_o;
	output        vga_csync_pad_o;                       // composite sync
	reg vga_csync_pad_o;
	output        vga_blank_pad_o;                       // blanking signal
	reg vga_blank_pad_o;
	output [ 7:0] vga_r_pad_o, vga_g_pad_o, vga_b_pad_o; // RGB color signals

	// line fifo dual ported memory connections
	output	                      	line_fifo_dpm_wreq;
	output	[23:0]                	line_fifo_dpm_d;
	input 	[23:0]	                line_fifo_dpm_q;
	output	[LINE_FIFO_AWIDTH-1:0]	line_fifo_dpm_wptr, line_fifo_dpm_rptr;

	//
	// variable declarations
	//

	// from wb_slave
	wire ctrl_bl, ctrl_csl, ctrl_vsl, ctrl_hsl, ctrl_pc, ctrl_cbsw, ctrl_vbsw, ctrl_ven;
	wire [ 1: 0] ctrl_cd, ctrl_vbl;
	wire [ 7: 0] Thsync, Thgdel, Tvsync, Tvgdel;
	wire [15: 0] Thgate, Thlen, Tvgate, Tvlen;
	wire [31: 2] VBARa, VBARb;
	wire [31:11] CBAR;

	// to wb_slave
	wire stat_avmp, stat_acmp, bsint, hint, vint, sint;
	reg luint;

	// from pixel generator
	wire cgate; // composite gate signal
	wire ihsync, ivsync, icsync, iblank; // intermediate horizontal/vertical/composite sync, intermediate blank

	//
	// Module body
	//

	// hookup wishbone slave
	vga_wb_slave u1 (
		// wishbone interface
		.CLK_I(wb_clk_i),
		.RST_I(wb_rst_i),
		.nRESET(rst_nreset_i),
		.ADR_I(wb_adr_i),
		.DAT_I(wb_sdat_i),
		.DAT_O(wb_sdat_o),
		.SEL_I(wb_sel_i),
		.WE_I(wb_we_i),
		.STB_I(wb_stb_i),
		.CYC_I(wb_cyc_i),
		.ACK_O(wb_ack_o),
		.ERR_O(wb_err_o),
		.INTA_O(wb_inta_o),

		// internal connections
		.bl(ctrl_bl),
		.csl(ctrl_csl),
		.vsl(ctrl_vsl),
		.hsl(ctrl_hsl),
		.pc(ctrl_pc),
		.cd(ctrl_cd),
		.vbl(ctrl_vbl),
		.cbsw(ctrl_cbsw),
		.vbsw(ctrl_vbsw),
		.ven(ctrl_ven),
		.acmp(stat_acmp),
		.avmp(stat_avmp),
		.bsint_in(bsint),
		.hint_in(hint),
		.vint_in(vint),
		.luint_in(luint),
		.sint_in(sint),
		.Thsync(Thsync),
		.Thgdel(Thgdel),
		.Thgate(Thgate),
		.Thlen(Thlen),
		.Tvsync(Tvsync),
		.Tvgdel(Tvgdel),
		.Tvgate(Tvgate),
		.Tvlen(Tvlen),
		.VBARa(VBARa),
		.VBARb(VBARb),
		.CBAR(CBAR)
	);

	// hookup wishbone master
	vga_wb_master u2 (
		// wishbone interface
		.CLK_I(wb_clk_i),
		.RST_I(wb_rst_i),
		.nRESET(rst_nreset_i),
		.CYC_O(wb_cyc_o),
		.STB_O(wb_stb_o),
		.CAB_O(wb_cab_o),
		.WE_O(wb_we_o),
		.ADR_O(wb_adr_o),
		.SEL_O(wb_sel_o),
		.ACK_I(wb_ack_i),
		.ERR_I(wb_err_i),
		.DAT_I(wb_mdat_i),

		// internal connections
		.SINT(sint),
		.ctrl_ven(ctrl_ven),
		.ctrl_cd(ctrl_cd),
		.ctrl_pc(ctrl_pc),
		.ctrl_vbl(ctrl_vbl),
		.ctrl_cbsw(ctrl_cbsw),
		.ctrl_vbsw(ctrl_vbsw),
		.VBAa(VBARa),
		.VBAb(VBARb),
		.CBA(CBAR),
		.Thgate(Thgate),
		.Tvgate(Tvgate),
		.stat_acmp(stat_acmp),
		.stat_avmp(stat_avmp),
		.bs_req(bsint),

		// line fifo memory signals
		.line_fifo_wreq(line_fifo_dpm_wreq),
		.line_fifo_d(line_fifo_dpm_d),
		.line_fifo_full(line_fifo_full_wr)
	);


	// hookup pixel and video timing generator
	vga_pgen u3 (
		.mclk(wb_clk_i),
		.pclk(clk_pclk_i),
		.ctrl_ven(ctrl_ven),
		.ctrl_HSyncL(ctrl_hsl),
		.Thsync(Thsync),
		.Thgdel(Thgdel),
		.Thgate(Thgate),
		.Thlen(Thlen),
		.ctrl_VSyncL(ctrl_vsl),
		.Tvsync(Tvsync),
		.Tvgdel(Tvgdel),
		.Tvgate(Tvgate),
		.Tvlen(Tvlen),
		.ctrl_CSyncL(ctrl_csl),
		.ctrl_BlankL(ctrl_bl),
		.eoh(hint),
		.eov(vint),
		.gate(cgate),
		.Hsync(ihsync),
		.Vsync(ivsync),
		.Csync(icsync),
		.Blank(iblank)
	);


	// delay video control signals 1 clock cycle (dual clock fifo synchronizes output)
	always@(posedge clk_pclk_i)
	begin
		vga_hsync_pad_o <= #1 ihsync;
		vga_vsync_pad_o <= #1 ivsync;
		vga_csync_pad_o <= #1 icsync;
		vga_blank_pad_o <= #1 iblank;
	end

	// hookup line-fifo
	vga_fifo_dc #(LINE_FIFO_AWIDTH) u4 (
			.rclk(clk_pclk_i),
			.wclk(wb_clk_i),
			.aclr(ctrl_ven),
			.wreq(line_fifo_dpm_wreq),
			.rreq(cgate),
			.rd_empty(line_fifo_empty_rd),
			.rd_full(),
			.wr_empty(),
			.wr_full(line_fifo_full_wr),
			.rptr(line_fifo_dpm_rptr),
			.wptr(line_fifo_dpm_wptr)
			);

	assign vga_r_pad_o = line_fifo_dpm_q[23:16];
	assign vga_g_pad_o = line_fifo_dpm_q[15: 8];
	assign vga_b_pad_o = line_fifo_dpm_q[ 7: 0];

	// generate interrupt signal when reading line-fifo while it is empty (line-fifo under-run interrupt)
	reg luint_pclk, sluint;

	always@(posedge clk_pclk_i)
		luint_pclk <= #1 cgate & line_fifo_empty_rd;

	always@(posedge wb_clk_i or negedge rst_nreset_i)
		if (!rst_nreset_i)
			begin
				sluint <= #1 1'b0;
				luint  <= #1 1'b0;
			end
		else if (wb_rst_i)
			begin
				sluint <= #1 1'b0;
				luint  <= #1 1'b0;
			end
		else if (!ctrl_ven)
			begin
				sluint <= #1 1'b0;
				luint  <= #1 1'b0;
			end
		else
			begin
				sluint <= #1 luint_pclk;	// resample at wb_clk_i clock
				luint  <= #1 sluint;     // sample again, reduce metastability risk
			end

endmodule


