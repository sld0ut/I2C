// Copyright (C) 2017, Andes Technology Corp. Confidential Proprietary

`include "atciic100_config.vh"
`include "atciic100_const.vh"

module atciic100 (
	input  wire			 CLK_I2C,
	input  wire			 CLK_LP,
	input  wire			 FCLK,
// AHB Common
	input  wire          TE,
	input  wire          SE,
	input  wire          HCLK_CG_EN,
	input  wire          HRESETn,
	input  wire          HRESETN_HREADY,
	input  wire          HCLK,
	input  wire          SLEEPING,
// AHB Master registers
    output wire [9:0]	 hclk_delay,
    output wire [2:0]	 hclk_burst,
    output wire [2:0]	 hclk_size,
    output wire [1:0]	 hclk_rendian,
    output wire [1:0]	 hclk_wendian,
    output wire [31:0]   hclk_prefix_addr,
    output wire [31:0]   hclk_flash_enter_addr,
    output wire [31:0]   hclk_flash_exit_addr,
    input  wire [5:0]    hclk_state,               // read only
    input  wire          hclk_ahbm_prefix_match,   // read only
    input  wire          hclk_addr_fix_on,         // read only
    output wire		     hclk_addr_fix_en,
    output wire         [`ATCIIC100_INDEX_WIDTH-1:0] hclk_i2c_entries,
	input  wire          hclk_im_fifo_clr,
	input  wire          hclk_i2c_master_idle,
    input  wire          hclk_prefix_period,       // read only
	input  wire          hclk_im_ahb_fifo_rd,
	input  wire          hclk_im_ahb_fifo_wr,
    output wire          hclk_fifo_empty_rx,
// AHB Slave
	input  wire   [31:0] S_HADDR,
	input  wire   [ 2:0] S_HSIZE,
	input  wire   [ 1:0] S_HTRANS,
	input  wire   [31:0] S_HWDATA,
	input  wire          S_HWRITE,
	input  wire          S_HSEL,
	input  wire          S_HREADY,
	output wire   [31:0] S_HRDATA,
	output wire          S_HREADYOUT,
	output wire   [ 1:0] S_HRESP,
// Simple I2C
	input  wire          si2c_intr_wakeup_i2c,
	input  wire	[7:0]	 si2c_status,
	input  wire	         hclk_si2c_aopd_max,
	input wire			 si2c_update_ack,
	output wire			 si2c_update,
	output wire			 si2c_aopd,
	output wire			 si2c_en,
	output wire			 si2c_adr,
	output wire	[6:0]	 si2c_id,
	output wire			 si2c_wku_en,
	output wire [15:0]	 si2c_wku_adr,
	output wire [07:0]	 si2c_wku_cmd,

	input wire			use_ext_slv_id,
	input wire			ext_slv_id,

	input wire			 scl_i,
	input wire			 sda_i,
	output wire			 clki2c_scl_o,
	output wire			 clki2c_sda_o,
	input wire			 hclk_dma_ack_rx,
	input wire			 hclk_dma_ack_tx,
	output wire			 hclk_dma_req_rx,
	output wire			 hclk_dma_req_tx,
	output wire			 hclk_i2c_int,
    
	output wire			 fclk_start_cond,
    output wire			 hclk_int_st_start,
    output wire			 hclk_int_st_addrhit,
    output wire			 hclk_int_st_cmpl,
    output wire			 hclk_int_st_stop,
	output wire			 hclk_rd_cntlr,
    output wire          hclk_wr_cntlr,
    output wire         [`ATCIIC100_DATA_WIDTH-1:0] hclk_wr_data_cntlr,
	output wire			 hclk_stop_cond,
    output wire			 hclk_int_st_wakeup_clr,
    output wire			 hclk_rdwt,
    output wire          hclk_sda,
    output wire         [`ATCIIC100_INDEX_WIDTH-1:0] hclk_entries_rx,
    output wire         [`ATCIIC100_INDEX_WIDTH-1:0] hclk_entries_tx,

    output wire          hclk_im_ahb_fifo_wr_mnt,                   
    output wire	[2:0]	 hclk_bit_cnt
);

wire            hclk_wr_apb ;
wire            hclk_si2c_intr_wakeup_i2c       ;
wire    [7:0]   hclk_si2c_status                ;

wire			hclk_rdwt_changed				;

wire            clki2c_fifo_full_rx             ;
wire            clki2c_fifo_empty_tx            ;
wire            clki2c_fifo_half_full_rx        ;
wire            clki2c_fifo_half_empty_tx       ;
wire			hclk_fifo_full_rx		        ;
wire			hclk_fifo_empty_tx		        ;
wire			hclk_fifo_half_full	            ;
wire			hclk_fifo_half_empty            ;

wire	[6:0]	 si2c_id_p;
assign si2c_id = (use_ext_slv_id) ? {si2c_id_p[6:1],ext_slv_id} : si2c_id_p;

wire	[9:0]	hclk_addr_p			            ;
wire	[9:0]	hclk_addr	= (use_ext_slv_id) ? {hclk_addr_p[9:1],ext_slv_id} : hclk_addr_p;
wire			hclk_int_en_byterecv            ;
wire			hclk_iic_rst		            ;
wire			hclk_clr_apb		            ;
wire			hclk_do_ack			            ;
wire			hclk_do_nack		            ;
wire			hclk_trans			            ;
wire			hclk_rd_apb			            ;
wire	[7:0]	hclk_wr_data_apb	            ;
wire			hclk_phase_S		            ;
wire			hclk_phase_adr		            ;
wire			hclk_phase_dat		            ;
wire			hclk_phase_P		            ;
wire	[15:0]	hclk_datacnt		            ;
wire	[2:0]	hclk_t_sp			            ;
wire	[4:0]	hclk_t_hddat		            ;
wire	[4:0]	hclk_t_sudat		            ;
wire	[9:0]	hclk_t_high			            ;
wire	[9:0]	hclk_t_low			            ;
wire			hclk_addressing		            ;
wire			hclk_master			            ;
wire			hclk_dma_en			            ;
wire			hclk_iic_en			            ;

