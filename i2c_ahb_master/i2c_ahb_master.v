
`include "atciic100_config.vh"
`include "atciic100_const.vh"

module i2c_ahb_master (
    input		  int_st_stop,
    input		  int_st_start,
    input		  rdwt,
    output		  xfer_start,
	output reg    FLASH_ON,
    input		  ext_fifo_rd,
    input		  ext_fifo_wr,
    input         [`ATCIIC100_DATA_WIDTH-1:0] ext_fifo_wr_data,
    input         [`ATCIIC100_INDEX_WIDTH-1:0] entries_rx,
    input         [`ATCIIC100_INDEX_WIDTH-1:0] entries_tx,
    input         [`ATCIIC100_INDEX_WIDTH-1:0] x_i2c_entries,
    output        o_ahb_fifo_rd,
    output        o_ahb_fifo_wr,
    output        o_im_fifo_clr,
	input         start_cond,
    output        o_i2c_master_idle,
	input         i_hclk_im_ahb_fifo_wr_mnt,
    input  [2:0]  i_hclk_bit_cnt,
	input         fifo_empty_rx,

    // registers
    input  [9:0]  EBMinitCount,
    input  [2:0]  xfer_burst,
    input  [2:0]  xfer_size,
    input  [1:0]  xfer_rendian,
    input  [1:0]  xfer_wendian,
    input  [31:0] prefix_addr,
    input  [31:0] flash_enter_addr,
    input  [31:0] flash_exit_addr,
	output reg    o_ahbm_prefix_match,
    output		  o_prefix_period,
    output [5:0]  o_state,          // read only
    output        o_addr_fix_on,    // read only
    input         i_addr_fix_en,
    
    //------------------------------------------------------
    // AHB signals
    //------------------------------------------------------
    // Global signals
    input         TE,
    input         TEST_RESET,
    input         HCLK,
    input         HRESETn,
    // Signals from AHB
    input [31:0]  HRDATA,
    input         HREADY,
    input [1:0]   HRESP,
    input         HGRANT,
    // Scan test dummy inputs, not connected until scan insertion    
    input         SCANENABLE,  // Scan Test Mode Enbl
    input         SCANINHCLK,  // Scan Chain Input
    // Signals to AHB
    output [31:0] HADDR,
    output [1:0]  HTRANS,
    output        HWRITE,
    output [2:0]  HSIZE,
    output [2:0]  HBURST,
    output [3:0]  HPROT,
    output [31:0] HWDATA,
    output        HBUSREQ,
    output        HLOCK,
    // Scan test dummy output, not connected until scan insertion    
    output        SCANOUTHCLK // Scan Chain Output
);

