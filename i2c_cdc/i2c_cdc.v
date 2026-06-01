
`include "atciic100_config.vh"
`include "atciic100_const.vh"

module i2c_cdc (

    input   wire            HRESETn                         ,
    input   wire            FCLK	                        , 
    input   wire            HCLK	                        ,  
    input   wire            CLK_I2C                         ,  
    input   wire            cdc_en                          ,
    output  wire            hclk_im_ahb_fifo_wr_mnt         ,

	input   wire            i_si2c_intr_wakeup_i2c          ,
	input   wire    [7:0]	i_si2c_status                   ,
	output  wire            o_hclk_si2c_intr_wakeup_i2c     ,
	output  wire    [7:0]   o_hclk_si2c_status              ,

// ----------------------------------------------------------------------------------

    input   wire			i_hclk_int_st_cmpl	            ,
    input   wire         	i_hclk_prefix_period	        ,
    input   wire	[9:0]	i_hclk_addr			            ,
    input   wire			i_hclk_int_en_byterecv          ,
    input   wire			i_hclk_iic_rst		            ,
    input   wire			i_hclk_clr_apb		            ,
    input   wire			i_hclk_do_ack			        ,
    input   wire			i_hclk_do_nack		            ,
    input   wire			i_hclk_trans			        ,
    input   wire			i_hclk_wr_apb			        ,
    input   wire			i_hclk_rd_apb			        ,
    input   wire	[7:0]	i_hclk_wr_data_apb	            ,
    input   wire			i_hclk_phase_S		            ,
    input   wire			i_hclk_phase_adr		        ,
    input   wire			i_hclk_phase_dat		        ,
    input   wire			i_hclk_phase_P		            ,
    input   wire			i_hclk_nx_rdwt			        ,
    input   wire	[15:0]	i_hclk_nx_datacnt		        ,
    input   wire	[2:0]	i_hclk_t_sp			            ,
    input   wire	[4:0]	i_hclk_t_hddat		            ,
    input   wire	[4:0]	i_hclk_t_sudat		            ,
    input   wire	[9:0]	i_hclk_t_high			        ,
    input   wire	[9:0]	i_hclk_t_low			        ,
    input   wire			i_hclk_addressing		        ,
    input   wire			i_hclk_master			        ,
    input   wire			i_hclk_dma_en			        ,
    input   wire			i_hclk_iic_en			        ,
    input   wire            i_hclk_dma_ack_rx               ,
    input   wire            i_hclk_dma_ack_tx               ,
    input   wire            i_hclk_im_ahb_fifo_rd	        ,
    input   wire            i_hclk_im_ahb_fifo_wr	        ,
    input   wire    [`ATCIIC100_INDEX_WIDTH-1:0]   i_hclk_entries_tx               ,
    input   wire            i_hclk_fifo_full_tx	            ,
    input   wire            i_hclk_wr_recv	                ,
    
    output  wire    [9:0]   o_clki2c_addr                   ,
    output  wire            o_clki2c_int_en_byterecv        ,
    output  wire            o_clki2c_iic_rst                ,
    output  wire            o_clki2c_do_ack                 ,
    output  wire            o_clki2c_do_nack                ,
    output  wire            o_clki2c_trans                  ,
    output  wire            o_clki2c_phase_S                ,
    output  wire            o_clki2c_phase_adr              ,
    output  wire            o_clki2c_phase_dat              ,
    output  wire            o_clki2c_phase_P                ,
    output  wire            o_clki2c_nx_rdwt                ,
    output  wire    [15:0]  o_clki2c_nx_datacnt             ,
    output  wire    [4:0]   o_clki2c_t_hddat                ,
    output  wire    [4:0]   o_clki2c_t_sudat                ,
    output  wire    [9:0]   o_clki2c_t_high                 ,
    output  wire    [9:0]   o_clki2c_t_low                  ,
    output  wire            o_clki2c_dma_en                 ,
    output  wire            o_clki2c_master                 ,
    output  wire            o_clki2c_addressing             ,
    output  wire            o_clki2c_iic_en                 ,
    output  wire            o_clki2c_dma_ack_rx             ,
    output  wire            o_clki2c_dma_ack_tx             ,
    output  wire            o_clki2c_int_st_cmpl            ,
    output  wire            o_clki2c_wr_apb                 ,
    output  wire            o_clki2c_rd_apb                 ,
    output  wire            o_clki2c_clr_apb                ,
    output  wire    [7:0]   o_clki2c_wr_data_apb            ,
    output  wire            o_clki2c_prefix_period	        ,
    output  wire            o_clki2c_im_ahb_fifo_rd	        ,
    output  wire            o_clki2c_im_ahb_fifo_wr	        ,
    output  wire    [2:0]   o_clki2c_t_sp                   , 
    output  wire    [`ATCIIC100_INDEX_WIDTH-1:0]   o_clki2c_entries_tx             ,
    output  wire            o_clki2c_fifo_full_tx	        ,
    output  wire            o_clki2c_wr_recv	            ,

    input   wire            i_clki2c_start_cond             ,
    input   wire            i_clki2c_fifo_full              ,
    input   wire            i_clki2c_fifo_half_full         ,
    input   wire            i_clki2c_fifo_half_empty        ,
    input   wire            i_clki2c_idle_state             ,
    input   wire            i_clki2c_dma_req_rx             ,
    input   wire            i_clki2c_dma_req_tx             ,
    input   wire            i_clki2c_st_busbusy             ,
    input   wire            i_clki2c_st_ack                 ,
    input   wire            i_clki2c_stop_cond              ,
    input   wire            i_clki2c_st_gencall             ,
    input   wire            i_clki2c_rdwt                   ,
    input   wire            i_clki2c_rdwt_changed			,
    input   wire    [15:0]  i_clki2c_datacnt                ,
    input   wire            i_clki2c_cmpl_trig              ,
    input   wire            i_clki2c_byterecv_trig          ,
    input   wire            i_clki2c_bytetrans_trig         ,
    input   wire            i_clki2c_arblose_trig           ,
    input   wire            i_clki2c_addrhit_trig           ,
    input   wire    [7:0]   i_clki2c_wr_data_cntlr          ,
    input   wire            i_clki2c_wr_cntlr               ,
    input   wire            i_clki2c_rd_cntlr               ,
    input   wire            i_clki2c_slv_hit                ,
    input   wire    [`ATCIIC100_INDEX_WIDTH-1:0]   i_clki2c_entries_rx             ,
    input   wire    [2:0]   i_clki2c_bit_cnt                ,
    input   wire            i_clki2c_sda                    ,
    input   wire            i_clki2c_scl                    ,
    input   wire            i_clki2c_clr_cntlr              ,
    
    output  wire			o_fclk_start_cond		        ,
    output  wire		    o_hclk_fifo_full		        ,
    output  wire		    o_hclk_fifo_half_full	        ,
    output  wire		    o_hclk_fifo_half_empty          ,
    output  wire			o_hclk_sda			            ,
    output  wire			o_hclk_scl			            ,
    output  wire			o_hclk_st_gencall		        ,
    output  wire			o_hclk_st_busbusy		        ,
    output  wire			o_hclk_st_ack			        ,
    output  wire			o_hclk_rdwt		                ,
    output  wire			o_hclk_rdwt_changed				,
    output  wire	[15:0]	o_hclk_datacnt		            ,
    output  wire			o_hclk_cmpl_trig		        ,
    output  wire			o_hclk_byterecv_trig	        ,
    output  wire			o_hclk_bytetrans_trig	        ,
    output  wire			o_hclk_stop_cond		        ,
    output  wire			o_hclk_arblose_trig	            ,
    output  wire			o_hclk_addrhit_trig	            ,
    output  wire	[2:0]	o_hclk_bit_cnt		            ,
    output  wire			o_hclk_slv_hit		            ,
    output  wire			o_hclk_idle_state               ,
    output  wire    [`ATCIIC100_INDEX_WIDTH-1:0]	o_hclk_entries_rx               ,
    output  wire            o_hclk_dma_req_rx               ,
    output  wire            o_hclk_dma_req_tx               ,
    output  wire    [7:0]   o_hclk_wr_data_cntlr            ,
    output  wire            o_hclk_wr_cntlr                 ,
    output  wire            o_hclk_rd_cntlr                 ,
    output  wire            o_hclk_clr_cntlr                 

);

////// CLK_I2C to FCLK Domain            
reg         r0_fclk_start_cond		            ;
reg         r1_fclk_start_cond		            ;
reg         r2_fclk_start_cond		            ;

////// SCL to HCLK Domain                    
reg         r0_hclk_si2c_intr_wakeup_i2c        ;
reg [7:0]   r0_hclk_si2c_status                 ;

reg         r1_hclk_si2c_intr_wakeup_i2c        ;
reg [7:0]	r1_hclk_si2c_status                 ;

////// CLK_I2C to HCLK Domain            
reg         r0_hclk_fifo_full		            ;
reg         r0_hclk_fifo_half_full	            ;
reg         r0_hclk_fifo_half_empty             ;
reg         r0_hclk_sda			                ;
reg         r0_hclk_scl			                ;
reg         r0_hclk_st_gencall		            ;
reg         r0_hclk_st_busbusy		            ;
reg         r0_hclk_st_ack			            ;
reg         r0_hclk_rdwt		                ;
reg         r0_hclk_rdwt_changed				;
reg [15:0]  r0_hclk_datacnt		                ;
reg         r0_hclk_cmpl_trig		            ;
reg         r0_hclk_byterecv_trig	            ;
reg         r0_hclk_bytetrans_trig	            ;
reg         r0_hclk_stop_cond		            ;
reg         r0_hclk_arblose_trig	            ;
reg         r0_hclk_addrhit_trig	            ;
reg [2:0]   r0_hclk_bit_cnt		                ;
reg         r0_hclk_slv_hit		                ;
reg         r0_hclk_idle_state                  ;
reg [`ATCIIC100_INDEX_WIDTH-1:0]   r0_hclk_entries_rx                  ;
reg         r0_hclk_dma_req_rx                  ;
reg         r0_hclk_dma_req_tx                  ;
reg [7:0]   r0_hclk_wr_data_cntlr               ;
reg         r0_hclk_wr_cntlr                    ;
reg         r0_hclk_rd_cntlr                    ;
reg         r0_hclk_clr_cntlr                   ;

reg         r1_hclk_fifo_full		            ;
reg         r1_hclk_fifo_half_full	            ;
reg         r1_hclk_fifo_half_empty             ;
reg         r1_hclk_sda			                ;
reg         r1_hclk_scl			                ;
reg         r1_hclk_st_gencall		            ;
reg         r1_hclk_st_busbusy		            ;
reg         r1_hclk_st_ack			            ;
reg         r1_hclk_rdwt		                ;
reg         r1_hclk_rdwt_changed 				;
reg [15:0]  r1_hclk_datacnt		                ;
reg         r1_hclk_cmpl_trig		            ;
reg         r1_hclk_byterecv_trig	            ;
reg         r1_hclk_bytetrans_trig	            ;
reg         r1_hclk_stop_cond		            ;
reg         r1_hclk_arblose_trig	            ;
reg         r1_hclk_addrhit_trig	            ;
reg [2:0]   r1_hclk_bit_cnt		                ;
reg         r1_hclk_slv_hit		                ;
reg         r1_hclk_idle_state                  ;
reg [`ATCIIC100_INDEX_WIDTH-1:0]   r1_hclk_entries_rx                  ;
reg         r1_hclk_dma_req_rx                  ;
reg         r1_hclk_dma_req_tx                  ;
reg [7:0]   r1_hclk_wr_data_cntlr               ;
reg         r1_hclk_wr_cntlr                    ;
reg         r1_hclk_rd_cntlr                    ;
reg         r1_hclk_clr_cntlr                   ;

    // one-pulse signals