wire			hclk_clr_cntlr			        ;
wire			hclk_scl			            ;
wire			hclk_st_gencall		            ;
wire			hclk_st_busbusy		            ;
wire			hclk_st_ack			            ;
wire			hclk_nx_rdwt	   		        ;
wire	[15:0]	hclk_nx_datacnt		            ;
wire			hclk_cmpl_trig		            ;
wire			hclk_byterecv_trig	            ;
wire			hclk_bytetrans_trig	            ;
wire			hclk_arblose_trig	            ;
wire			hclk_addrhit_trig	            ;
wire	[7:0]	hclk_rd_data		            ;
wire			hclk_slv_hit		            ;
wire			hclk_idle_state                 ;

wire            clki2c_rdwt                     ;
wire            clki2c_rdwt_changed				;
wire   [15:0]	clki2c_datacnt                  ;
wire            clki2c_idle_state               ;
wire            clki2c_dma_req_rx               ;
wire            clki2c_dma_req_tx               ;
wire            clki2c_st_busbusy               ;
wire            clki2c_st_ack                   ;
wire            clki2c_start_cond               ;
wire            clki2c_stop_cond                ;
wire            clki2c_st_gencall               ;
wire            clki2c_cmpl_trig                ;
wire            clki2c_byterecv_trig            ;
wire            clki2c_bytetrans_trig           ;
wire            clki2c_arblose_trig             ;
wire            clki2c_addrhit_trig             ;
wire    [7:0]	clki2c_wr_data_cntlr            ;
wire            clki2c_wr_cntlr                 ;
wire            clki2c_rd_cntlr                 ;
wire            clki2c_slv_hit                  ;
wire    [`ATCIIC100_INDEX_WIDTH-1:0]	clki2c_entries_rx               ;
wire    [`ATCIIC100_INDEX_WIDTH-1:0]	clki2c_entries_tx               ;
wire    [7:0]	clki2c_rd_data                  ;
wire            clki2c_sda                      ;
wire            clki2c_scl                      ;
wire    [2:0]	clki2c_bit_cnt                  ;
wire            clki2c_fifo_half_mask           ;

wire            clki2c_nx_rdwt                  ;
wire    [15:0]  clki2c_nx_datacnt               ;
wire   [9:0]	clki2c_addr                     ;
wire            clki2c_int_en_byterecv          ;
wire            clki2c_iic_rst                  ;
wire            clki2c_do_ack                   ;
wire            clki2c_do_nack                  ;
wire            clki2c_trans                    ;
wire            clki2c_phase_S                  ;
wire            clki2c_phase_adr                ;
wire            clki2c_phase_dat                ;
wire            clki2c_phase_P                  ;
wire   [4:0]	clki2c_t_hddat                  ;
wire   [4:0]	clki2c_t_sudat                  ;
wire   [9:0]	clki2c_t_high                   ;
wire   [9:0]	clki2c_t_low                    ;
wire            clki2c_dma_en                   ;
wire            clki2c_master                   ;
wire            clki2c_addressing               ;
wire            clki2c_iic_en                   ;
wire            clki2c_dma_ack_rx               ;
wire            clki2c_dma_ack_tx               ;
wire            clki2c_int_st_cmpl              ;
wire            clki2c_wr_apb                   ;
wire            clki2c_rd_apb                   ;
wire            clki2c_clr_apb                  ;
wire   [7:0]	clki2c_wr_data_apb              ;
wire            clki2c_prefix_period	        ;
wire            clki2c_im_ahb_fifo_rd	        ;
wire            clki2c_im_ahb_fifo_wr	        ;
wire   [2:0]	clki2c_t_sp                     ;
wire            clki2c_wr_recv                  ;

wire cmpl_trig = hclk_cmpl_trig ;
wire            hclk_fifo_full_tx	            ;
//wire            hclk_fifo_empty_rx	            ;
/*
wire            hclk_fifo_full     = (hclk_rdwt)? hclk_fifo_full_tx     : hclk_fifo_full_rx     ; 
wire            hclk_fifo_empty    = (hclk_rdwt)? hclk_fifo_empty_tx    : hclk_fifo_empty_rx    ; 
*/
reg            hclk_fifo_full     ;
reg            hclk_fifo_empty    ;
always @(*) begin
	hclk_fifo_full 	= 0;
	hclk_fifo_empty	= 0;
	if(hclk_master) begin
		hclk_fifo_full     = (hclk_rdwt)? hclk_fifo_full_rx     : hclk_fifo_full_tx     ; 
		hclk_fifo_empty    = (hclk_rdwt)? hclk_fifo_empty_rx    : hclk_fifo_empty_tx    ; 
	end else begin
		hclk_fifo_full     = (hclk_rdwt)? hclk_fifo_full_tx     : hclk_fifo_full_rx     ; 
		hclk_fifo_empty    = (hclk_rdwt)? hclk_fifo_empty_tx    : hclk_fifo_empty_rx    ; 
	end
end

wire            clki2c_fifo_full_tx     ;
wire            clki2c_fifo_empty_rx    ;
/*
wire            clki2c_fifo_full     = (clki2c_rdwt)? clki2c_fifo_full_tx     : clki2c_fifo_full_rx   ; 
wire            clki2c_fifo_empty    = (clki2c_rdwt)? clki2c_fifo_empty_tx    : clki2c_fifo_empty_rx  ; 
*/
reg            clki2c_fifo_full     ;
reg            clki2c_fifo_empty    ;
always @(*) begin
	clki2c_fifo_full     = 0;
	clki2c_fifo_empty    = 0;
	if(clki2c_master) begin
		clki2c_fifo_full     = (clki2c_rdwt)? clki2c_fifo_full_rx     : clki2c_fifo_full_tx   ; 
		clki2c_fifo_empty    = (clki2c_rdwt)? clki2c_fifo_empty_rx    : clki2c_fifo_empty_tx  ; 
	end else begin
		clki2c_fifo_full     = (clki2c_rdwt)? clki2c_fifo_full_tx     : clki2c_fifo_full_rx   ; 
		clki2c_fifo_empty    = (clki2c_rdwt)? clki2c_fifo_empty_tx    : clki2c_fifo_empty_rx  ; 
	end
