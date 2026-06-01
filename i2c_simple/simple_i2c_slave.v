
//-----------------------------------------------------------------------------
// Module Name & Input & Output Port Definition
//-----------------------------------------------------------------------------
module simple_i2c_slave
(
input	wire			test_mode		    ,
input	wire	[6:0]	i_device_addr	    ,
input	wire			resetn			    ,
//i2c port
input 	wire			i_scl			    /* synthesis syn_noprune=1 syn_keep=1 */,
input 	wire			i_scl_inv		    ,
input	wire			i_sda			    /* synthesis syn_noprune=1 syn_keep=1 */,
input	wire			i_sda_inv		    ,
output	wire			o_scl			    ,
output	wire			o_sda			    ,

input	wire			i_pmu_mp_aopd	    ,
input	wire			i_i2c_enable	    ,

input	wire			i_intr_wakeup_en    ,
input	wire			i_intr_wakeup_clr   ,
output	wire			o_intr_wakeup_i2c   ,
input	wire    [15:0]  i_wakeup_addr	    ,
input	wire	[7:0]	i_wakeup_cmd	    ,
input	wire	[7:0]	i_pmu_status	    ,
input	wire			i_sel_addr_width    ,  //0:8bit, 1:16bit
output	wire	[7:0]	o_debug_status      ,

output	wire			o_i2c_simple_stop	,
output	wire			o_start_detect
);

//-----------------------------------------------------------------------------
// Parameter & Wire & Register Definition
//-----------------------------------------------------------------------------
//
//parameter [6:0] device_address 	= 7'h55;
parameter [2:0] STATE_IDLE      = 3'h0,
                STATE_DEV_ADDR  = 3'h1,
                STATE_READ      = 3'h2,
                STATE_ADDR_H 	= 3'h3,
                STATE_ADDR_L 	= 3'h4,
                STATE_WRITE     = 3'h5;
//start check
reg             r_start_detect		;
reg             r_start_resetter	;
wire            w_start_rst 		;
//stop check
reg             r_stop_detect		;
reg             r_stop_resetter		;
wire            w_stop_rst 			;

//latching input data
reg [3:0]       r_bit_counter		;
reg [7:0]       r_input_shift		;
reg             r_master_ack		;
wire            w_lsb_bit 			;
wire            w_ack_bit 			;

wire            w_address_detect	;
wire            w_read_write_bit 	;

//FSM
reg [2:0]       r_state				;
wire            w_write_strobe 		;

//Register Transfers
reg		[7:0]   r_addr_h			;
reg		[15:0]	r_index_pointer		;
reg 	[7:0]   r_reg00				;
reg 	[7:0]   r_reg01				;
reg 	[7:0]   r_reg02				;
reg 	[7:0]   r_output_shift		;
//output control
reg             r_output_control	;
//check wakeup command
wire			w_check_wakeup_cmd	;
reg				r_intr_wakeup		;
//simple i2c select
wire			w_sel_i2c			;
//-----------------------------------------------------------------------------
// Operation Process
//-----------------------------------------------------------------------------
//assign		 w_sel_i2c	 = i_pmu_mp_aopd && ~i_pmu_i2c_spi  && i_i2c_enable;
assign		 w_sel_i2c	 = i_pmu_mp_aopd && i_i2c_enable;

//assign       w_start_rst = ~resetn | r_start_resetter;
//assign       w_stop_rst = ~resetn | r_stop_resetter;
assign       w_start_rst = test_mode ? resetn : resetn & ~r_start_resetter;
assign       w_stop_rst  = test_mode ? resetn : resetn & ~r_stop_resetter;

