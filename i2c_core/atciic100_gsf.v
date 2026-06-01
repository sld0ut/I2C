// Copyright (C) 2017, Andes Technology Corp. Confidential Proprietary

module atciic100_gsf(
		  pclk,
		  presetn,
		  t_sp,
		  I,
		  O,
		  rising_edge,
		  falling_edge
);

input			pclk;
input			presetn;
input	[2:0]	t_sp;
input			I;
output			O;
output			rising_edge;
output			falling_edge;

wire			I_sync;
wire			toggle;

reg 			O;
reg		[2:0]	cntr;

assign	toggle = (cntr == t_sp) & (O != I_sync);
assign	rising_edge = toggle & ~O;
assign	falling_edge = toggle & O;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		O <= 1'b1;
	else if (toggle)
		O <= ~O;

always @(posedge pclk or negedge presetn)
	if (!presetn)
		cntr <= 3'b0;
	else if (cntr >= t_sp)
		cntr <= 3'b0;
	else if (O != I_sync)
		cntr <= cntr + 3'b1;
	else
		cntr <= 3'b0;

defparam u_nds_sync_l2l.RESET_VALUE = 1'b1;
nds_sync_l2l u_nds_sync_l2l (
	.b_reset_n			(presetn),
	.b_clk				(pclk),
	.a_signal			(I),
	.b_signal			(I_sync),
	.b_signal_rising_edge_pulse		(),
	.b_signal_falling_edge_pulse	(),
	.b_signal_edge_pulse			()
);

endmodule
