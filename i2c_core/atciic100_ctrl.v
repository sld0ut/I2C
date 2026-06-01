// Copyright (C) 2017, Andes Technology Corp. Confidential Proprietary

`include "atciic100_config.vh"
`include "atciic100_const.vh"

module atciic100_ctrl(
		  HCLK,
		  pclk,
		  presetn,
		  scl,
		  sda,
		  scl_o,
		  sda_o,
		  addr,
		  int_en_byterecv,
		  iic_rst,
		  do_ack,
		  do_nack,
		  trans,
		  phase_S,
		  phase_adr,
		  phase_dat,
		  phase_P,
		  nx_rdwt,
		  nx_datacnt,
		  t_hddat,
		  t_sudat,
		  t_high,
		  t_low,
		  dma_en,
		  master,
		  addressing,
		  iic_en,
		  dma_ack_rx,
		  dma_ack_tx,
		  fifo_rd_data,
		  fifo_full,
		  fifo_empty,
		  fifo_entries,
		  int_st_cmpl,
		  wr_recv,
		  dma_req_rx,
		  dma_req_tx,
		  st_busbusy,
		  st_ack,
		  start_cond,
		  stop_cond,
		  st_gencall,
		  rdwt,
		  rdwt_changed,
		  datacnt,
		  cmpl_trig,
		  byterecv_trig,
		  bytetrans_trig,
		  arblose_trig,
		  addrhit_trig,
		  fifo_wr_data,
		  fifo_wr,
		  fifo_rd,
		  fifo_clr,
		  slv_hit,
		  scl_falling,
		  scl_rising,
		  sda_falling,
		  sda_rising,
          idle_state,
          bit_cnt,
          fifo_half_mask
);

parameter [4:0]	ST_IDLE		= 5'd0,
				ST_S_S		= 5'd1,
				ST_S_ADR7	= 5'd2,
				ST_S_ACK7	= 5'd3,
				ST_S_ADR10	= 5'd4,
				ST_S_ACK10	= 5'd5,
				ST_S_DAT_T	= 5'd6,
				ST_S_ACK_T	= 5'd7,
				ST_S_DAT_R	= 5'd8,
				ST_S_ACK_R	= 5'd9,
				ST_M_INIT	= 5'd16,
				ST_M_S		= 5'd17,
				ST_M_ADR7	= 5'd18,
				ST_M_ACK7	= 5'd19,
				ST_M_ADR10	= 5'd20,
				ST_M_ACK10	= 5'd21,
				ST_M_DAT_T	= 5'd22,
				ST_M_ACK_T	= 5'd23,
				ST_M_DAT_R	= 5'd24,
				ST_M_ACK_R	= 5'd25,
				ST_M_P		= 5'd26;

parameter TEN_BIT_ADR	= 5'b11110;
parameter IIC_ACK		= 1'b0;
parameter IIC_NACK		= 1'b1;

input			HCLK;
input			pclk;
input			presetn;

input			scl;
input			sda;
input			scl_falling;
input			scl_rising;
input			sda_falling;
input			sda_rising;

output			scl_o;
output			sda_o;