assign	     w_lsb_bit = (r_bit_counter == 4'h7) && !r_start_detect;
assign	     w_ack_bit = (r_bit_counter == 4'h8) && !r_start_detect;

assign	     w_address_detect = (r_input_shift[7:1] == i_device_addr);
assign	     w_read_write_bit = r_input_shift[0];

assign       w_write_strobe = (r_state == STATE_WRITE) && w_ack_bit;

assign		 w_check_wakeup_cmd = w_write_strobe && (r_index_pointer == i_wakeup_addr ) 
 								&& (r_input_shift == i_wakeup_cmd) && i_intr_wakeup_en ;

//// jys add
reg r_i2c_simple_stop_d0 ;
reg r_i2c_simple_stop_d1 ;
wire w_rstn_p = resetn & ~i_intr_wakeup_clr /* synthesis syn_noprune=1 syn_keep=1 */;
wire w_rstn /* synthesis syn_noprune=1 syn_keep=1 */;
CLK_MUX I_TMUX_RSTB (.A(w_rstn_p), .B(resetn), .S(test_mode), .Y(w_rstn));
//always @ (negedge resetn or posedge i_scl) begin   
//	if(~resetn)	begin
always @ (negedge w_rstn or posedge i_scl) begin   
	if(~w_rstn)	begin
        r_i2c_simple_stop_d0 <= 1'b0;
        r_i2c_simple_stop_d1 <= 1'b0;
    end    
	else begin
        r_i2c_simple_stop_d0 <= w_check_wakeup_cmd;
        r_i2c_simple_stop_d1 <= r_i2c_simple_stop_d0;
    end    
end
assign       o_i2c_simple_stop = r_i2c_simple_stop_d1 ;
assign       o_start_detect = r_start_detect ;

//-----------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------

//wakeup interrupt 
//always @ (negedge resetn or posedge i_scl)
//begin   
	//if(~resetn)	r_intr_wakeup <= 1'b0;
always @ (negedge w_rstn or posedge i_scl)
begin   
	if(~w_rstn)	r_intr_wakeup <= 1'b0;
	else if(r_start_detect)
				r_intr_wakeup <= 1'b0;
	else if(w_check_wakeup_cmd)  		
				r_intr_wakeup <= w_check_wakeup_cmd;
end

// start detect
//always @ (posedge w_start_rst or posedge i_sda_inv)
always @ (negedge w_start_rst or posedge i_sda_inv)
begin
     if (~w_start_rst)
         r_start_detect <= 1'b0;
     else
         r_start_detect <= i_scl;
end

always @ (negedge resetn or posedge i_scl)
begin
     if (~resetn)
         r_start_resetter <= 1'b0;
     else
         r_start_resetter <= r_start_detect;
end

// stop detect
//always @ (posedge w_stop_rst or posedge i_sda)
always @ (negedge  w_stop_rst or posedge i_sda)
begin   
     if (~w_stop_rst)
         r_stop_detect <= 1'b0;
     else
         r_stop_detect <= i_scl;
end

always @ (negedge resetn or posedge i_scl)
begin   
     if (~resetn)
         r_stop_resetter <= 1'b0;
     else
         r_stop_resetter <= r_stop_detect;
end

//latching input data
always @ (negedge resetn or posedge i_scl_inv)
begin
	 if (~resetn)
         r_bit_counter <= 4'h0;
     else if (w_ack_bit || r_start_detect)
         r_bit_counter <= 4'h0;
     else
         r_bit_counter <= r_bit_counter + 4'h1;
end

always @ (negedge resetn or posedge i_scl)
	 if(~resetn)
		 r_input_shift <= 8'h0;
     else if (!w_ack_bit)
         r_input_shift <= {r_input_shift[6:0], i_sda};


always @ (negedge resetn or posedge i_scl)
	 if(~resetn)
         r_master_ack <= 'd0;
     else if (w_ack_bit)
         r_master_ack <= ~i_sda;

//--------------------------------------------------------------------------
// FSM
//-----------------------------------------------------------------------------

// no synthesis-----------------------------------------------------------
// synopsys translate_off 

    reg [160:0] state_string ; 

    always @ ( * ) begin 
        case (r_state) 
            STATE_IDLE      : state_string =  "STATE_IDLE"      ;
            STATE_DEV_ADDR  : state_string =  "STATE_DEV_ADDR"  ;
            STATE_READ      : state_string =  "STATE_READ"      ;
            STATE_ADDR_H    : state_string =  "STATE_ADDR_H"    ;
            STATE_ADDR_L    : state_string =  "STATE_ADDR_L"    ;
            STATE_WRITE     : state_string =  "STATE_WRITE"     ;
        endcase
    end

// synopsys translate_on 
// ----------------------------------------------------------------------  

always @ (negedge resetn or posedge i_scl_inv)
begin
      if (~resetn)
              r_state <= STATE_IDLE;
	  else if(~w_sel_i2c)
              r_state <= STATE_IDLE;
      else if (r_start_detect)
              r_state <= STATE_DEV_ADDR;
      else if (w_ack_bit)
      begin
              case (r_state)
              STATE_IDLE:
                  r_state <= STATE_IDLE;

              STATE_DEV_ADDR:
                  if (!w_address_detect)
                          r_state <= STATE_IDLE;
                  else if (w_read_write_bit)
                          r_state <= STATE_READ;
                  else
                          r_state <= i_sel_addr_width ? STATE_ADDR_H : STATE_ADDR_L;

              STATE_READ:
                  if (r_master_ack)
                          r_state <= STATE_READ;
                  else
                          r_state <= STATE_IDLE;

              STATE_ADDR_H:  
                  r_state <= STATE_ADDR_L;
              STATE_ADDR_L:
                  r_state <= STATE_WRITE;
              STATE_WRITE:
                  //r_state <= STATE_WRITE;
                  r_state <= STATE_IDLE;
              default :
                  r_state <= STATE_IDLE;
              endcase
      end
end

//Register Transfers
always @ (negedge resetn or posedge i_scl_inv)
begin
       if (~resetn)
	   begin
            r_index_pointer <= 16'h00;
	   		r_addr_h		<= 8'h00;
	   end
       else if (r_stop_detect)
	   begin
            r_index_pointer <= 16'h00;
	   		r_addr_h		<= 8'h00;
	   end
       else if (w_ack_bit)
       begin
            if (r_state == STATE_ADDR_H)
                    r_addr_h <= r_input_shift;
            else if (r_state == STATE_ADDR_L)
                    r_index_pointer <= {r_addr_h,r_input_shift};
            else
                    r_index_pointer <= r_index_pointer + 1;
       end
end

always @ (negedge resetn or posedge i_scl_inv)
begin
       if (~resetn)
	   begin
               r_reg00 <= 8'h00;
               r_reg01 <= 8'h00;
               r_reg02 <= 8'h00;
	   end
       else if (w_write_strobe )
	   begin
	   		if(r_index_pointer == 16'h1000)
               	r_reg00 <= r_input_shift;
	   		else if(r_index_pointer == 16'h1001)
               	r_reg01 <= r_input_shift;
	   		else if (r_index_pointer == 16'h1002)
               	r_reg02 <= r_input_shift;
	   end
end

//output shift
always @ (negedge resetn or posedge i_scl_inv)
begin   
	   if (~resetn)
       		 r_output_shift <= 8'h0;
       else if (w_lsb_bit)
       begin   
            case (r_index_pointer)
            	16'h00	: r_output_shift <= i_pmu_status;	//r_reg00;
            	16'h01	: r_output_shift <= i_pmu_status;	//r_reg01;
            	16'h02	: r_output_shift <= i_pmu_status;	//r_reg02;
	   			default : r_output_shift <= i_pmu_status; 
            endcase
       end
       else	 r_output_shift <= {r_output_shift[6:0], 1'b0};
end


always @ (negedge resetn or posedge i_scl_inv)
begin   
       if (~resetn)
               r_output_control <= 1'b1;
       else if (r_start_detect)
               r_output_control <= 1'b1;
       else if (w_lsb_bit)
       begin   
            r_output_control <=
                !(((r_state == STATE_DEV_ADDR) && w_address_detect) ||
                  (r_state == STATE_ADDR_H) || (r_state == STATE_ADDR_L) ||
                  (r_state == STATE_WRITE));
       end
       else if (w_ack_bit)
       begin
            // Deliver the first bit of the next slave-to-master
            // transfer, if applicable.
            if (((r_state == STATE_READ) && r_master_ack) ||
                ((r_state == STATE_DEV_ADDR) &&
                    w_address_detect && w_read_write_bit))
                    r_output_control <= r_output_shift[7];
            else
                    r_output_control <= 1'b1;
       end
       else if (r_state == STATE_READ)
               r_output_control <= r_output_shift[7];
       else
               r_output_control <= 1'b1;
end

//-----------------------------------------------------------------------------
// Output 
//-----------------------------------------------------------------------------
assign	o_intr_wakeup_i2c	= r_intr_wakeup	;
assign 	o_debug_status		= {3'h0,r_stop_detect,1'b0,r_state };

//output driver
//assign     i_sda = r_output_control ? 1'bz : 1'b0;  

assign	o_sda				= r_output_control; 
assign	o_scl				= 1'b1			;
endmodule
