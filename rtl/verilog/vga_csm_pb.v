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
		wb_adr1_i, wb_dat1_i, wb_dat1_o, wb_sel1_i, wb_we1_i, wb_stb1_i, wb_cyc1_i, wb_ack1_o, wb_err1_o,
		mem_we, mem_wadr, mem_radr, mem_d, mem_q);
		
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


	// memory interface
	output mem_we;                // memory write enable output
	output [AWIDTH-1:0] mem_wadr; // memory write address output
	output [AWIDTH-1:0] mem_radr; // memory read address output
	reg [AWIDTH-1:0] mem_radr;
	output [DWIDTH-1:0] mem_d;    // memory write data output
	input  [DWIDTH-1:0] mem_q;    // memory read data input

	//
	// variable declarations
	//

	// multiplexor select signal
	wire       wb0_acc, wb1_acc;
	reg        dwb0_acc, dwb1_acc;
	wire       sel_wb0, sel_wb1;
	reg  [1:0] ack0_pipe, ack1_pipe;
	
	// acknowledge generation
	wire wb0_ack, wb1_ack;


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
					ack0_pipe <= #1 0;
					ack1_pipe <= #1 0;
				end
			else if (wb_rst_i)
				begin
					ack0_pipe <= #1 0;
					ack1_pipe <= #1 0;
				end
			else
				begin
					ack0_pipe[0] <= #1 sel_wb0      && !wb0_ack;
					ack0_pipe[1] <= #1 ack0_pipe[0] && !wb0_ack;

					ack1_pipe[0] <= #1 sel_wb1      && !wb1_ack;
					ack1_pipe[1] <= #1 ack1_pipe[0] && !wb1_ack;
				end

	assign mem_wadr = sel_wb0 ? wb_adr0_i : wb_adr1_i;
	assign mem_d    = sel_wb0 ? wb_dat0_i : wb_dat1_i;
	assign mem_we   = sel_wb0 ? wb_we0_i && wb_cyc0_i && wb_stb0_i : wb_we1_i && wb_cyc1_i && wb_stb1_i;


	// register memory read address
	always@(posedge wb_clk_i)
		mem_radr <= #1 mem_wadr;  // Altera FLEX RAMs require address to be registered with inclock for read operations

	// assign DAT_O outputs
	assign wb_dat0_o = mem_q;
	assign wb_dat1_o = mem_q;

	// generate ack signals
	assign wb0_ack = ( (sel_wb0 && wb_we0_i) || (ack0_pipe[1]) );
	assign wb1_ack = ( (sel_wb1 && wb_we1_i) || (ack1_pipe[1]) );

	// ACK outputs
	assign wb_ack0_o = wb0_ack;
	assign wb_ack1_o = wb1_ack;

	// ERR outputs
	assign wb_err0_o = !(&wb_sel0_i) && wb_cyc0_i && wb_stb0_i;
	assign wb_err1_o = !(&wb_sel1_i) && wb_cyc1_i && wb_stb1_i;

endmodule

