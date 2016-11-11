`define NUM_BIT 32
//rt_bin_cnt instance_name (
//  .rt_i_clk     (       ), 
//  .rt_i_rst     (       ), 
//  .rt_i_set     (       ), 
//  .rt_i_ce      (       ), 
//  .rt_i_inc_n   (       ), 
//  .rt_i_ld_val  (       ), 
//  .rt_o_bin_cnt (       ), 
//  .rt_o_eqnz    (       )
//  );


module rt_bin_cnt (
  input rt_i_clk,
  input rt_i_rst,
  input rt_i_set,
  input rt_i_ce,
  input rt_i_inc_n, //0:increase mode, 1:decrease mode
  input [`NUM_BIT-1 : 0] rt_i_ld_val,
  output reg [`NUM_BIT-1 : 0] rt_o_bin_cnt = `NUM_BIT'd0,
  output rt_o_eqnz

);

wire [`NUM_BIT-1:0] rt_w_add_num;
assign rt_w_add_num = rt_i_inc_n ? {`NUM_BIT{1'b1}}:`NUM_BIT'd1;
assign rt_o_eqnz = |rt_o_bin_cnt;

always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_o_bin_cnt <= `NUM_BIT'd0;
  else if(rt_i_set)
    rt_o_bin_cnt <= rt_i_ld_val;
  else if(rt_i_ce)
    rt_o_bin_cnt <= rt_o_bin_cnt + rt_w_add_num;
end



endmodule
