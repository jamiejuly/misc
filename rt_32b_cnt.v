module rt_32b_cnt(
  input         rt_i_clk,
  input         rt_i_rst,
  input         rt_i_ce,
  output [31:0] rt_o_cnt
);

reg [7:0] rt_r_cnt0 = 8'd0;
reg [7:0] rt_r_cnt1 = 8'd0;
reg [7:0] rt_r_cnt2 = 8'd0;
reg [7:0] rt_r_cnt3 = 8'd0;

wire rt_w_cnt0_full;
wire rt_w_cnt1_full;
wire rt_w_cnt2_full;
assign rt_w_cnt0_full = &rt_r_cnt0;
assign rt_w_cnt1_full = &rt_r_cnt1;
assign rt_w_cnt2_full = &rt_r_cnt2;
assign rt_o_cnt = {rt_r_cnt3, rt_r_cnt2, rt_r_cnt1,rt_r_cnt0};

always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_r_cnt0 <= 8'd0; 
  else if(rt_i_ce) 
    rt_r_cnt0 <= rt_r_cnt0 + 1'b1;
end

always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_r_cnt1 <= 8'd0;
  else if(rt_i_ce&rt_w_cnt0_full)
    rt_r_cnt1 <= rt_r_cnt1 + 1'b1;
end

always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_r_cnt2 <= 8'd0;
  else if(rt_i_ce&rt_w_cnt0_full&rt_w_cnt1_full)
    rt_r_cnt2 <= rt_r_cnt2 + 1'b1;
end

always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_r_cnt3 <= 8'd0;
  else if(rt_i_ce&rt_w_cnt0_full&rt_w_cnt1_full&rt_w_cnt2_full)
    rt_r_cnt3 <= rt_r_cnt3 + 1'b1;
end


endmodule
