//
// File wb_master.v, WISHBONE MASTER interface (video-memory/clut memory)
// Project: VGA
// Author : Richard Herveille
// rev.: 0.1 August  2nd, 2001. Initial Verilog release
// rev.: 0.2 August 29th, 2001. Changed some sections, try to get core up to speed.
//

`include "timescale.v"

module vga_wb_master (CLK_I, RST_I, nRESET, CYC_O, STB_O, CAB_O, WE_O, ADR_O, SEL_O, ACK_I, ERR_I, DAT_I, SINT,
	ctrl_ven, ctrl_cd, ctrl_pc, ctrl_vbl, ctrl_vbsw, ctrl_cbsw, VBAa, VBAb, CBA, Thgate, Tvgate,
	stat_avmp, stat_acmp, bs_req, line_fifo_wreq, line_fifo_d, line_fifo_full);

	// inputs & outputs

	// wishbone signals
	input         CLK_I;    // master clock input
	input         RST_I;    // synchronous active high reset
	input         nRESET;   // asynchronous low reset
	output        CYC_O;    // cycle output
	reg CYC_O;
	output        STB_O;    // strobe ouput
	reg STB_O;
	output        CAB_O;    // consecutive address burst output
	reg CAB_O;
	output        WE_O;     // write enable output
	reg WE_O;
	output [31:2] ADR_O;    // address output
	output [ 3:0] SEL_O;    // byte select outputs (only 32bits accesses are supported)
	reg [3:0] SEL_O;
	input         ACK_I;    // wishbone cycle acknowledge 
	input         ERR_I;    // wishbone cycle error
	input [31:0]  DAT_I;    // wishbone data in

	output        SINT;     // non recoverable error, interrupt host

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
	input [31:11] CBA;      // CLUT base address

	input [15:0] Thgate;    // horizontal visible area (in pixels)
	input [15:0] Tvgate;    // vertical visible area (in horizontal lines)

	output stat_avmp;       // active video memory page
	output stat_acmp;       // active CLUT memory page
	output bs_req;          // bank-switch request: memory page switched (when enabled). bs_req is always generated

	// to/from line-fifo
	output        line_fifo_wreq;
	output [23:0] line_fifo_d;
	input         line_fifo_full;

	//
	// variable declarations
	//
	reg vmem_acc, clut_acc;                                  // video memory access // clut access
	wire clut_req, clut_ack;      // clut access request // clut access acknowledge
	wire [7:0] clut_offs;                                 // clut memory offset
	wire nvmem_req, vmem_ack;     // NOT video memory access request // video memory access acknowledge
	wire ImDoneStrb;              // image done (strobe signal)
	reg  dImDoneStrb;
	wire pixelbuf_rreq, pixelbuf_empty, pixelbuf_hfull;
	wire [31:0] pixelbuf_q;
	wire RGBbuf_wreq, RGBbuf_empty, RGBbuf_full, RGB_fifo_full;
//	reg  RGBbuf_rreq, fill_RGBfifo;
	reg  fill_RGBfifo;
	wire RGBbuf_rreq;
	wire [23:0] RGBbuf_d;

	//
	// module body
	//

	
	//
	// WISHBONE block
	//
	reg  [ 2:0] burst_cnt;                       // video memory burst access counter
	wire        ImDone;                          // Done reading image from video mem 
	reg         dImDone;                         // delayed ImDone
	reg         hImDone;
	wire        burst_done;                      // completed burst access to video mem
	reg         sel_VBA, sel_CBA;                // select video memory base address // select clut base address
	reg  [31:2] vmemA;                           // video memory address 
	wire [31:2] clutA;                           // clut address
	reg  [15:0] hgate_cnt, vgate_cnt;            // horizontal / vertical pixel counters
	wire        hdone, vdone;                    // horizontal count done / vertical count done

	// wishbone access controller, video memory access request has highest priority (try to keep fifo full)
	always@(posedge CLK_I)
		if (~ctrl_ven)
			begin
				vmem_acc <= #1 1'b0;
				clut_acc <= #1 1'b0;
			end
		else
			begin
				clut_acc <= #1 clut_req & ( (nvmem_req & !vmem_acc) | clut_acc);
				vmem_acc <= #1 (!nvmem_req | (vmem_acc & !(burst_done & vmem_ack) )) & !clut_acc;
			end

	assign vmem_ack = ACK_I & vmem_acc;
	assign clut_ack = ACK_I & clut_acc;

	assign SINT = (vmem_acc | clut_acc) & ERR_I; // Non recoverable error, interrupt host system

	// select active memory page
	always@(posedge CLK_I)
		if (~ctrl_ven)
			sel_VBA <= #1 1'b0;
		else if (ctrl_vbsw)
			sel_VBA <= #1 sel_VBA ^ ImDoneStrb;  // select next video memory bank when finished reading current bank (and bank switch enabled)

	assign stat_avmp = sel_VBA; // assign output

	// select active clut page
	always@(posedge CLK_I)
		if (~ctrl_ven)
			sel_CBA <= #1 1'b0;
		else if (ctrl_cbsw)
			sel_CBA <= #1 sel_CBA ^ ImDoneStrb;  // select next clut when finished reading current video bank

	assign stat_acmp = sel_CBA; // assign output

	// assign bank_switch_request (status register) output
	assign bs_req = ImDoneStrb & ctrl_ven; // bank switch request

	// generate burst counter
	wire [3:0] burst_cnt_val;
	assign burst_cnt_val = {1'b0, burst_cnt} -4'h1;
	assign burst_done = burst_cnt_val[3];

	always@(posedge CLK_I)
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
	wire [16:0] hgate_cnt_val;
	assign hgate_cnt_val = {1'b0, hgate_cnt} -17'h1;
	assign hdone = hgate_cnt_val[16];

	always@(posedge CLK_I)
		if (~ctrl_ven)
			hgate_cnt <= #1 Thgate;
		else if (RGBbuf_wreq)
			if (hdone)
				hgate_cnt <= #1 Thgate;
			else
				hgate_cnt <= #1 hgate_cnt_val[15:0];

	// vgate counter
	wire [16:0] vgate_cnt_val;
	assign vgate_cnt_val = {1'b0, vgate_cnt} -17'h1;
	assign vdone = vgate_cnt_val[16];

	always@(posedge CLK_I)
		if (~ctrl_ven)
			vgate_cnt <= #1 Tvgate;
		else if (hdone & RGBbuf_wreq)
			if (ImDone)
				vgate_cnt <= #1 Tvgate;
			else
				vgate_cnt <= #1 vgate_cnt_val[15:0];

	assign ImDone = hdone & vdone;
	assign ImDoneStrb = ImDone & !dImDone;

	always@(posedge CLK_I)
	begin
		if (~ctrl_ven)
			dImDone <= #1 1'b0;
		else
			dImDone <= #1 ImDone;

		dImDoneStrb <= #1 ImDoneStrb;
	end

	always@(posedge CLK_I)
		if (!ctrl_ven)
			hImDone <= #1 1'b0;
		else
			hImDone <= #1 (ImDone || hImDone) && vmem_acc && !(burst_done && vmem_ack);

	//
	// generate addresses
	//

	// select video memory base address
	always@(posedge CLK_I)
		if (dImDoneStrb | !ctrl_ven)
			if (!sel_VBA)
				vmemA <= #1 VBAa;
			else
				vmemA <= #1 VBAb;
		else if (vmem_ack)
			vmemA <= #1 vmemA +30'h1;

	// calculate CLUT address
	assign clutA = {CBA, sel_CBA, clut_offs};

	// generate wishbone signals
	assign ADR_O = vmem_acc ? vmemA : clutA;

	always@(posedge CLK_I or negedge nRESET)
		if (!nRESET)
			begin
				CYC_O <= #1 1'b0;
				STB_O <= #1 1'b0;
				SEL_O <= #1 4'b1111;
				CAB_O <= #1 1'b0;
				WE_O  <= #1 1'b0;
			end
		else
			if (RST_I)
				begin
					CYC_O <= #1 1'b0;
					STB_O <= #1 1'b0;
					SEL_O <= #1 4'b1111;
					CAB_O <= #1 1'b0;
					WE_O  <= #1 1'b0;
				end
			else
				begin
					CYC_O <= #1 (clut_acc & clut_req & !ACK_I) | (vmem_acc & !(burst_done & vmem_ack & nvmem_req) );
					STB_O <= #1 (clut_acc & clut_req & !ACK_I) | (vmem_acc & !(burst_done & vmem_ack & nvmem_req) );
					SEL_O <= #1 4'b1111; // only 32bit accesses are supported
					CAB_O <= #1 vmem_acc & !(burst_done & vmem_ack & nvmem_req);
					WE_O  <= #1 1'b0; // read only
				end

	// pixel buffer (temporary store data read from video memory)
	vga_fifo #(4, 32) pixel_buf (
		.clk(CLK_I),
		.aclr(1'b1),
		.sclr(!ctrl_ven || hImDone || ImDoneStrb),
		.d(DAT_I),
		.wreq(vmem_ack),
		.q(pixelbuf_q),
		.rreq(pixelbuf_rreq),
		.empty(pixelbuf_empty),
		.hfull(pixelbuf_hfull),
		.full()
	);

	assign nvmem_req = !(!pixelbuf_hfull && !(ImDoneStrb || hImDone) );

	always@(posedge CLK_I)
		if (!ctrl_ven)
			fill_RGBfifo <= #1 1'b0;
		else
			fill_RGBfifo <= #1 (RGBbuf_empty | fill_RGBfifo) & !RGBbuf_full;

	assign RGB_fifo_full = !(fill_RGBfifo & !RGBbuf_full);

	// hookup color processor
	vga_colproc color_proc (
		.clk(CLK_I),
		.srst(!ctrl_ven || (ImDoneStrb && !clut_acc) ),
		.pixel_buffer_di(pixelbuf_q),
		.wb_di(DAT_I),
		.ColorDepth(ctrl_cd),
		.PseudoColor(ctrl_pc),
		.pixel_buffer_empty(pixelbuf_empty),
		.pixel_buffer_rreq(pixelbuf_rreq),
		.RGB_fifo_full(RGB_fifo_full),
		.RGB_fifo_wreq(RGBbuf_wreq),
		.R(RGBbuf_d[23:16]),
		.G(RGBbuf_d[15:8]),
		.B(RGBbuf_d[7:0]),
		.clut_req(clut_req),
		.clut_offs(clut_offs),
		.clut_ack(clut_ack)
	);

	// hookup RGB buffer (temporary station between WISHBONE-clock-domain and pixel-clock-domain)
	vga_fifo #(3, 24) RGB_buf (
		.clk(CLK_I),
		.aclr(1'b1),
		.sclr(!ctrl_ven),
		.d(RGBbuf_d),
		.wreq(RGBbuf_wreq),
		.q(line_fifo_d),
		.rreq(RGBbuf_rreq),
		.empty(RGBbuf_empty),
		.hfull(RGBbuf_full),
		.full()
	);

	// generate signals for line-fifo
	/*
	always@(posedge CLK_I)
		if (!ctrl_ven)
			RGBbuf_rreq <= #1 1'b0;
		else
			RGBbuf_rreq <= #1 !line_fifo_full & !RGBbuf_empty & !RGBbuf_rreq;
	*/

	assign RGBbuf_rreq = !line_fifo_full && !RGBbuf_empty;
	assign line_fifo_wreq = RGBbuf_rreq;

endmodule










