//
// Wishbone compliant cycle shared memory, priority based selection
// author: Richard Herveille
// 
// rev.: 1.0  August 13th, 2001. Initial Verilog release
//
// 

`include "timescale.v"

module vga_csm_pb (wb_clk_i, wb_rst_i, rst_nreset_i,
		wb_adr0_i, wb_dat0_i, wb_dat0_o, wb_sel0_i, wb_we0_i, wb_stb0_i, wb_cyc0_i, wb_ack0_o, wb_err0_o,
		wb_adr1_i, wb_dat1_i, wb_dat1_o, wb_sel1_i, wb_we1_i, wb_stb1_i, wb_cyc1_i, wb_ack1_o, wb_err1_o );
		
	//
	// parameters
	//
	parameter DWIDTH = 32; // databus width
	parameter AWIDTH = 8;  // address bus width

	//
	// inputs & outputs
	//
	
	// syscon signals
	input wb_clk_i;     // wishbone clock input
	input wb_rst_i;     // wishbone active high synchronous reset input
	input rst_nreset_i; // active low asynchronous input

	// wishbone slave0 connections
	input  [ AWIDTH   -1:0] wb_adr0_i; // address input
	input  [ DWIDTH   -1:0] wb_dat0_i; // data input
	output [ DWIDTH   -1:0] wb_dat0_o; // data output
	input  [(DWIDTH/8)-1:0] wb_sel0_i; // byte select input
	input                   wb_we0_i;  // write enable input
	input                   wb_stb0_i; // strobe/select input
	input                   wb_cyc0_i; // valid bus cycle input
	output                  wb_ack0_o; // acknowledge output
	output                  wb_err0_o; // error output

	// wishbone slave1 connections
	input  [ AWIDTH   -1:0] wb_adr1_i; // address input
	input  [ DWIDTH   -1:0] wb_dat1_i; // data input
	output [ DWIDTH   -1:0] wb_dat1_o; // data output
	input  [(DWIDTH/8)-1:0] wb_sel1_i; // byte select input
	input                   wb_we1_i;  // write enable input
	input                   wb_stb1_i; // strobe/select input
	input                   wb_cyc1_i; // valid bus cycle input
	output                  wb_ack1_o; // acknowledge output
	output                  wb_err1_o; // error output

	//
	// variable declarations
	//

	// multiplexor select signal
	wire wb0_acc, wb1_acc;
	reg  dwb0_acc, dwb1_acc;
	wire sel_wb0, sel_wb1;
	reg  ack0, ack1;
	
	// acknowledge generation
	wire wb0_ack, wb1_ack;

	// memory data output
	wire [DWIDTH -1:0] mem_q;


	//
	// module body
	//

	// generate multiplexor select signal
	assign wb0_acc = wb_cyc0_i && wb_stb0_i;
	assign wb1_acc = wb_cyc1_i && wb_stb1_i && !sel_wb0;

	always@(posedge wb_clk_i)
		begin
			dwb0_acc <= #1 wb0_acc & !wb0_ack;
			dwb1_acc <= #1 wb1_acc & !wb1_ack;
		end

	assign sel_wb0 = wb0_acc && !dwb0_acc;
	assign sel_wb1 = wb1_acc && !dwb1_acc;

	always@(posedge wb_clk_i or negedge rst_nreset_i)
			if (!rst_nreset_i)
				begin
					ack0 <= #1 0;
					ack1 <= #1 0;
				end
			else if (wb_rst_i)
				begin
					ack0 <= #1 0;
					ack1 <= #1 0;
				end
			else
				begin
					ack0 <= #1 sel_wb0 && !wb0_ack;
					ack1 <= #1 sel_wb1 && !wb1_ack;
				end

	wire [AWIDTH -1:0] mem_adr = sel_wb0 ? wb_adr0_i : wb_adr1_i;
	wire [DWIDTH -1:0] mem_d   = sel_wb0 ? wb_dat0_i : wb_dat1_i;
	wire               mem_we  = sel_wb0 ? wb_we0_i && wb_cyc0_i && wb_stb0_i : wb_we1_i && wb_cyc1_i && wb_stb1_i;

	// hookup generic synchronous single port memory
	generic_spram #(AWIDTH, DWIDTH) clut_mem(
		.clk(wb_clk_i),
		.rst(1'b0),       // no reset
		.ce(1'b1),        // always enable memory
		.we(mem_we),
		.oe(1'b1),        // always output data
		.addr(mem_adr),
		.di(mem_d),
		.do(mem_q)
	);

	// assign DAT_O outputs
	assign wb_dat0_o = mem_q;
	assign wb_dat1_o = mem_q;

	// generate ack signals
	assign wb0_ack = ( (sel_wb0 && wb_we0_i) || ack0 );
	assign wb1_ack = ( (sel_wb1 && wb_we1_i) || ack1 );

	// ACK outputs
	assign wb_ack0_o = wb0_ack;
	assign wb_ack1_o = wb1_ack;

	// ERR outputs
	assign wb_err0_o = !(&wb_sel0_i) && wb_cyc0_i && wb_stb0_i;
	assign wb_err1_o = !(&wb_sel1_i) && wb_cyc1_i && wb_stb1_i;

endmodule
