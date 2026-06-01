// Copyright (C) 2017, Andes Technology Corp. Confidential Proprietary

`include "atciic100_config.vh"
`include "atciic100_const.vh"

module atciic100_apbslv(
	  pclk,
	  presetn,
	  psel,
	  penable,
	  pwrite,
	  paddr,
	  pwdata,
	  prdata,
	  sda,
	  scl,
	  i2c_int,
	  st_gencall,
	  st_busbusy,
	  st_ack,
	  nx_rdwt,
	  nx_datacnt,
	  cmpl_trig,
	  byterecv_trig,
	  bytetrans_trig,
	  start_cond,
	  stop_cond,
	  arblose_trig,
	  addrhit_trig,
	  fifo_rd_data,
	  fifo_empty,
	  fifo_full,
	  fifo_half_full,
	  fifo_half_empty,
	  slv_hit,
	  addr,
	  int_en_byterecv,
	  int_st_cmpl,
	  iic_rst,
	  fifo_clr,
	  do_ack,
	  do_nack,
	  trans,
	  fifo_wr,
	  fifo_rd,
	  fifo_wr_data,
	  phase_S,
	  phase_adr,
	  phase_dat,
	  phase_P,
	  rdwt,
	  datacnt,
	  t_sp,
	  t_hddat,
	  t_sudat,
	  t_high,
	  t_low,
	  addressing,
	  master,
	  dma_en,
	  iic_en
);

parameter	CMD_IIC_RST		= 3'b101;
parameter	CMD_FIFO_CLR	= 3'b100;
parameter	CMD_DO_NACK		= 3'b011;
parameter	CMD_DO_ACK		= 3'b010;
parameter	CMD_TRANS		= 3'b001;

input			pclk;
input			presetn;
input			psel;
input			penable;
input			pwrite;
input	[5:2]	paddr;
input	[31:0]	pwdata;
output	[31:0]	prdata;

input			sda;
input			scl;
output			i2c_int;

input			st_gencall;
input			st_busbusy;
input			st_ack;
input			nx_rdwt;
//input	[8:0]	nx_datacnt;
input	[15:0]	nx_datacnt; //bruce
input			cmpl_trig;
input			byterecv_trig;
input			bytetrans_trig;
input			start_cond;
input			stop_cond;
input			arblose_trig;
input			addrhit_trig;
input	[7:0]	fifo_rd_data;
input			fifo_empty;
input			fifo_full;
input			fifo_half_full;
input			fifo_half_empty;
input			slv_hit;

output	[9:0]	addr;
output			int_en_byterecv;
output			int_st_cmpl;
output			iic_rst;
output			fifo_clr;
output			do_ack;
output			do_nack;
output			trans;
output			fifo_wr;
output			fifo_rd;
output	[7:0]	fifo_wr_data;
output			phase_S;
output			phase_adr;
output			phase_dat;
output			phase_P;
output			rdwt;
//output	[8:0]	datacnt;
output	[15:0]	datacnt; //bruce
output	[2:0]	t_sp;
output	[4:0]	t_hddat;
output	[4:0]	t_sudat;
output	[9:0]	t_high;
output	[9:0]	t_low;
output			addressing;
output			master;
output			dma_en;
output			iic_en;

reg				int_en_cmpl;
reg				int_en_byterecv;
reg				int_en_bytetrans;
reg				int_en_start;
reg				int_en_stop;
reg				int_en_arblose;
reg				int_en_addrhit;
reg				int_en_half;
reg				int_en_full;
reg				int_en_empty;

reg				int_st_cmpl;
reg				int_st_byterecv;
reg				int_st_bytetrans;
reg				int_st_start;
reg				int_st_stop;
reg				int_st_arblose;
reg				int_st_addrhit;

reg				phase_S;
reg				phase_adr;
reg				phase_dat;
reg				phase_P;
reg				rdwt;
//reg		[8:0]	datacnt;
reg		[15:0]	datacnt; //bruce

reg				trans;

reg		[2:0]	t_sp;
reg		[4:0]	t_hddat;
reg		[4:0]	t_sudat;
reg	    		t_sclratio;
reg		[8:0]	t_sclhi;
reg				dma_en;
reg				master;
reg				addressing;
reg				iic_en;

reg		[9:0]	addr;
reg		[7:0]	data;

wire			id_sel;
wire			cfg_sel;
wire			int_en_sel;
wire			ib_st_sel;
wire			addr_sel;
wire			data_sel;
wire			ctrl_sel;
wire			cmd_sel;
wire			setup_sel;

wire			pwrite_valid;

wire	[31:0]	idrev;
wire	[1:0]	cfg;
wire	[9:0]	int_en;
wire	[9:0]	int_st;
wire	[4:0]	bus_st;
//wire	[12:0]	ctrl;
wire	[23:0]	ctrl; //bruce 06/11
wire	[28:0]	setup;
wire	[9:0]	t_high;
wire	[9:0]	t_low;
wire 			fifo_half;