`include "io.inc"
parameter I2C_FIFO_ADDRESS  = I2C_BASE + 8'h20 ;    // i2c_core fifo read register address

parameter IDLE              = 6'd0 ;	
parameter READY             = 6'd1 ;		
parameter PREFIX_ST0        = 6'd2 ;		
parameter PREFIX_ST1        = 6'd3 ;		
parameter PREFIX_ST2        = 6'd4 ;		
parameter PREFIX_ST3        = 6'd5 ;		
parameter PREFIX_ADDR0      = 6'd6 ;		
parameter PREFIX_ADDR1      = 6'd7 ;		
parameter PREFIX_ADDR2      = 6'd8 ;		
parameter PREFIX_ADDR3      = 6'd9 ;		
parameter PREFIX_ADDR4      = 6'd10;		
parameter WAIT              = 6'd11;			
parameter PRE_TX_DAT_RD_ST0 = 6'd12;				
parameter PRE_TX_DAT_RD_ST1 = 6'd13;					
parameter PRE_TX_DAT_RD_ST2 = 6'd14;						
parameter PRE_TX_DAT_RD     = 6'd15;				
parameter PRE_TX_DAT_WR_ST0 = 6'd16;	
parameter PRE_TX_DAT_WR_ST1 = 6'd17;		
parameter PRE_TX_DAT_WR_ST2 = 6'd18;		
parameter PRE_TX_DAT_WR_ST3 = 6'd19;		
parameter START             = 6'd20;		
parameter RX_TX_SEL         = 6'd21;			
parameter RX_ST             = 6'd22;		
parameter RX_DAT_RD_ST0     = 6'd23;			
parameter RX_DAT_RD_ST1     = 6'd24;				
parameter RX_DAT_RD_ST2     = 6'd25;				
parameter RX_DAT_RD         = 6'd26;		
parameter RX_DAT_WR_ST0     = 6'd27;		
parameter RX_DAT_WR_ST1     = 6'd28;			
parameter RX_DAT_WR_ST2     = 6'd29;		
parameter RX_DAT_WR         = 6'd30;		
parameter TX_DAT_RD_ST0     = 6'd31;				
parameter TX_DAT_RD_ST1     = 6'd32;					
parameter TX_DAT_RD_ST2     = 6'd33;						
parameter TX_DAT_RD         = 6'd34;				
parameter TX_DAT_WR_ST0     = 6'd35;	
parameter TX_DAT_WR_ST1     = 6'd36;		
parameter TX_DAT_WR_ST2     = 6'd37;		
parameter TX_DAT_WR         = 6'd38;	
parameter END               = 6'd39;		

wire	    x_write ;
wire	    x_read	;
wire [31:0] x_addr	;
wire [31:0] x_din	;
wire [31:0] x_dout  ; 
                                     
reg [5:0]   r_state ;
reg	        r_write  ;
reg	        r_read	;
reg [31:0]  r_addr	;
reg [31:0]  r_din	;

// prefix
reg [2:0]   r_pref_cnt   ;
reg [31:0]  r_pref       ;
reg [31:0]  r_pref_addr  ;
reg [31:0]  r_pref_tmp   ;
reg [31:0]  r_wr_data    ; 

// prefill for read
reg [2:0]   r_pre_cnt    ; 
reg         r_pre_rx     ;    
reg         r_pre_tx     ;    

reg r_ahb_fifo_rd ;
reg r_ahb_fifo_wr ;
wire w_ahb_fifo_rd = (r_state==RX_DAT_RD_ST2 && HREADY)? 1'b1 : 1'b0 ;
wire w_ahb_fifo_wr = ((r_state==TX_DAT_WR_ST2 || r_state==PRE_TX_DAT_WR_ST2) && HREADY)? 1'b1 : 1'b0 ;
assign o_ahb_fifo_rd = w_ahb_fifo_rd ;
assign o_ahb_fifo_wr = w_ahb_fifo_wr ;

reg r_read_d0 ;
reg r_write_d0 ;
reg r_int_st_stop_d0 ;
reg r_int_st_start_d0 ;
reg r_prefix_period ;
reg r_addr_fix_on ;
assign  o_prefix_period = r_prefix_period ;
assign o_addr_fix_on = r_addr_fix_on ;

wire rise_int_st_stop = int_st_stop & ~r_int_st_stop_d0 ;
wire rise_int_st_start = int_st_start & ~r_int_st_start_d0 ;

reg r_idle;
reg r_i2c_write_stop_d0 ;
reg r_i2c_write_stop_d1 ;
reg r_i2c_read_stop ;
wire i2c_write_stop = fifo_empty_rx && r_idle ;
wire rise_i2c_write_stop = r_i2c_write_stop_d0 & ~r_i2c_write_stop_d1 ;
assign o_i2c_master_idle = i2c_write_stop | r_i2c_read_stop;

always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r_read_d0 <= #1 1'b0 ;
        r_write_d0 <= #1 1'b0 ;
        r_int_st_stop_d0 <= #1 1'b0 ;
        r_int_st_start_d0 <= #1 1'b0 ;
        r_i2c_write_stop_d0 <= #1 1'b0 ;
        r_i2c_write_stop_d1 <= #1 1'b0 ;
    end
    else begin
        r_read_d0 <= #1 r_read ;
        r_write_d0 <= #1 r_write ;
        r_int_st_stop_d0 <= #1 int_st_stop ;
        r_int_st_start_d0 <= #1 int_st_start ;
        r_i2c_write_stop_d1 <= #1 r_i2c_write_stop_d0 ;
        if(rise_int_st_start) r_i2c_write_stop_d0 <= #1 1'b0 ;
        else if(i2c_write_stop && x_write) r_i2c_write_stop_d0 <= #1 1'b1 ;
    end
end    
wire rise_rx_read = r_read & ~r_read_d0 ;
wire rise_rx_write = r_write & ~r_write_d0 ;

always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r_idle <= #1 'd1 ;
        r_i2c_read_stop <= #1 'd0 ;
    end
    else begin
        if(rise_int_st_start) r_idle <= #1 'd0 ;
        else if(rise_int_st_stop) r_idle <= #1 'd1 ;
        if(rise_int_st_start) r_i2c_read_stop <= #1 'd0 ;
        else if(rdwt && rise_int_st_stop) r_i2c_read_stop <= #1 'd1 ;
    end
end    

assign x_write  =   rise_rx_write   ;
assign x_read	=   rise_rx_read    ;
assign x_addr	=   r_addr          ;
assign x_din	=   r_din           ;

wire prefix_fifo_data_match =       (r_pref_cnt == 'd3 && prefix_addr[31:24] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (r_pref_cnt == 'd2 && prefix_addr[23:16] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (r_pref_cnt == 'd1 && prefix_addr[15: 8] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (r_pref_cnt == 'd0 && prefix_addr[ 7: 0] == ext_fifo_wr_data[7:0] && ext_fifo_wr) ;
                        
wire prefix_addr_fix_on     =       (r_pref_cnt == 'd0 && (prefix_addr[7:0]+1'b1) == ext_fifo_wr_data[7:0] && ext_fifo_wr) || i_addr_fix_en ;

reg r_im_fifo_clr_d0 ;
reg r_im_fifo_clr_d1 ;
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r_im_fifo_clr_d1 <= #1 'd0 ;
    end
    else begin
        r_im_fifo_clr_d1 <= #1 r_im_fifo_clr_d0 ;
    end
end    
assign o_im_fifo_clr = r_im_fifo_clr_d0 & ~r_im_fifo_clr_d1 ;

/////////////////////////////////////////////////////////////////////////////////
//	FSM for I2C_CORE to AHB_MASTER
/////////////////////////////////////////////////////////////////////////////////

// AHB Master Data Read FSM
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        r_state             <= #1 IDLE ;
        r_write             <= #1 'd0 ;
        r_read	            <= #1 'd0 ;
        r_addr	            <= #1 'd0 ;
        r_din	            <= #1 'd0 ;

        r_pref_cnt          <= #1 'd3 ;
        r_pref              <= #1 'd0 ;
        r_pref_addr         <= #1 'd0 ;
        r_pref_tmp          <= #1 'd0 ;
        r_wr_data           <= #1 'd0 ;
        r_prefix_period     <= #1 'd0 ;
        o_ahbm_prefix_match <= #1 'd0 ;
        r_addr_fix_on       <= #1 'd0 ;
        r_im_fifo_clr_d0    <= #1 'd0 ;
        r_pre_cnt           <= #1 'd3 ;
        r_pre_rx            <= #1 'd0 ;
        r_pre_tx            <= #1 'd0 ;
    end
    else begin
        case (r_state)
            IDLE : begin
                if(rise_int_st_start) r_state <= #1 READY ;
                else r_state <= #1 IDLE ;
            end
            READY : begin
                r_pref_cnt <= #1 'd3 ;
                r_prefix_period <= #1 'd0 ;
                o_ahbm_prefix_match <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    if(prefix_fifo_data_match) begin
                        r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        r_state <= #1 PREFIX_ST0 ; 
                    end    
                    else r_state <= #1 IDLE ;
                end
            end
            PREFIX_ST0 : begin  
                r_pref_cnt <= #1 'd2 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    if(prefix_fifo_data_match) begin
                        r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        r_state <= #1 PREFIX_ST1 ; 
                    end
                    else if(prefix_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        r_state <= #1 PREFIX_ST0 ; 
                    end    
                    else r_state <= #1 READY ;
                end
            end
            PREFIX_ST1 : begin  
                r_pref_cnt <= #1 'd1 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    if(prefix_fifo_data_match) begin
                        r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        r_state <= #1 PREFIX_ST2 ; 
                    end
                    else if(prefix_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        r_state <= #1 PREFIX_ST0 ; 
                    end    
                    else r_state <= #1 READY ;
                end
            end
            PREFIX_ST2 : begin  
                r_pref_cnt <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    //if(prefix_fifo_data_match) begin
                    if(prefix_fifo_data_match | prefix_addr_fix_on) begin
                        r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        r_state <= #1 PREFIX_ST3 ;                         
                        if(prefix_addr_fix_on) r_addr_fix_on       <= #1 'd1 ;
                    end
                    else if(prefix_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        r_state <= #1 PREFIX_ST0 ; 
                    end  
                    else r_state <= #1 READY ;
                end
            end
            PREFIX_ST3 : begin
                r_pref_cnt <= #1 'd3 ;
                r_pref <= #1 r_pref_tmp  ;
                if(rise_int_st_stop) r_state <= #1 END ;
                //else if(r_pref_tmp == prefix_addr) begin    // prefix_addr = 32'hA12C_A12C; anapass i2c (A12C)
                else if(r_pref_tmp == prefix_addr | r_addr_fix_on) begin    // prefix_addr = 32'hA12C_A12C; anapass i2c (A12C)
                    r_state <= #1 PREFIX_ADDR0 ;
                end    
                else r_state <= #1 IDLE ;
            end
            PREFIX_ADDR0 : begin  
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                    r_state <= #1 PREFIX_ADDR1 ; 
                end
            end
            PREFIX_ADDR1 : begin  
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                    r_state <= #1 PREFIX_ADDR2 ; 
                end
            end
            PREFIX_ADDR2 : begin  
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                    r_state <= #1 PREFIX_ADDR3 ; 
                end
            end
            PREFIX_ADDR3 : begin  
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(ext_fifo_wr) begin
                    r_pref_tmp <= #1 (r_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                    r_state <= #1 PREFIX_ADDR4 ; 
                end
            end
            PREFIX_ADDR4 : begin
                r_prefix_period <= #1 'd1 ;
                o_ahbm_prefix_match <= #1 'd1 ;
                r_pref <= #1 r_pref_tmp  ;
                if(rise_int_st_stop) begin 
                    r_im_fifo_clr_d0 <= #1 'd1 ;
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 WAIT ;
                end
            end

            WAIT : begin
                r_im_fifo_clr_d0 <= #1 'd0 ;
                r_pre_cnt <= #1 'd3 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(start_cond) r_state <= #1 PRE_TX_DAT_RD_ST0 ;   // i2c data start !!    
                else r_state <= #1 WAIT ;
            end
            PRE_TX_DAT_RD_ST0 : begin
                r_read <= #1 'd1 ;
                r_addr <= #1 r_pref_addr ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else if(xfer_start) begin
                    if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 PRE_TX_DAT_RD_ST2 ;  
                    else r_state <= #1 PRE_TX_DAT_RD_ST1 ;
                end    

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end
            PRE_TX_DAT_RD_ST1 : begin
                r_read <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 PRE_TX_DAT_RD_ST2 ;

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end
            PRE_TX_DAT_RD_ST2 : begin
                r_read <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else if(HREADY) r_state <= #1 PRE_TX_DAT_RD ;   // hready for master grant input 

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end
            PRE_TX_DAT_RD : begin
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else begin   
                    if(!r_addr_fix_on) r_pref_addr <= #1 r_pref_addr + 'd1 ;

                    if(r_addr[1:0] == 'd0) r_wr_data <= #1 x_dout[7:0] ;
                    else if(r_addr[1:0] == 'd1) r_wr_data <= #1 x_dout[15:8] ;
                    else if(r_addr[1:0] == 'd2) r_wr_data <= #1 x_dout[23:16] ;
                    else if(r_addr[1:0] == 'd3) r_wr_data <= #1 x_dout[31:24] ;
                    r_state <= #1 PRE_TX_DAT_WR_ST0 ;
                end

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end
            PRE_TX_DAT_WR_ST0 : begin
                r_write <= #1 'd1 ;
                r_addr <= #1 I2C_FIFO_ADDRESS ;
                r_din <= #1 r_wr_data ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else if(xfer_start) begin
                    if(HREADY && HGRANT && HTRANS[1]) begin
                        r_state <= #1 PRE_TX_DAT_WR_ST2 ;  
                    end    
                    else r_state <= #1 PRE_TX_DAT_WR_ST1 ; 
                end    

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end
            PRE_TX_DAT_WR_ST1 : begin
                r_write <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else if(HREADY && HGRANT && HTRANS[1]) begin
                    r_state <= #1 PRE_TX_DAT_WR_ST2 ; 
                end    

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end
            PRE_TX_DAT_WR_ST2 : begin
                r_write <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else if(HREADY) begin // hready for master grant input
                    if(r_pre_cnt=='d0) begin
                        if(r_pre_tx) r_state <= #1 TX_DAT_RD_ST0 ;  // Tx     
                        else r_state <= #1 START ;
                    end    
                    else begin
                        r_pre_cnt <= #1 r_pre_cnt - 'd1 ;
                        r_state <= #1 PRE_TX_DAT_WR_ST3 ;  
                    end
                end    

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end
            PRE_TX_DAT_WR_ST3 : begin   // wait for different frequency domain
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(rise_int_st_start && ~rdwt) begin   
                    // fifo to be cleard
                    r_pre_rx <= #1 'd1 ;  // Rx
                    r_pref_addr <= #1 r_pref_tmp  ;
                    r_state <= #1 RX_ST ;
                end
                else if(HREADY) begin
                    if(r_pre_tx) r_state <= #1 TX_DAT_RD_ST0 ;  // Tx     
                    else if(~i_hclk_im_ahb_fifo_wr_mnt) r_state <= #1 PRE_TX_DAT_RD_ST0 ;    
                end    
                else r_state <= #1 PRE_TX_DAT_WR_ST3 ;

                if(rise_int_st_start && rdwt) r_pre_tx <= #1 'd1 ;  // Tx
            end

            START : begin
                r_pre_cnt <= #1 'd3 ;
                r_pre_rx <= #1 'd0 ;
                r_pre_tx <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(rise_int_st_start) r_state <= #1 RX_TX_SEL ;    
                else r_state <= #1 START ;
            end
            RX_TX_SEL : begin
                r_pre_cnt <= #1 'd3 ;
                r_pre_rx <= #1 'd0 ;
                r_pre_tx <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else begin
                    if(rdwt) r_state <= #1 TX_DAT_RD_ST0 ;  // Tx 
                    else begin // fifo to be cleard         // Rx
                        r_pref_addr <= #1 r_pref_tmp  ;
                        r_state <= #1 RX_ST ;
                    end    
                end    
            end
            RX_ST : begin
                r_write <= #1 'd0 ;
                r_read <= #1 'd0 ;
                r_pre_rx <= #1 'd0 ;
                r_pre_tx <= #1 'd0 ;
                r_pre_cnt <= #1 'd3 ;
                if(i_hclk_bit_cnt == 'd1) r_im_fifo_clr_d0 <= #1 'd1 ;
                else r_im_fifo_clr_d0 <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(ext_fifo_wr) r_state <= #1 RX_DAT_RD_ST0 ; 
            end
            RX_DAT_RD_ST0 : begin
                r_read <= #1 'd1 ;
                r_addr <= #1 I2C_FIFO_ADDRESS ;
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else if(xfer_start) begin
                    if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 RX_DAT_RD_ST2 ;  
                    else r_state <= #1 RX_DAT_RD_ST1 ;    // read start wait
                end    
            end
            RX_DAT_RD_ST1 : begin
                r_read <= #1 'd0 ;
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 RX_DAT_RD_ST2 ;  
            end
            RX_DAT_RD_ST2 : begin
                r_read <= #1 'd0 ;
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else if(HREADY) r_state <= #1 RX_DAT_RD ;   // hready for master grant input     
            end
            RX_DAT_RD : begin
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else begin   
                    r_wr_data <= #1 {x_dout[7:0], x_dout[7:0], x_dout[7:0], x_dout[7:0]} ;
                    r_state <= #1 RX_DAT_WR_ST0 ;
                end
            end
            RX_DAT_WR_ST0 : begin
                r_write <= #1 'd1 ;
                r_addr <= #1 r_pref_addr ;
                r_din <= #1 r_wr_data ;
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else if(xfer_start) begin
                    if(!r_addr_fix_on) r_pref_addr <= #1 r_pref_addr + 'd1 ;
                    
                    if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 RX_DAT_WR_ST2 ;  
                    else r_state <= #1 RX_DAT_WR_ST1 ; 
                end    
            end
            RX_DAT_WR_ST1 : begin
                r_write <= #1 'd0 ;
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 RX_DAT_WR_ST2 ; 
            end
            RX_DAT_WR_ST2 : begin
                r_write <= #1 'd0 ;
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else if(HREADY) r_state <= #1 RX_DAT_WR ;   // hready for master grant input 
            end
            RX_DAT_WR : begin
                if(rise_i2c_write_stop) r_state <= #1 END ; 
                else if(r_idle) begin
                    if(fifo_empty_rx) r_state <= #1 END ; 
                    else r_state <= #1 RX_DAT_RD_ST0 ; 
                end
                else if(entries_rx!=0 && entries_rx>=x_i2c_entries) r_state <= #1 RX_DAT_RD_ST0 ; 
                else if(ext_fifo_wr) r_state <= #1 RX_DAT_RD_ST0 ; 
            end
            TX_DAT_RD_ST0 : begin
                r_read <= #1 'd1 ;
                r_pre_cnt <= #1 'd3 ;
                r_pre_tx <= #1 'd0 ;
                r_addr <= #1 r_pref_addr ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(xfer_start) begin
                    if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 TX_DAT_RD_ST2 ;  
                    else r_state <= #1 TX_DAT_RD_ST1 ;
                end    
            end
            TX_DAT_RD_ST1 : begin
                r_read <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 TX_DAT_RD_ST2 ;
            end
            TX_DAT_RD_ST2 : begin
                r_read <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ; 
                else if(HREADY) r_state <= #1 TX_DAT_RD ;   // hready for master grant input 
            end
            TX_DAT_RD : begin
                if(rise_int_st_stop) r_state <= #1 END ; 
                else begin   
                    if(!r_addr_fix_on) r_pref_addr <= #1 r_pref_addr + 'd1 ;

                    if(r_addr[1:0] == 'd0) r_wr_data <= #1 x_dout[7:0] ;
                    else if(r_addr[1:0] == 'd1) r_wr_data <= #1 x_dout[15:8] ;
                    else if(r_addr[1:0] == 'd2) r_wr_data <= #1 x_dout[23:16] ;
                    else if(r_addr[1:0] == 'd3) r_wr_data <= #1 x_dout[31:24] ;
                    r_state <= #1 TX_DAT_WR_ST0 ;
                end
            end
            TX_DAT_WR_ST0 : begin
                r_write <= #1 'd1 ;
                r_addr <= #1 I2C_FIFO_ADDRESS ;
                r_din <= #1 r_wr_data ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(xfer_start) begin
                    if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 TX_DAT_WR_ST2 ;  
                    else r_state <= #1 TX_DAT_WR_ST1 ; 
                end    
            end
            TX_DAT_WR_ST1 : begin
                r_write <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(HREADY && HGRANT && HTRANS[1]) r_state <= #1 TX_DAT_WR_ST2 ; 
            end
            TX_DAT_WR_ST2 : begin
                r_write <= #1 'd0 ;
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(HREADY) r_state <= #1 TX_DAT_WR ;   // hready for master grant input 
            end
            TX_DAT_WR : begin
                if(rise_int_st_stop) r_state <= #1 END ;
                else if(entries_tx < 4) r_state <= #1 TX_DAT_RD_ST0 ; 
                else if(ext_fifo_rd) r_state <= #1 TX_DAT_RD_ST0 ; 
            end
            END : begin
                r_state             <= #1 IDLE ;
                r_write             <= #1 'd0 ;
                r_read	            <= #1 'd0 ;
                r_addr	            <= #1 'd0 ;
                r_din	            <= #1 'd0 ;

                r_pref_cnt          <= #1 'd3 ;
                r_pref              <= #1 'd0 ;
                r_pref_addr         <= #1 'd0 ;
                r_pref_tmp          <= #1 'd0 ;
                r_wr_data           <= #1 'd0 ;
                r_im_fifo_clr_d0    <= #1 'd0 ;
                r_prefix_period     <= #1 'd0 ;
                r_addr_fix_on       <= #1 'd0 ;
                r_pre_cnt           <= #1 'd3 ;
                r_pre_rx            <= #1 'd0 ;
                r_pre_tx            <= #1 'd0 ;
            end
            default : begin
                r_state             <= #1 IDLE ;
                r_write             <= #1 'd0 ;
                r_read	            <= #1 'd0 ;
                r_addr	            <= #1 'd0 ;
                r_din	            <= #1 'd0 ;

                r_pref_cnt          <= #1 'd3 ;
                r_pref              <= #1 'd0 ;
                r_pref_addr         <= #1 'd0 ;
                r_pref_tmp          <= #1 'd0 ;
                r_wr_data           <= #1 'd0 ;
                o_ahbm_prefix_match <= #1 'd0 ;
                r_im_fifo_clr_d0    <= #1 'd0 ;
                r_prefix_period     <= #1 'd0 ;
                r_addr_fix_on       <= #1 'd0 ;
                r_pre_cnt           <= #1 'd3 ;
                r_pre_rx            <= #1 'd0 ;
                r_pre_tx            <= #1 'd0 ;
            end
        endcase
    end
end

reg [5:0] d_state ;
always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) d_state <= #1 'd0 ;
    else d_state <= #1 r_state ;
end
assign o_state = d_state ;

/////////////////////////////////////////////////////////////////////////////////
//	AHB Master
/////////////////////////////////////////////////////////////////////////////////

wire w_HRESETn_p = HRESETn && (~r_pre_rx) ;
wire w_HRESETn;
CLK_MUX I_TMUX_HRESETN (.A(w_HRESETn_p), .B(TEST_RESET), .S(TE), .Y(w_HRESETn));

EgMaster I_AHB_MASTER (
	
	.EBMwenable		(x_write	    ),
	.EBMrenable		(x_read		    ),
	.EBMAddr		(x_addr		    ),
	.EBMDin			(x_din		    ),
	.EBMDout		(x_dout		    ),
	.EBMinitCount	(EBMinitCount   ),

	.xfer_burst		(xfer_burst	    ),
	.xfer_size		(xfer_size	    ),
	.xfer_rendian	(xfer_rendian   ),
	.xfer_wendian	(xfer_wendian   ),
	.xfer_done		(xfer_start		),
	
    // AHB signals
	.HCLK			(HCLK		    ),
	//.HRESETn		(HRESETn	    ),
	.HRESETn		(w_HRESETn	    ),
	
	.HRDATA			(HRDATA	        ),
	.HREADY			(HREADY	        ),
	.HRESP			(HRESP          ),
	.HGRANT			(HGRANT	        ),

	.SCANENABLE		(SCANENABLE     ),
	.SCANINHCLK		(SCANINHCLK	    ),
	
	.HADDR			(HADDR	        ),
	.HTRANS			(HTRANS	        ),
	.HWRITE			(HWRITE	        ),
	.HSIZE			(HSIZE	        ),
	.HBURST			(HBURST	        ),
	.HPROT			(HPROT	        ),
	.HWDATA			(HWDATA	        ),
	.HBUSREQ		(HBUSREQ	    ),
	.HLOCK			(HLOCK	        ),
	
	.SCANOUTHCLK	(SCANOUTHCLK    )
);


/////////////////////////////////////////////////////////////////////////////////
//	FSM for flash enter & exit special function
/////////////////////////////////////////////////////////////////////////////////

parameter FLASH_IDLE              = 4'd0 ;	
parameter FLASH_READY             = 4'd1 ;		
parameter FLASH_PREFIX_ST0        = 4'd2 ;		
parameter FLASH_PREFIX_ST1        = 4'd3 ;		
parameter FLASH_PREFIX_ST2        = 4'd4 ;		
parameter FLASH_PREFIX_ST3        = 4'd5 ;		
parameter FLASH_PREFIX_ON         = 4'd6 ;	
parameter FLASH_PREFIX_READY      = 4'd7 ;		
parameter FLASH_PREFIX_ED0        = 4'd8 ;		
parameter FLASH_PREFIX_ED1        = 4'd9 ;		
parameter FLASH_PREFIX_ED2        = 4'd10;		
parameter FLASH_PREFIX_ED3        = 4'd11;		
parameter FLASH_PREFIX_ED4        = 4'd12;			
parameter FLASH_PREFIX_OFF        = 4'd13;			
parameter FLASH_END               = 4'd14;		
                                     
reg [3:0]   f_state ;
reg [1:0]   f_pref_cnt   ;
reg [31:0]  f_pref       ;
reg [31:0]  f_pref_tmp   ;

wire flash_on_fifo_data_match =     (f_pref_cnt == 'd3 && flash_enter_addr[31:24] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (f_pref_cnt == 'd2 && flash_enter_addr[23:16] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (f_pref_cnt == 'd1 && flash_enter_addr[15: 8] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (f_pref_cnt == 'd0 && flash_enter_addr[ 7: 0] == ext_fifo_wr_data[7:0] && ext_fifo_wr) ;
wire flash_off_fifo_data_match =    (f_pref_cnt == 'd3 && flash_exit_addr[31:24] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (f_pref_cnt == 'd2 && flash_exit_addr[23:16] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (f_pref_cnt == 'd1 && flash_exit_addr[15: 8] == ext_fifo_wr_data[7:0] && ext_fifo_wr) |
                                    (f_pref_cnt == 'd0 && flash_exit_addr[ 7: 0] == ext_fifo_wr_data[7:0] && ext_fifo_wr) ;

always @ (negedge HRESETn or posedge HCLK) begin
    if(!HRESETn) begin
        FLASH_ON            <= #1 'd0 ;
        f_state             <= #1 FLASH_IDLE ;
        f_pref_cnt          <= #1 'd3 ;
        f_pref              <= #1 'd0 ;
        f_pref_tmp          <= #1 'd0 ;
    end
    else begin
        case (f_state)
            FLASH_IDLE : begin
                FLASH_ON <= #1 'd0 ;
                if(rise_int_st_start) f_state <= #1 FLASH_READY ;
                else f_state <= #1 FLASH_IDLE ;
            end
            FLASH_READY : begin
                FLASH_ON <= #1 'd0 ;
                f_pref_cnt <= #1 'd3 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_END ;
                else if(ext_fifo_wr) begin
                    if(flash_on_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ST0 ; 
                    end    
                    else f_state <= #1 FLASH_IDLE ;
                end
            end
            FLASH_PREFIX_ST0 : begin  
                FLASH_ON <= #1 'd0 ;
                f_pref_cnt <= #1 'd2 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_END ;
                else if(ext_fifo_wr) begin
                    if(flash_on_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ST1 ; 
                    end
                    else if(flash_enter_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ST0 ; 
                    end    
                    else f_state <= #1 FLASH_READY ;
                end
            end
            FLASH_PREFIX_ST1 : begin  
                FLASH_ON <= #1 'd0 ;
                f_pref_cnt <= #1 'd1 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_END ;
                else if(ext_fifo_wr) begin
                    if(flash_on_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ST2 ; 
                    end
                    else if(flash_enter_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ST0 ; 
                    end    
                    else f_state <= #1 FLASH_READY ;
                end
            end
            FLASH_PREFIX_ST2 : begin  
                FLASH_ON <= #1 'd0 ;
                f_pref_cnt <= #1 'd0 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_END ;
                else if(ext_fifo_wr) begin
                    if(flash_on_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ST3 ; 
                    end
                    else if(flash_enter_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ST0 ; 
                    end  
                    else f_state <= #1 FLASH_READY ;
                end
            end
            FLASH_PREFIX_ST3 : begin
                FLASH_ON <= #1 'd0 ;
                f_pref_cnt <= #1 'd3 ;
                f_pref <= #1 f_pref_tmp  ;
                if(rise_int_st_stop) f_state <= #1 FLASH_END ;
                else if(f_pref_tmp == flash_enter_addr) f_state <= #1 FLASH_PREFIX_ON ;
                else f_state <= #1 FLASH_IDLE ;
            end
            FLASH_PREFIX_ON : begin
                FLASH_ON <= #1 'd1 ;
                if(rise_int_st_start) f_state <= #1 FLASH_PREFIX_READY ;    
                else f_state <= #1 FLASH_PREFIX_ON ;
            end
            FLASH_PREFIX_READY : begin
                FLASH_ON <= #1 'd1 ;
                f_pref_cnt <= #1 'd3 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_PREFIX_ON ;
                else if(ext_fifo_wr) begin
                    if(flash_off_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ED0 ; 
                    end    
                    else f_state <= #1 FLASH_PREFIX_ON ;
                end
            end
            FLASH_PREFIX_ED0 : begin  
                FLASH_ON <= #1 'd1 ;
                f_pref_cnt <= #1 'd2 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_PREFIX_ON ;
                else if(ext_fifo_wr) begin
                    if(flash_off_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ED1 ; 
                    end
                    else if(flash_exit_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ED0 ; 
                    end    
                    else f_state <= #1 FLASH_PREFIX_READY ;
                end
            end
            FLASH_PREFIX_ED1 : begin  
                FLASH_ON <= #1 'd1 ;
                f_pref_cnt <= #1 'd1 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_PREFIX_ON ;
                else if(ext_fifo_wr) begin
                    if(flash_off_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ED2 ; 
                    end
                    else if(flash_exit_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ED0 ; 
                    end    
                    else f_state <= #1 FLASH_PREFIX_READY ;
                end
            end
            FLASH_PREFIX_ED2 : begin  
                FLASH_ON <= #1 'd1 ;
                f_pref_cnt <= #1 'd0 ;
                if(rise_int_st_stop) f_state <= #1 FLASH_PREFIX_ON ;
                else if(ext_fifo_wr) begin
                    if(flash_off_fifo_data_match) begin
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ED3 ; 
                    end
                    else if(flash_exit_addr[31:24] == ext_fifo_wr_data[7:0]) begin // when restarting from prefix msb
                        f_pref_tmp <= #1 (f_pref_tmp << 8) + ext_fifo_wr_data[7:0] ;
                        f_state <= #1 FLASH_PREFIX_ED0 ; 
                    end  
                    else f_state <= #1 FLASH_PREFIX_READY ;
                end
            end
            FLASH_PREFIX_ED3 : begin
                FLASH_ON <= #1 'd1 ;
                f_pref_cnt <= #1 'd3 ;
                f_pref <= #1 f_pref_tmp  ;
                if(rise_int_st_stop) f_state <= #1 FLASH_PREFIX_ON ;
                else if(f_pref_tmp == flash_exit_addr) f_state <= #1 FLASH_PREFIX_OFF ;
            end
            FLASH_PREFIX_OFF : begin
                FLASH_ON <= #1 'd1 ;
                f_pref_cnt <= #1 'd3 ;
                f_pref <= #1 f_pref_tmp  ;
                if(rise_int_st_stop) f_state <= #1 FLASH_END ;
                else f_state <= #1 FLASH_PREFIX_OFF ;
            end
            FLASH_END : begin
                FLASH_ON            <= #1 'd0 ;
                f_state             <= #1 FLASH_IDLE ;
                f_pref_cnt          <= #1 'd3 ;
                f_pref_tmp          <= #1 'd0 ;
            end
            default : begin
                FLASH_ON            <= #1 'd0 ;
                f_state             <= #1 FLASH_IDLE ;
                f_pref_cnt          <= #1 'd3 ;
                f_pref_tmp          <= #1 'd0 ;
            end
        endcase
    end
end

endmodule
