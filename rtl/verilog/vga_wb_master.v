//
// File wb_master.v, WISHBONE MASTER interface (video-memory/clut memory)
// Project: VGA
// Author : Richard Herveille
// rev.: 0.1 August   2nd, 2001. Initial Verilog release
// rev.: 0.2 August  29th, 2001. Changed some sections, try to get core up to speed.
// rev.: 1.0 October  2nd, 2001. Revised core. Moved clut-memory into color-processor. Removed all references to clut-accesses from wishbone master.
//                               Changed video memory address generation.
//

`include "timescale.v"

module vga_wb_master (clk_i, rst_i, nrst_i, cyc_o, stb_o, cab_o, we_o, adr_o, sel_o, ack_i, err_i, dat_i, sint,
	ctrl_ven, ctrl_cd, ctrl_pc, ctrl_vbl, ctrl_vbsw, ctrl_cbsw, VBAa, VBAb, Thgate, Tvgate,
	stat_avmp, stat_acmp, vmem_switch, clut_switch, line_fifo_wreq, line_fifo_d, line_fifo_full,
	clut_req, clut_ack, clut_adr, clut_q);

	// inputs & outputs

	// wishbone signals
	input         clk_i;    // master clock input
	input         rst_i;    // synchronous active high reset
	input         nrst_i;   // asynchronous low reset
	output        cyc_o;    // cycle output
	reg cyc_o;
	output        stb_o;    // strobe ouput
	reg stb_o;
	output        cab_o;    // consecutive address burst output
	reg cab_o;
	output        we_o;     // write enable output
	reg we_o;
	output [31:0] adr_o;    // address output
	output [ 3:0] sel_o;    // byte select outputs (only 32bits accesses are supported)
	reg [3:0] sel_o;
	input         ack_i;    // wishbone cycle acknowledge 
	input         err_i;    // wishbone cycle error
	input [31:0]  dat_i;    // wishbone data in

	output        sint;     // non recoverable error, interrupt host

	// control register settings
	input       ctrl_ven;   // video enable bit
	input [1:0] ctrl_cd;    // color depth
	input       ctrl_pc;    // 8bpp pseudo color/bw
	input [1:0] ctrl_vbl;   // burst length
	input       ctrl_vbsw;  // enable video bank switching
	input       ctrl_cbsw;  // enable clut bank switching

	// video memory addresses
	input [31: 2] VBAa;     // video memory base address A
	input [31: 2] VBAb;     // video memory base address B

	input [15:0] Thgate;    // horizontal visible area (in pixels)
	input [15:0] Tvgate;    // vertical visible area (in horizontal lines)

	output stat_avmp;       // active video memory page
	output stat_acmp;       // active CLUT memory page
	reg stat_acmp;
	output vmem_switch;     // video memory bank-switch request: memory page switched (when enabled)
	output clut_switch;     // clut memory bank-switch request: clut page switched (when enabled)

	// to/from line-fifo
	output        line_fifo_wreq;
	output [23:0] line_fifo_d;
	input         line_fifo_full;

	// to/from color lookup-table
	output        clut_req;  // clut access request
	input         clut_ack;  // clut access acknowledge
	output [ 8:0] clut_adr;  // clut access address
	input  [23:0] clut_q;    // clut access data in

	//
	// variable declarations
	//

	reg vmem_acc;                 // video memory access
	wire nvmem_req, vmem_ack;     // NOT video memory access request // video memory access acknowledge
	reg  dvmem_ack;               // delayed video memory acknowledge

//	wire  ImDone;                 // Done reading image from video mem 
	reg  ImDone;                 // Done reading image from video mem 
	reg  dImDone;                 // delayed ImDone
	wire  ImDoneStrb;             // image done (strobe signal)
	reg  dImDoneStrb;             // delayed ImDoneStrb

	wire data_fifo_rreq, data_fifo_empty, data_fifo_hfull;
	wire [31:0] data_fifo_q;
	wire rgb_fifo_wreq, rgb_fifo_empty, rgb_fifo_full, rgb_ffull, rgb_fifo_rreq;
	reg  fill_rgb_fifo;
	wire [23:0] rgb_fifo_d;
	wire ImDoneFifoQ;
	reg  dImDoneFifoQ;
	reg  [2:0] ImDoneCpQ;
	reg        dImDoneCpQ;

	reg sclr; // synchronous clear

	wire [7:0] clut_offs; // color lookup table offset

	//
	// module body
	//

	// generate synchronous clear
	always@(posedge clk_i)
		sclr <= #1 ~ctrl_ven;
	
	//
	// WISHBONE block
	//
	reg  [ 2:0] burst_cnt;                       // video memory burst access counter
	wire        burst_done;                      // completed burst access to video mem
	reg         sel_VBA;                         // select video memory base address
	reg  [31:2] vmemA;                           // video memory address 

	// wishbone access controller, video memory access request has highest priority (try to keep fifo full)
	always@(posedge clk_i)
		if (sclr)
			vmem_acc <= #1 1'b0;
		else
			vmem_acc <= #1 (!nvmem_req | (vmem_acc & !(burst_done & vmem_ack) ) ) & !ImDone;

	assign vmem_ack = ack_i;
	assign sint = err_i; // Non recoverable error, interrupt host system

	// select active memory page
	assign vmem_switch = ImDoneStrb;

	always@(posedge clk_i)
		if (sclr)
			sel_VBA <= #1 1'b0;
		else if (ctrl_vbsw)
			sel_VBA <= #1 sel_VBA ^ vmem_switch;  // select next video memory bank when finished reading current bank (and bank switch enabled)

	assign stat_avmp = sel_VBA; // assign output

	// select active clut page

	// clut bank switch delay1; push ImDoneStrb into fifo. Account for data_fifo delay
	always@(posedge clk_i)
		dvmem_ack <= #1 vmem_ack;

	vga_fifo #(4, 1) clut_sw_fifo (
		.clk(clk_i),
		.aclr(1'b1),
		.sclr(sclr),
		.d(ImDone),
		.wreq(dvmem_ack),
		.q(ImDoneFifoQ),
		.rreq(data_fifo_rreq),
		.empty(),
		.hfull(),
		.full()
	);

	// clut bank switch delay2: Account for ColorProcessor DataBuffer delay
	always@(posedge clk_i)
		if (data_fifo_rreq)
			dImDoneFifoQ <= #1 ImDoneFifoQ;

	// clut bank switch delay3; Account for ColorProcessor internal delay
	always@(posedge clk_i)
		if (sclr)
			begin
				ImDoneCpQ  <= #1 4'h0;
				dImDoneCpQ <= #1 1'b0;
			end
		else
			begin
				dImDoneCpQ <= #1 ImDoneCpQ[2];
				if (rgb_fifo_wreq)
					ImDoneCpQ <= #1 { ImDoneCpQ[2:0], dImDoneFifoQ };
			end

	assign clut_switch = ImDoneCpQ[2] & !dImDoneCpQ;

	always@(posedge clk_i)
		if (sclr)
			stat_acmp <= #1 1'b0;
		else if (ctrl_cbsw)
			stat_acmp <= #1 stat_acmp ^ clut_switch;  // select next clut when finished reading clut for current video bank (and bank switch enabled)

	// generate clut-address
	assign clut_adr = {stat_acmp, clut_offs};

	// generate burst counter
	wire [3:0] burst_cnt_val;
	assign burst_cnt_val = {1'b0, burst_cnt} -4'h1;
	assign burst_done = burst_cnt_val[3];

	always@(posedge clk_i)
		if ( (burst_done & vmem_ack) | !vmem_acc)
			case (ctrl_vbl) // synopsis full_case parallel_case
				2'b00: burst_cnt <= #1 3'b000; // burst length 1
				2'b01: burst_cnt <= #1 3'b001; // burst length 2
				2'b10: burst_cnt <= #1 3'b011; // burst length 4
				2'b11: burst_cnt <= #1 3'b111; // burst length 8
			endcase
		else if(vmem_ack)
			burst_cnt <= #1 burst_cnt_val[2:0];

	//
	// generate image counters
	//

	// hgate counter
	reg  [15:0] hgate_cnt;
	reg  [16:0] hgate_cnt_val;
	reg  [1:0]  hgate_div_cnt;
	reg  [2:0]  hgate_div_val;

	wire hdone = hgate_cnt_val[16] & vmem_ack; // ????

	always@(hgate_cnt or hgate_div_cnt or ctrl_cd)
		begin
			hgate_div_val = {1'b0, hgate_div_cnt} - 3'h1;
			
			if (ctrl_cd != 2'b10)
				hgate_cnt_val = {1'b0, hgate_cnt} - 17'h1;
			else if ( hgate_div_val[2] )
				hgate_cnt_val = {1'b0, hgate_cnt} - 17'h1;
			else
				hgate_cnt_val = {1'b0, hgate_cnt};
		end

	always@(posedge clk_i)
		if (sclr)
				begin
					case(ctrl_cd) // synopsys full_case parallel_case
						2'b00: // 8bpp
							hgate_cnt <= #1 Thgate >> 2; // 4 pixels per cycle
						2'b01: //16bpp
							hgate_cnt <= #1 Thgate >> 1; // 2 pixels per cycle
						2'b10: //24bpp
							hgate_cnt <= #1 Thgate >> 2; // 4/3 pixels per cycle
						2'b11: //reserved
							;
					endcase

					hgate_div_cnt <= 2'b10;
				end
		else if (vmem_ack)
			if (hdone)
				begin
					case(ctrl_cd) // synopsys full_case parallel_case
						2'b00: // 8bpp
							hgate_cnt <= #1 Thgate >> 2; // 4 pixels per cycle
						2'b01: //16bpp
							hgate_cnt <= #1 Thgate >> 1; // 2 pixels per cycle
						2'b10: //24bpp
							hgate_cnt <= #1 Thgate >> 2; // 4/3 pixels per cycle
						2'b11: //reserved
							;
					endcase
					hgate_div_cnt <= #1 2'b10;
				end
			else //if (vmem_ack)
				begin
					hgate_cnt <= #1 hgate_cnt_val[15:0];

					if ( hgate_div_val[2] )
						hgate_div_cnt <= #1 2'b10;
					else
						hgate_div_cnt <= #1 hgate_div_val[1:0];
				end

	// vgate counter
	reg  [15:0] vgate_cnt;
	wire [16:0] vgate_cnt_val = {1'b0, vgate_cnt} -17'h1;
	wire vdone = vgate_cnt_val[16];

	always@(posedge clk_i)
		if (sclr)
			vgate_cnt <= #1 Tvgate;
		else if (ImDoneStrb)
			vgate_cnt <= #1 Tvgate;
		else if (hdone)
			vgate_cnt <= #1 vgate_cnt_val[15:0];

	always@(posedge clk_i)
		ImDone <= #1 hdone & vdone;

//	assign ImDone = hdone & vdone;
	assign ImDoneStrb = ImDone & !dImDone;

	always@(posedge clk_i)
		begin
			dImDone <= #1 ImDone;
			dImDoneStrb <= #1 ImDoneStrb;
		end

	//
	// generate addresses
	//

	// select video memory base address
	always@(posedge clk_i)
		if (dImDoneStrb | sclr)
			if (!sel_VBA)
				vmemA <= #1 VBAa;
			else
				vmemA <= #1 VBAb;
		else if (vmem_ack)
			vmemA <= #1 vmemA +30'h1;

	// generate wishbone signals
	assign adr_o = {vmemA, 2'b00};
	wire wb_cycle = vmem_acc & !(burst_done & vmem_ack & nvmem_req) & !ImDone;

	always@(posedge clk_i or negedge nrst_i)
		if (!nrst_i)
			begin
				cyc_o <= #1 1'b0;
				stb_o <= #1 1'b0;
				sel_o <= #1 4'b1111;
				cab_o <= #1 1'b0;
				we_o  <= #1 1'b0;
			end
		else
			if (rst_i)
				begin
					cyc_o <= #1 1'b0;
					stb_o <= #1 1'b0;
					sel_o <= #1 4'b1111;
					cab_o <= #1 1'b0;
					we_o  <= #1 1'b0;
				end
			else
				begin
					cyc_o <= #1 wb_cycle;
					stb_o <= #1 wb_cycle;
					sel_o <= #1 4'b1111;   // only 32bit accesses are supported
					cab_o <= #1 wb_cycle;
					we_o  <= #1 1'b0;      // read only
				end

	// pixel buffer (temporary store data read from video memory)
	vga_fifo #(4, 32) data_fifo (
		.clk(clk_i),
		.aclr(1'b1),
		.sclr(sclr),
		.d(dat_i),
		.wreq(vmem_ack),
		.q(data_fifo_q),
		.rreq(data_fifo_rreq),
		.empty(data_fifo_empty),
		.hfull(data_fifo_hfull),
		.full()
	);

	assign nvmem_req = data_fifo_hfull;

	always@(posedge clk_i)
		if (sclr)
			fill_rgb_fifo <= #1 1'b0;
		else
			fill_rgb_fifo <= #1 (rgb_fifo_empty | fill_rgb_fifo) & !rgb_fifo_full;

	assign rgb_ffull = !(fill_rgb_fifo & !rgb_fifo_full);

	// hookup color processor
	vga_colproc color_proc (
		.clk(clk_i),
		.srst(sclr),
		.pixel_buffer_di(data_fifo_q),
		.ColorDepth(ctrl_cd),
		.PseudoColor(ctrl_pc),
		.pixel_buffer_empty(data_fifo_empty),
		.pixel_buffer_rreq(data_fifo_rreq),
		.RGB_fifo_full(rgb_ffull),
		.RGB_fifo_wreq(rgb_fifo_wreq),
		.R(rgb_fifo_d[23:16]),
		.G(rgb_fifo_d[15:8]),
		.B(rgb_fifo_d[7:0]),
		.clut_req(clut_req),
		.clut_ack(clut_ack),
		.clut_offs(clut_offs),
		.clut_q(clut_q)
	);

	// hookup RGB buffer (temporary station between WISHBONE-clock-domain and pixel-clock-domain)
	vga_fifo #(3, 24) rgb_fifo (
		.clk(clk_i),
		.aclr(1'b1),
		.sclr(sclr),
		.d(rgb_fifo_d),
		.wreq(rgb_fifo_wreq),
		.q(line_fifo_d),
		.rreq(rgb_fifo_rreq),
		.empty(rgb_fifo_empty),
		.hfull(rgb_fifo_full),
		.full()
	);

	assign rgb_fifo_rreq = !line_fifo_full && !rgb_fifo_empty;
	assign line_fifo_wreq = rgb_fifo_rreq;

endmodule


