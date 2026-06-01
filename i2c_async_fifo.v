
`include "atciic100_config.vh"
`include "atciic100_const.vh"

module i2c_async_fifo # (
	parameter N = 8	// FIFO Width
)
(
	test_mode,
	rst_n,
	in_clk,
	out_clk,
	fifo_flush,
	fifo_write,
	fifo_read,
	data_in,
	data_out,
	af_threshold,
	//ram_valid,    // jys 200408
	fifo_full_req,
	//fifo_full_ack,    // jys 200408
	fifo_inpempty,
	//must use this to inform writer fifo has been flushed
	fifo_outempty,
    // jys 200408
    fifo_half_full,
    fifo_half_empty,
    diff
);

`ifndef	Td
	`define	Td	#1
`endif

// in_clk is write clock, out_clk is read clock
input		test_mode;
input		rst_n, in_clk, out_clk;
input		fifo_read, fifo_write;
input		fifo_flush;
input	[N-1:0]	data_in;
input	[4:0]	af_threshold;

output	[N-1:0]	data_out;
//output		ram_valid, fifo_full_req, fifo_inpempty, fifo_outempty;
output		fifo_full_req, fifo_inpempty, fifo_outempty;    // jys 200408
//input		fifo_full_ack;    // jys 200408
output	[4:0]	diff;    // jys 200408

// jys 200408
output		fifo_half_full;
output		fifo_half_empty;

reg	    [4:0]	fifo_write_ptr, fifo_read_ptr;
reg 	[4:0]	sync_write_ptr, sync_read_ptr;
reg 	[4:0]	sync_write_ptr_a, sync_read_ptr_a;
reg 	[4:0]	grey_write_ptr_out, grey_read_ptr_out;
wire	[4:0]	t_next_fifo_write_ptr, t_next_fifo_read_ptr, diff;
reg 	     	ram_valid;

wire		fwrite_n = ~fifo_write;
//wire 		fifo_outempty = ~ram_valid;
wire 		w_fifo_outempty = ~ram_valid;
//reg  		fifo_full_reg, fifo_inpempty;
reg  		fifo_full_reg, r_fifo_inpempty;
wire	[N-1:0]	data_out;
// jys 200612
assign      fifo_inpempty = r_fifo_inpempty | w_fifo_outempty ;
assign      fifo_outempty = fifo_inpempty ;

//Function to generate a 4-bit grey code for a 4-bit binary number given.
function [4:0] bin2grey4;
	input [4:0] value;
	bin2grey4 = {value[4], ^value[4:3], ^value[3:2], ^value[2:1], ^value[1:0]};
endfunction

//Function to generate a 4-bit binary code for a 4-bit grey code.
function [4:0] grey2bin4;
	input [4:0] value;
     	grey2bin4 = {value[4], ^value[4:3], ^value[4:2], ^value[4:1], ^value[4:0]};
endfunction

//fifo flushing mechanism for flushes directed from the read (out_clk) side
reg		flush1, flush2, flush3 ;    // jys 200610   // in_clk domain  
reg     flush0, flush4, flush5, flush6 ;            // out_clk domain
//wire		rd_fifo_rst = ~rst_n || flush0 || flush1 || flush2;
// wire		wr_fifo_rst = ~rst_n || flush2;
wire		rd_fifo_rst = flush0 || flush1 || flush2;
//wire		wr_fifo_rst = flush2;
reg         wr_fifo_rst ;   // in_clk domain
wire		wr_fifo_rst2 = flush5 && ~flush6 ; // jys 200610 // out_clk domain
//wire		valid = (cascade) ? ram_valid_cascade : ram_valid;
wire		valid = ram_valid;

//verilint 484 off -- possible loss of carry/borrow
assign t_next_fifo_write_ptr  = (fifo_write) ? (fifo_write_ptr + 5'h1) :
                                                fifo_write_ptr;
assign t_next_fifo_read_ptr = (valid & fifo_read) ? (fifo_read_ptr + 5'h1) :
                                                     fifo_read_ptr;
assign diff  = t_next_fifo_write_ptr - grey2bin4(sync_read_ptr);
//verilint 484 on

// jys 200610
always @(posedge in_clk or negedge rst_n)
	if (!rst_n) begin
		wr_fifo_rst   <= `Td  1'b0;
    end    
	else begin
		if(flush3) wr_fifo_rst   <= `Td  1'b0;
		else if(flush2) wr_fifo_rst   <= `Td  1'b1;
	end