input	[9:0]	addr;
input			int_en_byterecv;
input			iic_rst;
input			do_ack;
input			do_nack;
input			trans;
input			phase_S;
input			phase_adr;
input			phase_dat;
input			phase_P;
input			nx_rdwt;
input	[15:0]	nx_datacnt; 
input	[4:0]	t_hddat;
input	[4:0]	t_sudat;
input	[9:0]	t_high;
input	[9:0]	t_low;
input			dma_en;
input			master;
input			addressing;
input			iic_en;
input			dma_ack_rx;
input			dma_ack_tx;
input	[7:0]	fifo_rd_data;
input			fifo_full;
input			fifo_empty;
input	[`ATCIIC100_INDEX_WIDTH-1:0]	fifo_entries;
input			int_st_cmpl;
input			wr_recv;

output			dma_req_rx;
output			dma_req_tx;
output			st_busbusy;
output			st_ack;
output			start_cond;
output			stop_cond;
output			st_gencall;
output	[15:0]	datacnt; 
output			rdwt;
output			rdwt_changed;
output			cmpl_trig;
output			byterecv_trig;
output			bytetrans_trig;
output			arblose_trig;
output			addrhit_trig;
output	[7:0]	fifo_wr_data;
output			fifo_wr;
output			fifo_rd;
output			fifo_clr;
output			slv_hit;

output			idle_state;
output	[2:0]	bit_cnt;
output			fifo_half_mask;

reg				scl_o;
reg				sda_o;
reg				nx_scl_o;
reg				nx_sda_o;

reg				st_busbusy;
reg				busbusy_flag;
reg				st_ack;
reg				st_gencall;
reg				ten_b_flag;
reg		[15:0]	datacnt; 
reg				rdwt;
reg				rdwt_changed;

reg		[9:0]	cntr;
reg		[7:0]	sr;
reg		[2:0]	bit_cnt/* synthesis syn_noprune=1 syn_preserve=1 */;

reg				sr_ready/* synthesis syn_noprune=1 syn_preserve=1 */;
reg				ack_ready;

reg		[4:0]	cs/* synthesis syn_noprune=1 syn_preserve=1 */;
reg		[4:0]	ns;

wire			cmpl_trig;
wire			byterecv_trig;
wire			bytetrans_trig;
wire			arblose_trig;
wire			addrhit_trig;
reg				dma_req_rx;
reg				dma_req_tx;


wire			start_cond;
wire			stop_cond;
wire			t_high_end;
wire			t_low_end;
wire			t_hold_end;
wire			t_scl_rel;
wire			adr7_hit;
wire			adr10_0_hit;
wire			adr10_1_hit;
wire			gencall_hit;
wire			slv_hit;
reg				slv_hit_10bit_wr_flag;
reg				scl_rel_flag;

wire			cntr_pause;
wire			cntr_reset;
wire			fifo_wr;
wire			fifo_rd;

assign	start_cond	= sda_falling & scl & !scl_falling & !scl_rising;
assign	stop_cond	= sda_rising  & scl & !scl_falling & !scl_rising;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		st_busbusy <= 1'b0;
	else if (iic_rst | stop_cond)
		st_busbusy <= 1'b0;
	else if (start_cond)
		st_busbusy <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		busbusy_flag <= 1'b0;
	else if (iic_rst | stop_cond | arblose_trig)
		busbusy_flag <= 1'b0;
	else if ((cs == ST_M_S) && start_cond)
		busbusy_flag <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		scl_rel_flag <= 1'b0;
	else if (!master && t_hold_end && sr_ready && ack_ready)
		scl_rel_flag <= 1'b1;
	else if (scl_rising)
		scl_rel_flag <= 1'b0;

reg d0_hclk_ack ;
reg d1_hclk_ack ;
reg d0_hclk_st_busbusy ;
reg d1_hclk_st_busbusy ;
reg d2_hclk_st_busbusy ;
always @(posedge HCLK or negedge presetn)
	if (!presetn) begin
		d0_hclk_ack <= 'd0 ;
		d1_hclk_ack <= 'd0 ;
		d0_hclk_st_busbusy <= 'd0 ;
		d1_hclk_st_busbusy <= 'd0 ;
		d2_hclk_st_busbusy <= 'd0 ;
    end      
	else begin
		d0_hclk_ack <= st_ack       ;
		d1_hclk_ack <= d0_hclk_ack  ;
		d0_hclk_st_busbusy <= st_busbusy            ;
		d1_hclk_st_busbusy <= d0_hclk_st_busbusy    ;
		d2_hclk_st_busbusy <= d1_hclk_st_busbusy    ;
    end    
wire  rise_hclk_st_busbusy = ~d2_hclk_st_busbusy && d1_hclk_st_busbusy ;

reg hclk_valid ;
always @(posedge HCLK or negedge presetn)
	if (!presetn) begin
		hclk_valid <= 'd0 ;
    end    
	else if(d1_hclk_ack && (cs==ST_S_ACK7)) begin
		hclk_valid <= 'd0 ;
    end    
	else if(rise_hclk_st_busbusy) begin
		hclk_valid <= 'd1 ;
    end    

//// 200427 jys for light sleep wakeup
//Repeated Start Bug fix, restore R0
assign	adr7_hit	= !addressing && (sr[7:1] == addr[6:0]);
assign	adr10_0_hit	= addressing && (sr[7:1] == {5'b11110, addr[9:8]}) && (sr[0] == ten_b_flag);
assign	adr10_1_hit	= addressing && (sr[7:0] == addr[7:0]);
assign	gencall_hit	= sr[7:1] == 7'b0;
//assign	adr7_hit	= hclk_valid && !addressing && (sr[7:1] == addr[6:0]);
//assign	adr10_0_hit	= hclk_valid && addressing && (sr[7:1] == {5'b11110, addr[9:8]}) && (sr[0] == ten_b_flag);
//assign	adr10_1_hit	= hclk_valid && addressing && (sr[7:0] == addr[7:0]);
//assign	gencall_hit	= hclk_valid && (sr[7:1] == 7'b0);

assign 	t_high_end	=  scl && (cntr == t_high);
assign 	t_low_end	= !scl && (cntr == t_low);
assign	t_hold_end	= !scl && (cntr == {5'b0, t_hddat}) && !scl_rel_flag;
assign 	t_scl_rel	= !scl && (cntr == {5'b0, t_sudat}) && scl_rel_flag;

// no synthesis-----------------------------------------------------------
// synopsys translate_off 

    reg [160:0] state_string ; 

    always @ ( * ) begin 
        case (cs) 
            ST_IDLE		: state_string = "ST_IDLE"	  ;	
			ST_S_S		: state_string = "ST_S_S"	  ;
			ST_S_ADR7	: state_string = "ST_S_ADR7"  ;
			ST_S_ACK7	: state_string = "ST_S_ACK7"  ;
			ST_S_ADR10	: state_string = "ST_S_ADR10" ;
			ST_S_ACK10	: state_string = "ST_S_ACK10" ;
			ST_S_DAT_T	: state_string = "ST_S_DAT_T" ;
			ST_S_ACK_T	: state_string = "ST_S_ACK_T" ;
			ST_S_DAT_R	: state_string = "ST_S_DAT_R" ;
			ST_S_ACK_R	: state_string = "ST_S_ACK_R" ;
			ST_M_INIT	: state_string = "ST_M_INIT"  ;
			ST_M_S		: state_string = "ST_M_S"	  ;
			ST_M_ADR7	: state_string = "ST_M_ADR7"  ;
			ST_M_ACK7	: state_string = "ST_M_ACK7"  ;
			ST_M_ADR10	: state_string = "ST_M_ADR10" ;
			ST_M_ACK10	: state_string = "ST_M_ACK10" ;
			ST_M_DAT_T	: state_string = "ST_M_DAT_T" ;
			ST_M_ACK_T	: state_string = "ST_M_ACK_T" ;
			ST_M_DAT_R	: state_string = "ST_M_DAT_R" ;
			ST_M_ACK_R	: state_string = "ST_M_ACK_R" ;
			ST_M_P		: state_string = "ST_M_P"	  ;  	
        endcase
    end

// synopsys translate_on 
// ----------------------------------------------------------------------  

always @(*) begin
	if (stop_cond || iic_rst || arblose_trig)
		ns = ST_IDLE;
	else begin
		ns = cs;
		case (cs)
			ST_S_S:
				if (scl_falling)							ns = ST_S_ADR7;
			ST_S_ADR7:
				if (scl_falling && (bit_cnt == 3'h0)) begin
					if (gencall_hit || adr7_hit || adr10_0_hit)	ns = ST_S_ACK7;
					else									ns = ST_IDLE;
				end
			ST_S_ACK7:
				if (scl_falling) begin
					if (ten_b_flag | rdwt)					ns = ST_S_DAT_T;
					else if (addressing && !gencall_hit)	ns = ST_S_ADR10;
					else									ns = ST_S_DAT_R;
				end
			ST_S_ADR10:
				if (scl_falling && (bit_cnt == 3'h0)) begin
					if (adr10_1_hit)						ns = ST_S_ACK10;
					else									ns = ST_IDLE;
				end
			ST_S_ACK10:
				if (scl_falling)							ns = ST_S_DAT_R;
			ST_S_DAT_T:
				if (scl_falling && (bit_cnt == 3'b0))			ns = ST_S_ACK_T;
			ST_S_ACK_T:
				if (scl_falling) begin
					if (st_ack)								ns = ST_S_DAT_T;
					else 									ns = ST_IDLE;
				end
			ST_S_DAT_R:
				if (start_cond)								ns = ST_S_S;
				else if (scl_falling && (bit_cnt == 3'b0))  	ns = ST_S_ACK_R;
			ST_S_ACK_R:
				if (scl_falling) begin
					if (st_ack)								ns = ST_S_DAT_R;
					else									ns = ST_IDLE;
				end
			ST_M_INIT:
				if (!scl)									ns = phase_adr ? ST_M_ADR7 : phase_dat ? rdwt ? ST_M_DAT_R : ST_M_DAT_T : ST_M_P;
			ST_M_S:
				if (scl_falling) 							ns = phase_adr ? ST_M_ADR7 : phase_dat ? rdwt ? ST_M_DAT_R : ST_M_DAT_T : phase_P ? ST_M_P : ST_IDLE;
			ST_M_ADR7:
				if (scl_falling && (bit_cnt == 3'b0))			ns = ST_M_ACK7;
			ST_M_ACK7:
				if (scl_falling) begin
					if (st_ack) begin
						if (ten_b_flag | !addressing)		ns = phase_dat ? rdwt ? ST_M_DAT_R : ST_M_DAT_T : phase_P ? ST_M_P : ST_IDLE;
						else								ns = ST_M_ADR10;
					end
					else									ns = phase_P ? ST_M_P : ST_IDLE;
				end
			ST_M_ADR10:
				if (scl_falling && (bit_cnt == 3'b0)) 			ns = ST_M_ACK10;
			ST_M_ACK10:
				if (scl_falling) begin
					if (st_ack) begin
						if (!rdwt)							ns = phase_dat ? ST_M_DAT_T : phase_P ? ST_M_P : ST_IDLE;
						else								ns = ST_M_S;
					end
					else									ns = phase_P ? ST_M_P : ST_IDLE;
				end
			ST_M_DAT_T:
				if (scl_falling && (bit_cnt == 3'b0)) 			ns = ST_M_ACK_T;
			ST_M_ACK_T:
				if (scl_falling) begin
					if (!st_ack || (datacnt == 16'h0))		ns = phase_P ? ST_M_P : ST_IDLE; //bruce
					else 									ns = ST_M_DAT_T;
				end
			ST_M_DAT_R:
				if (scl_falling && (bit_cnt == 3'b0)) 			ns = ST_M_ACK_R;
			ST_M_ACK_R:
				if (scl_falling) begin
					if (st_ack)								ns = ST_M_DAT_R;
					else 									ns = phase_P ? ST_M_P : ST_IDLE;
				end
			ST_M_P:
				if ((t_high_end && scl && sda) || scl_falling)	ns = ST_IDLE;
			default:
				if (!master && start_cond && iic_en) 		ns = ST_S_S;
				else if (master && trans && iic_en && (!st_busbusy || busbusy_flag))			ns = phase_S ? ST_M_S : ST_M_INIT;
		endcase
	end
end

always @(posedge pclk or negedge presetn)
	if (!presetn)
		cs <= ST_IDLE;
	else
		cs <= ns;

always @(*) begin
	nx_scl_o = scl_o;
	case (cs)
		ST_M_INIT:
			nx_scl_o = 1'b0;
		ST_M_S:
			if (t_low_end)
				nx_scl_o = 1'b1;
			else if ((t_high_end || scl_falling) && !sda_o)
				nx_scl_o = 1'b0;
		ST_S_ACK7:
			if (!int_st_cmpl || addressing)
				nx_scl_o = 1'b1;
			else
				nx_scl_o = 1'b0;
		ST_S_ACK10:
			if (!int_st_cmpl)
				nx_scl_o = 1'b1;
			else
				nx_scl_o = 1'b0;
		ST_S_DAT_T:
			if (!sr_ready)
				nx_scl_o = 1'b0;
			else if (t_scl_rel)
				nx_scl_o = 1'b1;
		ST_S_ACK_R:
			if (!ack_ready || !sr_ready)
				nx_scl_o = 1'b0;
			else if (t_scl_rel)
				nx_scl_o = 1'b1;
		ST_M_ADR7, ST_M_ACK7, ST_M_ADR10, ST_M_ACK10,
			ST_M_DAT_T, ST_M_ACK_T, ST_M_DAT_R, ST_M_ACK_R:
			if (t_low_end)
				nx_scl_o = 1'b1;
			else if (t_high_end || scl_falling)
				nx_scl_o = 1'b0;
		ST_M_P:
			if (t_low_end)
				nx_scl_o = 1'b1;
		default:
				nx_scl_o = scl_o;
	endcase
end

always @(posedge pclk or negedge presetn)
	if (!presetn)
		scl_o <= 1'b1;
	else if (iic_rst || arblose_trig)
		scl_o <= 1'b1;
	else
		scl_o <= nx_scl_o;

always @(*) begin
	nx_sda_o = sda_o;
	case(cs)
		ST_M_S:
			if (t_hold_end)
				nx_sda_o = 1'b1;
			else if(t_high_end)
				nx_sda_o = 1'b0;
		ST_S_DAT_T, ST_M_ADR7, ST_M_ADR10, ST_M_DAT_T:
			if (t_hold_end)
				nx_sda_o = sr[7];
		ST_S_ACK7, ST_S_ACK10, ST_S_ACK_R, ST_M_ACK_R:
			if (t_hold_end)
				nx_sda_o = st_ack ? IIC_ACK : IIC_NACK;
		ST_S_ADR10, ST_S_DAT_R, ST_S_ACK_T, ST_M_ACK7, ST_M_ACK10, ST_M_DAT_R, ST_M_ACK_T:
			if (t_hold_end)
				nx_sda_o = 1'b1;
		ST_M_P:
			if (t_hold_end)
				nx_sda_o = 1'b0;
			else if (t_high_end)
				nx_sda_o = 1'b1;
		default:
			nx_sda_o = sda_o;
	endcase
end

always @(posedge pclk or negedge presetn)
	if (!presetn)
		sda_o <= 1'b1;
	else if (iic_rst || arblose_trig)
		sda_o <= 1'b1;
	else
		sda_o <= nx_sda_o;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		bit_cnt <= 3'h7;
	else if (cs == ST_IDLE)
		bit_cnt <= 3'h7;
    else if (((cs == ST_S_ADR7) || (cs == ST_S_ADR10) || (cs == ST_S_DAT_T) || (cs == ST_S_DAT_R) ||
			  (cs == ST_M_ADR7) || (cs == ST_M_ADR10) || (cs == ST_M_DAT_T) || (cs == ST_M_DAT_R)) && scl_falling)
		bit_cnt <= bit_cnt - 3'h1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		sr <= 8'b0;
	else if (fifo_rd)
		sr <= fifo_rd_data;
	else if ((cs != ST_M_ADR7) && (ns == ST_M_ADR7))
		sr <= addressing ? {TEN_BIT_ADR, addr[9:8], ten_b_flag} : {addr[6:0], rdwt};
	else if ((cs == ST_M_ACK7) && (ns == ST_M_ADR10))
		sr <= addr[7:0];
	else if (((cs == ST_M_ADR7) || (cs == ST_M_ADR10) || (cs == ST_M_DAT_T) || (cs == ST_S_DAT_T) ||
		(cs == ST_S_ADR7)  || (cs == ST_S_ADR10) ||	(cs == ST_S_DAT_R) || (cs == ST_M_DAT_R))
		&& scl_rising)
		sr <= {sr[6:0], sda};

always @(posedge pclk or negedge presetn)
	if (!presetn)
		ten_b_flag <= 1'b0;
	else if (cs == ST_IDLE)
		ten_b_flag <= 1'b0;
	else if ((cs == ST_S_ADR10) && (ns == ST_S_ACK10) && adr10_1_hit)
		ten_b_flag <= 1'b1;
	else if ((cs == ST_M_ACK10) && scl_rising && !sda)
		ten_b_flag <= 1'b1;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		sr_ready <= 1'b1;
	else if (iic_rst | (ns == ST_IDLE))
		sr_ready <= 1'b1;
	else if ((((cs == ST_S_ACK_R) || (cs == ST_M_ACK_R)) && !fifo_full) ||
			 (((cs == ST_S_DAT_T) || (cs == ST_M_DAT_T)) && !fifo_empty))
		sr_ready <= 1'b1;
	else if ((((cs == ST_S_DAT_R) && (ns == ST_S_ACK_R)) || ((cs == ST_M_DAT_R) && (ns == ST_M_ACK_R))) && fifo_full)
		sr_ready <= 1'b0;
	else if ((((cs != ST_S_DAT_T) && (ns == ST_S_DAT_T)) || ((cs != ST_M_DAT_T) && (ns == ST_M_DAT_T))) && fifo_empty)
		sr_ready <= 1'b0;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		ack_ready <= 1'b1;
	else if (do_ack | do_nack | iic_rst | (ns == ST_IDLE))
		ack_ready <= 1'b1;
	else if ((((cs == ST_S_DAT_R) && (ns == ST_S_ACK_R)) || ((cs == ST_M_DAT_R) && (ns == ST_M_ACK_R))) && int_en_byterecv)
		ack_ready <= 1'b0;

assign cntr_pause = (master && (scl_o != scl)) || !sr_ready || !ack_ready || (cs == ST_M_INIT);
assign cntr_reset = scl_falling || scl_rising || iic_rst || (cs == ST_IDLE) ||
					(((cs == ST_M_P) || (cs == ST_M_S)) && t_high_end) ||
					(!master && t_hold_end && !scl_rel_flag);

always @(posedge pclk or negedge presetn)
	if (!presetn)
		cntr <= 10'h0;
	else if (cntr_reset)
		cntr <= 10'h0;
	else if (!cntr_pause)
		cntr <= cntr + 10'h001;


always @(posedge pclk or negedge presetn)
	if (!presetn)
		slv_hit_10bit_wr_flag <= 1'b0;
	else if (cs == ST_IDLE)
		slv_hit_10bit_wr_flag <= 1'b0;
	else if ((cs == ST_S_ACK10) && (ns == ST_S_DAT_R))
		slv_hit_10bit_wr_flag <= 1'b1;
	else if ((cs == ST_S_DAT_R) && scl_falling && (bit_cnt == 3'h7))
		slv_hit_10bit_wr_flag <= 1'b0;

assign slv_hit = ((cs == ST_S_ACK7) && scl_rising && (gencall_hit || !addressing || ten_b_flag)) ||
				((cs == ST_S_DAT_R) && scl_falling && (bit_cnt == 3'h7) && slv_hit_10bit_wr_flag);
		
reg [15:0] r_nx_datacnt ;
always @(posedge pclk or negedge presetn)
	if (!presetn)
		r_nx_datacnt <= 'd0;
	else 
		r_nx_datacnt <= nx_datacnt;
wire w_nx_datacnt_en = (r_nx_datacnt != nx_datacnt) ;
		
always @(posedge pclk or negedge presetn)
	if (!presetn)
		datacnt <= 16'h0;
	else if (slv_hit & !dma_en)
		datacnt <= 16'h0;
	else if (fifo_rd | fifo_wr)
		datacnt <= (master | dma_en) ? (datacnt - 16'h1) : (datacnt + 16'h1);
	else if(w_nx_datacnt_en)
		datacnt <= nx_datacnt;
		
reg r_nx_rdwt ;
always @(posedge pclk or negedge presetn)
	if (!presetn)
		r_nx_rdwt <= 'd0;
	else 
		r_nx_rdwt <= nx_rdwt;
wire w_nx_rdwt_en = (r_nx_rdwt != nx_rdwt) ;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		rdwt <= 'd0;
	else if ((cs == ST_S_ADR7) && (ns == ST_S_ACK7))
		rdwt <= sr[0];
	else if(w_nx_rdwt_en)
		rdwt <= nx_rdwt;

always @(posedge pclk or negedge presetn)
	if (!presetn) begin
		rdwt_changed <= 0;
	end else begin
		if(master&&w_nx_rdwt_en) begin
			rdwt_changed <= 1;
		end else if(rdwt_changed&&(cs!=ST_IDLE)) begin
			rdwt_changed <= 0;
		end
	end

always @(posedge pclk or negedge presetn)
	if (!presetn)
		st_gencall <= 1'b0;
	else if (iic_rst)
		st_gencall <= 1'b0;
	else if (slv_hit) begin
		if ((cs == ST_S_ACK7) && scl_rising && gencall_hit)
			st_gencall <= 1'b1;
		else
			st_gencall <= 1'b0;
	end

always @(posedge pclk or negedge presetn)
	if (!presetn)
		st_ack <= 1'b0;
	else if (iic_rst)
		st_ack <= 1'b0;
	else if ((cs == ST_M_DAT_R) && (ns == ST_M_ACK_R))
		st_ack <= (datacnt != 16'h1); //bruce
	else if ((cs == ST_S_DAT_R) && (ns == ST_S_ACK_R))
		st_ack <= 1'b1;
	else if (((cs == ST_S_ACK_R) || (cs == ST_M_ACK_R)) && !ack_ready) begin
		if (do_ack)
			st_ack <= 1'b1;
		else if (do_nack)
			st_ack <= 1'b0;
	end
	else if (cs == ST_S_ADR7) begin
		if (ns == ST_S_ACK7)
			st_ack <= 1'b1;
		else if (ns == ST_IDLE)
			st_ack <= 1'b0;
	end
	else if (cs == ST_S_ADR10) begin
		if (ns == ST_S_ACK10)
			st_ack <= 1'b1;
		else if (ns == ST_IDLE)
			st_ack <= 1'b0;
	end
	else if (((cs == ST_M_ACK7) || (cs == ST_M_ACK10) ||
			(cs == ST_M_ACK_T) || (cs == ST_S_ACK_T)) && scl_rising)
		st_ack <= (sda == IIC_ACK);

assign arblose_trig =
	((cs == ST_M_S) && t_high_end && sda_o && !sda) ||
	(((cs == ST_M_ADR7) || (cs == ST_M_ADR10) || (cs == ST_M_DAT_T) || (cs == ST_M_ACK_R)) &&
		((scl_rising && sda_o && !sda) || start_cond || stop_cond)) ||
	(((cs == ST_M_DAT_R) || (cs == ST_M_ACK_T)) && (start_cond || stop_cond));

assign byterecv_trig =
	((cs == ST_S_DAT_R) && (ns == ST_S_ACK_R)) ||
	((cs == ST_M_DAT_R) && (ns == ST_M_ACK_R));

assign bytetrans_trig =
	((cs == ST_M_ACK_T) || (cs == ST_S_ACK_T)) && scl_falling;

assign addrhit_trig =
	slv_hit ||
	((cs == ST_M_ACK7) && scl_rising && (sda == IIC_ACK) && (ten_b_flag | !addressing | gencall_hit)) ||
	((cs == ST_M_ACK10) && scl_rising && (sda == IIC_ACK) && !rdwt);

assign cmpl_trig =
	(master && !arblose_trig && (cs != ST_IDLE) && (ns == ST_IDLE)) ||
	(((cs == ST_S_DAT_R) || (cs == ST_S_DAT_T) || (cs == ST_S_ACK_T) || (cs == ST_S_ACK_R)) && (ns == ST_IDLE)) ||
	((cs == ST_S_DAT_R) && (ns == ST_S_S));

always @(posedge pclk or negedge presetn)
	if (!presetn)
		dma_req_rx <= 1'b0;
	else if (dma_ack_rx | iic_rst | !dma_en | !iic_en)
		dma_req_rx <= 1'b0;
	else if (master && rdwt && !fifo_empty) // master receiver. fifo not empty.
		dma_req_rx <= 1'b1;
	else if (!master && !rdwt && !fifo_empty)   // slave receiver.  fifo not empty.
		dma_req_rx <= 1'b1;
		
always @(posedge pclk or negedge presetn)
	if (!presetn)
		dma_req_tx <= 1'b0;
	//else if (dma_ack_tx | iic_rst | !dma_en | !iic_en) 
	else if ((dma_ack_tx && wr_recv) | iic_rst | !dma_en | !iic_en) // jys 200508
		dma_req_tx <= 1'b0;
	else if (master && !rdwt && !fifo_full && (cs != ST_IDLE) &&    // master transmitter. fifo not full.
				({{9-`ATCIIC100_INDEX_WIDTH{1'b0}}, fifo_entries} < datacnt))   // when wr_fifo_num - rd_fifo_num < datacnt
		dma_req_tx	<= 1'b1;
	else if (!master && rdwt && !fifo_full && ((cs == ST_S_DAT_T) || (cs == ST_S_ACK_T)) && // slave transmitter.
				({{9-`ATCIIC100_INDEX_WIDTH{1'b0}}, fifo_entries} < datacnt))   // when wr_fifo_num - rd_fifo_num < datacnt  
		dma_req_tx <= 1'b1;

assign	fifo_wr = (((cs == ST_S_DAT_R) && (ns == ST_S_ACK_R)) || ((cs == ST_M_DAT_R) && (ns == ST_M_ACK_R)) ||
					(((cs == ST_S_ACK_R) || (cs == ST_M_ACK_R)) && !sr_ready)) && !fifo_full;
assign	fifo_rd = (((cs != ST_S_DAT_T) && (ns == ST_S_DAT_T)) || ((cs != ST_M_DAT_T) && (ns == ST_M_DAT_T)) ||
					(((cs == ST_S_DAT_T) || (cs == ST_M_DAT_T)) && !sr_ready)) && !fifo_empty;

assign	fifo_wr_data = sr[7:0];

assign	fifo_clr = (((cs == ST_IDLE) || (cs == ST_M_S) || (cs == ST_M_ACK7)) && (ns == ST_M_DAT_R)) ||
					(((cs == ST_S_ACK7) || (cs == ST_S_ACK10)) && (ns == ST_S_DAT_R));

assign  idle_state = cs == ST_IDLE ;
         
assign  fifo_half_mask = (cs == 3) ;

endmodule
