
`include "atciic100_config.vh"
`include "atciic100_const.vh"

module i2c (
	input  wire			CLK_I2C     ,
	input  wire			CLK_LP 	    ,
	input  wire			FCLK 	    ,

	// AHB Common
    input               RESET_IP    ,
	input  wire			TE          ,
	input  wire			SE          ,
	input  wire			HCLK_CG_EN  ,
	input  wire			HRESETn     ,
	input  wire			RESETN_HREADY	,
	input  wire			HCLK        ,
	input  wire			TEST_CLK    ,
	input  wire			TEST_RESET	,

	// AHB Master
	input  wire			HGRANT		,
	input  wire [31:0] 	HRDATA		,
	input  wire			HREADY		,
	input  wire [1:0]	HRESP		,
	output wire [31:0]	HADDR 		,
	output wire [1:0] 	HTRANS		,
	output wire			HWRITE		,
	output wire [2:0] 	HSIZE 		,
	output wire [2:0] 	HBURST		,
	output wire [3:0] 	HPROT 		,
	output wire [31:0]	HWDATA		,
	output wire			HLOCK		,
	output wire			HBUSREQ		,

	// AHB Slave
	input  wire [31:0]	S_HADDR     ,
	input  wire [ 2:0]	S_HSIZE     ,
	input  wire [ 1:0]	S_HTRANS    ,
	input  wire [31:0]	S_HWDATA    ,
	input  wire			S_HWRITE    ,
	input  wire			S_HSEL      ,
	input  wire			S_HREADY    ,
	output wire [31:0]  S_HRDATA    ,
	output wire			S_HREADYOUT ,
	output wire [ 1:0]	S_HRESP     ,

	output wire 		I2C2PMU_S_I2C_UPDATE				,
	output wire 		I2C2PMU_R_SI2C_AOPD_MAX				,
	output wire 		I2C2PMU_W_SI2C_EN					,
	output wire 		I2C2PMU_W_SI2C_WKU_EN				,
	output wire 		I2C2PMU_INT_ST_WAKEUP_CLR			,
	output wire [15:0]	I2C2PMU_W_SI2C_WKU_ADR				,
	output wire [7:0]	I2C2PMU_W_SI2C_WKU_CMD				,
	output wire [7:0]	I2C2PMU_W_PMU_STATUS				,
	output wire [6:0]	I2C2PMU_W_SI2C_ID					,
	output wire 		I2C2PMU_W_SI2C_ADR					,
	input wire			PMU2I2C_INTR_WAKEUP_I2C				,
	input wire			PMU2I2C_INT_ST_WAKEUP_CLR			,
	input wire [7:0]	PMU2I2C_W_SI2C_STATUS				,
	input wire			PMU2I2C_W_I2C_SIMPLE_STOP			,
	input wire			PMU2I2C_W_START_DETECT				,
	input wire			PMU2I2C_SI2C_UPDATE_ACK				,
	input wire	[5:0]	pmu_status	,

	input wire			use_ext_slv_id,
	input wire			ext_slv_id,

	input wire			SLEEPING    ,
	input wire			SLEEPDEEP   ,
	output wire			dma_req_rx  ,
	output wire			dma_req_tx  ,
	input wire			dma_ack_rx  ,
	input wire			dma_ack_tx  ,
    input wire          scl_i       ,
    input wire          sda_i       ,
    output wire         scl_o       ,
    output wire         sda_o       ,

    output wire         FLASH_ON    ,

	output wire			i2c_int     ,
	output wire			i2c_wakeup	
)/* synthesis syn_noprune=1 syn_preserve=1 syn_keep=1 */; 
//----------------------------------------------------------------------------
// Rest & Clock Control
//----------------------------------------------------------------------------
wire          sig_reset;
wire          sig_reset_hready;

assign sig_reset		= HRESETn & (TE|RESET_IP);
assign sig_reset_hready	= (FLASH_ON) ? sig_reset : (RESETN_HREADY & (TE|RESET_IP));

//----------------------------------------------------------------------------

wire    		w_si2c_update;
wire    		w_si2c_update_ack;
wire    		w_si2c_aopd;        // 0:i2c_core, 1:i2c_simple
reg    		    r_si2c_aopd_max;    // si2c_aopd_max set to high after i2c complete + w_si2c_aopd=1

wire [7:0] w_pmu_status = {r_si2c_aopd_max, w_si2c_aopd, pmu_status} ;