reg         r2_hclk_clr_cntlr                   ;
reg         r2_hclk_wr_cntlr                    ;
reg         r2_hclk_rd_cntlr                    ;
reg         r2_hclk_addrhit_trig	            ;
reg         r2_hclk_cmpl_trig		            ;
reg         r2_hclk_byterecv_trig	            ;
reg         r2_hclk_bytetrans_trig	            ;
reg         r2_hclk_arblose_trig	            ;
reg         r2_hclk_slv_hit		                ;
reg         r2_hclk_st_gencall		            ;
reg         r2_hclk_stop_cond		            ;

////// HCLK to CLK_I2C Domain       
reg [9:0]	r0_clki2c_addr                      ;
reg         r0_clki2c_int_en_byterecv           ;
reg         r0_clki2c_iic_rst                   ;
reg         r0_clki2c_do_ack                    ;
reg         r0_clki2c_do_nack                   ;
reg         r0_clki2c_trans                     ;
reg         r0_clki2c_phase_S                   ;
reg         r0_clki2c_phase_adr                 ;
reg         r0_clki2c_phase_dat                 ;
reg         r0_clki2c_phase_P                   ;
reg         r0_clki2c_nx_rdwt                   ;
reg [15:0]	r0_clki2c_nx_datacnt                ;
reg [4:0]	r0_clki2c_t_hddat                   ;
reg [4:0]	r0_clki2c_t_sudat                   ;
reg [9:0]	r0_clki2c_t_high                    ;
reg [9:0]	r0_clki2c_t_low                     ;
reg         r0_clki2c_dma_en                    ;
reg         r0_clki2c_master                    ;
reg         r0_clki2c_addressing                ;
reg         r0_clki2c_iic_en                    ;
reg         r0_clki2c_dma_ack_rx                ;
reg         r0_clki2c_dma_ack_tx                ;
reg         r0_clki2c_int_st_cmpl               ;
reg         r0_clki2c_wr_apb                    ;
reg         r0_clki2c_rd_apb                    ;
reg         r0_clki2c_clr_apb                   ;
reg [7:0]	r0_clki2c_wr_data_apb               ;
reg         r0_clki2c_prefix_period	            ;
reg         r0_clki2c_im_ahb_fifo_rd	        ;
reg         r0_clki2c_im_ahb_fifo_wr	        ;
reg [2:0]	r0_clki2c_t_sp                      ;
reg [`ATCIIC100_INDEX_WIDTH-1:0]	r0_clki2c_entries_tx                ;
reg         r0_clki2c_fifo_full_tx	            ;
reg         r0_clki2c_wr_recv	                ;

reg [9:0]	r1_clki2c_addr                      ;
reg         r1_clki2c_int_en_byterecv           ;
reg         r1_clki2c_iic_rst                   ;
reg         r1_clki2c_do_ack                    ;
reg         r1_clki2c_do_nack                   ;
reg         r1_clki2c_trans                     ;
reg         r1_clki2c_phase_S                   ;
reg         r1_clki2c_phase_adr                 ;
reg         r1_clki2c_phase_dat                 ;
reg         r1_clki2c_phase_P                   ;
reg         r1_clki2c_nx_rdwt                   ;
reg [15:0]	r1_clki2c_nx_datacnt                ;
reg [4:0]	r1_clki2c_t_hddat                   ;
reg [4:0]	r1_clki2c_t_sudat                   ;
reg [9:0]	r1_clki2c_t_high                    ;
reg [9:0]	r1_clki2c_t_low                     ;
reg         r1_clki2c_dma_en                    ;
reg         r1_clki2c_master                    ;
reg         r1_clki2c_addressing                ;
reg         r1_clki2c_iic_en                    ;
reg         r1_clki2c_dma_ack_rx                ;
reg         r1_clki2c_dma_ack_tx                ;
reg         r1_clki2c_int_st_cmpl               ;
reg         r1_clki2c_wr_apb                    ;
reg         r1_clki2c_rd_apb                    ;
reg         r1_clki2c_clr_apb                   ;
reg [7:0]	r1_clki2c_wr_data_apb               ;
reg         r1_clki2c_prefix_period	            ;
reg         r1_clki2c_im_ahb_fifo_rd	        ;
reg         r1_clki2c_im_ahb_fifo_wr	        ;
reg [2:0]	r1_clki2c_t_sp                      ;
reg [`ATCIIC100_INDEX_WIDTH-1:0]	r1_clki2c_entries_tx                ;
reg         r1_clki2c_fifo_full_tx	            ;
reg         r1_clki2c_wr_recv	                ;

    // one-pulse signals
reg         r2_clki2c_wr_apb                    ;
reg         r2_clki2c_rd_apb                    ;
reg         r2_clki2c_im_ahb_fifo_rd	        ;
reg         r2_clki2c_im_ahb_fifo_wr	        ;
reg [7:0]	r2_clki2c_wr_data_apb               ;
reg         r2_clki2c_clr_apb                   ;
reg         r2_clki2c_iic_rst                   ;
reg         r2_clki2c_do_ack                    ;
reg         r2_clki2c_do_nack                   ;
reg         r2_clki2c_trans                     ;

//// non-constant signal hand-shaking
reg         r0_clki2c_addrhit_trig_rqack        ;   
reg         r0_clki2c_arblose_trig_rqack        ;   
reg         r0_clki2c_byterecv_trig_rqack       ;   
reg         r0_clki2c_bytetrans_trig_rqack      ;   
reg         r0_clki2c_cmpl_trig_rqack           ;   
reg         r0_clki2c_rd_cntlr_rqack            ;   
reg         r0_clki2c_slv_hit_rqack             ;   
reg         r0_clki2c_st_gencall_rqack          ;   
reg         r0_clki2c_start_cond_rqack          ;   
reg         r0_clki2c_stop_cond_rqack           ;   
reg         r0_clki2c_wr_cntlr_rqack            ;   
reg         r0_clki2c_clr_cntlr_rqack           ;   
//reg         r0_clki2c_dma_req_rx_rqack          ;
//reg         r0_clki2c_dma_req_tx_rqack          ;
//reg         r0_clki2c_fifo_empty_rqack          ;
//reg         r0_clki2c_fifo_full_rqack           ;
//reg         r0_clki2c_fifo_half_empty_rqack     ;
//reg         r0_clki2c_fifo_half_full_rqack      ;
//reg         r0_clki2c_idle_state_rqack          ;
//reg         r0_clki2c_rd_data_rqack             ;   
//reg         r0_clki2c_scl_rqack                 ;
//reg         r0_clki2c_sda_rqack                 ;
//reg         r0_clki2c_st_ack_rqack              ;
//reg         r0_clki2c_st_busbusy_rqack          ;
//reg         r0_clki2c_wr_data_cntlr_rqack       ;
//reg         r0_clki2c_entries_rx_rqack          ;   

reg         r1_clki2c_addrhit_trig_rqack        ;
reg         r1_clki2c_arblose_trig_rqack        ;
reg         r1_clki2c_byterecv_trig_rqack       ;
reg         r1_clki2c_bytetrans_trig_rqack      ;
reg         r1_clki2c_cmpl_trig_rqack           ;
reg         r1_clki2c_idle_state_rqack          ;
reg         r1_clki2c_rd_cntlr_rqack            ;
reg         r1_clki2c_slv_hit_rqack             ;
reg         r1_clki2c_st_gencall_rqack          ;
reg         r1_clki2c_start_cond_rqack          ;
reg         r1_clki2c_stop_cond_rqack           ;
reg         r1_clki2c_wr_cntlr_rqack            ;
reg         r1_clki2c_clr_cntlr_rqack           ;
//reg         r1_clki2c_dma_req_rx_rqack          ;
//reg         r1_clki2c_dma_req_tx_rqack          ;
//reg         r1_clki2c_fifo_empty_rqack          ;
//reg         r1_clki2c_fifo_full_rqack           ;
//reg         r1_clki2c_fifo_half_empty_rqack     ;
//reg         r1_clki2c_fifo_half_full_rqack      ;
//reg         r1_clki2c_rd_data_rqack             ;
//reg         r1_clki2c_scl_rqack                 ;
//reg         r1_clki2c_sda_rqack                 ;
//reg         r1_clki2c_st_ack_rqack              ;
//reg         r1_clki2c_st_busbusy_rqack          ;
//reg         r1_clki2c_wr_data_cntlr_rqack       ;
//reg         r1_clki2c_entries_rx_rqack          ;

reg         r2_clki2c_addrhit_trig_rqack        ;   
reg         r2_clki2c_arblose_trig_rqack        ;   
reg         r2_clki2c_byterecv_trig_rqack       ;   
reg         r2_clki2c_bytetrans_trig_rqack      ;   
reg         r2_clki2c_cmpl_trig_rqack           ;   
reg         r2_clki2c_rd_cntlr_rqack            ;   
reg         r2_clki2c_slv_hit_rqack             ;   
reg         r2_clki2c_st_gencall_rqack          ;   
reg         r2_clki2c_start_cond_rqack          ;   
reg         r2_clki2c_stop_cond_rqack           ;   
reg         r2_clki2c_wr_cntlr_rqack            ;   
reg         r2_clki2c_clr_cntlr_rqack           ;   

reg         r_clki2c_addrhit_trig               ;   
reg         r_clki2c_arblose_trig               ;   
reg         r_clki2c_byterecv_trig              ;   
reg         r_clki2c_bytetrans_trig             ;   
reg         r_clki2c_cmpl_trig                  ;   
reg         r_clki2c_rd_cntlr                   ;   
reg         r_clki2c_slv_hit                    ;   
reg         r_clki2c_st_gencall                 ;   
reg         r_clki2c_start_cond                 ;   
reg         r_clki2c_stop_cond                  ;   
reg         r_clki2c_wr_cntlr                   ;  
reg         r_clki2c_clr_cntlr                  ;  

reg         r0_hclk_clr_apb_rqack               ;
reg         r0_hclk_do_ack_rqack                ;
reg         r0_hclk_do_nack_rqack               ;
reg         r0_hclk_iic_rst_rqack               ;
reg         r0_hclk_im_ahb_fifo_rd_rqack        ;
reg         r0_hclk_im_ahb_fifo_wr_rqack        ;
reg         r0_hclk_rd_apb_rqack                ;
reg         r0_hclk_trans_rqack                 ;
reg         r0_hclk_wr_apb_rqack                ;
reg         r0_hclk_wr_data_apb_rqack           ;
//reg         r0_hclk_nx_rdwt_rqack               ;
//reg         r0_hclk_nx_datacnt_rqack            ;
reg         r0_hclk_dma_ack_rx_rqack            ;
reg         r0_hclk_dma_ack_tx_rqack            ;
//reg         r0_hclk_int_st_cmpl_rqack           ;
//reg         r0_hclk_prefix_period_rqack         ;
 
reg         r1_hclk_clr_apb_rqack               ;
reg         r1_hclk_do_ack_rqack                ;
reg         r1_hclk_do_nack_rqack               ;
reg         r1_hclk_iic_rst_rqack               ;
reg         r1_hclk_im_ahb_fifo_rd_rqack        ;
reg         r1_hclk_im_ahb_fifo_wr_rqack        ;
reg         r1_hclk_rd_apb_rqack                ;
reg         r1_hclk_trans_rqack                 ;
reg         r1_hclk_wr_apb_rqack                ;
reg         r1_hclk_wr_data_apb_rqack           ;
//reg         r1_hclk_nx_rdwt_rqack               ;
//reg         r1_hclk_nx_datacnt_rqack            ;
//reg         r1_hclk_dma_ack_rx_rqack            ;
reg         r1_hclk_dma_ack_tx_rqack            ;
//reg         r1_hclk_int_st_cmpl_rqack           ;
//reg         r1_hclk_prefix_period_rqack         ;
 