always @(posedge out_clk or negedge rst_n)
	if (!rst_n) begin
		flush4   <= `Td  1'b0;
		flush5   <= `Td  1'b0;
		flush6   <= `Td  1'b0;
    end    
	else begin
		flush4   <= `Td  flush3;
		flush5   <= `Td  flush4;
		flush6   <= `Td  flush5;
	end

// lock until opposite side resets
always @(posedge out_clk or negedge rst_n)
	if (!rst_n)
		flush0   <= `Td  1'b0;
	else begin
		//if (wr_fifo_rst)  // jys 200610
		if (wr_fifo_rst2) 
		    flush0   <= `Td  1'b0;
	    else
		    flush0 <= `Td  fifo_flush || flush0;
	end


wire		in_clk_int;
CLK_MUX in_clk_mux (
	.A	(~in_clk	),
	.B	(in_clk		),
	.S	(test_mode	),
	.Y	(in_clk_int	)
);

//verilint 396 off -- flipflop without asynchronous reset
//always @(negedge in_clk or negedge rst_n)
always @(posedge in_clk_int or negedge rst_n)
	if (!rst_n)
      		flush1   <= `Td  0;
	else begin
		//if (wr_fifo_rst) // jys 200610
		//	flush1   <= `Td  0;
		//else
			flush1   <= `Td  flush0;
	end

always @(posedge in_clk or negedge rst_n)
      if (!rst_n) begin 
      	flush2   <= `Td  0;
      	flush3   <= `Td  0;
      end  
      else begin
	    //  if (wr_fifo_rst) // jys 200610
		//flush2   <= `Td  0;
	    //  else
		flush2   <= `Td  flush1;
		flush3   <= `Td  flush2;
      end

//verilint 396 on

//to save 1/2 clock latency try using negedge for intermediate pointer stage
//always @(negedge in_clk or negedge rst_n)
always @(posedge in_clk_int or negedge rst_n)
	if (!rst_n)
		sync_read_ptr_a    <= `Td  5'h0;
	else begin
		if (wr_fifo_rst)
			sync_read_ptr_a    <= `Td  5'h0;
		else
			sync_read_ptr_a    <= `Td  grey_read_ptr_out;
	end

reg	fifo_full_int;
reg	fifo_half_full;    
always @(posedge in_clk or negedge rst_n) begin
	if (!rst_n) begin
		fifo_write_ptr     <= `Td  5'h0;
		grey_write_ptr_out <= `Td  5'h0;
		sync_read_ptr      <= `Td  5'h0;
		fifo_full_int      <= `Td  1'b0;
		r_fifo_inpempty    <= `Td  1'b1;
		fifo_half_full     <= `Td  1'b0;
	end else begin
		if (wr_fifo_rst) begin
			fifo_write_ptr     <= `Td  5'h0;
			grey_write_ptr_out <= `Td  5'h0;
			sync_read_ptr      <= `Td  5'h0;
			fifo_full_int      <= `Td  1'b0;
			r_fifo_inpempty    <= `Td  1'b1;
		end else begin
			fifo_write_ptr     <= `Td  t_next_fifo_write_ptr;
			grey_write_ptr_out <= `Td  bin2grey4(t_next_fifo_write_ptr);
			sync_read_ptr      <= `Td  sync_read_ptr_a;
			//fifo_full_int      <= `Td  (diff > af_threshold);
			fifo_full_int      <= `Td  (diff >= af_threshold);   // jys 200408
			r_fifo_inpempty    <= `Td  (t_next_fifo_write_ptr ==
							grey2bin4(sync_read_ptr));
		end
        fifo_half_full     <= `Td  (diff > (af_threshold>>1)) ; // jys 200609
	end
	end

// jys 200408
//reg		fifo_full_req;
//always @(posedge in_clk or negedge rst_n)
//	if (!rst_n)
//		fifo_full_req <= `Td 1'b0;
//	else begin
//		if (fifo_full_int)						fifo_full_req <= `Td 1'b1;
//		else if(fifo_full_req&fifo_full_ack)	fifo_full_req <= `Td 1'b0;
//	end
assign fifo_full_req = fifo_full_int ; // jys 200408