// i2c_core
wire      [5:2] paddr;
wire            pclk;
wire            penable;
wire            presetn;
wire            psel;
wire     [31:0] pwdata;
wire            pwrite;
wire     [31:0] prdata;
wire            scl_i_core      = r_si2c_aopd_max ? 1'b1 : scl_i ;
wire            sda_i_core      = r_si2c_aopd_max ? 1'b1 : sda_i ;
wire            scl_o_core;
wire            sda_o_core;
wire            start_cond;
wire            stop_cond;
wire            int_st_wakeup_clr;
wire     [`ATCIIC100_INDEX_WIDTH-1:0] entries_rx;
wire     [`ATCIIC100_INDEX_WIDTH-1:0] entries_tx;
wire     [`ATCIIC100_INDEX_WIDTH-1:0] x_i2c_entries;
wire     [2:0]  w_hclk_bit_cnt;

/*
// i2c_simple
wire			i_scl;
wire			i_sda;
wire      		i_scl_p		    = r_si2c_aopd_max ? scl_i : 1'b1 ;
wire    		i_sda_p		    = r_si2c_aopd_max ? sda_i : 1'b1 ;
wire			i_scl_;
wire			i_sda_;
CLK_AND I_I2C_SCL (.A(i_scl_p), .B(1'b1), .Y(i_scl_));
CLK_AND I_I2C_SDA (.A(i_sda_p), .B(1'b1), .Y(i_sda_));

CLK_MUX I_TMUX_SCL (.A(i_scl_), .B(TEST_CLK), .S(TE), .Y(i_scl));
CLK_MUX I_TMUX_SDA (.A(i_sda_), .B(TEST_CLK), .S(TE), .Y(i_sda));

wire      		i_scl_inv		= ~i_scl;
wire    		i_sda_inv		= ~i_sda;
wire      		o_scl			;
wire      		o_sda			;
*/

wire    [6:0]   w_si2c_id	;
wire    		w_si2c_en	;
wire  		    w_si2c_adr	;	//0:8bit, 1:16bit

wire    		w_si2c_wku_en   ;
wire    [15:0]  w_si2c_wku_adr	;
wire    [7:0]	w_si2c_wku_cmd	;
wire	[7:0]	w_si2c_status   ;    

//----------------------------------------------------------------------------
// wakeup
//----------------------------------------------------------------------------
wire      		intr_wakeup_i2c     ;
wire		    int_st_start        ;
wire		    int_st_stop         ;

assign i2c_wakeup = r_si2c_aopd_max? intr_wakeup_i2c : int_st_start && SLEEPING ;

//----------------------------------------------------------------------------
// i2c ahb master
//----------------------------------------------------------------------------
wire [9:0]	  x_delay   ;
wire [2:0]	  x_burst   ;
wire [2:0]	  x_size    ;
wire [1:0]	  x_rendian ;
wire [1:0]	  x_wendian ;
wire		  xfer_start;

wire          w_ahbm_prefix_match ;
wire		  int_st_addrhit;
wire		  int_st_cmpl ;
wire		  rdwt;
wire [31:0]	  x_prefix_addr ;
wire [31:0]	  x_flash_enter_addr ;
wire [31:0]	  x_flash_exit_addr ;
wire [5:0]	  w_state ;
wire          w_prefix_period ;
wire          ext_fifo_rd;
wire          ext_fifo_wr;
wire [`ATCIIC100_DATA_WIDTH-1:0] ext_fifo_wr_data;
wire		  sda;
wire          w_addr_fix_on;
wire          w_addr_fix_en;
wire          w_im_ahb_fifo_rd;
wire          w_im_ahb_fifo_wr;
wire          w_im_fifo_clr;
wire          w_i2c_master_idle;
wire          w_fifo_empty_rx;

wire          w_hclk_im_ahb_fifo_wr_mnt;