reg         r2_hclk_clr_apb_rqack               ;
reg         r2_hclk_do_ack_rqack                ;
reg         r2_hclk_do_nack_rqack               ;
reg         r2_hclk_iic_rst_rqack               ;
reg         r2_hclk_im_ahb_fifo_rd_rqack        ;
reg         r2_hclk_im_ahb_fifo_wr_rqack        ;
reg         r2_hclk_rd_apb_rqack                ;
reg         r2_hclk_trans_rqack                 ;
reg         r2_hclk_wr_apb_rqack                ;
reg         r2_hclk_wr_data_apb_rqack           ;
//reg         r2_hclk_nx_rdwt_rqack               ;
//reg         r2_hclk_nx_datacnt_rqack            ;
//reg         r2_hclk_dma_ack_rx_rqack            ;
reg         r2_hclk_dma_ack_tx_rqack            ;

//reg         r_hclk_nx_rdwt                      ;
//reg         r_hclk_nx_datacnt                   ;
reg         r_hclk_clr_apb                      ;
reg         r_hclk_do_ack                       ;
reg         r_hclk_do_nack                      ;
reg         r_hclk_iic_rst                      ;
reg         r_hclk_im_ahb_fifo_rd               ;
reg         r_hclk_im_ahb_fifo_wr               ;
reg         r_hclk_rd_apb                       ;
reg         r_hclk_trans                        ;
reg         r_hclk_wr_apb                       ;
//reg         r_hclk_dma_ack_rx                   ;
//reg         r_hclk_dma_ack_tx                   ;
reg [7:0]	r_hclk_wr_data_apb                  ;

wire        rise_fclk_start_cond                ;
wire        rise_hclk_wr_cntlr                  ;
wire        rise_hclk_rd_cntlr                  ;
wire        rise_hclk_clr_cntlr                 ;
wire        rise_hclk_addrhit_trig              ;
wire        rise_hclk_arblose_trig	            ;
wire        rise_hclk_cmpl_trig		            ;
wire        rise_hclk_byterecv_trig	            ;
wire        rise_hclk_bytetrans_trig            ;
wire        rise_hclk_slv_hit                   ;
wire        rise_hclk_st_gencall                ;
wire        rise_hclk_stop_cond                 ;

wire        rise_clki2c_wr_apb                  ;
wire        rise_clki2c_rd_apb                  ;
wire        rise_clki2c_im_ahb_fifo_rd          ;
wire        rise_clki2c_im_ahb_fifo_wr          ;
wire        rise_clki2c_clr_apb                 ;
wire        rise_clki2c_iic_rst                 ;
wire        rise_clki2c_do_ack                  ;
wire        rise_clki2c_do_nack                 ;
wire        rise_clki2c_trans                   ;

// ----------------------------------------------------------------------------------

////// CLK_I2C to FCLK Domain    
always @ (negedge HRESETn or posedge FCLK) begin
    if(!HRESETn) begin
        r0_fclk_start_cond		            <= 'd0 ;
        r1_fclk_start_cond		            <= 'd0 ;
        r2_fclk_start_cond		            <= 'd0 ;
    end
    else begin
        r0_fclk_start_cond		            <= r_clki2c_start_cond	        ;
        r1_fclk_start_cond		            <= r0_fclk_start_cond		    ;
        r2_fclk_start_cond		            <= r1_fclk_start_cond		    ;
    end
end   
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r0_hclk_fifo_full		            <= 'd0 ;
        r0_hclk_fifo_half_full	            <= 'd0 ;
        r0_hclk_fifo_half_empty             <= 'd0 ;
        
        r1_hclk_fifo_full		            <= 'd0 ;
        r1_hclk_fifo_half_full	            <= 'd0 ;
        r1_hclk_fifo_half_empty             <= 'd0 ;
    end
    else begin
        r0_hclk_fifo_full		            <= i_clki2c_fifo_full           ;
        r0_hclk_fifo_half_full	            <= i_clki2c_fifo_half_full      ;
        r0_hclk_fifo_half_empty             <= i_clki2c_fifo_half_empty     ;
        
        r1_hclk_fifo_full		            <= r0_hclk_fifo_full	        ;
        r1_hclk_fifo_half_full	            <= r0_hclk_fifo_half_full       ;
        r1_hclk_fifo_half_empty             <= r0_hclk_fifo_half_empty      ;
    end
end       

//////// FCLK to CLK_I2C Domain    
//always @ (negedge HRESETn or posedge FCLK) begin
//    if(!HRESETn) begin
//        r0_clki2c_fifo_full_rqack           <= 'd0 ;
//        r0_clki2c_fifo_empty_rqack          <= 'd0 ;
//        r0_clki2c_fifo_half_empty_rqack     <= 'd0 ;
//        r0_clki2c_fifo_half_full_rqack      <= 'd0 ;
//        r1_clki2c_fifo_full_rqack           <= 'd0 ;
//        r1_clki2c_fifo_empty_rqack          <= 'd0 ;
//        r1_clki2c_fifo_half_empty_rqack     <= 'd0 ;
//        r1_clki2c_fifo_half_full_rqack      <= 'd0 ;
//    end
//    else begin
//        r0_clki2c_fifo_full_rqack           <= i_hclk_fifo_full_rqack           ;
//        r0_clki2c_fifo_empty_rqack          <= i_hclk_fifo_empty_rqack          ;
//        r0_clki2c_fifo_half_empty_rqack     <= i_hclk_fifo_half_empty_rqack     ;
//        r0_clki2c_fifo_half_full_rqack      <= i_hclk_fifo_half_full_rqack      ;
//        r1_clki2c_fifo_full_rqack           <= r0_clki2c_fifo_full_rqack        ;
//        r1_clki2c_fifo_empty_rqack          <= r0_clki2c_fifo_empty_rqack       ;
//        r1_clki2c_fifo_half_empty_rqack     <= r0_clki2c_fifo_half_empty_rqack  ;
//        r1_clki2c_fifo_half_full_rqack      <= r0_clki2c_fifo_half_full_rqack   ;
//    end
//end     

////// SCL to HCLK Domain     
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r0_hclk_si2c_intr_wakeup_i2c        <= 'd0 ;
        r0_hclk_si2c_status                 <= 'd0 ;
        
        r1_hclk_si2c_intr_wakeup_i2c        <= 'd0 ;
        r1_hclk_si2c_status                 <= 'd0 ;
    end
    else begin
        r0_hclk_si2c_intr_wakeup_i2c        <= i_si2c_intr_wakeup_i2c       ;
        r0_hclk_si2c_status                 <= i_si2c_status                ;
        
        r1_hclk_si2c_intr_wakeup_i2c        <= r0_hclk_si2c_intr_wakeup_i2c ;
        r1_hclk_si2c_status                 <= r0_hclk_si2c_status          ;
    end
end                                                               

