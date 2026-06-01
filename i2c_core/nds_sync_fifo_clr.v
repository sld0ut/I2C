// Copyright (C) 2017, Andes Technology Corp. Confidential Proprietary

`ifdef NO_TIMESCALE
`else
`timescale 1ns/100ps
`endif

module nds_sync_fifo_clr(
reset_n,
clk,
wr,
wr_data,
rd,
rd_data,
empty,
full,
wr_ptr,
rd_ptr,
fifo_clr
);

parameter DATA_WIDTH = 32;
parameter FIFO_DEPTH = 8;
parameter POINTER_INDEX_WIDTH = 4;

input  reset_n;
input  clk;
input  wr;
input  [DATA_WIDTH-1:0] wr_data;
input  rd;
output [DATA_WIDTH-1:0] rd_data;
output empty;
output full;
output [POINTER_INDEX_WIDTH-1:0] wr_ptr/* synthesis syn_noprune=1 syn_keep=1 */;
output [POINTER_INDEX_WIDTH-1:0] rd_ptr/* synthesis syn_noprune=1 syn_keep=1 */;
input  fifo_clr;

wire   [DATA_WIDTH-1:0] rd_data;
reg  [DATA_WIDTH-1:0] mem[0:FIFO_DEPTH-1];
reg  [POINTER_INDEX_WIDTH-1:0] wr_ptr;
reg  [POINTER_INDEX_WIDTH-1:0] rd_ptr;
wire [POINTER_INDEX_WIDTH-1:0] next_rd_ptr/* synthesis syn_noprune=1 syn_keep=1 */;
wire [POINTER_INDEX_WIDTH-1:0] next_wr_ptr/* synthesis syn_noprune=1 syn_keep=1 */;
wire [POINTER_INDEX_WIDTH-2:0] rd_addr;
reg empty;
reg full;

integer i;
integer j;

wire [POINTER_INDEX_WIDTH-2:0] index;

assign index = wr_ptr[POINTER_INDEX_WIDTH-2:0];

always @(negedge reset_n or posedge clk)
begin
	if (!reset_n) begin
		for(i=0;i<FIFO_DEPTH;i=i+1) begin
			mem[i] <= 'd0;
		end
	end else begin
		if (wr)
			mem[index] <= wr_data;
	end
end

`ifdef NO_TIMESCALE
assign next_wr_ptr = ( (wr) ? wr_ptr + { {POINTER_INDEX_WIDTH-1 {1'b0} }, 1'b1 } : wr_ptr);
`else
assign #1 next_wr_ptr = ( (wr) ? wr_ptr + { {POINTER_INDEX_WIDTH-1 {1'b0} }, 1'b1 } : wr_ptr);
`endif

always @(negedge reset_n or posedge clk)
begin
     if (!reset_n)
	     wr_ptr <= { POINTER_INDEX_WIDTH { 1'b0 }};
     else if (fifo_clr)
	     wr_ptr <= { POINTER_INDEX_WIDTH { 1'b0 }};
     else
	     wr_ptr <= next_wr_ptr;
end

always @(negedge reset_n or posedge clk)
begin
     if (!reset_n)
        full <= 1'b0;
     else if (fifo_clr)
        full <= 1'b0;
     else
        full <= (next_wr_ptr[POINTER_INDEX_WIDTH-2:0] == next_rd_ptr[POINTER_INDEX_WIDTH-2:0]) &&
                (next_wr_ptr[POINTER_INDEX_WIDTH-1] != next_rd_ptr[POINTER_INDEX_WIDTH-1]);
end

`ifdef NO_TIMESCALE
assign next_rd_ptr = ( (rd) ? rd_ptr + { {POINTER_INDEX_WIDTH-1 {1'b0} }, 1'b1 } : rd_ptr);
`else
assign #1 next_rd_ptr = ( (rd) ? rd_ptr + { {POINTER_INDEX_WIDTH-1 {1'b0} }, 1'b1 } : rd_ptr);
`endif
always @(negedge reset_n or posedge clk)
begin
     if (!reset_n)
	rd_ptr <=  { POINTER_INDEX_WIDTH { 1'b0 }};
     else if (fifo_clr)
	rd_ptr <=  { POINTER_INDEX_WIDTH { 1'b0 }};
     else
	rd_ptr <= next_rd_ptr;
end

always @(negedge reset_n or posedge clk)
begin
     if (!reset_n)
        empty <= 1'b1;
     else if (fifo_clr)
        empty <= 1'b1;
     else
        empty <= (next_rd_ptr[POINTER_INDEX_WIDTH-1:0] == next_wr_ptr[POINTER_INDEX_WIDTH-1:0]);
end

assign rd_addr = rd_ptr[POINTER_INDEX_WIDTH-2:0];
assign rd_data = mem[rd_addr];

endmodule