wire		out_clk_int;
CLK_MUX out_clk_mux (
	.A	(~out_clk	),
	.B	(out_clk	),
	.S	(test_mode	),
	.Y	(out_clk_int)
);

//always @(negedge out_clk or negedge rst_n)
always @(posedge out_clk_int or negedge rst_n)
	if (!rst_n)
		sync_write_ptr_a   <= `Td  5'h0;
	else begin
		if (rd_fifo_rst)
			sync_write_ptr_a   <= `Td  5'h0;
		else
			sync_write_ptr_a   <= `Td  grey_write_ptr_out;
	end

reg	fifo_half_empty;
always @(posedge out_clk or negedge rst_n) begin
	if (!rst_n) begin
		fifo_read_ptr      <= `Td  5'h0;
		grey_read_ptr_out  <= `Td  5'h0;
		sync_write_ptr     <= `Td  5'h0;
		ram_valid          <= `Td  1'b0;
		fifo_half_empty    <= `Td  1'b0;
	end else begin
		if (rd_fifo_rst) begin
			fifo_read_ptr      <= `Td  5'h0;
			grey_read_ptr_out  <= `Td  5'h0;
			sync_write_ptr     <= `Td  5'h0;
			ram_valid          <= `Td  1'b0;
		end else begin
			fifo_read_ptr      <= `Td  t_next_fifo_read_ptr;
			grey_read_ptr_out  <= `Td  bin2grey4(t_next_fifo_read_ptr);
			sync_write_ptr     <= `Td  sync_write_ptr_a;
			ram_valid          <= `Td  (bin2grey4(t_next_fifo_read_ptr) !=
							sync_write_ptr);
		end
        fifo_half_empty    <= `Td  (diff <= (af_threshold>>1)) ;    // jys 200408
	end
end

frame #(.N(N)) frame (
	.clk		(in_clk		),
	.rst_n		(rst_n	      	),
	.write_n   	(fwrite_n      	),
	.write_ptr 	(fifo_write_ptr	),
	.read_ptr  	(fifo_read_ptr 	),
	.data_in   	(data_in       	),
	.data_out  	(data_out      	)
);
endmodule


/////////////////////////////////////////////////////////////
//	
module frame # (
	parameter N = 8	// FIFO Width
)
(
	clk,
	rst_n,
	write_n,   // Write enable
	write_ptr, // Write Address
	read_ptr,  // Read Address
	data_in,   // Write Data
	data_out   // Read Data
);
input		clk;
input		rst_n;
input		write_n;
input	[4:0]	write_ptr;
input	[4:0]	read_ptr;
input	[N-1:0]	data_in;

output	[N-1:0]	data_out;
reg   	[N-1:0]	data_out;

reg 	[N-1:0]	reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7;
reg 	[N-1:0]	reg8, reg9, reg10, reg11, reg12, reg13, reg14, reg15;
reg 	[N-1:0]	reg16, reg17, reg18, reg19, reg20, reg21, reg22, reg23;
reg 	[N-1:0]	reg24, reg25, reg26, reg27, reg28, reg29, reg30, reg31;
wire	 [4:0]	write_ptr;

// synopsys translate_off
//-------------------
initial begin
	reg0  = 32'hABADFACE;
	reg1  = 32'hABADFACE;
	reg2  = 32'hABADFACE;
	reg3  = 32'hABADFACE;
	reg4  = 32'hABADFACE;
	reg5  = 32'hABADFACE;
	reg6  = 32'hABADFACE;
	reg7  = 32'hABADFACE;
	reg8  = 32'hABADFACE;
	reg9  = 32'hABADFACE;
	reg10 = 32'hABADFACE;
	reg11 = 32'hABADFACE;
	reg12 = 32'hABADFACE;
	reg13 = 32'hABADFACE;
	reg14 = 32'hABADFACE;
	reg15 = 32'hABADFACE;
	reg16 = 32'hABADFACE;
	reg17 = 32'hABADFACE;
	reg18 = 32'hABADFACE;
	reg19 = 32'hABADFACE;
	reg20 = 32'hABADFACE;
	reg21 = 32'hABADFACE;
	reg22 = 32'hABADFACE;
	reg23 = 32'hABADFACE;
	reg24 = 32'hABADFACE;
	reg25 = 32'hABADFACE;
	reg26 = 32'hABADFACE;
	reg27 = 32'hABADFACE;
	reg28 = 32'hABADFACE;
	reg29 = 32'hABADFACE;
	reg30 = 32'hABADFACE;
	reg31 = 32'hABADFACE;
end
//-------------------
// synopsys translate_on

// Continuous output of Read Ptr location
always @(read_ptr or reg0 or reg1 or reg2 or reg3 or reg4 or reg5 or
	reg6 or reg7 or reg8 or reg9 or reg10 or reg11 or reg12 or
	reg13 or reg14 or reg15 or reg16 or reg17 or reg18 or reg19 or
	reg20 or reg21 or reg22 or reg23 or reg24 or reg25 or reg26 or
	reg27 or reg28 or reg29 or reg30 or reg31)
	case (read_ptr)
		5'd0 	:	data_out = reg0;
		5'd1 	:	data_out = reg1;
		5'd2 	:	data_out = reg2;
		5'd3 	:	data_out = reg3;
		5'd4 	:	data_out = reg4;
		5'd5 	:	data_out = reg5;
		5'd6 	:	data_out = reg6;
		5'd7 	:	data_out = reg7;
		5'd8 	:	data_out = reg8;
		5'd9 	:	data_out = reg9;
		5'd10	:	data_out = reg10;
		5'd11	:	data_out = reg11;
		5'd12	:	data_out = reg12;
		5'd13	:	data_out = reg13;
		5'd14	:	data_out = reg14;
		5'd15	:	data_out = reg15;
		5'd16	:	data_out = reg16;
		5'd17	:	data_out = reg17;
		5'd18	:	data_out = reg18;
		5'd19	:	data_out = reg19;
		5'd20	:	data_out = reg20;
		5'd21	:	data_out = reg21;
		5'd22	:	data_out = reg22;
		5'd23	:	data_out = reg23;
		5'd24	:	data_out = reg24;
		5'd25	:	data_out = reg25;
		5'd26	:	data_out = reg26;
		5'd27	:	data_out = reg27;
		5'd28	:	data_out = reg28;
		5'd29	:	data_out = reg29;
		5'd30	:	data_out = reg30;
		5'd31	:	data_out = reg31;
		default : data_out =0;
	endcase

// Update RAM on a write pulse
always @(posedge clk or negedge rst_n)
	if(!rst_n) begin
		reg0 <= `Td 0;
		reg1 <= `Td 0;
		reg2 <= `Td 0;
		reg3 <= `Td 0;
		reg4 <= `Td 0;
		reg5 <= `Td 0;
		reg6 <= `Td 0;
		reg7 <= `Td 0;
		reg8 <= `Td 0;
		reg9 <= `Td 0;
		reg10 <= `Td 0;
		reg11 <= `Td 0;
		reg12 <= `Td 0;
		reg13 <= `Td 0;
		reg14 <= `Td 0;
		reg15 <= `Td 0;
		reg16 <= `Td 0;
		reg17 <= `Td 0;
		reg18 <= `Td 0;
		reg19 <= `Td 0;
		reg20 <= `Td 0;
		reg21 <= `Td 0;
		reg22 <= `Td 0;
		reg23 <= `Td 0;
		reg24 <= `Td 0;
		reg25 <= `Td 0;
		reg26 <= `Td 0;
		reg27 <= `Td 0;
		reg28 <= `Td 0;
		reg29 <= `Td 0;
		reg30 <= `Td 0;
		reg31 <= `Td 0;
	end
	else begin
		if(!write_n) begin
			case (write_ptr)
				5'd0    : reg0   <= `Td  data_in;
				5'd1    : reg1   <= `Td  data_in;
				5'd2    : reg2   <= `Td  data_in;
				5'd3    : reg3   <= `Td  data_in;
				5'd4    : reg4   <= `Td  data_in;
				5'd5    : reg5   <= `Td  data_in;
				5'd6    : reg6   <= `Td  data_in;
				5'd7    : reg7   <= `Td  data_in;
				5'd8    : reg8   <= `Td  data_in;
				5'd9    : reg9   <= `Td  data_in;
				5'd10   : reg10  <= `Td  data_in;
				5'd11   : reg11  <= `Td  data_in;
				5'd12   : reg12  <= `Td  data_in;
				5'd13   : reg13  <= `Td  data_in;
				5'd14   : reg14  <= `Td  data_in;
				5'd15   : reg15  <= `Td  data_in;
				5'd16   : reg16  <= `Td  data_in;
				5'd17   : reg17  <= `Td  data_in;
				5'd18   : reg18  <= `Td  data_in;
				5'd19   : reg19  <= `Td  data_in;
				5'd20   : reg20  <= `Td  data_in;
				5'd21   : reg21  <= `Td  data_in;
				5'd22   : reg22  <= `Td  data_in;
				5'd23   : reg23  <= `Td  data_in;
				5'd24   : reg24  <= `Td  data_in;
				5'd25   : reg25  <= `Td  data_in;
				5'd26   : reg26  <= `Td  data_in;
				5'd27   : reg27  <= `Td  data_in;
				5'd28   : reg28  <= `Td  data_in;
				5'd29   : reg29  <= `Td  data_in;
				5'd30   : reg30  <= `Td  data_in;
				5'd31   : reg31  <= `Td  data_in;
				default : begin
					reg0 <= `Td 0;
					reg1 <= `Td 0;
					reg2 <= `Td 0;
					reg3 <= `Td 0;
					reg4 <= `Td 0;
					reg5 <= `Td 0;
					reg6 <= `Td 0;
					reg7 <= `Td 0;
					reg8 <= `Td 0;
					reg9 <= `Td 0;
					reg10 <= `Td 0;
					reg11 <= `Td 0;
					reg12 <= `Td 0;
					reg13 <= `Td 0;
					reg14 <= `Td 0;
					reg15 <= `Td 0;
					reg16 <= `Td 0;
					reg17 <= `Td 0;
					reg18 <= `Td 0;
					reg19 <= `Td 0;
					reg20 <= `Td 0;
					reg21 <= `Td 0;
					reg22 <= `Td 0;
					reg23 <= `Td 0;
					reg24 <= `Td 0;
					reg25 <= `Td 0;
					reg26 <= `Td 0;
					reg27 <= `Td 0;
					reg28 <= `Td 0;
					reg29 <= `Td 0;
					reg30 <= `Td 0;
					reg31 <= `Td 0;