////// CLK_I2C to HCLK Domain    
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r0_hclk_sda			                <= 'd0 ;
        r0_hclk_scl			                <= 'd0 ;
        r0_hclk_st_gencall		            <= 'd0 ;
        r0_hclk_st_busbusy		            <= 'd0 ;
        r0_hclk_st_ack			            <= 'd0 ;
        r0_hclk_rdwt		                <= 'd0 ;
        r0_hclk_rdwt_changed				<= 'd0 ;
        r0_hclk_datacnt		                <= 'd0 ;
        r0_hclk_cmpl_trig		            <= 'd0 ;
        r0_hclk_byterecv_trig	            <= 'd0 ;
        r0_hclk_bytetrans_trig	            <= 'd0 ;
        r0_hclk_stop_cond		            <= 'd0 ;
        r0_hclk_arblose_trig	            <= 'd0 ;
        r0_hclk_addrhit_trig	            <= 'd0 ;
        r0_hclk_bit_cnt		                <= 'd0 ;
        r0_hclk_slv_hit		                <= 'd0 ;
        r0_hclk_idle_state                  <= 'd0 ;
        r0_hclk_entries_rx                  <= 'd0 ;
        r0_hclk_dma_req_rx                  <= 'd0 ;
        r0_hclk_dma_req_tx                  <= 'd0 ;
        r0_hclk_wr_data_cntlr               <= 'd0 ;
        r0_hclk_wr_cntlr                    <= 'd0 ;
        r0_hclk_rd_cntlr                    <= 'd0 ;
        r0_hclk_clr_cntlr                   <= 'd0 ;
        
        r1_hclk_sda			                <= 'd0 ;
        r1_hclk_scl			                <= 'd0 ;
        r1_hclk_st_gencall		            <= 'd0 ;
        r1_hclk_st_busbusy		            <= 'd0 ;
        r1_hclk_st_ack			            <= 'd0 ;
        r1_hclk_rdwt		                <= 'd0 ;
        r1_hclk_rdwt_changed				<= 'd0 ;
        r1_hclk_datacnt		                <= 'd0 ;
        r1_hclk_cmpl_trig		            <= 'd0 ;
        r1_hclk_byterecv_trig	            <= 'd0 ;
        r1_hclk_bytetrans_trig	            <= 'd0 ;
        r1_hclk_stop_cond		            <= 'd0 ;
        r1_hclk_arblose_trig	            <= 'd0 ;
        r1_hclk_addrhit_trig	            <= 'd0 ;
        r1_hclk_bit_cnt		                <= 'd0 ;
        r1_hclk_slv_hit		                <= 'd0 ;
        r1_hclk_idle_state                  <= 'd0 ;
        r1_hclk_entries_rx                  <= 'd0 ;
        r1_hclk_dma_req_rx                  <= 'd0 ;
        r1_hclk_dma_req_tx                  <= 'd0 ;
        r1_hclk_wr_data_cntlr               <= 'd0 ;
        r1_hclk_wr_cntlr                    <= 'd0 ;
        r1_hclk_rd_cntlr                    <= 'd0 ;
        r1_hclk_clr_cntlr                   <= 'd0 ;

        r2_hclk_wr_cntlr                    <= 'd0 ;
        r2_hclk_rd_cntlr                    <= 'd0 ;
        r2_hclk_clr_cntlr                   <= 'd0 ;
        r2_hclk_addrhit_trig	            <= 'd0 ;
        r2_hclk_cmpl_trig		            <= 'd0 ;
        r2_hclk_byterecv_trig	            <= 'd0 ;
        r2_hclk_bytetrans_trig	            <= 'd0 ;
        r2_hclk_arblose_trig	            <= 'd0 ;
        r2_hclk_slv_hit		                <= 'd0 ;
        r2_hclk_st_gencall		            <= 'd0 ;
        r2_hclk_stop_cond		            <= 'd0 ;

        //// non-constant signal hand-shaking
        r0_hclk_clr_apb_rqack               <= 'd0 ;
        r0_hclk_do_ack_rqack                <= 'd0 ;
        r0_hclk_do_nack_rqack               <= 'd0 ;
        r0_hclk_iic_rst_rqack               <= 'd0 ;
        r0_hclk_im_ahb_fifo_rd_rqack        <= 'd0 ;
        r0_hclk_im_ahb_fifo_wr_rqack        <= 'd0 ;
        r0_hclk_rd_apb_rqack                <= 'd0 ;
        r0_hclk_trans_rqack                 <= 'd0 ;
        r0_hclk_wr_apb_rqack                <= 'd0 ;
        r0_hclk_wr_data_apb_rqack           <= 'd0 ;
        //r0_hclk_nx_rdwt_rqack               <= 'd0 ;
        //r0_hclk_nx_datacnt_rqack            <= 'd0 ;
        r0_hclk_dma_ack_rx_rqack            <= 'd0 ;
        r0_hclk_dma_ack_tx_rqack            <= 'd0 ;
        //r0_hclk_int_st_cmpl_rqack           <= 'd0 ;
        //r0_hclk_prefix_period_rqack         <= 'd0 ;
        
        r1_hclk_clr_apb_rqack               <= 'd0 ;
        r1_hclk_do_ack_rqack                <= 'd0 ;
        r1_hclk_do_nack_rqack               <= 'd0 ;
        r1_hclk_iic_rst_rqack               <= 'd0 ;
        r1_hclk_im_ahb_fifo_rd_rqack        <= 'd0 ;
        r1_hclk_im_ahb_fifo_wr_rqack        <= 'd0 ;
        r1_hclk_rd_apb_rqack                <= 'd0 ;
        r1_hclk_trans_rqack                 <= 'd0 ;
        r1_hclk_wr_apb_rqack                <= 'd0 ;
        r1_hclk_wr_data_apb_rqack           <= 'd0 ;
        //r1_hclk_nx_rdwt_rqack               <= 'd0 ;
        //r1_hclk_nx_datacnt_rqack            <= 'd0 ;
        //r1_hclk_dma_ack_rx_rqack            <= 'd0 ;
        r1_hclk_dma_ack_tx_rqack            <= 'd0 ;
        //r1_hclk_int_st_cmpl_rqack           <= 'd0 ;
        //r1_hclk_prefix_period_rqack         <= 'd0 ;

        r2_hclk_do_ack_rqack                <= 'd0 ;
        r2_hclk_do_nack_rqack               <= 'd0 ;
        r2_hclk_iic_rst_rqack               <= 'd0 ;
        r2_hclk_im_ahb_fifo_rd_rqack        <= 'd0 ;
        r2_hclk_im_ahb_fifo_wr_rqack        <= 'd0 ;
        r2_hclk_rd_apb_rqack                <= 'd0 ;
        r2_hclk_trans_rqack                 <= 'd0 ;
        r2_hclk_wr_apb_rqack                <= 'd0 ;
        //r2_hclk_nx_datacnt_rqack            <= 'd0 ;
        r2_hclk_clr_apb_rqack               <= 'd0 ;
        //r2_hclk_dma_ack_rx_rqack            <= 'd0 ;
        r2_hclk_wr_data_apb_rqack           <= 'd0 ;
        r2_hclk_dma_ack_tx_rqack            <= 'd0 ;
    end
    else begin
        r0_hclk_sda			                <= i_clki2c_sda			        ;
        r0_hclk_scl			                <= i_clki2c_scl			        ;
        r0_hclk_st_busbusy		            <= i_clki2c_st_busbusy	        ;
        r0_hclk_st_ack			            <= i_clki2c_st_ack		        ;
        r0_hclk_rdwt		                <= i_clki2c_rdwt		        ;
        r0_hclk_rdwt_changed				<= i_clki2c_rdwt_changed        ;
        r0_hclk_datacnt		                <= i_clki2c_datacnt	            ;
        r0_hclk_bit_cnt		                <= i_clki2c_bit_cnt		        ;
        r0_hclk_idle_state                  <= i_clki2c_idle_state          ;
        r0_hclk_dma_req_rx                  <= i_clki2c_dma_req_rx          ;
        r0_hclk_dma_req_tx                  <= i_clki2c_dma_req_tx          ;
        r0_hclk_wr_data_cntlr               <= i_clki2c_wr_data_cntlr       ;
        r0_hclk_entries_rx                  <= i_clki2c_entries_rx          ;
        ////// non-constant signal hand-shaking @@
        r0_hclk_addrhit_trig	            <= r_clki2c_addrhit_trig        ;
        r0_hclk_arblose_trig	            <= r_clki2c_arblose_trig        ;
        r0_hclk_byterecv_trig	            <= r_clki2c_byterecv_trig       ;
        r0_hclk_bytetrans_trig	            <= r_clki2c_bytetrans_trig      ;
        r0_hclk_cmpl_trig		            <= r_clki2c_cmpl_trig	        ;
        r0_hclk_rd_cntlr                    <= r_clki2c_rd_cntlr            ;
        r0_hclk_slv_hit		                <= r_clki2c_slv_hit		        ;
        r0_hclk_st_gencall		            <= r_clki2c_st_gencall	        ;
        r0_hclk_stop_cond		            <= r_clki2c_stop_cond	        ;
        r0_hclk_wr_cntlr                    <= r_clki2c_wr_cntlr            ;
        r0_hclk_clr_cntlr                   <= r_clki2c_clr_cntlr           ;
        
        r1_hclk_sda			                <= r0_hclk_sda			        ;
        r1_hclk_scl			                <= r0_hclk_scl			        ;
        r1_hclk_st_gencall		            <= r0_hclk_st_gencall		    ;
        r1_hclk_st_busbusy		            <= r0_hclk_st_busbusy		    ;
        r1_hclk_st_ack			            <= r0_hclk_st_ack			    ;
        r1_hclk_rdwt		                <= r0_hclk_rdwt		            ;
        r1_hclk_rdwt_changed				<= r0_hclk_rdwt_changed			;
        r1_hclk_datacnt		                <= r0_hclk_datacnt		        ;
        r1_hclk_cmpl_trig		            <= r0_hclk_cmpl_trig		    ;
        r1_hclk_byterecv_trig	            <= r0_hclk_byterecv_trig	    ;
        r1_hclk_bytetrans_trig	            <= r0_hclk_bytetrans_trig	    ;
        r1_hclk_stop_cond		            <= r0_hclk_stop_cond		    ;
        r1_hclk_arblose_trig	            <= r0_hclk_arblose_trig	        ;
        r1_hclk_addrhit_trig	            <= r0_hclk_addrhit_trig	        ;
        r1_hclk_bit_cnt		                <= r0_hclk_bit_cnt		        ;
        r1_hclk_slv_hit		                <= r0_hclk_slv_hit		        ;
        r1_hclk_idle_state                  <= r0_hclk_idle_state           ;
        r1_hclk_entries_rx                  <= r0_hclk_entries_rx           ;
        r1_hclk_dma_req_rx                  <= r0_hclk_dma_req_rx           ;
        r1_hclk_dma_req_tx                  <= r0_hclk_dma_req_tx           ;
        r1_hclk_wr_data_cntlr               <= r0_hclk_wr_data_cntlr        ;
        r1_hclk_wr_cntlr                    <= r0_hclk_wr_cntlr             ;
        r1_hclk_rd_cntlr                    <= r0_hclk_rd_cntlr             ;
        r1_hclk_clr_cntlr                   <= r0_hclk_clr_cntlr            ;

        r2_hclk_wr_cntlr                    <= r1_hclk_wr_cntlr             ;
        r2_hclk_rd_cntlr                    <= r1_hclk_rd_cntlr             ;
        r2_hclk_clr_cntlr                   <= r1_hclk_clr_cntlr            ;
        r2_hclk_addrhit_trig	            <= r1_hclk_addrhit_trig	        ;
        r2_hclk_cmpl_trig		            <= r1_hclk_cmpl_trig		    ;
        r2_hclk_byterecv_trig	            <= r1_hclk_byterecv_trig	    ;
        r2_hclk_bytetrans_trig	            <= r1_hclk_bytetrans_trig	    ;
        r2_hclk_arblose_trig	            <= r1_hclk_arblose_trig	        ;
        r2_hclk_slv_hit		                <= r1_hclk_slv_hit		        ;
        r2_hclk_st_gencall		            <= r1_hclk_st_gencall		    ;
        r2_hclk_stop_cond		            <= r1_hclk_stop_cond		    ;

        ////// non-constant signal hand-shaking
        r0_hclk_clr_apb_rqack               <= r1_clki2c_clr_apb                ;
        r0_hclk_do_ack_rqack                <= r1_clki2c_do_ack                 ;
        r0_hclk_do_nack_rqack               <= r1_clki2c_do_nack                ;
        r0_hclk_iic_rst_rqack               <= r1_clki2c_iic_rst                ;
        r0_hclk_im_ahb_fifo_rd_rqack        <= r1_clki2c_im_ahb_fifo_rd         ;
        r0_hclk_im_ahb_fifo_wr_rqack        <= r1_clki2c_im_ahb_fifo_wr         ;
        r0_hclk_rd_apb_rqack                <= r1_clki2c_rd_apb                 ;
        r0_hclk_trans_rqack                 <= r1_clki2c_trans                  ;
        r0_hclk_wr_apb_rqack                <= r1_clki2c_wr_apb                 ;
        r0_hclk_wr_data_apb_rqack           <= r1_clki2c_wr_data_apb            ;
        r0_hclk_dma_ack_rx_rqack            <= r1_clki2c_dma_ack_rx             ;
        r0_hclk_dma_ack_tx_rqack            <= r1_clki2c_dma_ack_tx             ;
        //r0_hclk_int_st_cmpl_rqack           <= i_clki2c_int_st_cmpl             ;
        //r0_hclk_prefix_period_rqack         <= i_clki2c_prefix_period           ;
        //r0_hclk_nx_rdwt_rqack               <= i_clki2c_nx_rdwt                ;
        //r0_hclk_nx_datacnt_rqack            <= i_clki2c_nx_datacnt             ;
        
        r1_hclk_clr_apb_rqack               <= r0_hclk_clr_apb_rqack            ;
        r1_hclk_do_ack_rqack                <= r0_hclk_do_ack_rqack             ;
        r1_hclk_do_nack_rqack               <= r0_hclk_do_nack_rqack            ;
        r1_hclk_iic_rst_rqack               <= r0_hclk_iic_rst_rqack            ;
        r1_hclk_im_ahb_fifo_rd_rqack        <= r0_hclk_im_ahb_fifo_rd_rqack     ;
        r1_hclk_im_ahb_fifo_wr_rqack        <= r0_hclk_im_ahb_fifo_wr_rqack     ;
        r1_hclk_rd_apb_rqack                <= r0_hclk_rd_apb_rqack             ;
        r1_hclk_trans_rqack                 <= r0_hclk_trans_rqack              ;
        r1_hclk_wr_apb_rqack                <= r0_hclk_wr_apb_rqack             ;
        r1_hclk_wr_data_apb_rqack           <= r0_hclk_wr_data_apb_rqack        ;
        //r1_hclk_nx_rdwt_rqack               <= r0_hclk_nx_rdwt_rqack            ;
        //r1_hclk_nx_datacnt_rqack            <= r0_hclk_nx_datacnt_rqack         ;
        //r1_hclk_dma_ack_rx_rqack            <= r0_hclk_dma_ack_rx_rqack         ;
        r1_hclk_dma_ack_tx_rqack            <= r0_hclk_dma_ack_tx_rqack         ;
        //r1_hclk_int_st_cmpl_rqack           <= r0_hclk_int_st_cmpl_rqack        ;
        //r1_hclk_prefix_period_rqack         <= r0_hclk_prefix_period_rqack      ;

        r2_hclk_clr_apb_rqack               <= r1_hclk_clr_apb_rqack            ;
        r2_hclk_do_ack_rqack                <= r1_hclk_do_ack_rqack             ;
        r2_hclk_do_nack_rqack               <= r1_hclk_do_nack_rqack            ;
        r2_hclk_iic_rst_rqack               <= r1_hclk_iic_rst_rqack            ;
        r2_hclk_im_ahb_fifo_rd_rqack        <= r1_hclk_im_ahb_fifo_rd_rqack     ;
        r2_hclk_im_ahb_fifo_wr_rqack        <= r1_hclk_im_ahb_fifo_wr_rqack     ;
        r2_hclk_rd_apb_rqack                <= r1_hclk_rd_apb_rqack             ;
        r2_hclk_trans_rqack                 <= r1_hclk_trans_rqack              ;
        r2_hclk_wr_apb_rqack                <= r1_hclk_wr_apb_rqack             ;
        r2_hclk_wr_data_apb_rqack           <= r1_hclk_wr_data_apb_rqack        ;
        //r2_hclk_nx_rdwt_rqack               <= r1_hclk_nx_rdwt_rqack            ;
        //r2_hclk_nx_datacnt_rqack            <= r1_hclk_nx_datacnt_rqack         ;
        //r2_hclk_dma_ack_rx_rqack            <= r1_hclk_dma_ack_rx_rqack         ;
        r2_hclk_dma_ack_tx_rqack            <= r1_hclk_dma_ack_tx_rqack         ;
    end
end                       

