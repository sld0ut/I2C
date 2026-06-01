// Copyright (C) 2017, Andes Technology Corp. Confidential Proprietary

`include "atciic100_config.vh"
`include "atciic100_const.vh"

module atciic100_ahbslv(
    input  wire          CLK_LP, 
    input  wire          FCLK, 
    input  wire          SLEEPING, 
  // AHB Master registers
    output reg [9:0]	 x_delay,
    output reg [2:0]	 x_burst,
    output reg [2:0]	 x_size,
    output reg [1:0]	 x_rendian,
    output reg [1:0]	 x_wendian,
    output reg [31:0]    x_prefix_addr,
    output reg [31:0]    x_flash_enter_addr,
    output reg [31:0]    x_flash_exit_addr,
    input  wire [5:0]    i_state,           // read only
	input  wire          i_ahbm_prefix_match,  // read only
	input  wire          i_prefix_period,   // read only
	input  wire          i_addr_fix_on,     // read only
	output reg           x_addr_fix_en,     
    output reg          [`ATCIIC100_INDEX_WIDTH-1:0] x_i2c_entries,
	input  wire          i_im_fifo_clr,
	input  wire          i_i2c_master_idle,

  // AHB Slave
	input  wire          SE,
	input  wire          HCLK_CG_EN,
	input  wire          HRESETn,
	input  wire          HRESETN_HREADY,
	input  wire          HCLK,
	input  wire   [31:0] HADDR,
	input  wire   [ 2:0] HSIZE,
	input  wire   [ 1:0] HTRANS,
	input  wire   [31:0] HWDATA,
	input  wire          HWRITE,
	input  wire          HSEL,
	input  wire          HREADY,
	output wire   [31:0] HRDATA,
	output wire          HREADYOUT,
	output wire   [ 1:0] HRESP,

	input wire			 sda,
	input wire			 scl,
	output wire			 i2c_int,

  // Simple I2C
	input wire           si2c_intr_wakeup_i2c,          // read only. scl domain
	input wire           hclk_si2c_intr_wakeup_i2c,     // read only. hclk domain 
	input wire	         hclk_si2c_aopd_max,            // read only. hclk domain
	input wire	[7:0]	 hclk_si2c_status,              // read only. hclk domain
	input wire           si2c_update_ack,
	output reg			 reg_si2c_update,
	output reg			 reg_si2c_aopd,
	output reg			 reg_si2c_en,
	output reg			 reg_si2c_adr,
	output reg [06:0]	 reg_si2c_id,
	output reg			 reg_si2c_wku_en,
	output reg [15:0]	 reg_si2c_wku_adr,
	output reg [07:0]	 reg_si2c_wku_cmd,

	input wire			 st_gencall,
	input wire			 st_busbusy,
	input wire			 st_ack,
	input wire			 rdwt,
	input wire			 rdwt_changed,
	input wire	[15:0]	 datacnt, 
	input wire			 cmpl_trig,
	input wire			 byterecv_trig,
	input wire			 bytetrans_trig,
	input wire			 start_cond,
	input wire			 stop_cond,
	input wire			 arblose_trig,
	input wire			 addrhit_trig,
	input wire	[7:0]	 fifo_rd_data,
	input wire			 fifo_empty,
	input wire			 fifo_full,
	input wire			 fifo_half_full,
	input wire			 fifo_half_empty,
	input wire			 slv_hit,

	output reg	[9:0]	 addr,
	output reg			 int_en_byterecv,
	output reg			 trans,
	output wire			 fifo_clr,
	output wire			 iic_rst,
	output wire			 do_ack,
	output wire			 do_nack,
	output wire			 fifo_wr,
	output wire			 fifo_rd,
	output wire	[7:0]	 fifo_wr_data,
	output reg			 phase_S,
	output reg			 phase_adr,
	output reg			 phase_dat,
	output reg			 phase_P,
	output reg			 nx_rdwt,
	output reg	[15:0]	 nx_datacnt, 
	output reg	[2:0]	 t_sp,
	output reg	[4:0]	 t_hddat,
	output reg	[4:0]	 t_sudat,
	output wire	[9:0]	 t_high,
	output wire	[9:0]	 t_low,
	output reg			 addressing,
	output reg			 master,
	output reg			 dma_en,
	output reg			 iic_en,
    output wire			 int_st_wakeup_clr,
    output reg			 int_st_start,
    output reg			 int_st_addrhit,
	output reg			 int_st_cmpl,
	output reg			 int_st_stop,
    input wire		     idle_state
);



//`include "io.inc"

//----------------------------------------------------------------------------
// Registers Map
//----------------------------------------------------------------------------
parameter	C_ADDR_ID		        = 5'h00;		//6'h00;
parameter	C_ADDR_CFG		        = 5'h04;		//6'h10;
parameter	C_ADDR_INT_EN	        = 5'h05;		//6'h14;
parameter	C_ADDR_IB_ST	        = 5'h06;		//6'h18;
parameter	C_ADDR_ADDR		        = 5'h07;		//6'h1C;
parameter	C_ADDR_DATA		        = 5'h08;		//6'h20;
parameter	C_ADDR_CTRL		        = 5'h09;		//6'h24;
parameter	C_ADDR_CMD		        = 5'h0A;		//6'h28;
parameter	C_ADDR_SETUP	        = 5'h0B;		//6'h2C;
parameter	C_ADDR_SI2C_CFG	        = 5'h0C;		//6'h30;
parameter	C_ADDR_SI2C_WKU	        = 5'h0D;		//6'h34;
parameter	C_ADDR_AHB_M0           = 5'h0E;		//6'h38;
parameter	C_ADDR_AHB_M1	        = 5'h0F;		//6'h3C;
parameter	C_ADDR_AHB_M_PREFIX     = 5'h10;		//6'h40;
parameter	C_ADDR_FLASH_ENTER      = 5'h11;		//6'h44;
parameter	C_ADDR_FLASH_EXIT       = 5'h12;		//6'h48;
parameter	C_ADDR_AON_UP	        = 5'h13;		//6'h4C;

parameter	CMD_NO_ACTION	        = 3'b000;
parameter	CMD_TRANS		        = 3'b001;
parameter	CMD_DO_ACK		        = 3'b010;
parameter	CMD_DO_NACK		        = 3'b011;
parameter	CMD_FIFO_CLR	        = 3'b100;
parameter	CMD_IIC_RST		        = 3'b101;

//----------------------------------------------------------------------------
// Internal signals
//----------------------------------------------------------------------------
reg   [31:0] haddr_reg;
reg          hvalid_reg;
reg          hwrite_reg;
reg    [1:0] hsize_reg;

reg   [31:0] hrdata_reg;
reg   [31:0] hrdata_mem;
reg          mem_out_en;

wire         byte_00_we;
wire         byte_01_we;
wire         byte_10_we;
wire         byte_11_we;

reg			ihready2;

reg				int_en_wakeup;
reg				int_en_cmpl;
reg				int_en_bytetrans;
reg				int_en_start;
reg				int_en_stop;
reg				int_en_arblose;
reg				int_en_addrhit;
reg				int_en_half;
reg				int_en_full;
reg				int_en_empty;

reg				int_st_wakeup;
//reg				int_st_addrhit;
reg				int_st_arblose;
//reg				int_st_start;
//reg				int_st_stop;
reg				int_st_bytetrans;
reg				int_st_byterecv;

reg				int_st_addrhit_init;
reg				int_st_arblose_init;
reg				int_st_stop_init;
reg				int_st_start_init;
reg				int_st_bytetrans_init;
reg				int_st_byterecv_init;
reg				int_st_cmpl_init;
reg				int_st_wakeup_init;

wire			int_st_addrhit_r;
wire			int_st_arblose_r;
wire			int_st_stop_r;
wire			int_st_start_r;
wire			int_st_bytetrans_r;
wire			int_st_byterecv_r;
wire			int_st_cmpl_r;

reg				rdwt_init;
wire			rdwt_r, rdwt_f;
reg				trans_init;
wire			trans_r;

reg	    		t_sclratio;
reg [8:0]		t_sclhi;

reg		        x_firmware_on;      // 1 at firmware on

wire	[31:0]	idrev;
wire	[2:0]	cfg;
wire	[10:0]	int_en;
wire	[10:0]	int_st;
wire	[4:0]	bus_st;
wire	[31:0]	ctrl; //bruce 06/11
wire	[28:0]	setup;
wire 			fifo_half;

assign	idrev	= {`ATCIIC100_ID, `ATCIIC100_REV_MAJOR, `ATCIIC100_REV_MINOR};
assign	cfg		= `ATCIIC100_FIFO_CONFIG;
assign	int_en	= {int_en_wakeup, int_en_cmpl, int_en_byterecv, int_en_bytetrans, int_en_start, int_en_stop, int_en_arblose,
				   int_en_addrhit, int_en_half, int_en_full, int_en_empty};
assign	int_st	= {int_st_wakeup, int_st_cmpl, int_st_byterecv, int_st_bytetrans, int_st_start, int_st_stop, int_st_arblose,
				   int_st_addrhit, fifo_half, fifo_full, fifo_empty};
assign	bus_st	= {sda, scl, st_gencall, st_busbusy, st_ack};
assign	ctrl	= {datacnt[15:0],3'b0,phase_S, phase_adr, phase_dat, phase_P, rdwt, 8'h0};
assign	setup	= {t_sudat, t_sp, t_hddat, 2'b0, 1'b0, 9'h0, dma_en, master, addressing, iic_en};

wire w_update_reg = (i_ahbm_prefix_match)? i_i2c_master_idle & idle_state : idle_state ; 

//----------------------------------------------------------------------------
// AHB Clock Gating
//----------------------------------------------------------------------------
//wire 	HCLK_CG;
//wire	HCLK_MUX;
//
//reg		hsel_d;
//always @(posedge HCLK or negedge HRESETn)
//  if(!HRESETn) begin
//  	hsel_d <= #1 1'b0;
//  end else begin
//  	hsel_d <= #1 HSEL;
//  end
//
//CLK_GATE I_HCLK_GATE (.TE(SE), .EN((HSEL|hsel_d)), .ICLK(HCLK), .OCLK(HCLK_CG)); 
//CLK_MUX I_HCLK_MUX (.A(HCLK), .B(HCLK_CG), .S(HCLK_CG_EN), .Y(HCLK_MUX));

wire	HCLK_MUX;
hclk_cg u_HCLK_CG (
/*input wire	*/	.SE				(SE			),
/*input wire	*/	.HCLK			(HCLK		),
/*input wire	*/	.HRESET_N		(HRESETn	),
/*input wire	*/	.HSEL			(HSEL	    ),
/*input wire	*/	.HCLK_CG_EN		(HCLK_CG_EN	),
/*output wire	*/	.HCLK_CG		(HCLK_MUX	)
);

//----------------------------------------------------------------------------
// i2c_simple wakeup on CLK_LP domain 
//----------------------------------------------------------------------------

wire int_st_wakeup_set;
reg	r_int_st_wakeup_init;
reg r0_intr_wakeup_set;     // SCL to CLK_LP domain
reg r1_intr_wakeup_set;     // SCL to CLK_LP domain
reg r2_intr_wakeup_set;     // SCL to CLK_LP domain
reg r0_int_st_wakeup_clr;   // HCLK to CLK_LP domain
reg r1_int_st_wakeup_clr;   // HCLK to CLK_LP domain
reg r2_int_st_wakeup_clr;   // HCLK to CLK_LP domain
always @(posedge CLK_LP or negedge HRESETn) begin 
    if(!HRESETn) begin
    	r0_intr_wakeup_set <= #1 1'b0;
    	r1_intr_wakeup_set <= #1 1'b0;
    	r2_intr_wakeup_set <= #1 1'b0;
    	r0_int_st_wakeup_clr <= #1 1'b0;
    	r1_int_st_wakeup_clr <= #1 1'b0;
    	r2_int_st_wakeup_clr <= #1 1'b0;
		int_st_wakeup <= #1 'd0;
    end 
    else begin
    	r0_intr_wakeup_set <= #1 si2c_intr_wakeup_i2c;
    	r1_intr_wakeup_set <= #1 r0_intr_wakeup_set;
    	r2_intr_wakeup_set <= #1 r1_intr_wakeup_set;
    	r0_int_st_wakeup_clr <= #1 r_int_st_wakeup_init;
    	r1_int_st_wakeup_clr <= #1 r0_int_st_wakeup_clr;
    	r2_int_st_wakeup_clr <= #1 r1_int_st_wakeup_clr;

		if (iic_rst || int_st_wakeup_clr) begin
			int_st_wakeup		<= 1'b0;
		end if (int_st_wakeup_set) begin
			int_st_wakeup		<= 1'b1;
		end
    end
end  
assign int_st_wakeup_set = ~r2_intr_wakeup_set & r1_intr_wakeup_set ;
assign int_st_wakeup_clr = ~r2_int_st_wakeup_clr & r1_int_st_wakeup_clr ;

reg [1:0] int_st_wakeup_clr_sync;

always @(posedge FCLK or negedge HRESETn)
  if(!HRESETn) begin
  	int_st_wakeup_clr_sync <= #1 2'b0;
  end 
  else begin
  	int_st_wakeup_clr_sync <= #1 {int_st_wakeup_clr_sync[0], int_st_wakeup_clr};
  end


//always @(posedge HCLK or negedge HRESETn)
always @(posedge FCLK or negedge HRESETn)
  if(!HRESETn) begin
  	r_int_st_wakeup_init <= #1 1'b0;
  end 
//else if(int_st_wakeup_clr) begin
  else if(int_st_wakeup_clr_sync[1]) begin
  	r_int_st_wakeup_init <= #1 1'b0;
  end  
  else if(int_st_wakeup_init) begin
  	r_int_st_wakeup_init <= #1 1'b1;
  end

//----------------------------------------------------------------------------
// AHB Slave
//----------------------------------------------------------------------------
assign byte_00_we = (haddr_reg[1:0]==2'b00);
assign byte_01_we = (((hsize_reg[1:0]==2'b00)&&(haddr_reg[1:0]==2'b01)) ||
					((hsize_reg[1:0]==2'b01)&&(haddr_reg[1:0]==2'b00)) ||
					((hsize_reg[1]==1'b1)&&(haddr_reg[1:0]==2'b00)));
assign byte_10_we = (((hsize_reg[1:0]==2'b00)&&(haddr_reg[1:0]==2'b10)) ||
					((hsize_reg[1:0]==2'b01)&&(haddr_reg[1:0]==2'b10)) ||
					((hsize_reg[1]==1'b1)&&(haddr_reg[1:0]==2'b00)));
assign byte_11_we = (((hsize_reg[1:0]==2'b00)&&(haddr_reg[1:0]==2'b11)) ||
					((hsize_reg[1:0]==2'b01)&&(haddr_reg[1:0]==2'b10)) ||
					((hsize_reg[1]==1'b1)&&(haddr_reg[1:0]==2'b00)));

always @(negedge HRESETn or posedge HCLK_MUX)
begin
	if (~HRESETn) begin
		haddr_reg <= #1 20'b0;
		hvalid_reg <= #1 1'b0;
		hwrite_reg <= #1 1'b0;
		hsize_reg <= #1 2'b10; //word
	end
	else begin
		if (HREADY & HTRANS[1] & HSEL)
		haddr_reg <= #1 HADDR[19:0];
		hvalid_reg <= #1 HREADY & HTRANS[1] & HSEL;
		hwrite_reg <= #1 HWRITE;
		hsize_reg <= #1 HSIZE[1:0];
	end
end

//----------------------------------------------------------------------------
// Registers in HCLK domain
//----------------------------------------------------------------------------
wire		sync_si2c_update_ack_r;
wire		sync_si2c_update_ack_f;
reg [2:0]	sync_si2c_update_ack;

always @(negedge HRESETN_HREADY or posedge HCLK)
	if (~HRESETN_HREADY) begin
		sync_si2c_update_ack <= 'd0;
	end else begin
		sync_si2c_update_ack <= {sync_si2c_update_ack[1:0],si2c_update_ack};
	end

always @(negedge HRESETN_HREADY or posedge HCLK)
	if (~HRESETN_HREADY) begin
		reg_si2c_update		    <= 'd0;
		ihready2 <= 1'b1;
	end else begin
		if (sync_si2c_update_ack_r) begin
			reg_si2c_update	<= 1'b0;
		end
		if (sync_si2c_update_ack_f) begin
			ihready2 <= 1'b1;
		end
		//address phase
		if (HREADY & HTRANS[1] & HSEL & HWRITE & (HADDR[6:2]==C_ADDR_AON_UP)) begin
			ihready2 <= 0;
		end
		//data phase
		if (hvalid_reg & hwrite_reg) begin
			case (haddr_reg[6:2])
				C_ADDR_AON_UP : begin
					if (byte_00_we) begin
						reg_si2c_update	<= HWDATA[0];
						if(HWDATA[0]==1'b0) begin
							ihready2 <= 1;
						end
					end
				end
				default : begin
				end
			endcase
		end
	end
assign sync_si2c_update_ack_r = ((sync_si2c_update_ack[1]==1'b1) && (sync_si2c_update_ack[2]==1'b0)) ? 1'b1 : 1'b0;
assign sync_si2c_update_ack_f = ((sync_si2c_update_ack[1]==1'b0) && (sync_si2c_update_ack[2]==1'b1)) ? 1'b1 : 1'b0;

reg			ihready3;
reg 		ihready4;

always @(negedge HRESETn or posedge HCLK)
	if (~HRESETn) begin
		ihready4	<= 1;
	end else begin
		if(rdwt_changed) begin
			ihready4 <= 1;
		end
		if (hvalid_reg & hwrite_reg & (haddr_reg[6:2]==C_ADDR_CTRL) & byte_01_we) begin
			if(master&&(rdwt_init!=HWDATA[8])) begin
				ihready4 <= 0;
			end
		end
	end

always @(negedge HRESETn or posedge HCLK_MUX)
	if (~HRESETn) begin
		int_en_wakeup		    <= 'd0;
		int_en_cmpl		        <= 'd0;
		int_en_byterecv	        <= 'd0;
		int_en_bytetrans    	<= 'd0;
		int_en_start	    	<= 'd0;
		int_en_stop		        <= 'd0;
		int_en_arblose	    	<= 'd0;
		int_en_addrhit	    	<= 'd0;
		int_en_half		        <= 'd0;
		int_en_full		        <= 'd0;
		int_en_empty	    	<= 'd0;
		int_st_addrhit_init		<= 'd0;
		int_st_arblose_init		<= 'd0;
		int_st_start_init		<= 'd0;
		int_st_stop_init		<= 'd0;
		int_st_bytetrans_init	<= 'd0;
		int_st_byterecv_init	<= 'd0;
		int_st_cmpl_init		<= 'd0;
		int_st_wakeup_init		<= 'd0;
		addr					<= 'h52;
		rdwt_init				<= 'd0;
		phase_S					<= 'd1;
		phase_adr				<= 'd1;
		phase_dat				<= 'd1;
		phase_P					<= 'd1;
		trans_init				<= 'd0;
		t_sudat					<= 5'h05;
		t_sp					<= 3'h1;
		t_hddat					<= 5'h05;
		t_sclratio				<= 1'h1;
		t_sclhi					<= 9'h010;
		dma_en					<= 1'b0;
		master					<= 1'b0;
		addressing				<= 1'b0;
		iic_en					<= 1'b1;
		reg_si2c_en				<= 'd0;
		reg_si2c_adr			<= 'd0;
		reg_si2c_id				<= 7'h70;
		reg_si2c_wku_en			<= 'd0;
		reg_si2c_wku_adr		<= 16'h80;
		reg_si2c_wku_cmd		<= 8'h40;
        x_delay                 <= 10'd0 ;
        x_burst                 <= 3'd0 ;
        x_size                  <= 3'd0 ;
        x_rendian               <= 2'd0 ;
        x_wendian               <= 2'd0 ;
        x_prefix_addr           <= 32'hA12C_1234;   // i2c_ahb_master prefix
        x_flash_enter_addr      <= 32'hA12C_5678;   // flash special function enter prefix
        x_flash_exit_addr       <= 32'hA12C_ABCD;   // flash special function exit prefix
        x_firmware_on           <= 1'b0 ;           // must 1 set when firmware on
        x_addr_fix_en           <= 1'b0 ;
        x_i2c_entries           <= 'd0 ;            // 0 recommended

		ihready3	<= 1;
	end else begin
		ihready3 <= 1;
		if (HREADY&HTRANS[1]&HSEL&HWRITE &(HADDR[6:2]==C_ADDR_CTRL)) begin
			ihready3 <= 0;
		end

		if (hvalid_reg & hwrite_reg) begin
			case (haddr_reg[6:2])
				C_ADDR_INT_EN : begin
					if (byte_00_we) begin
						int_en_empty    		<= HWDATA[0];
						int_en_full     		<= HWDATA[1];
						int_en_half     		<= HWDATA[2];
						int_en_addrhit  		<= HWDATA[3];
						int_en_arblose  		<= HWDATA[4];
						int_en_stop     		<= HWDATA[5];
						int_en_start    		<= HWDATA[6];
						int_en_bytetrans     	<= HWDATA[7];
					end
					if (byte_01_we) begin
						int_en_byterecv     	<= HWDATA[8];
						int_en_cmpl     		<= HWDATA[9];
						int_en_wakeup     		<= HWDATA[10];
					end
				end
				C_ADDR_IB_ST : begin
					if (byte_00_we) begin
						int_st_addrhit_init		<= HWDATA[3];
						int_st_arblose_init		<= HWDATA[4];
						int_st_stop_init		<= HWDATA[5];
						int_st_start_init		<= HWDATA[6];
						int_st_bytetrans_init	<= HWDATA[7];
					end
					if (byte_01_we) begin
						int_st_byterecv_init	<= HWDATA[8];
						int_st_cmpl_init		<= HWDATA[9];
						int_st_wakeup_init		<= HWDATA[10];
					end
				end
				C_ADDR_ADDR : begin
					if (byte_00_we)	addr[7:0]	<= HWDATA[7:0];
					if (byte_01_we)	addr[9:8]	<= HWDATA[9:8];
				end
				C_ADDR_DATA : begin
				end
				C_ADDR_CTRL : begin
					if (byte_01_we) begin   // i2c master mode setting
						rdwt_init		<= HWDATA[8];
						phase_P			<= HWDATA[9];
						phase_dat		<= HWDATA[10];
						phase_adr		<= HWDATA[11];
						phase_S			<= HWDATA[12];
					end
				end
				C_ADDR_CMD : begin
					if (byte_00_we) begin
						if(HWDATA[2:0]==CMD_TRANS)			trans_init <= 1;
						else if(HWDATA[2:0]==CMD_NO_ACTION)	trans_init <= 0;
					end
					if (byte_01_we)	t_sclhi[7:0]	<= HWDATA[15:8];
					if (byte_10_we)	t_sclhi[8]		<= HWDATA[16];
					if (byte_11_we)	t_sclratio		<= HWDATA[24];
				end
				C_ADDR_SETUP : begin
					if (byte_00_we) begin
						iic_en		<= HWDATA[0];
						addressing	<= HWDATA[1];
						master		<= HWDATA[2];
						dma_en		<= HWDATA[3];
					end
					if (byte_10_we) begin
						t_hddat		<= HWDATA[20:16];
						t_sp		<= HWDATA[23:21];
					end
					if (byte_11_we) begin
						t_sudat		<= HWDATA[28:24];
					end
				end
				C_ADDR_SI2C_CFG : begin
					if (byte_00_we) begin
						reg_si2c_en		<= HWDATA[0];
						//reg_si2c_aopd	<= HWDATA[2];
						reg_si2c_adr	<= HWDATA[3];
					end
					if (byte_01_we) reg_si2c_id	<= HWDATA[14:08];
				end
				C_ADDR_SI2C_WKU : begin
					if (byte_00_we) reg_si2c_wku_en			<= HWDATA[0];
					if (byte_01_we) reg_si2c_wku_cmd		<= HWDATA[15:08];
					if (byte_10_we)	reg_si2c_wku_adr[07:00]	<= HWDATA[23:16];
					if (byte_11_we)	reg_si2c_wku_adr[15:08]	<= HWDATA[31:24];
				end
				C_ADDR_AHB_M0 : begin
					if (byte_00_we) begin
				        x_firmware_on  <= HWDATA[0] ;
				        x_rendian  <= HWDATA[2:1] ;
				        x_wendian  <= HWDATA[4:3] ;
				        x_burst    <= HWDATA[7:5] ;
                    end
					if (byte_01_we) begin
				        x_size  <= HWDATA[10:8] ;
				        x_delay[4:0] <= HWDATA[15:11] ;
                    end
					if (byte_10_we)	begin
                        x_delay[9:5] <= HWDATA[20:16] ;
                        // <= HWDATA[21] ;
                        // <= HWDATA[22] ;
                        x_addr_fix_en <= HWDATA[23] ;
                    end 
				    if (byte_11_we)	begin
				        // i_state <=  HWDATA[29:24];           // read only
				        // i_ahbm_prefix_match <=  HWDATA[30];  // read only
				        // i_prefix_period <=  HWDATA[31];      // read only
                    end    
				end
				C_ADDR_AHB_M1 : begin
					if (byte_00_we) begin
				        x_i2c_entries <= HWDATA[`ATCIIC100_INDEX_WIDTH-1:0] ;
                    end
					//if (byte_01_we) 
					//if (byte_10_we)	
					if (byte_11_we)	begin
                        // i_addr_fix_on <= HWDATA[31] ;        // read only
                    end
				end
				C_ADDR_AHB_M_PREFIX : begin
					if (byte_00_we) x_prefix_addr[07:00]	<= HWDATA[07:00];
					if (byte_01_we) x_prefix_addr[15:08]    <= HWDATA[15:08];
					if (byte_10_we)	x_prefix_addr[23:16]	<= HWDATA[23:16];
					if (byte_11_we)	x_prefix_addr[31:24]	<= HWDATA[31:24];
				end
				C_ADDR_FLASH_ENTER : begin
					if (byte_00_we) x_flash_enter_addr[07:00]	<= HWDATA[07:00];
					if (byte_01_we) x_flash_enter_addr[15:08]   <= HWDATA[15:08];
					if (byte_10_we)	x_flash_enter_addr[23:16]	<= HWDATA[23:16];
					if (byte_11_we)	x_flash_enter_addr[31:24]	<= HWDATA[31:24];
				end
				C_ADDR_FLASH_EXIT : begin
					if (byte_00_we) x_flash_exit_addr[07:00]	<= HWDATA[07:00];
					if (byte_01_we) x_flash_exit_addr[15:08]    <= HWDATA[15:08];
					if (byte_10_we)	x_flash_exit_addr[23:16]	<= HWDATA[23:16];
					if (byte_11_we)	x_flash_exit_addr[31:24]	<= HWDATA[31:24];
				end
				default : begin
				end
			endcase
		end //hwrite_valid
	end //clock edge

//----------------------------------------------------------------------------
// Read multiplexing
//----------------------------------------------------------------------------
always @(*)
begin
	hrdata_reg <= 32'b0;
	if (hvalid_reg & ~hwrite_reg) begin
		case (haddr_reg[6:2])
			C_ADDR_ID : begin
				hrdata_reg		<= idrev;
			end
			C_ADDR_CFG : begin
				hrdata_reg[2:0]	<= cfg;
			end
			C_ADDR_INT_EN : begin
				hrdata_reg[10:0]	<= int_en;
			end
			C_ADDR_IB_ST : begin
				hrdata_reg[10:0]	<= int_st;
				hrdata_reg[15:11]	<= bus_st;
			end
			C_ADDR_ADDR : begin
				hrdata_reg[9:0]		<= addr;
			end
			C_ADDR_DATA : begin
				hrdata_reg[7:0]		<= fifo_rd_data;
			end
			C_ADDR_CTRL : begin
				hrdata_reg[31:0]	<= ctrl;
			end
			C_ADDR_CMD : begin
				hrdata_reg[0]		<= trans;
				hrdata_reg[16:8]	<= t_sclhi;
				hrdata_reg[24]		<= t_sclratio;
			end
			C_ADDR_SETUP : begin
				hrdata_reg[28:0]	<= setup;
			end
			C_ADDR_SI2C_CFG : begin
				hrdata_reg[0]		<= reg_si2c_en;
				hrdata_reg[2]		<= reg_si2c_aopd;
				hrdata_reg[3]		<= reg_si2c_adr;
				hrdata_reg[4]		<= hclk_si2c_intr_wakeup_i2c;   // read only
				hrdata_reg[5]		<= hclk_si2c_aopd_max;          // read only
				hrdata_reg[14:8]	<= reg_si2c_id;
				hrdata_reg[23:16]	<= hclk_si2c_status;            // read only
			end
			C_ADDR_SI2C_WKU : begin
				hrdata_reg[0]		<= reg_si2c_wku_en;
				hrdata_reg[15:08]	<= reg_si2c_wku_cmd;
				hrdata_reg[31:16]	<= reg_si2c_wku_adr;
			end
			C_ADDR_AHB_M0 : begin
				hrdata_reg[0]	    <= x_firmware_on;
				hrdata_reg[2:1]	    <= x_rendian;
				hrdata_reg[4:3]	    <= x_wendian;
				hrdata_reg[7:5]	    <= x_burst  ;
				hrdata_reg[10:8]	<= x_size   ;
				hrdata_reg[20:11]	<= x_delay  ;
				//hrdata_reg[21]	    <=  ;
				//hrdata_reg[22]	    <=  ;    
				hrdata_reg[23]	    <= x_addr_fix_en ;    

				hrdata_reg[29:24]	<= i_state  ;               // read only
				hrdata_reg[30]	    <= i_ahbm_prefix_match ;    // read only
				hrdata_reg[31]	    <= i_prefix_period ;        // read only
			end
			C_ADDR_AHB_M1 : begin
				hrdata_reg[`ATCIIC100_INDEX_WIDTH-1:0]	    <= x_i2c_entries;
				hrdata_reg[30]	    <= w_update_reg;            // read only
				hrdata_reg[31]	    <= i_addr_fix_on;           // read only
			end
			C_ADDR_AHB_M_PREFIX : begin
				hrdata_reg[31:0]	<= x_prefix_addr;
			end
			C_ADDR_FLASH_ENTER : begin
			    hrdata_reg[31:0]	<= x_flash_enter_addr;
			end
			C_ADDR_FLASH_EXIT : begin
			    hrdata_reg[31:0]	<= x_flash_exit_addr;
			end
		endcase
	end
end

GET_EDGE #(.ASYNC(0)) I_COMPL_EDGE	(.src(int_st_cmpl_init),	.rising(int_st_cmpl_r),		.falling(),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_BRECV_EDGE	(.src(int_st_byterecv_init),.rising(int_st_byterecv_r),	.falling(),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_BTRANS_EDGE	(.src(int_st_bytetrans_init),.rising(int_st_bytetrans_r),.falling(),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_START_EDGE	(.src(int_st_start_init),	.rising(int_st_start_r),	.falling(),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_STOP_EDGE	(.src(int_st_stop_init),	.rising(int_st_stop_r),		.falling(),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_ARBLOSE_EDGE(.src(int_st_arblose_init), .rising(int_st_arblose_r),	.falling(),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_ADDRHIT_EDGE(.src(int_st_addrhit_init), .rising(int_st_addrhit_r),	.falling(),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_RDWT_EDGE	(.src(rdwt_init),			.rising(rdwt_r),	.falling(rdwt_f),.clk(HCLK),.rstb(HRESETn));
GET_EDGE #(.ASYNC(0)) I_TRANS_EDGE	(.src(trans_init),			.rising(trans_r),			.falling(),.clk(HCLK),.rstb(HRESETn));

//always @(negedge HRESETn or posedge FCLK)
always @(negedge HRESETn or posedge HCLK)
	if (~HRESETn) begin
		int_st_addrhit			<= 'd0;
		int_st_arblose			<= 'd0;
		//int_st_start			<= 'd0;
		int_st_stop				<= 'd0;
		int_st_bytetrans		<= 'd0;
		int_st_byterecv			<= 'd0;
		int_st_cmpl				<= 'd0;
	end else begin

        // jys 191002 for no mcu
        if(!x_firmware_on) begin   // auto 0 set 
            if(iic_rst || int_st_cmpl)     
			int_st_cmpl		<= 1'b0;
        end
		else if (iic_rst || int_st_cmpl_r) begin
			int_st_cmpl		<= 1'b0;
		end if (cmpl_trig) begin
			int_st_cmpl		<= 1'b1;
		end

		if (iic_rst || int_st_byterecv_r) begin
			int_st_byterecv		<= 1'b0;
		end if (byterecv_trig) begin
			int_st_byterecv		<= 1'b1;
		end

		if (iic_rst || int_st_bytetrans_r) begin
			int_st_bytetrans		<= 1'b0;
		end if (bytetrans_trig) begin
			int_st_bytetrans		<= 1'b1;
		end

		//if (iic_rst || int_st_start_r) begin
		//	int_st_start		<= 1'b0;
		//end if (start_cond) begin
		//	int_st_start		<= 1'b1;
		//end

		if (iic_rst || slv_hit || int_st_stop_r) begin
			int_st_stop		<= 1'b0;
		end if (stop_cond) begin
			int_st_stop		<= 1'b1;
		end

		if (iic_rst || int_st_arblose_r) begin
			int_st_arblose		<= 1'b0;
		end if (arblose_trig) begin
			int_st_arblose		<= 1'b1;
		end

        // jys 191002 for no mcu
        if(!x_firmware_on) begin   // auto 0 set
            if(iic_rst || int_st_addrhit)     
			int_st_addrhit		<= 1'b0;
        end
		else if (iic_rst || int_st_addrhit_r) begin
			int_st_addrhit		<= 1'b0;
		end if (addrhit_trig) begin
			int_st_addrhit		<= 1'b1;
		end
	end

always @(negedge HRESETn or posedge FCLK)
	if (~HRESETn) begin
		int_st_start			<= 'd0;
	end else begin
		if (iic_rst || int_st_start_r || cmpl_trig) begin   
			int_st_start		<= 1'b0;
		end if (start_cond) begin
			int_st_start		<= 1'b1;
		end
	end

always @(negedge HRESETn or posedge HCLK)
	if (~HRESETn) begin
		nx_rdwt					<= 'd0;
		trans					<= 'd0;
	end else begin
		if(trans_r)				    trans	<= 1'b1;
		else if (cmpl_trig || arblose_trig)	trans	<= 1'b0;

		if(rdwt_r||rdwt_f)	nx_rdwt	<= rdwt_init;   
	end

always @(negedge HRESETn or posedge HCLK)
	if (~HRESETn) begin
		nx_datacnt	<= 'd0;
	end else begin
		if (hwrite_reg & hvalid_reg & (haddr_reg[6:2]==C_ADDR_CTRL)) begin
			if (byte_10_we) nx_datacnt[7:0]	<= HWDATA[23:16];
			if (byte_11_we) nx_datacnt[15:8] <= HWDATA[31:24];
		end 
	end

reg r0_sleeping ;
reg r1_sleeping ;
always @(negedge HRESETn or posedge FCLK)
	if (~HRESETn) begin
		r0_sleeping			<= 'd0;
		r1_sleeping			<= 'd0;
	end else begin
		r0_sleeping			<= SLEEPING;
		r1_sleeping			<= r0_sleeping;
	end
wire fall_sleeping = ~r0_sleeping & r1_sleeping ;    

always @(negedge HRESETn or posedge FCLK)
	if (~HRESETn) begin
		reg_si2c_aopd			<= 'd0;
	end else begin
        if(fall_sleeping) reg_si2c_aopd	<= 'd0;
		else if(hvalid_reg && hwrite_reg && haddr_reg[6:2]==C_ADDR_SI2C_CFG) begin
		    if (byte_00_we) reg_si2c_aopd	<= HWDATA[2];
        end        
	end

//----------------------------------------------------------------------------
// Drive output
//----------------------------------------------------------------------------
assign HRESP = 2'b0;

assign HRDATA = hrdata_reg;
assign HREADYOUT = 1'b1 & ihready2 & (ihready3&ihready4);

assign	fifo_wr			=  hwrite_reg & hvalid_reg & (haddr_reg[6:2]==C_ADDR_DATA) & !fifo_full;
assign	fifo_rd			= ~hwrite_reg & hvalid_reg & (haddr_reg[6:2]==C_ADDR_DATA) & !fifo_empty;
assign	fifo_wr_data	= HWDATA[7:0] ;
assign 	fifo_half		= (master ^ rdwt) ? fifo_half_empty : fifo_half_full;

assign	t_high	= {1'b0, t_sclhi};
assign	t_low	= t_sclratio ? {t_sclhi, 1'b1} : {1'b0, t_sclhi};

assign fifo_clr	= (hwrite_reg & hvalid_reg & (haddr_reg[6:2]==C_ADDR_CMD) & (HWDATA[2:0]==CMD_FIFO_CLR)) | iic_rst  | i_im_fifo_clr ; // for no firmware & fifo prefix clear
assign do_nack	= (hwrite_reg & hvalid_reg & (haddr_reg[6:2]==C_ADDR_CMD) & (HWDATA[2:0]==CMD_DO_NACK));
assign do_ack	= (hwrite_reg & hvalid_reg & (haddr_reg[6:2]==C_ADDR_CMD) & (HWDATA[2:0]==CMD_DO_ACK));
assign iic_rst	= (hwrite_reg & hvalid_reg & (haddr_reg[6:2]==C_ADDR_CMD) & (HWDATA[2:0]==CMD_IIC_RST));

assign 	i2c_int =
	(fifo_full & int_en_full) |
	(fifo_empty & int_en_empty) |
	(fifo_half & int_en_half) |
	(int_st_addrhit & int_en_addrhit) |
	(int_st_arblose & int_en_arblose) |
	(int_st_stop & int_en_stop) |
	(int_st_start & int_en_start) |                     // for light sleep
	(int_st_bytetrans & int_en_bytetrans) |
	(int_st_byterecv & int_en_byterecv) |
	(int_st_cmpl & int_en_cmpl) |
	(int_st_wakeup & (int_en_wakeup | SLEEPING));       // for deep sleep

endmodule
