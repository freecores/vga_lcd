//
// file: vga_vga_and_clut.v
// project: VGA/LCD controller + Color Lookup Table
// author: Richard Herveille
//
// rev. 1.0 August 10th, 2001. Initial Verilog release

`include "timescale.v"

module vga_vga_and_clut_top (wb_clk_i, wb_rst_i, rst_nreset_i, wb_inta_o, 
		wb_adr_i, wb_sdat_i, wb_sdat_o, wb_sel_i, wb_we_i, wb_vga_stb_i, wb_clut_stb_i, wb_cyc_i, wb_ack_o, wb_err_o,
		wb_adr_o, wb_mdat_i, wb_sel_o, wb_we_o, wb_stb_o, wb_cyc_o, wb_cab_o, wb_ack_i, wb_err_i,
		clk_pclk_i, vga_hsync_pad_o, vga_vsync_pad_o, vga_csync_pad_o, vga_blank_pad_o, vga_r_pad_o, vga_g_pad_o, vga_b_pad_o);

	//
	// parameters
	//
	parameter LINE_FIFO_AWIDTH = 7;

	//
	// inputs & outputs
	//
	
	input  wb_clk_i;     // wishbone clock input
	input  wb_rst_i;     // synchronous active high reset
	input  rst_nreset_i; // asynchronous active low reset
	output wb_inta_o;    // interrupt request output

	// slave signals
	input  [10:2] wb_adr_i;      // addressbus input (only 32bit databus accesses supported)
	input  [31:0] wb_sdat_i;     // Slave databus output
	output [31:0] wb_sdat_o;     // Slave databus input
	input  [ 3:0] wb_sel_i;      // byte select inputs
	input         wb_we_i;       // write enabel input
	input         wb_vga_stb_i;  // vga strobe/select input
	input         wb_clut_stb_i; // color-lookup-table strobe/select input
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
	output        wb_cab_o;      // continuous address burst output
	input         wb_ack_i;      // bus cycle acknowledge input
	input         wb_err_i;      // bus cycle error input

	// VGA signals
	input         clk_pclk_i;                            // pixel clock
	output        vga_hsync_pad_o;                       // horizontal sync
	output        vga_vsync_pad_o;                       // vertical sync
	output        vga_csync_pad_o;                       // composite sync
	output        vga_blank_pad_o;                       // blanking signal
	output [ 7:0] vga_r_pad_o, vga_g_pad_o, vga_b_pad_o; // RGB color signals

	//
	// variable declarations
	//
	reg [31:11] CBA; // color lookup table base address

	reg vga_clut_acc; // vga access to color lookup table
	
	wire        vga_ack_o, vga_ack_i, vga_err_o, vga_err_i;
	wire [31:2] vga_adr_o;
	wire [31:0] vga_dat_i, vga_dat_o; //vga master data input, vga slave data output
	wire [ 3:0] vga_sel_o;
	wire        vga_we_o, vga_stb_o, vga_cyc_o;

	wire vga_clut_stb;

	wire [23:0] mem0_dat_o, mem1_dat_o;
	wire        mem0_ack_o, mem0_err_o;
	wire        mem1_ack_o, mem1_err_o;

	//
	// module body
	//

	// capture VGA CBAR access
	always@(posedge wb_clk_i or negedge rst_nreset_i)
		if (!rst_nreset_i)
			CBA <= #1 21'h0;
		else if (wb_rst_i)
			CBA <= #1 21'h0;
		else if ( (wb_sel_i == 4'b1111) & wb_cyc_i & wb_vga_stb_i & wb_we_i & (wb_adr_i[4:2] == 3'b111) )
			CBA <= #1 wb_sdat_i[31:11];


	// generate vga_clut_acc. Because CYC_O and STB_O are generated one clock cycle after ADR_O,
	// vga_clut_acc may be synchronous.
	always@(posedge wb_clk_i)
		vga_clut_acc <= #1 (vga_adr_o[31:11] == CBA);

	//
	// hookup vga controller
	//
	vga_top #(LINE_FIFO_AWIDTH) u1 (
		// slave interface
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.rst_nreset_i(rst_nreset_i),
		.wb_inta_o(wb_inta_o),
		.wb_adr_i(wb_adr_i[4:2]),
		.wb_sdat_i(wb_sdat_i),
		.wb_sdat_o(vga_dat_o),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_stb_i(wb_vga_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_ack_o(vga_ack_o),
		.wb_err_o(vga_err_o),

		// master interface
		.wb_adr_o(vga_adr_o),
		.wb_mdat_i(vga_dat_i),
		.wb_sel_o(vga_sel_o),
		.wb_we_o(vga_we_o),
		.wb_stb_o(vga_stb_o),
		.wb_cyc_o(vga_cyc_o),
		.wb_cab_o(wb_cab_o),
		.wb_ack_i(vga_ack_i),
		.wb_err_i(vga_err_i),
		.clk_pclk_i(clk_pclk_i),
		.vga_hsync_pad_o(vga_hsync_pad_o),
		.vga_vsync_pad_o(vga_vsync_pad_o),
		.vga_csync_pad_o(vga_csync_pad_o),
		.vga_blank_pad_o(vga_blank_pad_o),
		.vga_r_pad_o(vga_r_pad_o),
		.vga_g_pad_o(vga_g_pad_o),
		.vga_b_pad_o(vga_b_pad_o)
	);

	//
	// hookup cycle shared memory
	//
	assign vga_clut_stb = vga_clut_acc & vga_stb_o;

	vga_csm_pb #(24, 9) u2 (
		// syscon interface
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.rst_nreset_i(rst_nreset_i),

		// first slave interface
		.wb_adr0_i(vga_adr_o[10:2]),
		.wb_dat0_i(24'b0),
		.wb_dat0_o(mem0_dat_o),
		.wb_sel0_i(vga_sel_o[2:0]),
		.wb_we0_i(vga_we_o),
		.wb_stb0_i(vga_clut_stb),
		.wb_cyc0_i(vga_cyc_o),
		.wb_ack0_o(mem0_ack_o),
		.wb_err0_o(mem0_err_o),
		
		// second slave interface
		.wb_adr1_i(wb_adr_i[10:2]),
		.wb_dat1_i(wb_sdat_i[23:0]),
		.wb_dat1_o(mem1_dat_o),
		.wb_sel1_i(wb_sel_i[2:0]),
		.wb_we1_i(wb_we_i),
		.wb_stb1_i(wb_clut_stb_i),
		.wb_cyc1_i(wb_cyc_i),
		.wb_ack1_o(mem1_ack_o),
		.wb_err1_o(mem1_err_o)
	);

	//
	// assign outputs
	//

	// wishbone master
	assign wb_cyc_o = !vga_clut_acc & vga_cyc_o;
	assign wb_stb_o = !vga_clut_acc & vga_stb_o;
	assign wb_adr_o = vga_adr_o;
	assign wb_sel_o = vga_sel_o;
	assign wb_we_o  = vga_we_o;

	assign vga_dat_i[31:24] = wb_mdat_i[31:24];
	assign vga_dat_i[23:0]  = vga_clut_acc ? mem0_dat_o : wb_mdat_i[23:0];
	assign vga_ack_i        = vga_clut_acc ? mem0_ack_o : wb_ack_i;
	assign vga_err_i        = vga_clut_acc ? mem0_err_o : wb_err_i;


	// wishbone slave
	assign wb_sdat_o = wb_clut_stb_i ? {2'h0, mem1_dat_o} : vga_dat_o;
	assign wb_ack_o  = wb_clut_stb_i ? mem1_ack_o : vga_ack_o;
	assign wb_err_o  = wb_clut_stb_i ? mem1_err_o : vga_err_o;

endmodule