////// HCLK to CLK_I2C Domain   
always @ (negedge HRESETn or posedge CLK_I2C) begin
    if(!HRESETn) begin
        r0_clki2c_addr                      <= 'd0 ;
        r0_clki2c_int_en_byterecv           <= 'd0 ;
        r0_clki2c_iic_rst                   <= 'd0 ;
        r0_clki2c_do_ack                    <= 'd0 ;
        r0_clki2c_do_nack                   <= 'd0 ;
        r0_clki2c_trans                     <= 'd0 ;
        r0_clki2c_phase_S                   <= 'd0 ;
        r0_clki2c_phase_adr                 <= 'd0 ;
        r0_clki2c_phase_dat                 <= 'd0 ;
        r0_clki2c_phase_P                   <= 'd0 ;
        r0_clki2c_nx_rdwt                   <= 'd0 ;
        r0_clki2c_nx_datacnt                <= 'd0 ;
        r0_clki2c_t_hddat                   <= 'd0 ;
        r0_clki2c_t_sudat                   <= 'd0 ;
        r0_clki2c_t_high                    <= 'd0 ;
        r0_clki2c_t_low                     <= 'd0 ;
        r0_clki2c_dma_en                    <= 'd0 ;
        r0_clki2c_master                    <= 'd0 ;
        r0_clki2c_addressing                <= 'd0 ;
        r0_clki2c_iic_en                    <= 'd0 ;
        r0_clki2c_dma_ack_rx                <= 'd0 ;
        r0_clki2c_dma_ack_tx                <= 'd0 ;
        r0_clki2c_int_st_cmpl               <= 'd0 ;
        r0_clki2c_wr_apb                    <= 'd0 ;
        r0_clki2c_rd_apb                    <= 'd0 ;
        r0_clki2c_clr_apb                   <= 'd0 ;
        r0_clki2c_wr_data_apb               <= 'd0 ;
        r0_clki2c_prefix_period	            <= 'd0 ;
        r0_clki2c_im_ahb_fifo_rd	        <= 'd0 ;
        r0_clki2c_im_ahb_fifo_wr	        <= 'd0 ;
        r0_clki2c_t_sp                      <= 'd0 ;
        r0_clki2c_entries_tx                <= 'd0 ;
        r0_clki2c_fifo_full_tx              <= 'd0 ;
        r0_clki2c_wr_recv                   <= 'd0 ;
        
        r1_clki2c_addr                      <= 'd0 ;
        r1_clki2c_int_en_byterecv           <= 'd0 ;
        r1_clki2c_iic_rst                   <= 'd0 ;
        r1_clki2c_do_ack                    <= 'd0 ;
        r1_clki2c_do_nack                   <= 'd0 ;
        r1_clki2c_trans                     <= 'd0 ;
        r1_clki2c_phase_S                   <= 'd0 ;
        r1_clki2c_phase_adr                 <= 'd0 ;
        r1_clki2c_phase_dat                 <= 'd0 ;
        r1_clki2c_phase_P                   <= 'd0 ;
        r1_clki2c_nx_rdwt                   <= 'd0 ;
        r1_clki2c_nx_datacnt                <= 'd0 ;
        r1_clki2c_t_hddat                   <= 'd0 ;
        r1_clki2c_t_sudat                   <= 'd0 ;
        r1_clki2c_t_high                    <= 'd0 ;
        r1_clki2c_t_low                     <= 'd0 ;
        r1_clki2c_dma_en                    <= 'd0 ;
        r1_clki2c_master                    <= 'd0 ;
        r1_clki2c_addressing                <= 'd0 ;
        r1_clki2c_iic_en                    <= 'd0 ;
        r1_clki2c_dma_ack_rx                <= 'd0 ;
        r1_clki2c_dma_ack_tx                <= 'd0 ;
        r1_clki2c_int_st_cmpl               <= 'd0 ;
        r1_clki2c_wr_apb                    <= 'd0 ;
        r1_clki2c_rd_apb                    <= 'd0 ;
        r1_clki2c_clr_apb                   <= 'd0 ;
        r1_clki2c_wr_data_apb               <= 'd0 ;
        r1_clki2c_prefix_period	            <= 'd0 ;
        r1_clki2c_im_ahb_fifo_rd	        <= 'd0 ;
        r1_clki2c_im_ahb_fifo_wr	        <= 'd0 ;
        r1_clki2c_t_sp                      <= 'd0 ;
        r1_clki2c_entries_tx                <= 'd0 ;
        r1_clki2c_fifo_full_tx              <= 'd0 ;
        r1_clki2c_wr_recv                   <= 'd0 ;

        r2_clki2c_wr_apb                    <= 'd0 ;
        r2_clki2c_rd_apb                    <= 'd0 ;
        r2_clki2c_im_ahb_fifo_rd	        <= 'd0 ;
        r2_clki2c_im_ahb_fifo_wr	        <= 'd0 ;
        r2_clki2c_wr_data_apb               <= 'd0 ;
        r2_clki2c_clr_apb                   <= 'd0 ;
        r2_clki2c_iic_rst                   <= 'd0 ;
        r2_clki2c_do_ack                    <= 'd0 ;
        r2_clki2c_do_nack                   <= 'd0 ;
        r2_clki2c_trans                     <= 'd0 ;

        ////// non-constant signal hand-shaking
        r0_clki2c_addrhit_trig_rqack        <= 'd0 ;
        r0_clki2c_arblose_trig_rqack        <= 'd0 ;
        r0_clki2c_byterecv_trig_rqack       <= 'd0 ;
        r0_clki2c_bytetrans_trig_rqack      <= 'd0 ;
        r0_clki2c_cmpl_trig_rqack           <= 'd0 ;
        r0_clki2c_rd_cntlr_rqack            <= 'd0 ;
        r0_clki2c_slv_hit_rqack             <= 'd0 ;
        r0_clki2c_st_gencall_rqack          <= 'd0 ;
        r0_clki2c_start_cond_rqack          <= 'd0 ;
        r0_clki2c_stop_cond_rqack           <= 'd0 ;
        r0_clki2c_wr_cntlr_rqack            <= 'd0 ;
        r0_clki2c_clr_cntlr_rqack           <= 'd0 ;
        //r0_clki2c_entries_rx_rqack             <= 'd0 ;
        ////r0_clki2c_dma_req_rx_rqack          <= 'd0 ;
        ////r0_clki2c_dma_req_tx_rqack          <= 'd0 ;
        //r0_clki2c_idle_state_rqack          <= 'd0 ;
        //r0_clki2c_rd_data_rqack             <= 'd0 ;
        ////r0_clki2c_scl_rqack                 <= 'd0 ;
        ////r0_clki2c_sda_rqack                 <= 'd0 ;
        //r0_clki2c_st_ack_rqack              <= 'd0 ;
        //r0_clki2c_st_busbusy_rqack          <= 'd0 ;
        //r0_clki2c_wr_data_cntlr_rqack       <= 'd0 ;
        
        r1_clki2c_addrhit_trig_rqack        <= 'd0 ;
        r1_clki2c_arblose_trig_rqack        <= 'd0 ;
        r1_clki2c_byterecv_trig_rqack       <= 'd0 ;
        r1_clki2c_bytetrans_trig_rqack      <= 'd0 ;
        r1_clki2c_cmpl_trig_rqack           <= 'd0 ;
        r1_clki2c_rd_cntlr_rqack            <= 'd0 ;
        r1_clki2c_slv_hit_rqack             <= 'd0 ;
        r1_clki2c_st_gencall_rqack          <= 'd0 ;
        r1_clki2c_start_cond_rqack          <= 'd0 ;
        r1_clki2c_stop_cond_rqack           <= 'd0 ;
        r1_clki2c_wr_cntlr_rqack            <= 'd0 ;
        r1_clki2c_clr_cntlr_rqack           <= 'd0 ;
        //r1_clki2c_entries_rx_rqack             <= 'd0 ;
        ////r1_clki2c_dma_req_rx_rqack          <= 'd0 ;
        ////r1_clki2c_dma_req_tx_rqack          <= 'd0 ;
        //r1_clki2c_idle_state_rqack          <= 'd0 ;
        //r1_clki2c_rd_data_rqack             <= 'd0 ;
        ////r1_clki2c_scl_rqack                 <= 'd0 ;
        ////r1_clki2c_sda_rqack                 <= 'd0 ;
        //r1_clki2c_st_ack_rqack              <= 'd0 ;
        //r1_clki2c_st_busbusy_rqack          <= 'd0 ;
        //r1_clki2c_wr_data_cntlr_rqack       <= 'd0 ;
        
        r2_clki2c_addrhit_trig_rqack        <= 'd0 ;
        r2_clki2c_arblose_trig_rqack        <= 'd0 ;
        r2_clki2c_byterecv_trig_rqack       <= 'd0 ;
        r2_clki2c_bytetrans_trig_rqack      <= 'd0 ;
        r2_clki2c_cmpl_trig_rqack           <= 'd0 ;
        r2_clki2c_rd_cntlr_rqack            <= 'd0 ;
        r2_clki2c_slv_hit_rqack             <= 'd0 ;
        r2_clki2c_st_gencall_rqack          <= 'd0 ;
        r2_clki2c_start_cond_rqack          <= 'd0 ;
        r2_clki2c_stop_cond_rqack           <= 'd0 ;
        r2_clki2c_wr_cntlr_rqack            <= 'd0 ;
        r2_clki2c_clr_cntlr_rqack           <= 'd0 ;
    end
    else begin
        r0_clki2c_int_st_cmpl               <= i_hclk_int_st_cmpl               ;
        r0_clki2c_addr                      <= i_hclk_addr                      ;
        r0_clki2c_int_en_byterecv           <= i_hclk_int_en_byterecv           ;
        r0_clki2c_phase_S                   <= i_hclk_phase_S                   ;
        r0_clki2c_phase_adr                 <= i_hclk_phase_adr                 ;
        r0_clki2c_phase_dat                 <= i_hclk_phase_dat                 ;
        r0_clki2c_phase_P                   <= i_hclk_phase_P                   ;
        r0_clki2c_t_hddat                   <= i_hclk_t_hddat                   ;
        r0_clki2c_t_sudat                   <= i_hclk_t_sudat                   ;
        r0_clki2c_t_high                    <= i_hclk_t_high                    ;
        r0_clki2c_t_low                     <= i_hclk_t_low                     ;
        r0_clki2c_dma_en                    <= i_hclk_dma_en                    ;
        r0_clki2c_master                    <= i_hclk_master                    ;
        r0_clki2c_addressing                <= i_hclk_addressing                ;
        r0_clki2c_iic_en                    <= i_hclk_iic_en                    ;
        r0_clki2c_prefix_period	            <= i_hclk_prefix_period             ;
        r0_clki2c_t_sp                      <= i_hclk_t_sp                      ;
        r0_clki2c_nx_rdwt                   <= i_hclk_nx_rdwt                   ;
        r0_clki2c_nx_datacnt                <= i_hclk_nx_datacnt                ;
        r0_clki2c_dma_ack_rx                <= i_hclk_dma_ack_rx                ;
        r0_clki2c_entries_tx                <= i_hclk_entries_tx                ;
        r0_clki2c_fifo_full_tx              <= i_hclk_fifo_full_tx              ;
        r0_clki2c_wr_recv                   <= i_hclk_wr_recv                   ;
        r0_clki2c_dma_ack_tx                <= i_hclk_dma_ack_tx                ;
        ////// non-constant signal hand-shaking @@
        r0_clki2c_iic_rst                   <= r_hclk_iic_rst                   ;
        r0_clki2c_do_ack                    <= r_hclk_do_ack                    ;
        r0_clki2c_do_nack                   <= r_hclk_do_nack                   ;