i2c_ahb_master I2C_AHB_MASTER ( 
    /*input         */	.int_st_stop                (int_st_cmpl	            ),
    /*input         */	.int_st_start	            (int_st_addrhit	            ),
    /*input         */	.rdwt	                    (rdwt	                    ),
    /*output		*/  .xfer_start                 (xfer_start                 ),
    /*input         */	.ext_fifo_rd	            (ext_fifo_rd	            ),
    /*input         */	.ext_fifo_wr	            (ext_fifo_wr	            ),
    /*input         */	.ext_fifo_wr_data	        (ext_fifo_wr_data	        ),
    /*input [5:0]   */	.entries_rx                 (entries_rx                 ),
    /*input [5:0]   */	.entries_tx                 (entries_tx                 ),
    /*input [5:0]   */	.x_i2c_entries	            (x_i2c_entries	            ),
    /*output		*/  .o_ahb_fifo_rd              (w_im_ahb_fifo_rd           ),
    /*output		*/  .o_ahb_fifo_wr              (w_im_ahb_fifo_wr           ),
    /*output		*/  .o_im_fifo_clr              (w_im_fifo_clr              ),
    /*input 		*/	.start_cond		            (start_cond		            ),
    /*output		*/  .o_i2c_master_idle          (w_i2c_master_idle          ),
    /*input 		*/	.i_hclk_im_ahb_fifo_wr_mnt	(w_hclk_im_ahb_fifo_wr_mnt	),
    /*input [2:0]   */	.i_hclk_bit_cnt	            (w_hclk_bit_cnt	            ),
    /*input 		*/	.fifo_empty_rx		        (w_fifo_empty_rx		    ),

    // registers
    /*input	[9:0]	*/  .EBMinitCount               (x_delay                    ),
    /*input	[2:0]	*/  .xfer_burst                 (x_burst                    ),
    /*input	[2:0]	*/  .xfer_size                  (x_size                     ),
    /*input	[1:0]	*/  .xfer_rendian               (x_rendian                  ),
    /*input	[1:0]	*/  .xfer_wendian               (x_wendian                  ),
    /*input	[31:0]	*/  .prefix_addr                (x_prefix_addr              ),
    /*input [31:0]	*/  .flash_enter_addr           (x_flash_enter_addr         ),
    /*input [31:0]	*/  .flash_exit_addr            (x_flash_exit_addr          ),
    /*output[5:0]	*/  .o_state                    (w_state	                ),
    /*output		*/  .o_ahbm_prefix_match        (w_ahbm_prefix_match        ),  
    /*output		*/  .FLASH_ON                   (FLASH_ON                   ),  
    /*output		*/  .o_prefix_period            (w_prefix_period            ),  
    /*output		*/  .o_addr_fix_on              (w_addr_fix_on              ),  
    /*input		    */  .i_addr_fix_en              (w_addr_fix_en              ),  
    
    // AHB signals
    /*input         */  .TE							(TE							),
    /*input         */  .TEST_RESET					(TEST_RESET					),
    /*input         */  .HCLK                       (HCLK                       ),
    /*input         */  .HRESETn                    (sig_reset                  ),
    /*input [31:0]  */  .HRDATA                     (HRDATA                     ),
    /*input         */  .HREADY                     (HREADY                     ),
    /*input [1:0]   */  .HRESP                      (HRESP                      ),
    /*input         */  .HGRANT                     (HGRANT                     ),
    /*input         */  .SCANENABLE                 (SE                         ),  // Scan Test Mode Enbl
    /*input         */  .SCANINHCLK                 (TEST_CLK                   ),  // Scan Chain Input
    /*output [31:0] */  .HADDR                      (HADDR                      ),
    /*output [1:0]  */  .HTRANS                     (HTRANS                     ),
    /*output        */  .HWRITE                     (HWRITE                     ),
    /*output [2:0]  */  .HSIZE                      (HSIZE                      ),
    /*output [2:0]  */  .HBURST                     (HBURST                     ),
    /*output [3:0]  */  .HPROT                      (HPROT                      ),
    /*output [31:0] */  .HWDATA                     (HWDATA                     ),
    /*output        */  .HBUSREQ                    (HBUSREQ                    ),
    /*output        */  .HLOCK                      (HLOCK                      ),
    /*output        */  .SCANOUTHCLK                (                           )  // Scan Chain Output
);  // i2c_ahb_master