assign	idrev	= {`ATCIIC100_ID, `ATCIIC100_REV_MAJOR, `ATCIIC100_REV_MINOR};
assign	cfg		= `ATCIIC100_FIFO_CONFIG;
assign	int_en	= {int_en_cmpl, int_en_byterecv, int_en_bytetrans, int_en_start, int_en_stop, int_en_arblose,
				   int_en_addrhit, int_en_half, int_en_full, int_en_empty};
assign	int_st	= {int_st_cmpl, int_st_byterecv, int_st_bytetrans, int_st_start, int_st_stop, int_st_arblose,
				   int_st_addrhit, fifo_half, fifo_full, fifo_empty};
assign	bus_st	= {sda, scl, st_gencall, st_busbusy, st_ack};
//assign	ctrl	= {phase_S, phase_adr, phase_dat, phase_P, rdwt, datacnt[7:0]};
assign	ctrl	= {datacnt[15:0],3'b0,phase_S, phase_adr, phase_dat, phase_P, rdwt}; //bruce
assign	setup	= {t_sudat, t_sp, t_hddat, 2'b0, t_sclratio, t_sclhi, dma_en, master, addressing, iic_en};

assign	id_sel		= psel & ({paddr[5:2], 2'b0} == 6'h00);
assign	cfg_sel		= psel & ({paddr[5:2], 2'b0} == 6'h10);
assign	int_en_sel	= psel & ({paddr[5:2], 2'b0} == 6'h14);
assign	ib_st_sel	= psel & ({paddr[5:2], 2'b0} == 6'h18);
assign	addr_sel	= psel & ({paddr[5:2], 2'b0} == 6'h1C);
assign	data_sel	= psel & ({paddr[5:2], 2'b0} == 6'h20);
assign	ctrl_sel	= psel & ({paddr[5:2], 2'b0} == 6'h24);
assign	cmd_sel		= psel & ({paddr[5:2], 2'b0} == 6'h28);
assign	setup_sel	= psel & ({paddr[5:2], 2'b0} == 6'h2C);

assign pwrite_valid = penable & pwrite;

always @(posedge pclk or negedge presetn)
	if (!presetn) begin
		int_en_cmpl		<= 1'b0;
		int_en_byterecv <= 1'b0;
		int_en_bytetrans <= 1'b0;
		int_en_start	<= 1'b0;
		int_en_stop		<= 1'b0;
		int_en_arblose	<= 1'b0;
		int_en_addrhit	<= 1'b0;
		int_en_half		<= 1'b0;
		int_en_full		<= 1'b0;
		int_en_empty	<= 1'b0;
	end
	else if (iic_rst) begin
		int_en_cmpl		<= 1'b0;
		int_en_byterecv <= 1'b0;
		int_en_bytetrans <= 1'b0;
		int_en_start	<= 1'b0;
		int_en_stop		<= 1'b0;
		int_en_arblose	<= 1'b0;
		int_en_addrhit	<= 1'b0;
		int_en_half		<= 1'b0;
		int_en_full		<= 1'b0;
		int_en_empty	<= 1'b0;
	end
	else if (pwrite_valid & int_en_sel) begin
		int_en_cmpl		<= pwdata[9];
		int_en_byterecv <= pwdata[8];
		int_en_bytetrans <= pwdata[7];
		int_en_start	<= pwdata[6];
		int_en_stop		<= pwdata[5];
		int_en_arblose	<= pwdata[4];
		int_en_addrhit	<= pwdata[3];
		int_en_half		<= pwdata[2];
		int_en_full		<= pwdata[1];
		int_en_empty	<= pwdata[0];
	end


assign 	i2c_int =
	(fifo_full & int_en_full) |
	(fifo_empty & int_en_empty) |
	(fifo_half & int_en_half) |
	(int_st_addrhit & int_en_addrhit) |
	(int_st_arblose & int_en_arblose) |
	(int_st_stop & int_en_stop) |
	(int_st_start & int_en_start) |
	(int_st_bytetrans & int_en_bytetrans) |
	(int_st_byterecv & int_en_byterecv) |
	(int_st_cmpl & int_en_cmpl);

always @(posedge pclk or negedge presetn)
	if (!presetn)
		int_st_cmpl <= 1'b0;
	else if (iic_rst | (pwrite_valid & ib_st_sel & pwdata[9]))
		int_st_cmpl <= 1'b0;
	else if (cmpl_trig)
		int_st_cmpl <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		int_st_byterecv <= 1'b0;
	else if (iic_rst | (pwrite_valid & ib_st_sel & pwdata[8]))
		int_st_byterecv <= 1'b0;
	else if (byterecv_trig)
		int_st_byterecv <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		int_st_bytetrans <= 1'b0;
	else if (iic_rst | (pwrite_valid & ib_st_sel & pwdata[7]))
		int_st_bytetrans <= 1'b0;
	else if (bytetrans_trig)
		int_st_bytetrans <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		int_st_start <= 1'b0;
	else if (iic_rst | (pwrite_valid & ib_st_sel & pwdata[6]))
		int_st_start <= 1'b0;
	else if (start_cond)
		int_st_start <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		int_st_stop <= 1'b0;
	else if (iic_rst | slv_hit | (pwrite_valid & ib_st_sel & pwdata[5]))
		int_st_stop <= 1'b0;
	else if (stop_cond)
		int_st_stop <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		int_st_arblose <= 1'b0;
	else if (iic_rst | (pwrite_valid & ib_st_sel & pwdata[4]))
		int_st_arblose <= 1'b0;
	else if (arblose_trig)
		int_st_arblose <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		int_st_addrhit <= 1'b0;
	else if (iic_rst | (pwrite_valid & ib_st_sel & pwdata[3]))
		int_st_addrhit <= 1'b0;
	else if (addrhit_trig)
		int_st_addrhit <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		addr <= 10'b0;
	else if (pwrite_valid & addr_sel)
		addr <= pwdata[9:0];

assign	fifo_wr			= pwrite_valid & data_sel & !fifo_full;
assign	fifo_wr_data	= pwdata[7:0];
assign	fifo_rd			= ~pwrite & penable & data_sel & !fifo_empty;
assign 	fifo_half		= (master ^ rdwt) ? fifo_half_empty : fifo_half_full;

always @(posedge pclk or negedge presetn)
	if (!presetn) begin
		phase_S		<= 1'b1;
		phase_adr	<= 1'b1;
		phase_dat	<= 1'b1;
		phase_P		<= 1'b1;
	end
	else if (pwrite_valid & ctrl_sel) begin
		phase_S		<= pwdata[12];
		phase_adr	<= pwdata[11];
		phase_dat	<= pwdata[10];
		phase_P		<= pwdata[9];
	end

always @(posedge pclk or negedge presetn)
	if (!presetn)
		rdwt	<= 1'b0;
	else if (pwrite_valid & ctrl_sel)
		rdwt	<= pwdata[8];
	else
		rdwt	<= nx_rdwt;

//always @(posedge pclk or negedge presetn)
//	if (!presetn)
//		datacnt	<= 9'h0;
//	else if (pwrite_valid & ctrl_sel)
//		datacnt	<= {pwdata[7:0] == 8'h0, pwdata[7:0]};
//	else
//		datacnt	<= nx_datacnt;
		
//bruce
always @(posedge pclk or negedge presetn)
	if (!presetn)
		datacnt	<= 16'h0;
	else if (pwrite_valid & ctrl_sel)
		datacnt	<= {pwdata[31:16]};
	else
		datacnt	<= nx_datacnt;


assign fifo_clr	= (pwrite_valid && cmd_sel && (pwdata[2:0] == CMD_FIFO_CLR)) | iic_rst;
assign do_nack	= pwrite_valid && cmd_sel && (pwdata[2:0] == CMD_DO_NACK);
assign do_ack	= pwrite_valid && cmd_sel && (pwdata[2:0] == CMD_DO_ACK);
assign iic_rst	= pwrite_valid && cmd_sel && (pwdata[2:0] == CMD_IIC_RST);

always @(posedge pclk or negedge presetn)
	if (!presetn)
		trans <= 1'b0;
	else if (pwrite_valid && cmd_sel && (pwdata[2:0] == CMD_TRANS))
		trans <= 1'b1;
	else if (cmpl_trig || arblose_trig)
		trans <= 1'b0;

assign	t_high	= {1'b0, t_sclhi};
assign	t_low	= t_sclratio ? {t_sclhi, 1'b1} : {1'b0, t_sclhi};

always @(posedge pclk or negedge presetn)
	if (!presetn) begin
		t_sudat		<= 5'h05;
		t_sp		<= 3'h1;
		t_hddat		<= 5'h05;
		t_sclratio	<= 1'h1;
		t_sclhi		<= 9'h010;
		dma_en		<= 1'b0;
		master		<= 1'b0;
		addressing	<= 1'b0;
		iic_en		<= 1'b0;
	end
	else if (pwrite_valid & setup_sel) begin
		t_sudat		<= pwdata[28:24];
		t_sp		<= pwdata[23:21];
		t_hddat		<= pwdata[20:16];
		t_sclratio	<= pwdata[13];
		t_sclhi		<= pwdata[12:4];
		dma_en		<= pwdata[3];
		master		<= pwdata[2];
		addressing	<= pwdata[1];
		iic_en		<= pwdata[0];
	end


assign	prdata = {32{~pwrite}} & (
		{       {32{id_sel}}     & idrev} |
		{30'h0, { 2{cfg_sel}}    & cfg} |
		{22'h0, {10{int_en_sel}} & int_en} |
		{17'h0, {15{ib_st_sel}}  & {bus_st, int_st}} |
		{22'h0, {10{addr_sel}}   & addr} |
		{24'h0, { 8{data_sel & !fifo_empty}}   & fifo_rd_data} |
		//{19'h0, {13{ctrl_sel}}   & ctrl} |
		{{32{ctrl_sel}}   & {ctrl,8'b0} } | //bruce
		{31'h0, cmd_sel          & trans} |
		{3'h0, {29{setup_sel}}  & setup});

endmodule