//      r0_clki2c_trans                     <= r_hclk_trans                     ;
        r0_clki2c_trans                     <= i_hclk_trans                     ;
        r0_clki2c_wr_apb                    <= r_hclk_wr_apb                    ;
        r0_clki2c_rd_apb                    <= r_hclk_rd_apb                    ;
        r0_clki2c_clr_apb                   <= r_hclk_clr_apb                   ;
        r0_clki2c_im_ahb_fifo_rd	        <= r_hclk_im_ahb_fifo_rd            ;
        r0_clki2c_im_ahb_fifo_wr	        <= r_hclk_im_ahb_fifo_wr            ;
        r0_clki2c_wr_data_apb               <= r_hclk_wr_data_apb               ;
        //r0_clki2c_dma_ack_tx                <= r_hclk_dma_ack_tx                ;
        //r0_clki2c_dma_ack_rx                <= r_hclk_dma_ack_rx                ;
        //r0_clki2c_nx_rdwt                   <= r_hclk_nx_rdwt                   ;
        //r0_clki2c_nx_datacnt                <= r_hclk_nx_datacnt                ;
        
        r1_clki2c_addr                      <= r0_clki2c_addr                   ;
        r1_clki2c_int_en_byterecv           <= r0_clki2c_int_en_byterecv        ;
        r1_clki2c_iic_rst                   <= r0_clki2c_iic_rst                ;
        r1_clki2c_do_ack                    <= r0_clki2c_do_ack                 ;
        r1_clki2c_do_nack                   <= r0_clki2c_do_nack                ;
        r1_clki2c_trans                     <= r0_clki2c_trans                  ;
        r1_clki2c_phase_S                   <= r0_clki2c_phase_S                ;
        r1_clki2c_phase_adr                 <= r0_clki2c_phase_adr              ;
        r1_clki2c_phase_dat                 <= r0_clki2c_phase_dat              ;
        r1_clki2c_phase_P                   <= r0_clki2c_phase_P                ;
        r1_clki2c_nx_rdwt                   <= r0_clki2c_nx_rdwt                ;
        r1_clki2c_nx_datacnt                <= r0_clki2c_nx_datacnt             ;
        r1_clki2c_t_hddat                   <= r0_clki2c_t_hddat                ;
        r1_clki2c_t_sudat                   <= r0_clki2c_t_sudat                ;
        r1_clki2c_t_high                    <= r0_clki2c_t_high                 ;
        r1_clki2c_t_low                     <= r0_clki2c_t_low                  ;
        r1_clki2c_dma_en                    <= r0_clki2c_dma_en                 ;
        r1_clki2c_master                    <= r0_clki2c_master                 ;
        r1_clki2c_addressing                <= r0_clki2c_addressing             ;
        r1_clki2c_iic_en                    <= r0_clki2c_iic_en                 ;
        r1_clki2c_dma_ack_rx                <= r0_clki2c_dma_ack_rx             ;
        r1_clki2c_dma_ack_tx                <= r0_clki2c_dma_ack_tx             ;
        r1_clki2c_int_st_cmpl               <= r0_clki2c_int_st_cmpl            ;
        r1_clki2c_wr_apb                    <= r0_clki2c_wr_apb                 ;
        r1_clki2c_rd_apb                    <= r0_clki2c_rd_apb                 ;
        r1_clki2c_clr_apb                   <= r0_clki2c_clr_apb                ;
        r1_clki2c_wr_data_apb               <= r0_clki2c_wr_data_apb            ;
        r1_clki2c_prefix_period	            <= r0_clki2c_prefix_period	        ;
        r1_clki2c_im_ahb_fifo_rd	        <= r0_clki2c_im_ahb_fifo_rd         ;
        r1_clki2c_im_ahb_fifo_wr	        <= r0_clki2c_im_ahb_fifo_wr         ;
        r1_clki2c_t_sp                      <= r0_clki2c_t_sp                   ;
        r1_clki2c_entries_tx                <= r0_clki2c_entries_tx             ;
        r1_clki2c_fifo_full_tx              <= r0_clki2c_fifo_full_tx           ;
        r1_clki2c_wr_recv                   <= r0_clki2c_wr_recv                ;

        r2_clki2c_wr_apb                    <= r1_clki2c_wr_apb                 ;
        r2_clki2c_rd_apb                    <= r1_clki2c_rd_apb                 ;
        r2_clki2c_im_ahb_fifo_rd	        <= r1_clki2c_im_ahb_fifo_rd         ;
        r2_clki2c_im_ahb_fifo_wr	        <= r1_clki2c_im_ahb_fifo_wr         ;
        r2_clki2c_wr_data_apb               <= r1_clki2c_wr_data_apb            ;
        r2_clki2c_clr_apb                   <= r1_clki2c_clr_apb                ;
        r2_clki2c_iic_rst                   <= r1_clki2c_iic_rst                ;
        r2_clki2c_do_ack                    <= r1_clki2c_do_ack                 ;
        r2_clki2c_do_nack                   <= r1_clki2c_do_nack                ;
        r2_clki2c_trans                     <= r1_clki2c_trans                  ;

        ////// non-constant signal hand-shaking
        r0_clki2c_start_cond_rqack          <= r1_fclk_start_cond               ;
        r0_clki2c_addrhit_trig_rqack        <= r1_hclk_addrhit_trig             ;
        r0_clki2c_arblose_trig_rqack        <= r1_hclk_arblose_trig             ;
        r0_clki2c_byterecv_trig_rqack       <= r1_hclk_byterecv_trig            ;
        r0_clki2c_bytetrans_trig_rqack      <= r1_hclk_bytetrans_trig           ;
        r0_clki2c_cmpl_trig_rqack           <= r1_hclk_cmpl_trig                ;
        r0_clki2c_rd_cntlr_rqack            <= r1_hclk_rd_cntlr                 ;
        r0_clki2c_slv_hit_rqack             <= r1_hclk_slv_hit                  ;
        r0_clki2c_st_gencall_rqack          <= r1_hclk_st_gencall               ;
        r0_clki2c_stop_cond_rqack           <= r1_hclk_stop_cond                ;
        r0_clki2c_wr_cntlr_rqack            <= r1_hclk_wr_cntlr                 ;
        r0_clki2c_clr_cntlr_rqack           <= r1_hclk_clr_cntlr                ;
        //r0_clki2c_entries_rx_rqack             <= r1_hclk_entries_rx                  ;
        ////r0_clki2c_dma_req_rx_rqack          <= i_hclk_dma_req_rx_rqack          ;
        ////r0_clki2c_dma_req_tx_rqack          <= i_hclk_dma_req_tx_rqack          ;
        //r0_clki2c_idle_state_rqack          <= i_hclk_idle_state_rqack          ;
        //r0_clki2c_rd_data_rqack             <= i_hclk_rd_data_rqack             ;
        ////r0_clki2c_scl_rqack                 <= i_hclk_scl_rqack                 ;
        ////r0_clki2c_sda_rqack                 <= i_hclk_sda_rqack                 ;
        //r0_clki2c_st_ack_rqack              <= i_hclk_st_ack_rqack              ;
        //r0_clki2c_st_busbusy_rqack          <= i_hclk_st_busbusy_rqack          ;
        //r0_clki2c_wr_data_cntlr_rqack       <= i_hclk_wr_data_cntlr_rqack       ;
        
        r1_clki2c_addrhit_trig_rqack        <= r0_clki2c_addrhit_trig_rqack     ;
        r1_clki2c_arblose_trig_rqack        <= r0_clki2c_arblose_trig_rqack     ;
        r1_clki2c_byterecv_trig_rqack       <= r0_clki2c_byterecv_trig_rqack    ;
        r1_clki2c_bytetrans_trig_rqack      <= r0_clki2c_bytetrans_trig_rqack   ;
        r1_clki2c_cmpl_trig_rqack           <= r0_clki2c_cmpl_trig_rqack        ;
        r1_clki2c_rd_cntlr_rqack            <= r0_clki2c_rd_cntlr_rqack         ;
        r1_clki2c_slv_hit_rqack             <= r0_clki2c_slv_hit_rqack          ;
        r1_clki2c_st_gencall_rqack          <= r0_clki2c_st_gencall_rqack       ;
        r1_clki2c_start_cond_rqack          <= r0_clki2c_start_cond_rqack       ;
        r1_clki2c_stop_cond_rqack           <= r0_clki2c_stop_cond_rqack        ;
        r1_clki2c_wr_cntlr_rqack            <= r0_clki2c_wr_cntlr_rqack         ;
        r1_clki2c_clr_cntlr_rqack           <= r0_clki2c_clr_cntlr_rqack        ;
        //r1_clki2c_entries_rx_rqack             <= r0_clki2c_entries_rx_rqack          ;
        ////r1_clki2c_dma_req_rx_rqack          <= r0_clki2c_dma_req_rx_rqack       ;
        ////r1_clki2c_dma_req_tx_rqack          <= r0_clki2c_dma_req_tx_rqack       ;
        //r1_clki2c_idle_state_rqack          <= r0_clki2c_idle_state_rqack       ;
        //r1_clki2c_rd_data_rqack             <= r0_clki2c_rd_data_rqack          ;
        ////r1_clki2c_scl_rqack                 <= r0_clki2c_scl_rqack              ;
        ////r1_clki2c_sda_rqack                 <= r0_clki2c_sda_rqack              ;
        //r1_clki2c_st_ack_rqack              <= r0_clki2c_st_ack_rqack           ;
        //r1_clki2c_st_busbusy_rqack          <= r0_clki2c_st_busbusy_rqack       ;
        //r1_clki2c_wr_data_cntlr_rqack       <= r0_clki2c_wr_data_cntlr_rqack    ;
        
        r2_clki2c_addrhit_trig_rqack        <= r1_clki2c_addrhit_trig_rqack     ;
        r2_clki2c_arblose_trig_rqack        <= r1_clki2c_arblose_trig_rqack     ;
        r2_clki2c_byterecv_trig_rqack       <= r1_clki2c_byterecv_trig_rqack    ;
        r2_clki2c_bytetrans_trig_rqack      <= r1_clki2c_bytetrans_trig_rqack   ;
        r2_clki2c_cmpl_trig_rqack           <= r1_clki2c_cmpl_trig_rqack        ;
        r2_clki2c_rd_cntlr_rqack            <= r1_clki2c_rd_cntlr_rqack         ;
        r2_clki2c_slv_hit_rqack             <= r1_clki2c_slv_hit_rqack          ;
        r2_clki2c_st_gencall_rqack          <= r1_clki2c_st_gencall_rqack       ;
        r2_clki2c_start_cond_rqack          <= r1_clki2c_start_cond_rqack       ;
        r2_clki2c_stop_cond_rqack           <= r1_clki2c_stop_cond_rqack        ;
        r2_clki2c_wr_cntlr_rqack            <= r1_clki2c_wr_cntlr_rqack         ;
        r2_clki2c_clr_cntlr_rqack           <= r1_clki2c_clr_cntlr_rqack        ;
    end
end               
   
//always @ (negedge HRESETn or posedge CLK_I2C or negedge r_hclk_rd_apb) begin
//    if(!HRESETn) begin
//        r0_clki2c_rd_apb                    <= 'd0 ;
//    end
//    else begin
//        if(~r_hclk_rd_apb) r0_clki2c_rd_apb <= 'd0                              ;
//        else r0_clki2c_rd_apb               <= 'd1                              ;
//    end
//end    

// ----------------------------------------------------------------------------------

