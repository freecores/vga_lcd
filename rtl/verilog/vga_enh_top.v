/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE rev.B2 compliant Enhanced VGA/LCD Core            ////
////  Top Level                                                  ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/vga_lcd ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001,2002 Richard Herveille                   ////
////                         richard@asics.ws                    ////
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
//  $Id: vga_enh_top.v,v 1.2 2002-03-04 11:01:59 rherveille Exp $
//
//  $Date: 2002-03-04 11:01:59 $
//  $Revision: 1.2 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.1  2002/02/07 05:42:10  rherveille
//               Fixed some bugs discovered by modified testbench
//               Removed / Changed some strange logic constructions
//               Started work on hardware cursor support (not finished yet)
//               Changed top-level name to vga_enh_top.v
//

`include "timescale.v"
`include "vga_defines.v"

module vga_enh_top (wb_clk_i, wb_rst_i, rst_i, wb_inta_o, 
		wbs_adr_i, wbs_dat_i, wbs_dat_o, wbs_sel_i, wbs_we_i, wbs_stb_i, wbs_cyc_i, wbs_ack_o, wbs_err_o, 
		wbm_adr_o,	wbm_dat_i, wbm_cab_o,  wbm_sel_o, wbm_we_o, wbm_stb_o, wbm_cyc_o, wbm_ack_i, wbm_err_i,
		clk_p_i, hsync_pad_o, vsync_pad_o, csync_pad_o, blank_pad_o, r_pad_o, g_pad_o, b_pad_o);

	//
	// parameters
	//
	parameter ARST_LVL = 1'b0;
	parameter LINE_FIFO_AWIDTH = 7;

	//
	// inputs & outputs
	//

	// syscon interface
	input  wb_clk_i;             // wishbone clock input
	input  wb_rst_i;             // synchronous active high reset
	input  rst_i;                // asynchronous reset
	output wb_inta_o;            // interrupt request output

	// slave signals
	input  [11:0] wbs_adr_i;     // addressbus input (only 32bit databus accesses supported)
	input  [31:0] wbs_dat_i;     // Slave databus output
	output [31:0] wbs_dat_o;     // Slave databus input
	input  [ 3:0] wbs_sel_i;     // byte select inputs
	input         wbs_we_i;      // write enabel input
	input         wbs_stb_i;     // strobe/select input
	input         wbs_cyc_i;     // valid bus cycle input
	output        wbs_ack_o;     // bus cycle acknowledge output
	output        wbs_err_o;     // bus cycle error output
		
	// master signals
	output [31:0] wbm_adr_o;     // addressbus output
	input  [31:0] wbm_dat_i;     // Master databus input
	output [ 3:0] wbm_sel_o;     // byte select outputs
	output        wbm_we_o;      // write enable output
	output        wbm_stb_o;     // strobe output
	output        wbm_cyc_o;     // valid bus cycle output
	output        wbm_cab_o;     // continuos address burst output
	input         wbm_ack_i;     // bus cycle acknowledge input
	input         wbm_err_i;     // bus cycle error input

	// VGA signals
	input         clk_p_i;                   // pixel clock
	output        hsync_pad_o;               // horizontal sync
	reg hsync_pad_o;
	output        vsync_pad_o;               // vertical sync
	reg vsync_pad_o;
	output        csync_pad_o;               // composite sync
	reg csync_pad_o;
	output        blank_pad_o;               // blanking signal
	reg blank_pad_o;
	output [ 7:0] r_pad_o, g_pad_o, b_pad_o; // RGB color signals

	//
	// variable declarations
	//

	// programable asynchronous reset
	wire arst = rst_i ^ ARST_LVL;

	// from wb_slave
	wire ctrl_bl, ctrl_csl, ctrl_vsl, ctrl_hsl, ctrl_pc, ctrl_cbsw, ctrl_vbsw, ctrl_ven;
	wire [ 1: 0] ctrl_cd, ctrl_vbl;
	wire [ 7: 0] Thsync, Thgdel, Tvsync, Tvgdel;
	wire [15: 0] Thgate, Thlen, Tvgate, Tvlen;
	wire [31: 2] VBARa, VBARb;
	wire [31: 0] cursor0_xy, cursor1_xy;
	wire         cursor0_en, cursor1_en;
	wire [31:11] cursor0_ba, cursor1_ba;
	wire         cursor0_ld, cursor1_ld;
	wire         cursor0_res, cursor1_res;
	wire [15: 0] cc0_dat_o, cc1_dat_o;

	// to wb_slave
	wire stat_avmp, stat_acmp, vmem_swint, clut_swint, hint, vint, sint;
	reg luint;
	wire [ 3: 0] cc0_adr_i, cc1_adr_i;

	// from pixel generator
	wire cgate; // composite gate signal
	wire ihsync, ivsync, icsync, iblank; // intermediate horizontal/vertical/composite sync, intermediate blank

	// line fifo connections
	wire line_fifo_dpm_wreq;
	wire [23:0] line_fifo_dpm_d, line_fifo_dpm_q;

	// clut connections
	wire        ext_clut_req, ext_clut_ack;
	wire [23:0] ext_clut_q;
	wire        cp_clut_req, cp_clut_ack;
	wire [ 8:0] cp_clut_adr;
	wire [23:0] cp_clut_q;

	//
	// Module body
	//

	// hookup wishbone slave
	vga_wb_slave u1 (
		// wishbone interface
		.clk_i(wb_clk_i),
		.rst_i(wb_rst_i),
		.arst_i(arst),
		.adr_i(wbs_adr_i[11:2]),
		.dat_i(wbs_dat_i),
		.dat_o(wbs_dat_o),
		.sel_i(wbs_sel_i),
		.we_i(wbs_we_i),
		.stb_i(wbs_stb_i),
		.cyc_i(wbs_cyc_i),
		.ack_o(wbs_ack_o),
		.err_o(wbs_err_o),
		.inta_o(wb_inta_o),

		// internal connections
		.bl(ctrl_bl),               // blank polarization level
		.csl(ctrl_csl),             // csync polarization level
		.vsl(ctrl_vsl),             // vsync polarization level
		.hsl(ctrl_hsl),             // hsync polarization level
		.pc(ctrl_pc),               // pseudo-color mode (only for 8bpp)
		.cd(ctrl_cd),               // color depth
		.vbl(ctrl_vbl),             // video memory burst length
		.cbsw(ctrl_cbsw),           // color lookup table bank switch enable
		.vbsw(ctrl_vbsw),           // video bank switch enable
		.ven(ctrl_ven),             // video enable
		.acmp(stat_acmp),           // active color lookup table page
		.avmp(stat_avmp),           // active video memory page
		.cursor0_res(cursor0_res),  // cursor0 resolution
		.cursor0_en(cursor0_en),    // cursor0 enable
		.cursor0_xy(cursor0_xy),    // cursor0 (x,y)
		.cursor0_ba(cursor0_ba),    // curso0 video memory base address
		.cursor0_ld(cursor0_ld),    // reload curso0 from video memory
 		.cc0_adr_i(cc0_adr_i),      // cursor0 color registers address
		.cc0_dat_o(cc0_dat_o),      // cursor0 color registers data
		.cursor1_res(cursor1_res),  // cursor1 resolution
		.cursor1_en(cursor1_en),    // cursor1 enable
		.cursor1_xy(cursor1_xy),    // cursor1 (x,y)
		.cursor1_ba(cursor1_ba),    // cursor1 video memory base address
		.cursor1_ld(cursor1_ld),    // reload cursor1 from video memory
 		.cc1_adr_i(cc1_adr_i),      // cursor1 color registers address
		.cc1_dat_o(cc1_dat_o),      // cursor1 color registers data
		.vbsint_in(vmem_swint),     // video memory bank switch interrupt
		.cbsint_in(clut_swint),     // clut memory bank switch interrupt
		.hint_in(hint),             // horizontal interrupt
		.vint_in(vint),             // vertical interrupt
		.luint_in(luint),           // line fifo underrun interrupt
		.sint_in(sint),             // system-error interrupt 
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
		.clut_acc(ext_clut_req),
		.clut_ack(ext_clut_ack),
		.clut_q(ext_clut_q)
	);

	// hookup wishbone master
	vga_wb_master u2 (
		// wishbone interface
		.clk_i(wb_clk_i),
		.rst_i(wb_rst_i),
		.nrst_i(arst),
		.cyc_o(wbm_cyc_o),
		.stb_o(wbm_stb_o),
		.cab_o(wbm_cab_o),
		.we_o(wbm_we_o),
		.adr_o(wbm_adr_o),
		.sel_o(wbm_sel_o),
		.ack_i(wbm_ack_i),
		.err_i(wbm_err_i),
		.dat_i(wbm_dat_i),

		// internal connections
		.sint(sint),
		.ctrl_ven(ctrl_ven),
		.ctrl_cd(ctrl_cd),
		.ctrl_pc(ctrl_pc),
		.ctrl_vbl(ctrl_vbl),
		.ctrl_cbsw(ctrl_cbsw),
		.ctrl_vbsw(ctrl_vbsw),
		.cursor0_en(cursor0_en),    // cursor0 enable
		.cursor0_res(cursor0_res),  // cursor0 resolution
		.cursor0_xy(cursor0_xy),    // cursor0 (x,y)
		.cursor0_ba(cursor0_ba),    // curso0 video memory base address
		.cursor0_ld(cursor0_ld),    // reload curso0 from video memory
 		.cc0_adr_o(cc0_adr_i),      // cursor0 color registers address
		.cc0_dat_i(cc0_dat_o),      // cursor0 color registers data
		.cursor1_en(cursor1_en),    // cursor1 enable
		.cursor1_res(cursor1_res),  // cursor1 resolution
		.cursor1_xy(cursor1_xy),    // cursor1 (x,y)
		.cursor1_ba(cursor1_ba),    // cursor1 video memory base address
		.cursor1_ld(cursor1_ld),    // reload cursor1 from video memory
 		.cc1_adr_o(cc1_adr_i),      // cursor1 color registers address
		.cc1_dat_i(cc1_dat_o),      // cursor1 color registers data
		.VBAa(VBARa),
		.VBAb(VBARb),
		.Thgate(Thgate),
		.Tvgate(Tvgate),
		.stat_acmp(stat_acmp),
		.stat_avmp(stat_avmp),
		.vmem_switch(vmem_swint),
		.clut_switch(clut_swint),

		// line fifo memory signals
		.line_fifo_wreq(line_fifo_dpm_wreq),
		.line_fifo_d(line_fifo_dpm_d),
		.line_fifo_full(line_fifo_full_wr),

		// clut memory signals
		.clut_req(cp_clut_req),
		.clut_ack(cp_clut_ack),
		.clut_adr(cp_clut_adr),
		.clut_q(cp_clut_q)
	);

	// hookup CLUT <cycle shared memory>
	vga_csm_pb #(24, 9) clut_mem(
		.clk_i(wb_clk_i),

		// color processor access
		.req0_i(cp_clut_req),
		.ack0_o(cp_clut_ack),
		.adr0_i(cp_clut_adr),
		.dat0_i(24'h0),
		.dat0_o(cp_clut_q),
		.we0_i(1'b0), // no writes

		// external access
		.req1_i(ext_clut_req),
		.ack1_o(ext_clut_ack),
		.adr1_i(wbs_adr_i[10:2]),
		.dat1_i(wbs_dat_i[23:0]),
		.dat1_o(ext_clut_q),
		.we1_i(wbs_we_i)
	);

	// hookup pixel and video timing generator
	vga_pgen u3 (
		.mclk(wb_clk_i),
		.pclk(clk_p_i),
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
	always@(posedge clk_p_i)
	begin
		hsync_pad_o <= #1 ihsync;
		vsync_pad_o <= #1 ivsync;
		csync_pad_o <= #1 icsync;
		blank_pad_o <= #1 iblank;
	end

	// hookup line-fifo
	vga_fifo_dc #(LINE_FIFO_AWIDTH, 24) u4 (
		.rclk(clk_p_i),
		.wclk(wb_clk_i),
		.aclr(ctrl_ven),
		.wreq(line_fifo_dpm_wreq),
		.d(line_fifo_dpm_d),
		.rreq(cgate),
		.q(line_fifo_dpm_q),
		.rd_empty(line_fifo_empty_rd),
		.rd_full(),
		.wr_empty(),
		.wr_full(line_fifo_full_wr)
	);

	assign r_pad_o = line_fifo_dpm_q[23:16];
	assign g_pad_o = line_fifo_dpm_q[15: 8];
	assign b_pad_o = line_fifo_dpm_q[ 7: 0];

	// generate interrupt signal when reading line-fifo while it is empty (line-fifo under-run interrupt)
	reg luint_pclk, sluint;

	always@(posedge clk_p_i)
		luint_pclk <= #1 cgate & line_fifo_empty_rd;

	always@(posedge wb_clk_i or negedge arst)
		if (!arst)
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