//----------------------------------------------------------------------------
// i2c core
//----------------------------------------------------------------------------
atciic100 I_I2C_CORE (
    /*input         */	.CLK_I2C                        (CLK_I2C                    ), 
    /*input         */	.CLK_LP				            (CLK_LP                     ), 
    /*input         */	.FCLK				            (FCLK                       ),  
    	// AHB Common
    /*input  		*/	.TE				                (TE				            ),
    /*input  		*/	.SE				                (SE				            ),
    /*input        	*/	.HCLK_CG_EN	                    (HCLK_CG_EN	                ),
    /*input  		*/	.HRESETn		                (sig_reset		            ),
    /*input  		*/	.HRESETN_HREADY	                (sig_reset_hready			),
    /*input  		*/	.HCLK			                (HCLK   			        ),
    /*input  		*/	.SLEEPING			            (SLEEPING			        ),
    	// AHB Master registers
    /*output [9:0]	*/  .hclk_delay                     (x_delay                    ),
    /*output [2:0]	*/  .hclk_burst                     (x_burst                    ),
    /*output [2:0]	*/  .hclk_size                      (x_size                     ),
    /*output [1:0]	*/  .hclk_rendian                   (x_rendian                  ),
    /*output [1:0]	*/  .hclk_wendian                   (x_wendian                  ),
    /*output [31:0]	*/  .hclk_prefix_addr               (x_prefix_addr              ),
    /*output [31:0]	*/  .hclk_flash_enter_addr          (x_flash_enter_addr         ),
    /*output [31:0]	*/  .hclk_flash_exit_addr           (x_flash_exit_addr          ),
    /*input  [5:0]	*/  .hclk_state                     (w_state	                ),
    /*input		    */  .hclk_ahbm_prefix_match         (w_ahbm_prefix_match        ),  
    /*input		    */  .hclk_prefix_period             (w_prefix_period            ),  
    /*input		    */  .hclk_addr_fix_on               (w_addr_fix_on              ),  
    /*output	    */  .hclk_addr_fix_en               (w_addr_fix_en              ),  
    /*input		    */  .hclk_im_ahb_fifo_rd            (w_im_ahb_fifo_rd           ),
    /*input		    */  .hclk_im_ahb_fifo_wr            (w_im_ahb_fifo_wr           ),
    /*input		    */  .hclk_im_fifo_clr               (w_im_fifo_clr              ),
    /*input		    */  .hclk_i2c_master_idle           (w_i2c_master_idle          ),
    /*output		*/  .hclk_fifo_empty_rx             (w_fifo_empty_rx            ),
    	// AHB Slave
    /*input  [31:0]	*/	.S_HADDR		                (S_HADDR		            ),
    /*input  [ 2:0]	*/	.S_HSIZE		                (S_HSIZE		            ),
    /*input  [ 1:0]	*/	.S_HTRANS		                (S_HTRANS		            ),
    /*input  [31:0]	*/	.S_HWDATA		                (S_HWDATA		            ),
    /*input        	*/	.S_HWRITE		                (S_HWRITE		            ),
    /*input        	*/	.S_HSEL			                (S_HSEL			            ),
    /*input        	*/	.S_HREADY		                (S_HREADY		            ),
    /*output [31:0]	*/	.S_HRDATA		                (S_HRDATA		            ),
    /*output       	*/	.S_HREADYOUT	                (S_HREADYOUT	            ),
    /*output [ 1:0]	*/	.S_HRESP		                (S_HRESP		            ),
        // i2c_simple registers
    /*input         */	.si2c_intr_wakeup_i2c	        (intr_wakeup_i2c	        ),
    /*input  [7:0]	*/	.si2c_status	                (w_si2c_status	            ),
    /*input  	    */	.hclk_si2c_aopd_max	            (r_si2c_aopd_max	        ),
    /*input 		*/	.si2c_update_ack				(w_si2c_update_ack			),
    /*output 		*/	.si2c_update					(w_si2c_update	            ),
    /*output 		*/	.si2c_aopd		                (w_si2c_aopd	            ),
    /*output 		*/	.si2c_en		                (w_si2c_en		            ),
    /*output 		*/	.si2c_adr		                (w_si2c_adr		            ),
    /*output [6:0]	*/	.si2c_id		                (w_si2c_id		            ),
    /*output   		*/	.si2c_wku_en	                (w_si2c_wku_en	            ),
    /*output [15:0]	*/	.si2c_wku_adr	                (w_si2c_wku_adr	            ),
    /*output [07:0]	*/	.si2c_wku_cmd	                (w_si2c_wku_cmd	            ),
        // controls
	/*input wire	*/	.use_ext_slv_id					(use_ext_slv_id				),
	/*input wire	*/	.ext_slv_id						(ext_slv_id					),
    /*input         */	.scl_i                          (scl_i_core                 ),
    /*input         */	.sda_i                          (sda_i_core                 ),
    /*output        */	.clki2c_scl_o                   (scl_o_core                 ),
    /*output        */	.clki2c_sda_o                   (sda_o_core                 ),
    /*output 		*/	.fclk_start_cond		        (start_cond		            ),
    /*output        */	.hclk_int_st_start	            (int_st_start	            ),
    /*output        */	.hclk_int_st_addrhit	        (int_st_addrhit             ),
    /*output        */	.hclk_int_st_cmpl               (int_st_cmpl	            ),
    /*output        */	.hclk_int_st_stop               (int_st_stop	            ),
    /*input         */	.hclk_dma_ack_rx                (dma_ack_rx                 ),
    /*input         */	.hclk_dma_ack_tx                (dma_ack_tx                 ),
    /*output        */  .hclk_dma_req_rx                (dma_req_rx                 ),
    /*output        */  .hclk_dma_req_tx                (dma_req_tx                 ),
    /*output        */	.hclk_i2c_int                   (i2c_int                    ),
    /*output        */	.hclk_rd_cntlr	                (ext_fifo_rd	            ),
    /*output        */	.hclk_wr_cntlr	                (ext_fifo_wr	            ),
    /*output        */	.hclk_wr_data_cntlr	            (ext_fifo_wr_data	        ),
    /*output 		*/	.hclk_stop_cond		            (stop_cond		            ),
    /*output 		*/	.hclk_int_st_wakeup_clr	        (int_st_wakeup_clr	        ),
    /*output        */	.hclk_rdwt	                    (rdwt	                    ),
    /*output        */	.hclk_sda	                    (sda	                    ),
    /*output [5:0]  */	.hclk_entries_rx	            (entries_rx                 ),
    /*output [5:0]  */	.hclk_entries_tx	            (entries_tx                 ),
    /*output [5:0]  */	.hclk_i2c_entries	            (x_i2c_entries	            ),

    /*output        */	.hclk_im_ahb_fifo_wr_mnt	    (w_hclk_im_ahb_fifo_wr_mnt	),
    /*output [2:0]  */	.hclk_bit_cnt	                (w_hclk_bit_cnt	            )
);  // atciic100