wire        hclk_clr_apb_rqack          = r1_hclk_clr_apb_rqack             &   ~r2_hclk_clr_apb_rqack          ;     
wire        hclk_do_ack_rqack           = r1_hclk_do_ack_rqack              &   ~r2_hclk_do_ack_rqack           ;     
wire        hclk_do_nack_rqack          = r1_hclk_do_nack_rqack             &   ~r2_hclk_do_nack_rqack          ;     
wire        hclk_iic_rst_rqack          = r1_hclk_iic_rst_rqack             &   ~r2_hclk_iic_rst_rqack          ;     
wire        hclk_im_ahb_fifo_rd_rqack   = r1_hclk_im_ahb_fifo_rd_rqack      &   ~r2_hclk_im_ahb_fifo_rd_rqack   ;     
wire        hclk_im_ahb_fifo_wr_rqack   = r1_hclk_im_ahb_fifo_wr_rqack      &   ~r2_hclk_im_ahb_fifo_wr_rqack   ;     
wire        hclk_rd_apb_rqack           = r1_hclk_rd_apb_rqack              &   ~r2_hclk_rd_apb_rqack           ;     
wire        hclk_trans_rqack            = r1_hclk_trans_rqack               &   ~r2_hclk_trans_rqack            ;     
wire        hclk_wr_apb_rqack           = r1_hclk_wr_apb_rqack              &   ~r2_hclk_wr_apb_rqack           ;  
wire        hclk_wr_data_apb_rqack      = r1_hclk_wr_data_apb_rqack         &   ~r2_hclk_wr_data_apb_rqack      ;  
wire        hclk_dma_ack_tx_rqack       = r1_hclk_dma_ack_tx_rqack          &   ~r2_hclk_dma_ack_tx_rqack       ;  
//wire        hclk_nx_rdwt_rqack          = r1_hclk_nx_rdwt_rqack             &   ~r2_hclk_nx_rdwt_rqack          ;     
//wire        hclk_nx_datacnt_rqack       = r1_hclk_nx_datacnt_rqack          &   ~r2_hclk_nx_datacnt_rqack       ;     
//wire        hclk_dma_ack_rx_rqack       = r1_hclk_dma_ack_rx_rqack          &   ~r2_hclk_dma_ack_rx_rqack       ;  

////// HCLK Domain     
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r_hclk_clr_apb              <= 'd0 ;
        r_hclk_do_ack               <= 'd0 ;
        r_hclk_do_nack              <= 'd0 ;
        r_hclk_iic_rst              <= 'd0 ;
        r_hclk_im_ahb_fifo_rd       <= 'd0 ;
        r_hclk_im_ahb_fifo_wr       <= 'd0 ;
        r_hclk_rd_apb               <= 'd0 ;
        r_hclk_trans                <= 'd0 ;
        r_hclk_wr_apb               <= 'd0 ;
        //r_hclk_dma_ack_rx           <= 'd0 ;
        //r_hclk_dma_ack_tx           <= 'd0 ;
        r_hclk_wr_data_apb          <= 'd0 ;
        //r_hclk_nx_rdwt              <= 'd0 ;
        //r_hclk_nx_datacnt           <= 'd0 ;
    end
    else begin
        if(hclk_clr_apb_rqack)          r_hclk_clr_apb          <= 'd0 ;
        else if(i_hclk_clr_apb)         r_hclk_clr_apb          <= 'd1 ;
        if(hclk_do_ack_rqack)           r_hclk_do_ack           <= 'd0 ;
        else if(i_hclk_do_ack)          r_hclk_do_ack           <= 'd1 ;
        if(hclk_do_nack_rqack)          r_hclk_do_nack          <= 'd0 ;
        else if(i_hclk_do_nack)         r_hclk_do_nack          <= 'd1 ;
        if(hclk_iic_rst_rqack)          r_hclk_iic_rst          <= 'd0 ;
        else if(i_hclk_iic_rst)         r_hclk_iic_rst          <= 'd1 ;
        if(hclk_im_ahb_fifo_rd_rqack)   r_hclk_im_ahb_fifo_rd   <= 'd0 ;
        else if(i_hclk_im_ahb_fifo_rd)  r_hclk_im_ahb_fifo_rd   <= 'd1 ;
        if(hclk_im_ahb_fifo_wr_rqack)   r_hclk_im_ahb_fifo_wr   <= 'd0 ;
        else if(i_hclk_im_ahb_fifo_wr)  r_hclk_im_ahb_fifo_wr   <= 'd1 ;
        if(hclk_rd_apb_rqack)           r_hclk_rd_apb           <= 'd0 ;
        else if(i_hclk_rd_apb)          r_hclk_rd_apb           <= 'd1 ;
        if(hclk_wr_apb_rqack)           r_hclk_wr_apb           <= 'd0 ;
        else if(i_hclk_wr_apb)          r_hclk_wr_apb           <= 'd1 ;
        if(hclk_trans_rqack)            r_hclk_trans            <= 'd0 ;
        else if(i_hclk_trans)           r_hclk_trans            <= 'd1 ;
        //if(hclk_dma_ack_tx_rqack)       r_hclk_dma_ack_tx       <= 'd0 ;
        //else if(i_hclk_dma_ack_tx)      r_hclk_dma_ack_tx       <= 'd1 ;

        if(hclk_wr_data_apb_rqack)      r_hclk_wr_data_apb      <= 'd0 ;
        else if(i_hclk_wr_apb)          r_hclk_wr_data_apb      <= i_hclk_wr_data_apb ;
        //else if(r_hclk_wr_data_apb != i_hclk_wr_data_apb)     r_hclk_wr_data_apb      <= i_hclk_wr_data_apb ;
        
        //if(hclk_nx_rdwt_rqack)          r_hclk_nx_rdwt          <= 'd0 ;
        //else if(i_hclk_nx_rdwt)         r_hclk_nx_rdwt          <= 'd1 ;
        //if(hclk_nx_datacnt_rqack)       r_hclk_nx_datacnt       <= 'd0 ;
        //else if(i_hclk_nx_datacnt)      r_hclk_nx_datacnt       <= 'd1 ;
        //if(hclk_dma_ack_rx_rqack)       r_hclk_dma_ack_rx       <= 'd0 ;
        //else if(i_hclk_dma_ack_rx)      r_hclk_dma_ack_rx       <= 'd1 ;
    end
end    
assign hclk_im_ahb_fifo_wr_mnt = r_hclk_im_ahb_fifo_wr | r1_hclk_im_ahb_fifo_wr_rqack ;

wire        clki2c_addrhit_trig_rqack       = r1_clki2c_addrhit_trig_rqack      &   ~r2_clki2c_addrhit_trig_rqack       ;   
wire        clki2c_arblose_trig_rqack       = r1_clki2c_arblose_trig_rqack      &   ~r2_clki2c_arblose_trig_rqack       ;   
wire        clki2c_byterecv_trig_rqack      = r1_clki2c_byterecv_trig_rqack     &   ~r2_clki2c_byterecv_trig_rqack      ;   
wire        clki2c_bytetrans_trig_rqack     = r1_clki2c_bytetrans_trig_rqack    &   ~r2_clki2c_bytetrans_trig_rqack     ;   
wire        clki2c_cmpl_trig_rqack          = r1_clki2c_cmpl_trig_rqack         &   ~r2_clki2c_cmpl_trig_rqack          ;   
wire        clki2c_rd_cntlr_rqack           = r1_clki2c_rd_cntlr_rqack          &   ~r2_clki2c_rd_cntlr_rqack           ;   
wire        clki2c_slv_hit_rqack            = r1_clki2c_slv_hit_rqack           &   ~r2_clki2c_slv_hit_rqack            ;   
wire        clki2c_st_gencall_rqack         = r1_clki2c_st_gencall_rqack        &   ~r2_clki2c_st_gencall_rqack         ;   
wire        clki2c_start_cond_rqack         = r1_clki2c_start_cond_rqack        &   ~r2_clki2c_start_cond_rqack         ;   
wire        clki2c_stop_cond_rqack          = r1_clki2c_stop_cond_rqack         &   ~r2_clki2c_stop_cond_rqack          ;   
wire        clki2c_wr_cntlr_rqack           = r1_clki2c_wr_cntlr_rqack          &   ~r2_clki2c_wr_cntlr_rqack           ;  
wire        clki2c_clr_cntlr_rqack          = r1_clki2c_clr_cntlr_rqack         &   ~r2_clki2c_clr_cntlr_rqack          ;  

////// CLK_I2C Domain     
always @ (negedge HRESETn or posedge CLK_I2C) begin
    if(!HRESETn) begin
        r_clki2c_addrhit_trig         <= 'd0 ;
        r_clki2c_arblose_trig         <= 'd0 ;
        r_clki2c_byterecv_trig        <= 'd0 ;
        r_clki2c_bytetrans_trig       <= 'd0 ;
        r_clki2c_cmpl_trig            <= 'd0 ;
        r_clki2c_rd_cntlr             <= 'd0 ;
        r_clki2c_slv_hit              <= 'd0 ;
        r_clki2c_st_gencall           <= 'd0 ;
        r_clki2c_start_cond           <= 'd0 ;
        r_clki2c_stop_cond            <= 'd0 ;
        r_clki2c_wr_cntlr             <= 'd0 ;
        r_clki2c_clr_cntlr            <= 'd0 ;
    end
    else begin
        if(clki2c_addrhit_trig_rqack)       r_clki2c_addrhit_trig            <= 'd0 ;
        else if(i_clki2c_addrhit_trig)      r_clki2c_addrhit_trig            <= 'd1 ;
        if(clki2c_arblose_trig_rqack)       r_clki2c_arblose_trig            <= 'd0 ;
        else if(i_clki2c_arblose_trig)      r_clki2c_arblose_trig            <= 'd1 ;
        if(clki2c_byterecv_trig_rqack)      r_clki2c_byterecv_trig           <= 'd0 ;
        else if(i_clki2c_byterecv_trig)     r_clki2c_byterecv_trig           <= 'd1 ;
        if(clki2c_bytetrans_trig_rqack)     r_clki2c_bytetrans_trig          <= 'd0 ;
        else if(i_clki2c_bytetrans_trig)    r_clki2c_bytetrans_trig          <= 'd1 ;
        if(clki2c_cmpl_trig_rqack)          r_clki2c_cmpl_trig               <= 'd0 ;
        else if(i_clki2c_cmpl_trig)         r_clki2c_cmpl_trig               <= 'd1 ;
        if(clki2c_rd_cntlr_rqack)           r_clki2c_rd_cntlr                <= 'd0 ;
        else if(i_clki2c_rd_cntlr)          r_clki2c_rd_cntlr                <= 'd1 ;
        if(clki2c_slv_hit_rqack)            r_clki2c_slv_hit                 <= 'd0 ;
        else if(i_clki2c_slv_hit)           r_clki2c_slv_hit                 <= 'd1 ;
        if(clki2c_st_gencall_rqack)         r_clki2c_st_gencall              <= 'd0 ;
        else if(i_clki2c_st_gencall)        r_clki2c_st_gencall              <= 'd1 ;
        if(clki2c_start_cond_rqack)         r_clki2c_start_cond              <= 'd0 ;
        else if(i_clki2c_start_cond)        r_clki2c_start_cond              <= 'd1 ;
        if(clki2c_stop_cond_rqack)          r_clki2c_stop_cond               <= 'd0 ;
        else if(i_clki2c_stop_cond)         r_clki2c_stop_cond               <= 'd1 ;
        if(clki2c_wr_cntlr_rqack)           r_clki2c_wr_cntlr                <= 'd0 ;
        else if(i_clki2c_wr_cntlr)          r_clki2c_wr_cntlr                <= 'd1 ;
        if(clki2c_clr_cntlr_rqack)          r_clki2c_clr_cntlr               <= 'd0 ;
        else if(i_clki2c_clr_cntlr)         r_clki2c_clr_cntlr               <= 'd1 ;
    end
end    