end

wire			clki2c_clr_cntlr;
wire			clki2c_scl_falling;
wire			clki2c_scl_rising;
wire			clki2c_sda_falling;
wire			clki2c_sda_rising;

atciic100_ahbslv I_AHB_SLV (
/*input  wire           */	.CLK_LP				            (CLK_LP                         ), 
/*input  wire           */	.FCLK				            (FCLK                           ), 
	// AHB Common
/*input  wire			*/	.SE				                (SE				                ),
/*input  wire			*/	.HRESETn		                (HRESETn		                ),
/*input  wire			*/	.HRESETN_HREADY	                (HRESETN_HREADY	                ),
/*input  wire			*/	.HCLK			                (HCLK			                ),
/*input  wire			*/	.SLEEPING			            (SLEEPING			            ),
	// AHB Master registers
/*output reg   [9:0]	*/  .x_delay                        (hclk_delay                     ),
/*output reg   [2:0]	*/  .x_burst                        (hclk_burst                     ),
/*output reg   [2:0]	*/  .x_size                         (hclk_size                      ),
/*output reg   [1:0]	*/  .x_rendian                      (hclk_rendian                   ),
/*output reg   [1:0]	*/  .x_wendian                      (hclk_wendian                   ),
/*output reg   [31:0]	*/  .x_prefix_addr                  (hclk_prefix_addr               ),
/*output reg   [31:0]	*/  .x_flash_enter_addr             (hclk_flash_enter_addr          ),
/*output reg   [31:0]	*/  .x_flash_exit_addr              (hclk_flash_exit_addr           ),
/*input  reg   [5:0]	*/  .i_state                        (hclk_state	                    ),
/*input  wire           */  .i_ahbm_prefix_match            (hclk_ahbm_prefix_match         ),
/*input  wire         	*/	.i_prefix_period	            (hclk_prefix_period	            ),
/*input  wire         	*/	.i_addr_fix_on	                (hclk_addr_fix_on	            ),
/*output reg         	*/	.x_addr_fix_en	                (hclk_addr_fix_en	            ),
/*output reg   [4:0]	*/	.x_i2c_entries	                (hclk_i2c_entries	            ),
/*input	 wire           */  .i_im_fifo_clr                  (hclk_im_fifo_clr               ),
/*input	 wire           */  .i_i2c_master_idle              (hclk_i2c_master_idle           ),
	// AHB Slave
/*input  wire         	*/	.HCLK_CG_EN		                (HCLK_CG_EN		                ),
/*input  wire   [31:0]	*/	.HADDR			                (S_HADDR		                ),
/*input  wire   [ 2:0]	*/	.HSIZE			                (S_HSIZE		                ),
/*input  wire   [ 1:0]	*/	.HTRANS			                (S_HTRANS		                ),
/*input  wire   [31:0]	*/	.HWDATA			                (S_HWDATA		                ),
/*input  wire         	*/	.HWRITE			                (S_HWRITE		                ),
/*input  wire         	*/	.HSEL			                (S_HSEL			                ),
/*input  wire         	*/	.HREADY			                (S_HREADY		                ),
/*output wire   [31:0]	*/	.HRDATA			                (S_HRDATA		                ),
/*output wire         	*/	.HREADYOUT		                (S_HREADYOUT	                ),
/*output wire   [ 1:0]	*/	.HRESP			                (S_HRESP		                ),

/*input wire			*/	.sda			                (hclk_sda			            ),
/*input wire			*/	.scl			                (hclk_scl			            ),
/*output wire			*/	.i2c_int		                (hclk_i2c_int		            ),

    // Simple I2C
/*input wire			*/	.si2c_intr_wakeup_i2c	        (si2c_intr_wakeup_i2c	        ),  // scl domain
/*input wire			*/	.hclk_si2c_intr_wakeup_i2c	    (hclk_si2c_intr_wakeup_i2c	    ),  // hclk domain  
/*input wire       		*/	.hclk_si2c_aopd_max		        (hclk_si2c_aopd_max	            ),  // hclk domain
/*input wire	[7:0]	*/	.hclk_si2c_status		        (hclk_si2c_status	            ),  // hclk domain
/*input wire			*/	.si2c_update_ack	            (si2c_update_ack				),
/*output reg			*/	.reg_si2c_update	            (si2c_update	                ),
/*output reg			*/	.reg_si2c_aopd		            (si2c_aopd		                ),
/*output reg			*/	.reg_si2c_en		            (si2c_en		                ),
/*output reg			*/	.reg_si2c_adr		            (si2c_adr		                ),
/*output reg			*/	.reg_si2c_id		            (si2c_id_p		                ),
/*output reg			*/	.reg_si2c_wku_en	            (si2c_wku_en	                ),
/*output reg			*/	.reg_si2c_wku_adr	            (si2c_wku_adr	                ),
/*output reg			*/	.reg_si2c_wku_cmd	            (si2c_wku_cmd	                ),

/*input wire			*/	.start_cond		                (fclk_start_cond		        ),
/*input wire			*/	.st_gencall		                (hclk_st_gencall		        ),
/*input wire			*/	.st_busbusy		                (hclk_st_busbusy		        ),
/*input wire			*/	.st_ack			                (hclk_st_ack			        ),
/*input wire			*/	.rdwt			                (hclk_rdwt			            ),
/*input wire			*/	.rdwt_changed					(hclk_rdwt_changed				),
/*input wire	[15:0]	*/	.datacnt		                (hclk_datacnt		            ),
/*input wire			*/	.cmpl_trig		                (hclk_cmpl_trig		            ),
/*input wire			*/	.byterecv_trig	                (hclk_byterecv_trig	            ),
/*input wire			*/	.bytetrans_trig	                (hclk_bytetrans_trig	        ),
/*input wire			*/	.stop_cond		                (hclk_stop_cond		            ),
/*input wire			*/	.arblose_trig	                (hclk_arblose_trig	            ),
/*input wire			*/	.addrhit_trig	                (hclk_addrhit_trig	            ),
/*input wire	[7:0]	*/	.fifo_rd_data	                (hclk_rd_data		            ),
/*input wire			*/	.slv_hit		                (hclk_slv_hit		            ),
/*input wire			*/	.fifo_full		                (hclk_fifo_full		            ),  
/*input wire			*/	.fifo_empty		                (hclk_fifo_empty		        ),  
/*input wire			*/	.fifo_half_full	                (hclk_fifo_half_full	        ),  
/*input wire			*/	.fifo_half_empty                (hclk_fifo_half_empty           ),  
                                                                                       
/*output reg	[9:0]	*/	.addr			                (hclk_addr_p		            ),
/*output reg			*/	.int_en_byterecv                (hclk_int_en_byterecv           ),
/*output wire			*/	.iic_rst		                (hclk_iic_rst		            ),
/*output wire			*/	.fifo_clr		                (hclk_clr_apb		            ),
/*output wire			*/	.do_ack			                (hclk_do_ack			        ),
/*output wire			*/	.do_nack		                (hclk_do_nack		            ),
/*output reg			*/	.trans			                (hclk_trans			            ),
/*output reg			*/	.fifo_wr		                (hclk_wr_apb			        ),
/*output reg			*/	.fifo_rd		                (hclk_rd_apb			        ),
/*output reg	[7:0]	*/	.fifo_wr_data	                (hclk_wr_data_apb	            ),
/*output reg			*/	.phase_S		                (hclk_phase_S		            ),
/*output reg			*/	.phase_adr		                (hclk_phase_adr		            ),
/*output reg			*/	.phase_dat		                (hclk_phase_dat		            ),
/*output reg			*/	.phase_P		                (hclk_phase_P		            ),
/*output reg			*/	.nx_rdwt	   	                (hclk_nx_rdwt	  	            ),
/*output reg	[15:0]	*/	.nx_datacnt		                (hclk_nx_datacnt		        ),
/*output reg	[2:0]	*/	.t_sp			                (hclk_t_sp			            ),
/*output reg	[4:0]	*/	.t_hddat		                (hclk_t_hddat		            ),
/*output reg	[4:0]	*/	.t_sudat		                (hclk_t_sudat		            ),
/*output wire	[9:0]	*/	.t_high			                (hclk_t_high			        ),
/*output wire	[9:0]	*/	.t_low			                (hclk_t_low			            ),
/*output reg			*/	.addressing	                    (hclk_addressing		        ),
/*output reg			*/	.master		                    (hclk_master			        ),
/*output reg			*/	.dma_en		                    (hclk_dma_en			        ),
/*output reg			*/	.iic_en		                    (hclk_iic_en			        ),

/*output reg			*/	.int_st_wakeup_clr	            (hclk_int_st_wakeup_clr 	    ),
/*output wire           */	.int_st_start	                (hclk_int_st_start	            ),
/*output wire           */	.int_st_addrhit	                (hclk_int_st_addrhit	        ),
/*output reg			*/	.int_st_cmpl	                (hclk_int_st_cmpl	            ),
/*output reg			*/	.int_st_stop	                (hclk_int_st_stop	            ),
/*input wire			*/	.idle_state	                    (hclk_idle_state                )
);  // I_AHB_SLV

