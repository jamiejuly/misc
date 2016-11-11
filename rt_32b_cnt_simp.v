module rt_32b_cnt_simp(
  input rt_i_clk,
  input rt_i_rst,
  input rt_i_ce,
  output [31:0] rt_o_cnt
);

reg [31:0] rt_r_cnt = 32'd0;
assign rt_o_cnt = rt_r_cnt;

always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_r_cnt <= 32'd0;
  else if(rt_i_ce)
    rt_r_cnt <= rt_r_cnt + 1'b1;
end

endmodule