// ----------------------------------------------------------------------------------                                            
////// one-pulse signals        
assign   rise_fclk_start_cond           = r1_fclk_start_cond        &   ~r2_fclk_start_cond         ;
assign   rise_hclk_wr_cntlr             = r1_hclk_wr_cntlr          &   ~r2_hclk_wr_cntlr           ;
assign   rise_hclk_rd_cntlr             = r1_hclk_rd_cntlr          &   ~r2_hclk_rd_cntlr           ;
assign   rise_hclk_clr_cntlr            = r1_hclk_clr_cntlr         &   ~r2_hclk_clr_cntlr          ;
assign   rise_hclk_addrhit_trig         = r1_hclk_addrhit_trig      &   ~r2_hclk_addrhit_trig       ;
assign   rise_hclk_arblose_trig	        = r1_hclk_arblose_trig      &   ~r2_hclk_arblose_trig       ;
assign   rise_hclk_cmpl_trig		    = r1_hclk_cmpl_trig	        &   ~r2_hclk_cmpl_trig	        ;
assign   rise_hclk_byterecv_trig	    = r1_hclk_byterecv_trig     &   ~r2_hclk_byterecv_trig      ;
assign   rise_hclk_bytetrans_trig       = r1_hclk_bytetrans_trig    &   ~r2_hclk_bytetrans_trig     ;
assign   rise_hclk_slv_hit              = r1_hclk_slv_hit           &   ~r2_hclk_slv_hit            ;
assign   rise_hclk_st_gencall           = r1_hclk_st_gencall        &   ~r2_hclk_st_gencall         ;
assign   rise_hclk_stop_cond            = r1_hclk_stop_cond         &   ~r2_hclk_stop_cond          ;

assign   rise_clki2c_wr_apb             = r1_clki2c_wr_apb          &   ~r2_clki2c_wr_apb           ;
assign   rise_clki2c_rd_apb             = r1_clki2c_rd_apb          &   ~r2_clki2c_rd_apb           ;
assign   rise_clki2c_im_ahb_fifo_rd     = r1_clki2c_im_ahb_fifo_rd  &   ~r2_clki2c_im_ahb_fifo_rd   ;
assign   rise_clki2c_im_ahb_fifo_wr     = r1_clki2c_im_ahb_fifo_wr  &   ~r2_clki2c_im_ahb_fifo_wr   ;
assign   rise_clki2c_clr_apb            = r1_clki2c_clr_apb         &   ~r2_clki2c_clr_apb          ;
assign   rise_clki2c_iic_rst            = r1_clki2c_iic_rst         &   ~r2_clki2c_iic_rst          ;
assign   rise_clki2c_do_ack             = r1_clki2c_do_ack          &   ~r2_clki2c_do_ack           ;
assign   rise_clki2c_do_nack            = r1_clki2c_do_nack         &   ~r2_clki2c_do_nack          ;
assign   rise_clki2c_trans              = r1_clki2c_trans           &   ~r2_clki2c_trans            ;

wire [7:0] clki2c_wr_data_apb           = (rise_clki2c_wr_apb)? r1_clki2c_wr_data_apb : 'd0 ;

// ----------------------------------------------------------------------------------
                                                                                 
////// CLK_I2C to FCLK Domain                                                    
assign o_fclk_start_cond		        = (cdc_en)?     rise_fclk_start_cond	        :   i_clki2c_start_cond	        ;

////// SCL to HCLK Domain                    
assign o_hclk_si2c_intr_wakeup_i2c      = (cdc_en)?     r1_hclk_si2c_intr_wakeup_i2c    :   i_si2c_intr_wakeup_i2c      ;   
assign o_hclk_si2c_status               = (cdc_en)?     r1_hclk_si2c_status             :   i_si2c_status               ;
                                                                                 
////// CLK_I2C to HCLK Domain                                                    
assign o_hclk_fifo_full		            = (cdc_en)?     r1_hclk_fifo_full		        :   i_clki2c_fifo_full          ;  
assign o_hclk_fifo_half_full	        = (cdc_en)?     r1_hclk_fifo_half_full          :   i_clki2c_fifo_half_full     ;   
assign o_hclk_fifo_half_empty           = (cdc_en)?     r1_hclk_fifo_half_empty         :   i_clki2c_fifo_half_empty    ;   
assign o_hclk_sda			            = (cdc_en)?     r1_hclk_sda			            :   i_clki2c_sda			    ;
assign o_hclk_scl			            = (cdc_en)?     r1_hclk_scl			            :   i_clki2c_scl			    ;
assign o_hclk_st_busbusy		        = (cdc_en)?     r1_hclk_st_busbusy	            :   i_clki2c_st_busbusy	        ;
assign o_hclk_st_ack			        = (cdc_en)?     r1_hclk_st_ack		            :   i_clki2c_st_ack		        ;
assign o_hclk_rdwt		                = (cdc_en)?     r1_hclk_rdwt		            :   i_clki2c_rdwt		        ;
assign o_hclk_rdwt_changed				= (cdc_en)?     r1_hclk_rdwt_changed			:   i_clki2c_rdwt_changed		;
assign o_hclk_datacnt		            = (cdc_en)?     r1_hclk_datacnt	                :   i_clki2c_datacnt	        ;  
assign o_hclk_bit_cnt		            = (cdc_en)?     r1_hclk_bit_cnt		            :   i_clki2c_bit_cnt		    ; 
assign o_hclk_idle_state                = (cdc_en)?     r1_hclk_idle_state              :   i_clki2c_idle_state         ; 
assign o_hclk_entries_rx                = (cdc_en)?     r1_hclk_entries_rx              :   i_clki2c_entries_rx         ; 
assign o_hclk_dma_req_rx                = (cdc_en)?     r1_hclk_dma_req_rx              :   i_clki2c_dma_req_rx         ; 
assign o_hclk_dma_req_tx                = (cdc_en)?     r1_hclk_dma_req_tx              :   i_clki2c_dma_req_tx         ; 
assign o_hclk_wr_data_cntlr             = (cdc_en)?     r1_hclk_wr_data_cntlr           :   i_clki2c_wr_data_cntlr      ; 
assign o_hclk_st_gencall		        = (cdc_en)?     rise_hclk_st_gencall            :   i_clki2c_st_gencall	        ;
assign o_hclk_addrhit_trig	            = (cdc_en)?     rise_hclk_addrhit_trig	        :   i_clki2c_addrhit_trig	    ;
assign o_hclk_arblose_trig	            = (cdc_en)?     rise_hclk_arblose_trig	        :   i_clki2c_arblose_trig	    ;
assign o_hclk_cmpl_trig		            = (cdc_en)?     rise_hclk_cmpl_trig		        :   i_clki2c_cmpl_trig	        ;    
assign o_hclk_byterecv_trig	            = (cdc_en)?     rise_hclk_byterecv_trig	        :   i_clki2c_byterecv_trig      ;    
assign o_hclk_bytetrans_trig	        = (cdc_en)?     rise_hclk_bytetrans_trig        :   i_clki2c_bytetrans_trig     ; 
assign o_hclk_stop_cond		            = (cdc_en)?     rise_hclk_stop_cond		        :   i_clki2c_stop_cond	        ;   
assign o_hclk_slv_hit		            = (cdc_en)?     rise_hclk_slv_hit		        :   i_clki2c_slv_hit		    ;
assign o_hclk_wr_cntlr                  = rise_hclk_wr_cntlr        ; 
assign o_hclk_rd_cntlr                  = rise_hclk_rd_cntlr        ;  
assign o_hclk_clr_cntlr                 = rise_hclk_clr_cntlr       ; 
                                                                                    
////// HCLK to CLK_I2C Domain                                                    
assign o_clki2c_int_st_cmpl             = (cdc_en)?     r1_clki2c_int_st_cmpl           :   i_hclk_int_st_cmpl          ;
assign o_clki2c_addr                    = (cdc_en)?     r1_clki2c_addr                  :   i_hclk_addr                 ;
assign o_clki2c_int_en_byterecv         = (cdc_en)?     r1_clki2c_int_en_byterecv       :   i_hclk_int_en_byterecv      ;
assign o_clki2c_phase_S                 = (cdc_en)?     r1_clki2c_phase_S               :   i_hclk_phase_S              ;
assign o_clki2c_phase_adr               = (cdc_en)?     r1_clki2c_phase_adr             :   i_hclk_phase_adr            ;
assign o_clki2c_phase_dat               = (cdc_en)?     r1_clki2c_phase_dat             :   i_hclk_phase_dat            ;
assign o_clki2c_phase_P                 = (cdc_en)?     r1_clki2c_phase_P               :   i_hclk_phase_P              ;
assign o_clki2c_nx_rdwt                 = (cdc_en)?     r1_clki2c_nx_rdwt               :   i_hclk_nx_rdwt              ;
assign o_clki2c_nx_datacnt              = (cdc_en)?     r1_clki2c_nx_datacnt            :   i_hclk_nx_datacnt           ;
assign o_clki2c_t_hddat                 = (cdc_en)?     r1_clki2c_t_hddat               :   i_hclk_t_hddat              ;
assign o_clki2c_t_sudat                 = (cdc_en)?     r1_clki2c_t_sudat               :   i_hclk_t_sudat              ;
assign o_clki2c_t_high                  = (cdc_en)?     r1_clki2c_t_high                :   i_hclk_t_high               ;
assign o_clki2c_t_low                   = (cdc_en)?     r1_clki2c_t_low                 :   i_hclk_t_low                ;
assign o_clki2c_dma_en                  = (cdc_en)?     r1_clki2c_dma_en                :   i_hclk_dma_en               ;
assign o_clki2c_master                  = (cdc_en)?     r1_clki2c_master                :   i_hclk_master               ;
assign o_clki2c_addressing              = (cdc_en)?     r1_clki2c_addressing            :   i_hclk_addressing           ;
assign o_clki2c_iic_en                  = (cdc_en)?     r1_clki2c_iic_en                :   i_hclk_iic_en               ;
assign o_clki2c_dma_ack_rx              = (cdc_en)?     r1_clki2c_dma_ack_rx            :   i_hclk_dma_ack_rx           ;
assign o_clki2c_dma_ack_tx              = (cdc_en)?     r1_clki2c_dma_ack_tx            :   i_hclk_dma_ack_tx           ;
assign o_clki2c_prefix_period	        = (cdc_en)?     r1_clki2c_prefix_period         :   i_hclk_prefix_period        ;
assign o_clki2c_t_sp                    = (cdc_en)?     r1_clki2c_t_sp                  :   i_hclk_t_sp                 ;  
assign o_clki2c_entries_tx              = (cdc_en)?     r1_clki2c_entries_tx            :   i_hclk_entries_tx           ;   
assign o_clki2c_wr_data_apb             = (cdc_en)?     clki2c_wr_data_apb              :   i_hclk_wr_data_apb          ;
assign o_clki2c_iic_rst                 = (cdc_en)?     rise_clki2c_iic_rst             :   i_hclk_iic_rst              ;
assign o_clki2c_do_ack                  = (cdc_en)?     rise_clki2c_do_ack              :   i_hclk_do_ack               ;
assign o_clki2c_do_nack                 = (cdc_en)?     rise_clki2c_do_nack             :   i_hclk_do_nack              ;
assign o_clki2c_trans                   = (cdc_en)?     rise_clki2c_trans               :   i_hclk_trans                ;
assign o_clki2c_clr_apb                 = (cdc_en)?     rise_clki2c_clr_apb             :   i_hclk_clr_apb              ;
assign o_clki2c_im_ahb_fifo_rd	        = (cdc_en)?     rise_clki2c_im_ahb_fifo_rd      :   i_hclk_im_ahb_fifo_rd       ;
assign o_clki2c_im_ahb_fifo_wr	        = (cdc_en)?     rise_clki2c_im_ahb_fifo_wr      :   i_hclk_im_ahb_fifo_wr       ;
assign o_clki2c_wr_apb                  = (cdc_en)?     rise_clki2c_wr_apb              :   i_hclk_wr_apb               ;
assign o_clki2c_rd_apb                  = (cdc_en)?     rise_clki2c_rd_apb              :   i_hclk_rd_apb               ; 
assign o_clki2c_fifo_full_tx            = (cdc_en)?     r1_clki2c_fifo_full_tx          :   i_hclk_fifo_full_tx         ;   
assign o_clki2c_wr_recv                 = (cdc_en)?     r1_clki2c_wr_recv               :   i_hclk_wr_recv              ;   
 
endmodule                         
