//
// file: vga_fpga_top.v
// project: VGA/LCD controller. This file combines the vga controller and the line fifo memory
// author: Richard Herveille
//
//
// This file combine the vga controller and the line fifo memory for FPGA implementations.
// The line fifo memory implementation assures Altera EAB and Xilinx BlockRAM instantiation.
//
// rev 1.0 August 13th, 2001. Initial Verilog release

`include "timescale.v"

module vga_fpga_top (wb_clk_i, wb_rst_i, rst_nreset_i, wb_inta_o, 
		wb_adr_i, wb_sdat_i, wb_sdat_o, wb_sel_i, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_err_o, 
		wb_adr_o,	wb_mdat_i, wb_cab_o,  wb_sel_o, wb_we_o, wb_stb_o, wb_cyc_o, wb_ack_i, wb_err_i,
		clk_pclk_i, vga_hsync_pad_o, vga_vsync_pad_o, vga_csync_pad_o, vga_blank_pad_o,
		vga_r_pad_o, vga_g_pad_o, vga_b_pad_o);

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
	output wb_inta_o;    // interrupt request output

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
	output        vga_vsync_pad_o;                       // vertical sync
	output        vga_csync_pad_o;                       // composite sync
	output        vga_blank_pad_o;
	output [ 7:0] vga_r_pad_o, vga_g_pad_o, vga_b_pad_o; // RGB color signals

	//
	// variable declarations
	//
	wire                        line_fifo_dpm_wreq;
	wire [23:0]                 line_fifo_dpm_d, line_fifo_dpm_q;
	wire [LINE_FIFO_AWIDTH-1:0] line_fifo_dpm_wptr, line_fifo_dpm_rptr;


	//
	// Module body
	//

	//
	// hookup vga controller
	//
	vga_top #(LINE_FIFO_AWIDTH) u1 (
		// slave interface
		.wb_clk_i (wb_clk_i),
		.wb_rst_i (wb_rst_i),
		.rst_nreset_i(rst_nreset_i),
		.wb_inta_o(wb_inta_o),
		.wb_adr_i (wb_adr_i),
		.wb_sdat_i(wb_sdat_i),
		.wb_sdat_o(wb_sdat_o),
		.wb_sel_i (wb_sel_i),
		.wb_we_i  (wb_we_i),
		.wb_stb_i (wb_stb_i),
		.wb_cyc_i (wb_cyc_i),
		.wb_ack_o (wb_ack_o),
		.wb_err_o (wb_err_o),

		// master interface
		.wb_adr_o (wb_adr_o),
		.wb_mdat_i(wb_mdat_i),
		.wb_sel_o (wb_sel_o),
		.wb_we_o  (wb_we_o),
		.wb_stb_o (wb_stb_o),
		.wb_cyc_o (wb_cyc_o),
		.wb_cab_o (wb_cab_o),
		.wb_ack_i (wb_ack_i),
		.wb_err_i (wb_err_i),

		// vga connections
		.clk_pclk_i(clk_pclk_i),
		.vga_hsync_pad_o(vga_hsync_pad_o),
		.vga_vsync_pad_o(vga_vsync_pad_o),
		.vga_csync_pad_o(vga_csync_pad_o),
		.vga_blank_pad_o(vga_blank_pad_o),
		.vga_r_pad_o(vga_r_pad_o),
		.vga_g_pad_o(vga_g_pad_o),
		.vga_b_pad_o(vga_b_pad_o),

		// line fifo interface
		.line_fifo_dpm_wreq(line_fifo_dpm_wreq),
		.line_fifo_dpm_d(line_fifo_dpm_d),
		.line_fifo_dpm_q(line_fifo_dpm_q),
		.line_fifo_dpm_wptr(line_fifo_dpm_wptr),
		.line_fifo_dpm_rptr(line_fifo_dpm_rptr)
	);

	// insert memory block. dual_ported_memory is a wrapper around a target specific dual ported RAM
	vga_dpm #(LINE_FIFO_AWIDTH, 24) line_fifo_mem (
		.wclk(wb_clk_i),
		.d(line_fifo_dpm_d),
		.waddr(line_fifo_dpm_wptr),
		.wreq(line_fifo_dpm_wreq),
		.rclk(clk_pclk_i),
		.q(line_fifo_dpm_q),
		.raddr(line_fifo_dpm_rptr)
	);

endmodule


