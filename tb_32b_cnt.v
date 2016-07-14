`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:26:40 07/14/2016
// Design Name:   rt_32b_cnt
// Module Name:   D:/Project/verilog_templet/misc/ip_32b_cnt.v
// Project Name:  test_proj
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: rt_32b_cnt
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_32b_cnt;

	// Inputs
	reg rt_i_clk;
	reg rt_i_rst;
	reg rt_i_ce;

	// Outputs
	wire [31:0] rt_o_cnt;

	// Instantiate the Unit Under Test (UUT)
	rt_32b_cnt uut (
		.rt_i_clk(rt_i_clk), 
		.rt_i_rst(rt_i_rst), 
		.rt_i_ce(rt_i_ce), 
		.rt_o_cnt(rt_o_cnt)
	);

	initial begin
		// Initialize Inputs
		rt_i_rst = 0;
		rt_i_ce = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
                @(posedge rt_i_clk);#1;
	        rt_i_ce = 1;	
	        wait(rt_o_cnt == 32'hFFFFFFFF);
	        #1000;
                @(posedge rt_i_clk);#1;
	        rt_i_rst = 1;
	        #20;
	        rt_i_rst = 0;
	        #1000;
                @(posedge rt_i_clk);#1;
                rt_i_ce = 0;

	end
     

        initial begin
          rt_i_clk = 1'b0;
          forever #5  rt_i_clk = ~rt_i_clk;
        end


endmodule