reg hclk_wr_recv ;
reg d0_hclk_dma_ack_tx ;
wire fall_hclk_dma_ack_tx = ~hclk_dma_ack_tx && d0_hclk_dma_ack_tx ;
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        hclk_wr_recv <= #1 1'b0 ;
        d0_hclk_dma_ack_tx <= #1 1'b0 ;
    end
    else begin
        d0_hclk_dma_ack_tx <= #1 hclk_dma_ack_tx ;
        if(fall_hclk_dma_ack_tx || hclk_stop_cond) hclk_wr_recv <= #1 1'b0 ;
        else if(hclk_wr_apb && hclk_dma_en) hclk_wr_recv <= #1 1'b1 ;
    end
end

i2c_cdc i2c_cdc_U0 (
/*input  wire			*/	.HRESETn		                (HRESETn		                ),
/*input  wire			*/	.FCLK			                (FCLK			                ),  
/*input  wire			*/	.HCLK			                (HCLK			                ),  
/*input  wire           */	.CLK_I2C                        (CLK_I2C                        ), 
/*input  wire			*/	.cdc_en		                    (1'b1		                    ),
/*output  wire          */  .hclk_im_ahb_fifo_wr_mnt        (hclk_im_ahb_fifo_wr_mnt        ),

/*input   wire          */  .i_si2c_intr_wakeup_i2c         (si2c_intr_wakeup_i2c           ),
/*input   wire [7:0]    */	.i_si2c_status                  (si2c_status                    ),
/*output  wire          */  .o_hclk_si2c_intr_wakeup_i2c    (hclk_si2c_intr_wakeup_i2c      ),
/*output  wire [7:0]    */	.o_hclk_si2c_status             (hclk_si2c_status               ),
                                                                                        
/*input   wire          */  .i_clki2c_fifo_full             (clki2c_fifo_full_rx            ),  
/*input   wire          */  .i_clki2c_fifo_half_full        (clki2c_fifo_half_full_rx       ),  
/*input   wire          */  .i_clki2c_fifo_half_empty       (clki2c_fifo_half_empty_tx      ),  
/*output  wire		    */  .o_hclk_fifo_full		        (hclk_fifo_full_rx              ),  
/*output  wire		    */  .o_hclk_fifo_half_full	        (hclk_fifo_half_full	        ),  
/*output  wire		    */  .o_hclk_fifo_half_empty         (hclk_fifo_half_empty           ),  

/*input wire			*/	.i_hclk_int_st_cmpl	            (hclk_int_st_cmpl	            ),
/*input wire         	*/	.i_hclk_prefix_period	        (hclk_prefix_period	            ),
/*input wire	[9:0]	*/	.i_hclk_addr			        (hclk_addr			            ),
/*input wire			*/	.i_hclk_int_en_byterecv         (hclk_int_en_byterecv           ),
/*input wire			*/	.i_hclk_iic_rst		            (hclk_iic_rst		            ),
/*input wire			*/	.i_hclk_clr_apb		            (hclk_clr_apb		            ),
/*input wire			*/	.i_hclk_do_ack			        (hclk_do_ack			        ),
/*input wire			*/	.i_hclk_do_nack		            (hclk_do_nack		            ),
/*input wire			*/	.i_hclk_trans			        (hclk_trans			            ),
/*input wire			*/	.i_hclk_wr_apb			        (hclk_wr_apb			        ),
/*input wire			*/	.i_hclk_rd_apb			        (hclk_rd_apb			        ),
/*input wire	[7:0]	*/	.i_hclk_wr_data_apb	            (hclk_wr_data_apb	            ),
/*input wire			*/	.i_hclk_phase_S		            (hclk_phase_S		            ),
/*input wire			*/	.i_hclk_phase_adr		        (hclk_phase_adr		            ),
/*input wire			*/	.i_hclk_phase_dat		        (hclk_phase_dat		            ),
/*input wire			*/	.i_hclk_phase_P		            (hclk_phase_P		            ),
/*input wire			*/	.i_hclk_nx_rdwt		            (hclk_nx_rdwt		 	        ),
/*input wire	[15:0]	*/	.i_hclk_nx_datacnt		        (hclk_nx_datacnt		        ),
/*input wire	[2:0]	*/	.i_hclk_t_sp			        (hclk_t_sp			            ),
/*input wire	[4:0]	*/	.i_hclk_t_hddat		            (hclk_t_hddat		            ),
/*input wire	[4:0]	*/	.i_hclk_t_sudat		            (hclk_t_sudat		            ),
/*input wire	[9:0]	*/	.i_hclk_t_high			        (hclk_t_high			        ),
/*input wire	[9:0]	*/	.i_hclk_t_low			        (hclk_t_low			            ),
/*input wire			*/	.i_hclk_addressing		        (hclk_addressing		        ),
/*input wire			*/	.i_hclk_master			        (hclk_master			        ),
/*input wire			*/	.i_hclk_dma_en			        (hclk_dma_en			        ),
/*input wire			*/	.i_hclk_iic_en			        (hclk_iic_en			        ),
/*input wire            */  .i_hclk_dma_ack_rx              (hclk_dma_ack_rx                ),
/*input wire            */  .i_hclk_dma_ack_tx              (hclk_dma_ack_tx                ),
/*input wire            */  .i_hclk_im_ahb_fifo_rd	        (hclk_im_ahb_fifo_rd	        ),
/*input wire            */  .i_hclk_im_ahb_fifo_wr	        (hclk_im_ahb_fifo_wr	        ),
/*input wire    [4:0]	*/  .i_hclk_entries_tx              (hclk_entries_tx                ),
/*input wire            */  .i_hclk_fifo_full_tx            (hclk_fifo_full_tx              ),
/*input wire            */  .i_hclk_wr_recv                 (hclk_wr_recv                   ),
                                                                                          
/*output wire   [9:0]	*/  .o_clki2c_addr                  (clki2c_addr                    ),
/*output wire           */  .o_clki2c_int_en_byterecv       (clki2c_int_en_byterecv         ),
/*output wire           */  .o_clki2c_iic_rst               (clki2c_iic_rst                 ),
/*output wire           */  .o_clki2c_do_ack                (clki2c_do_ack                  ),
/*output wire           */  .o_clki2c_do_nack               (clki2c_do_nack                 ),
/*output wire           */  .o_clki2c_trans                 (clki2c_trans                   ),
/*output wire           */  .o_clki2c_phase_S               (clki2c_phase_S                 ),
/*output wire           */  .o_clki2c_phase_adr             (clki2c_phase_adr               ),
/*output wire           */  .o_clki2c_phase_dat             (clki2c_phase_dat               ),
/*output wire           */  .o_clki2c_phase_P               (clki2c_phase_P                 ),
/*output wire           */  .o_clki2c_nx_rdwt               (clki2c_nx_rdwt                 ),
/*output wire   [15:0]  */  .o_clki2c_nx_datacnt            (clki2c_nx_datacnt              ),
/*output wire   [4:0]	*/  .o_clki2c_t_hddat               (clki2c_t_hddat                 ),
/*output wire   [4:0]	*/  .o_clki2c_t_sudat               (clki2c_t_sudat                 ),
/*output wire   [9:0]	*/  .o_clki2c_t_high                (clki2c_t_high                  ),
/*output wire   [9:0]	*/  .o_clki2c_t_low                 (clki2c_t_low                   ),
/*output wire           */  .o_clki2c_dma_en                (clki2c_dma_en                  ),
/*output wire           */  .o_clki2c_master                (clki2c_master                  ),
/*output wire           */  .o_clki2c_addressing            (clki2c_addressing              ),
/*output wire           */  .o_clki2c_iic_en                (clki2c_iic_en                  ),
/*output wire           */  .o_clki2c_dma_ack_rx            (clki2c_dma_ack_rx              ),
/*output wire           */  .o_clki2c_dma_ack_tx            (clki2c_dma_ack_tx              ),
/*output wire           */  .o_clki2c_int_st_cmpl           (clki2c_int_st_cmpl             ),
/*output wire           */  .o_clki2c_wr_apb                (clki2c_wr_apb                  ),
/*output wire           */  .o_clki2c_rd_apb                (clki2c_rd_apb                  ),
/*output wire           */  .o_clki2c_clr_apb               (clki2c_clr_apb                 ),
/*output wire   [7:0]	*/  .o_clki2c_wr_data_apb           (clki2c_wr_data_apb             ),
/*output wire           */  .o_clki2c_prefix_period	        (clki2c_prefix_period	        ),
/*output wire           */  .o_clki2c_im_ahb_fifo_rd	    (clki2c_im_ahb_fifo_rd	        ),
/*output wire           */  .o_clki2c_im_ahb_fifo_wr	    (clki2c_im_ahb_fifo_wr	        ),
/*output wire   [2:0]	*/  .o_clki2c_t_sp                  (clki2c_t_sp                    ),
/*output wire   [4:0]	*/  .o_clki2c_entries_tx            (clki2c_entries_tx              ),
/*output wire           */  .o_clki2c_fifo_full_tx          (clki2c_fifo_full_tx            ),
/*output wire           */  .o_clki2c_wr_recv               (clki2c_wr_recv                 ),
                                                                                          
/*input wire            */  .i_clki2c_idle_state            (clki2c_idle_state              ),
/*input wire            */  .i_clki2c_dma_req_rx            (clki2c_dma_req_rx              ),
/*input wire            */  .i_clki2c_dma_req_tx            (clki2c_dma_req_tx              ),
/*input wire            */  .i_clki2c_st_busbusy            (clki2c_st_busbusy              ),
/*input wire            */  .i_clki2c_st_ack                (clki2c_st_ack                  ),
/*input wire            */  .i_clki2c_start_cond            (clki2c_start_cond              ),
/*input wire            */  .i_clki2c_stop_cond             (clki2c_stop_cond               ),
/*input wire            */  .i_clki2c_st_gencall            (clki2c_st_gencall              ),
/*input wire            */  .i_clki2c_rdwt                  (clki2c_rdwt                    ),
/*input wire            */  .i_clki2c_rdwt_changed			(clki2c_rdwt_changed			),
/*input wire   [15:0]	*/  .i_clki2c_datacnt               (clki2c_datacnt                 ),
/*input wire            */  .i_clki2c_cmpl_trig             (clki2c_cmpl_trig               ),
/*input wire            */  .i_clki2c_byterecv_trig         (clki2c_byterecv_trig           ),
/*input wire            */  .i_clki2c_bytetrans_trig        (clki2c_bytetrans_trig          ),
/*input wire            */  .i_clki2c_arblose_trig          (clki2c_arblose_trig            ),
/*input wire            */  .i_clki2c_addrhit_trig          (clki2c_addrhit_trig            ),
/*input wire    [7:0]	*/  .i_clki2c_wr_data_cntlr         (clki2c_wr_data_cntlr           ),
/*input wire            */  .i_clki2c_wr_cntlr              (clki2c_wr_cntlr                ),
/*input wire            */  .i_clki2c_rd_cntlr              (clki2c_rd_cntlr                ),
/*input wire            */  .i_clki2c_slv_hit               (clki2c_slv_hit                 ),
/*input wire    [4:0]	*/  .i_clki2c_entries_rx            (clki2c_entries_rx              ),
/*input wire    [2:0]	*/  .i_clki2c_bit_cnt               (clki2c_bit_cnt                 ),
/*input wire            */  .i_clki2c_sda                   (clki2c_sda                     ),
/*input wire            */  .i_clki2c_scl                   (clki2c_scl                     ),
/*input wire            */  .i_clki2c_clr_cntlr             (clki2c_clr_cntlr               ),
                                                                                          
/*output wire			*/	.o_fclk_start_cond		        (fclk_start_cond		        ),
/*output wire			*/	.o_hclk_sda			            (hclk_sda			            ),
/*output wire			*/	.o_hclk_scl			            (hclk_scl			            ),
/*output wire			*/	.o_hclk_st_gencall		        (hclk_st_gencall		        ),
/*output wire			*/	.o_hclk_st_busbusy		        (hclk_st_busbusy		        ),
/*output wire			*/	.o_hclk_st_ack			        (hclk_st_ack			        ),
/*output wire			*/	.o_hclk_rdwt		            (hclk_rdwt		                ),
/*output wire			*/	.o_hclk_rdwt_changed			(hclk_rdwt_changed				),
/*output wire	[15:0]	*/	.o_hclk_datacnt		            (hclk_datacnt		            ),
/*output wire			*/	.o_hclk_cmpl_trig		        (hclk_cmpl_trig		            ),
/*output wire			*/	.o_hclk_byterecv_trig	        (hclk_byterecv_trig	            ),
/*output wire			*/	.o_hclk_bytetrans_trig	        (hclk_bytetrans_trig	        ),
/*output wire			*/	.o_hclk_stop_cond		        (hclk_stop_cond		            ),
/*output wire			*/	.o_hclk_arblose_trig	        (hclk_arblose_trig	            ),
/*output wire			*/	.o_hclk_addrhit_trig	        (hclk_addrhit_trig	            ),
/*output wire	[2:0]	*/	.o_hclk_bit_cnt		            (hclk_bit_cnt		            ),
/*output wire			*/	.o_hclk_slv_hit		            (hclk_slv_hit		            ),
/*output wire			*/	.o_hclk_idle_state              (hclk_idle_state                ),
/*output wire   [4:0]	*/  .o_hclk_entries_rx              (hclk_entries_rx                ),
/*output wire           */  .o_hclk_dma_req_rx              (hclk_dma_req_rx                ),
/*output wire           */  .o_hclk_dma_req_tx              (hclk_dma_req_tx                ),
/*output wire   [7:0]	*/  .o_hclk_wr_data_cntlr           (hclk_wr_data_cntlr             ),
/*output wire           */  .o_hclk_wr_cntlr                (hclk_wr_cntlr                  ),
/*output wire           */  .o_hclk_rd_cntlr                (hclk_rd_cntlr                  ),
/*output wire           */  .o_hclk_clr_cntlr               (hclk_clr_cntlr                 )
);  // i2c_cdc 

atciic100_ctrl u_ctrl (
/*input wire			*/	.HCLK			                (HCLK			                ),
/*input wire            */  .pclk                           (CLK_I2C                        ),
/*input wire            */  .presetn                        (HRESETn                        ),
/*input wire            */  .scl                            (clki2c_scl                     ),
/*input wire            */  .sda                            (clki2c_sda                     ),
/*input wire [9:0]	    */  .addr                           (clki2c_addr                    ),
/*input wire            */  .int_en_byterecv                (clki2c_int_en_byterecv         ),
/*input wire            */  .iic_rst                        (clki2c_iic_rst                 ),
/*input wire            */  .do_ack                         (clki2c_do_ack                  ),
/*input wire            */  .do_nack                        (clki2c_do_nack                 ),
/*input wire            */  .trans                          (clki2c_trans                   ),
/*input wire            */  .phase_S                        (clki2c_phase_S                 ),
/*input wire            */  .phase_adr                      (clki2c_phase_adr               ),
/*input wire            */  .phase_dat                      (clki2c_phase_dat               ),
/*input wire            */  .phase_P                        (clki2c_phase_P                 ),
/*input wire            */  .nx_rdwt                        (clki2c_nx_rdwt                 ),
/*input wire [15:0]     */  .nx_datacnt                     (clki2c_nx_datacnt              ),
/*input wire [4:0]	    */  .t_hddat                        (clki2c_t_hddat                 ),
/*input wire [4:0]	    */  .t_sudat                        (clki2c_t_sudat                 ),
/*input wire [9:0]	    */  .t_high                         (clki2c_t_high                  ),
/*input wire [9:0]	    */  .t_low                          (clki2c_t_low                   ),
/*input wire            */  .dma_en                         (clki2c_dma_en                  ),
/*input wire            */  .master                         (clki2c_master                  ),
/*input wire            */  .addressing                     (clki2c_addressing              ),
/*input wire            */  .iic_en                         (clki2c_iic_en                  ),
/*input wire            */  .dma_ack_rx                     (clki2c_dma_ack_rx              ),
/*input wire            */  .dma_ack_tx                     (clki2c_dma_ack_tx              ),
/*input wire [7:0]	    */  .fifo_rd_data                   (clki2c_rd_data                 ),
/*input wire            */  .fifo_full                      (clki2c_fifo_full               ),
/*input wire            */  .fifo_empty                     (clki2c_fifo_empty              ),
/*input wire [4:0]	    */  .fifo_entries                   (clki2c_entries_tx              ),
/*input wire            */  .int_st_cmpl                    (clki2c_int_st_cmpl             ),
/*input wire            */  .scl_falling                    (clki2c_scl_falling             ),
/*input wire            */  .scl_rising                     (clki2c_scl_rising              ),
/*input wire            */  .sda_falling                    (clki2c_sda_falling             ),
/*input wire            */  .sda_rising                     (clki2c_sda_rising              ),
/*input wire            */  .wr_recv                        (clki2c_wr_recv                 ),
/*output wire           */  .idle_state                     (clki2c_idle_state              ),
/*output wire           */  .scl_o                          (clki2c_scl_o                   ),
/*output wire           */  .sda_o                          (clki2c_sda_o                   ),
/*output wire           */  .dma_req_rx                     (clki2c_dma_req_rx              ),
/*output wire           */  .dma_req_tx                     (clki2c_dma_req_tx              ),
/*output wire           */  .st_busbusy                     (clki2c_st_busbusy              ),
/*output wire           */  .st_ack                         (clki2c_st_ack                  ),
/*output wire           */  .start_cond                     (clki2c_start_cond              ),
/*output wire           */  .stop_cond                      (clki2c_stop_cond               ),
/*output wire           */  .st_gencall                     (clki2c_st_gencall              ),
/*output wire           */  .rdwt                           (clki2c_rdwt                    ),
/*output wire           */  .rdwt_changed					(clki2c_rdwt_changed			),
/*output wire [15:0]	*/  .datacnt                        (clki2c_datacnt                 ),
/*output wire           */  .cmpl_trig                      (clki2c_cmpl_trig               ),
/*output wire           */  .byterecv_trig                  (clki2c_byterecv_trig           ),
/*output wire           */  .bytetrans_trig                 (clki2c_bytetrans_trig          ),
/*output wire           */  .arblose_trig                   (clki2c_arblose_trig            ),
/*output wire           */  .addrhit_trig                   (clki2c_addrhit_trig            ),
/*output wire [7:0]	    */  .fifo_wr_data                   (clki2c_wr_data_cntlr           ),
/*output wire           */  .fifo_wr                        (clki2c_wr_cntlr                ),
/*output wire           */  .fifo_rd                        (clki2c_rd_cntlr                ),
/*output wire           */  .fifo_clr                       (clki2c_clr_cntlr               ),
/*output wire           */  .slv_hit                        (clki2c_slv_hit                 ),
/*output wire [2:0]	    */  .bit_cnt                        (clki2c_bit_cnt                 ),
/*output wire           */  .fifo_half_mask                 (clki2c_fifo_half_mask          )
);  // u_ctrl

//atciic100_fifo u_fifo (
///*input wire            */  .clk                            (CLK_I2C                        ),
///*input wire            */  .reset_n                        (HRESETn                        ),
///*input wire            */  .wr_apb                         (clki2c_wr_apb                  ),
///*input wire            */  .wr_cntlr                       (clki2c_wr_cntlr                ),
///*input wire            */  .rd_apb                         (clki2c_rd_apb                  ),
///*input wire            */  .rd_cntlr                       (clki2c_rd_cntlr                ),
///*input wire            */  .clr_apb                        (clki2c_clr_apb                 ),
///*input wire            */  .clr_cntlr                      (clki2c_clr_cntlr               ),
///*input wire [7:0]	    */  .wr_data_apb                    (clki2c_wr_data_apb             ),
///*input wire [7:0]	    */  .wr_data_cntlr                  (clki2c_wr_data_cntlr           ),
///*output wire           */  .full                           (/*clki2c_fifo_full      */         ),
///*output wire           */  .empty                          (/*clki2c_fifo_empty     */         ),
///*output wire           */  .half_full                      (/*clki2c_fifo_half_full */         ),
///*output wire           */  .half_empty                     (/*clki2c_fifo_half_empty*/         ),
///*output wire [4:0]	    */  .entries                        (/*clki2c_entries        */         ),
///*output wire [7:0]	    */  .rd_data                        (/*clki2c_rd_data        */         ),
//                          // From i2c ahb master
///*input wire            */  .i_prefix_period	            (clki2c_prefix_period	        ),
///*input wire            */  .i_im_ahb_fifo_rd	            (clki2c_im_ahb_fifo_rd	        ),
///*input wire            */  .i_im_ahb_fifo_wr	            (clki2c_im_ahb_fifo_wr	        ),
///*input wire            */  .i_fifo_half_mask               (clki2c_fifo_half_mask          )
//);  // u_fifo


wire hclk_fifo_clr      = hclk_clr_apb | hclk_clr_cntlr ;
wire clki2c_fifo_clr    = clki2c_clr_apb | clki2c_clr_cntlr ;

// Async FIFO for Rx (Host write) 
i2c_async_fifo #(
	.N(8)	// FIFO Width
)
async_fifo_rx_U0 (         // wr: CLK_I2C,     rd: HCLK
/* input  wire          */ .test_mode                       (TE                             ),
/* input  wire          */ .rst_n                           (HRESETn                        ),
/* input  wire          */ .in_clk                          (CLK_I2C                        ),   // write clock
/* input  wire          */ .out_clk                         (HCLK                           ),   // read clock
/* input  wire          */ .fifo_write                      (clki2c_wr_cntlr                ),   // in_clk  domain. wr
/* input  wire [4:0]    */ .af_threshold                    ({`ATCIIC100_INDEX_WIDTH{1'b1}} ),   // in_clk  domain. full out = (wr_ptr-rd_ptr) > 'threshold'
/* input  wire [7:0]    */ .data_in                         (clki2c_wr_data_cntlr           ),   // in_clk  domain. wr_data
/* input  wire          */ .fifo_flush                      (hclk_fifo_clr                  ),   // out_clk domain. pointer reset for both wr_ptr & rd_ptr. empty=1 after flush=1
/* input  wire          */ .fifo_read                       (hclk_rd_apb                    ),   // out_clk domain. rd
/* output wire          */ .fifo_full_req                   (clki2c_fifo_full_rx            ),   // in_clk  domain. fifo_full
/* output wire          */ .fifo_inpempty                   (clki2c_fifo_empty_rx           ),   // in_clk  domain. fifo_empty
/* output wire          */ .fifo_outempty                   (hclk_fifo_empty_rx             ),   // out_clk domain. fifo_empty
/* output wire [4:0]    */ .diff                            (clki2c_entries_rx              ),   // in_clk  domain. diff = wr_ptr-rd_ptr
/* output wire [7:0]    */ .data_out                        (hclk_rd_data                   ),   // out_clk domain. rd_data
/* output wire          */ .fifo_half_full                  (clki2c_fifo_half_full_rx       ),   // in_clk  domain. fifo_half_full
/* output wire          */ .fifo_half_empty                 (                               )    // out_clk domain. fifo_half_empty    
);

// Async FIFO for Tx (Host read)
i2c_async_fifo #(
	.N(8)	// FIFO Width
)
async_fifo_tx_U0 (         // wr: HCLK,     rd: CLK_I2C
/* input  wire          */ .test_mode						(TE                             ),
/* input  wire          */ .rst_n                           (HRESETn                        ),
/* input  wire          */ .in_clk                          (HCLK                           ),   // write clock
/* input  wire          */ .out_clk                         (CLK_I2C                        ),   // read clock
/* input  wire          */ .fifo_write                      (hclk_wr_apb                    ),   // in_clk  domain. wr
/* input  wire [4:0]    */ .af_threshold                    ({`ATCIIC100_INDEX_WIDTH{1'b1}} ),   // in_clk  domain. full out = (wr_ptr-rd_ptr) > 'threshold'
/* input  wire [7:0]    */ .data_in                         (hclk_wr_data_apb               ),   // in_clk  domain. wr_data
/* input  wire          */ .fifo_flush                      (clki2c_fifo_clr                ),   // out_clk domain. pointer reset for both wr_ptr & rd_ptr. empty=1 after flush=1
/* input  wire          */ .fifo_read                       (clki2c_rd_cntlr                ),   // out_clk domain. rd
/* output wire          */ .fifo_full_req                   (hclk_fifo_full_tx              ),   // in_clk  domain. fifo_full
/* output wire          */ .fifo_inpempty                   (hclk_fifo_empty_tx             ),   // in_clk  domain. fifo_empty
/* output wire          */ .fifo_outempty                   (clki2c_fifo_empty_tx           ),   // out_clk domain. fifo_empty
/* output wire [4:0]    */ .diff                            (hclk_entries_tx                ),   // in_clk  domain. diff = wr_ptr-rd_ptr
/* output wire [7:0]    */ .data_out                        (clki2c_rd_data                 ),   // out_clk domain. rd_data
/* output wire          */ .fifo_half_full                  (                               ),   // in_clk  domain. fifo_half_full
/* output wire          */ .fifo_half_empty                 (clki2c_fifo_half_empty_tx      )    // out_clk domain. fifo_half_empty    
);

atciic100_gsf u_sda_gsf (
/*input wire            */  .pclk                           (CLK_I2C                        ),
/*input wire            */  .presetn                        (HRESETn                        ),
/*input wire [2:0]	    */  .t_sp                           (clki2c_t_sp                    ),
/*input wire            */  .I                              (sda_i                          ),
/*output wire           */  .O                              (clki2c_sda                     ),
/*output wire           */  .rising_edge                    (clki2c_sda_rising              ),
/*output wire           */  .falling_edge                   (clki2c_sda_falling             )
);  

atciic100_gsf u_scl_gsf (
/*input wire            */  .pclk                           (CLK_I2C                        ),
/*input wire            */  .presetn                        (HRESETn                        ),
/*input wire [2:0]	    */  .t_sp                           (clki2c_t_sp                    ),
/*input wire            */  .I                              (scl_i                          ),
/*output wire           */  .O                              (clki2c_scl                     ),
/*output wire           */  .rising_edge                    (clki2c_scl_rising              ),
/*output wire           */  .falling_edge                   (clki2c_scl_falling             )
);

endmodule