//----------------------------------------------------------------------------
// i2c simple for deep sleep
//----------------------------------------------------------------------------
// synhronizer scl to HCLK domain
wire w_start_detect ;
reg r0_start_detect ;
reg r1_start_detect ;
wire w_i2c_simple_stop ;
reg r0_i2c_simple_stop ;
reg r1_i2c_simple_stop ;
always @ (negedge sig_reset or posedge HCLK) begin
    if(!sig_reset) begin
        r0_start_detect <= #1 1'b0 ;  
        r1_start_detect <= #1 1'b0 ;  
        r0_i2c_simple_stop <= #1 1'b0 ;  
        r1_i2c_simple_stop <= #1 1'b0 ;  
    end
    else begin
        r0_start_detect <= #1 w_start_detect ;  
        r1_start_detect <= #1 r0_start_detect ; 
        r0_i2c_simple_stop <= #1 w_i2c_simple_stop ;  
        r1_i2c_simple_stop <= #1 r0_i2c_simple_stop ;   
    end
end

reg r_i2c_simple_stop ;
reg r_i2c_core_stop ;
always @ (negedge sig_reset or posedge HCLK) begin
    if(!sig_reset) begin
        r_i2c_simple_stop <= #1 1'b0 ;        
        r_i2c_core_stop <= #1 1'b0 ;
    end
    else begin
        if(r1_i2c_simple_stop && sda) r_i2c_simple_stop <= #1 1'b1 ;    
        else if(r1_start_detect) r_i2c_simple_stop <= #1 1'b0 ;

        // jys 200424
        //if(int_st_cmpl && stop_cond) r_i2c_core_stop <= #1 1'b1 ;  
        if(stop_cond) r_i2c_core_stop <= #1 1'b1 ;  
        else if(int_st_addrhit) r_i2c_core_stop <= #1 1'b0 ;
    end
end

reg si2c_aopd_ctrl ;
//always @ (negedge sig_reset or posedge HCLK) begin
always @ (negedge sig_reset or posedge FCLK) begin  // for deepsleep mode enter without w_si2c_aopd register setting
    if(!sig_reset) begin
        si2c_aopd_ctrl <= #1 1'b0 ;
        r_si2c_aopd_max <= #1 1'b0 ;        // 0:i2c_core, 1:i2c_simple
    end
    else if(SLEEPDEEP) r_si2c_aopd_max <= #1 1'b1 ;   // i2c simple selected at deep sleep mode
    else if(intr_wakeup_i2c) r_si2c_aopd_max <= #1 1'b0 ;   // i2c core selected at deep sleep wake up
    else if(!si2c_aopd_ctrl) begin      
        r_si2c_aopd_max <= #1 w_si2c_aopd;  // initial i2c owner set
        if(r1_start_detect | int_st_addrhit) si2c_aopd_ctrl <= #1 1'b1 ;
    end
    else begin
        if(!w_si2c_aopd) r_si2c_aopd_max <= #1 1'b0 ;                           // i2c_simple -> i2c_core
        else if(w_si2c_aopd && r_i2c_core_stop) r_si2c_aopd_max <= #1 1'b1 ;    // i2c_core -> i2c_simple
    end
end

reg 		req_int_st_wakeup_clr;
reg [1:0]	sync_int_st_wakeup_clr;
always @ (negedge sig_reset or posedge FCLK)
    if(!sig_reset) begin
		req_int_st_wakeup_clr <= 1'b0;
		sync_int_st_wakeup_clr <= 'd0;
	end else begin
		sync_int_st_wakeup_clr <= {sync_int_st_wakeup_clr[0],PMU2I2C_INT_ST_WAKEUP_CLR};
		if(int_st_wakeup_clr) begin
			req_int_st_wakeup_clr <= 1'b1;
		end else if(req_int_st_wakeup_clr && sync_int_st_wakeup_clr[1]) begin
			req_int_st_wakeup_clr <= 1'b0;
		end
	end

/*
simple_i2c_slave I2C_SIMPLE (    
    .test_mode		    (TE				    ),
    .i_device_addr	    (w_si2c_id		    ),
    .resetn			    (HRESETn		    ),
                                            
    .i_scl			    (i_scl			    ),
    .i_scl_inv		    (i_scl_inv		    ),
    .i_sda			    (i_sda			    ),
    .i_sda_inv		    (i_sda_inv		    ),
    .o_scl			    (o_scl			    ),
    .o_sda			    (o_sda			    ),
                                            
    .i_pmu_mp_aopd	    (r_si2c_aopd_max	),
    .i_i2c_enable	    (w_si2c_en    		),
                                           
    .i_intr_wakeup_en   (w_si2c_wku_en		),
    .i_intr_wakeup_clr  (int_st_wakeup_clr	),
    .o_intr_wakeup_i2c  (intr_wakeup_i2c    ),
    .i_wakeup_addr	    (w_si2c_wku_adr	    ),
    .i_wakeup_cmd	    (w_si2c_wku_cmd	    ),
    .i_pmu_status	    (w_pmu_status	   	),
    .i_sel_addr_width   (w_si2c_adr			),  //0:8bit, 1:16bit
    .o_debug_status     (w_si2c_status		),

    .o_i2c_simple_stop	(w_i2c_simple_stop	),
    .o_start_detect	    (w_start_detect	   	)
);
*/

assign I2C2PMU_S_I2C_UPDATE			= w_si2c_update			;
assign I2C2PMU_R_SI2C_AOPD_MAX		= r_si2c_aopd_max		;
assign I2C2PMU_W_SI2C_EN			= w_si2c_en				;
assign I2C2PMU_W_SI2C_WKU_EN		= w_si2c_wku_en			;
assign I2C2PMU_INT_ST_WAKEUP_CLR	= req_int_st_wakeup_clr	;
assign I2C2PMU_W_SI2C_WKU_ADR		= w_si2c_wku_adr		;
assign I2C2PMU_W_SI2C_WKU_CMD		= w_si2c_wku_cmd		;
assign I2C2PMU_W_PMU_STATUS			= w_pmu_status			;
assign I2C2PMU_W_SI2C_ID			= w_si2c_id				;
assign I2C2PMU_W_SI2C_ADR			= w_si2c_adr			;

assign intr_wakeup_i2c		= PMU2I2C_INTR_WAKEUP_I2C;
assign w_si2c_status		= PMU2I2C_W_SI2C_STATUS;
assign w_i2c_simple_stop	= PMU2I2C_W_I2C_SIMPLE_STOP;
assign w_start_detect		= PMU2I2C_W_START_DETECT;
assign w_si2c_update_ack 	= PMU2I2C_SI2C_UPDATE_ACK;

// output mux
assign scl_o = scl_o_core ;
assign sda_o = sda_o_core ;

endmodule
