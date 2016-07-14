module rt_i2c_timing(
  input rt_i_clk,
  input rt_i_rst,
  input rt_i_en,
  input [15:0] rt_i_len,
  input [5:0] rt_i_clk_div,
  input rt_i_nak,
  output reg rt_o_scl = 1'b1,
  output reg rt_o_sda_valid = 1'b0,
  output reg rt_o_sda_latch = 1'b0,
  output reg rt_o_ack_valid = 1'b0,
  output reg rt_o_ack_latch = 1'b0,
  output reg rt_o_sda = 1'b1,
  output reg rt_o_ack_oe = 1'b1,
  output reg [3:0] rt_o_blank_sync = 4'b0,
  output reg rt_o_ready = 1'b0
);
localparam CONST_DISABLE    = 1'b0;
localparam CONST_ENABLE     = 1'b1;

localparam FSM1_S0_IDLE 	= 3'd0;
localparam FSM1_S1_START   	= 3'd1;
localparam FSM1_S2_DATA   	= 3'd2;
localparam FSM1_S3_DATA8   	= 3'd3;
localparam FSM1_S4_ACK      = 3'd4;
localparam FSM1_S5_BLANKING = 3'd5;
localparam FSM1_S6_STOP		= 3'd6;
localparam FSM1_S7_READY	= 3'd7;

localparam FSM2_S0_PHASE_0 = 4'd1;
localparam FSM2_S1_PHASE_1 = 4'd2;
localparam FSM2_S2_PHASE_2 = 4'd4;
localparam FSM2_S3_PHASE_3 = 4'd8;
//ex input clock period is 10ns target 625ns for 400khz
//clk_div is 63
//clk div logic
reg [5:0] rt_r_div_cnt = 6'd0;
reg rt_r_scl_en = 1'b0;
wire rt_w_div_cnt_eqnz;
//fsm1: IDLE, Start, Data, Data 8, Ack, blanking
reg [2:0] rt_r_fsm1_state = FSM1_S0_IDLE;
//bit counter
wire	  rt_w_bit_cnt_ce;
reg [6:0] rt_r_bit_cnt = 7'd1;
//length counter
wire      rt_w_len_cnt_eqnz;
wire      rt_w_len_cnt_ce;
wire      rt_w_len_cnt_rst;
reg [15:0]rt_r_len_cnt = 16'd0;
//fsm output
reg		  rt_r_i2c_data_en  = CONST_DISABLE;
reg       rt_r_sda_valid_en = CONST_DISABLE;
reg       rt_r_sda_latch_en = CONST_DISABLE;
wire	  rt_w_i2c_start;
wire	  rt_w_i2c_stop;
reg       rt_r_nak = CONST_DISABLE;
//fsm2: phase 0, phase 1, phase 2, phase 3
wire rt_w_fsm2_step;
reg [3:0] rt_r_fsm2_state = FSM2_S0_PHASE_0;
wire [3:0]rt_w_phase_sync;
//scl
reg rt_r_scl_s = 1'b1;
reg rt_r_sda_s = 1'b1;
reg rt_r_scl_d = 1'b0;
reg rt_r_scl_p = 1'b0;
reg rt_r_sda_p = 1'b1;

always@(posedge rt_i_clk) begin
	if(rt_r_nak)
		rt_r_nak <= ~((rt_r_fsm1_state == FSM1_S5_BLANKING)&rt_w_phase_sync[3]);
	else
		rt_r_nak <= rt_i_nak;
end

assign rt_w_len_cnt_eqnz = |rt_r_len_cnt;
assign rt_w_len_cnt_ce   = (rt_r_fsm1_state == FSM1_S5_BLANKING)&
                           rt_w_phase_sync[3]&
                           ~rt_r_nak;
assign rt_w_len_cnt_rst  = (rt_r_fsm1_state == FSM1_S0_IDLE);
always@(posedge rt_i_clk) begin
  if(rt_i_rst | rt_w_len_cnt_rst)
    rt_r_len_cnt <= rt_i_len;
  else if(rt_w_len_cnt_ce&rt_w_len_cnt_eqnz)
    rt_r_len_cnt <= rt_r_len_cnt - 1'b1;
end

//scl logic in start phase
always@(*) begin
  if(rt_i_rst | ~rt_w_i2c_start)begin
    rt_r_scl_s = CONST_ENABLE;
    rt_r_sda_s = CONST_ENABLE;
  end else begin
    rt_r_scl_s = (|rt_r_fsm2_state[1:0])&~(|rt_r_fsm2_state[3:2]);
    rt_r_sda_s = rt_r_fsm2_state[0]&~(|rt_r_fsm2_state[3:1]);
  end
end

//scl logic in data phase
always@(*) begin
  if(rt_i_rst | ~rt_r_i2c_data_en)
    rt_r_scl_d = CONST_DISABLE;
  else begin
    rt_r_scl_d = (|rt_r_fsm2_state[2:1])&~(rt_r_fsm2_state[0]|rt_r_fsm2_state[3]);
  end
end

//scl logic in stop phase
always@(*) begin
  if(rt_i_rst | ~rt_w_i2c_stop) begin
    rt_r_scl_p = CONST_DISABLE;
    rt_r_sda_p = CONST_DISABLE;
  end else begin
    rt_r_scl_p = (|rt_r_fsm2_state[3:2])&~(|rt_r_fsm2_state[1:0]);
    rt_r_sda_p = (|rt_r_fsm2_state[3])&~(|rt_r_fsm2_state[2:0]);
  end
end

always@(posedge rt_i_clk) begin
  rt_o_sda_valid <= (rt_r_sda_valid_en|
					(rt_r_fsm1_state == FSM1_S5_BLANKING)&
					 (rt_w_len_cnt_eqnz |
					 rt_r_nak)) &
                     rt_w_phase_sync[3];
end
always@(posedge rt_i_clk) begin
  rt_o_sda_latch <= rt_r_sda_latch_en & rt_w_phase_sync[1];
end

always@(posedge rt_i_clk) begin
  rt_o_ack_valid <= (rt_r_fsm1_state == FSM1_S3_DATA8) & 
                     rt_w_phase_sync[2];
end

always@(posedge rt_i_clk) begin
  rt_o_ack_latch <= (rt_r_fsm1_state == FSM1_S4_ACK) & 
                     rt_w_phase_sync[0];
end

always@(posedge rt_i_clk) begin
  rt_o_ack_oe <= ~((rt_r_fsm1_state == FSM1_S3_DATA8)&
                    rt_r_fsm2_state[3]|
                   (rt_r_fsm1_state == FSM1_S4_ACK)&
                  (|rt_r_fsm2_state[2:0]));
end

always@(posedge rt_i_clk) begin
  rt_o_blank_sync <= {rt_w_phase_sync[2:0]&
                     {3{(rt_r_fsm1_state == FSM1_S5_BLANKING)}},
                     (rt_r_fsm1_state == FSM1_S4_ACK)&
                     rt_w_phase_sync[3]};
end

////fsm1:
always@(posedge rt_i_clk) begin
  if(rt_i_rst)begin
    rt_o_scl <= CONST_ENABLE;
	rt_o_sda <= CONST_ENABLE;
  end else begin
    case(rt_r_fsm1_state)
    FSM1_S0_IDLE:begin
      rt_o_scl <= rt_r_scl_s;
      rt_o_sda <= rt_r_sda_s;
    end
    FSM1_S1_START:begin
      rt_o_scl <= rt_r_scl_s;
      rt_o_sda <= rt_r_sda_s;
    end
    FSM1_S6_STOP:begin
      rt_o_scl <= rt_r_scl_p;
      rt_o_sda <= rt_r_sda_p;
    end
	FSM1_S7_READY: begin
      rt_o_scl <= CONST_ENABLE;
      rt_o_sda <= CONST_ENABLE;
	end
    default:begin
      rt_o_scl <= rt_r_scl_d;
      rt_o_sda <= CONST_DISABLE;
    end
    endcase
  end
end

//clk div logic
assign rt_w_div_cnt_eqnz = |rt_r_div_cnt;
always@(posedge rt_i_clk) begin
  if(rt_i_rst | ~rt_w_div_cnt_eqnz)
    rt_r_div_cnt <= rt_i_clk_div;
  else if(rt_w_div_cnt_eqnz&rt_r_scl_en)
    rt_r_div_cnt <= rt_r_div_cnt - 6'd1;
end

always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_r_fsm1_state <= FSM1_S0_IDLE;
  else begin
    case(rt_r_fsm1_state)
    FSM1_S0_IDLE:      rt_r_fsm1_state <= rt_i_en?FSM1_S1_START:FSM1_S0_IDLE;
    FSM1_S1_START:     rt_r_fsm1_state <= rt_w_phase_sync[3]?FSM1_S2_DATA:FSM1_S1_START;
    FSM1_S2_DATA:      rt_r_fsm1_state <= rt_w_phase_sync[3]?(
                                          rt_r_bit_cnt[6]?
                                          FSM1_S3_DATA8:
                                          FSM1_S2_DATA):
                                          FSM1_S2_DATA;
    FSM1_S3_DATA8:     rt_r_fsm1_state <= rt_w_phase_sync[3]?FSM1_S4_ACK:FSM1_S3_DATA8;
    FSM1_S4_ACK:       rt_r_fsm1_state <= rt_w_phase_sync[3]?
	                                      FSM1_S5_BLANKING:
										  FSM1_S4_ACK;
    FSM1_S5_BLANKING:  rt_r_fsm1_state <= rt_w_phase_sync[3]?(
                                          rt_w_len_cnt_eqnz?
                                          FSM1_S2_DATA:(rt_r_nak?
										  FSM1_S2_DATA:
                                          FSM1_S6_STOP)):
                                          FSM1_S5_BLANKING;
    FSM1_S6_STOP:      rt_r_fsm1_state <= rt_w_phase_sync[3]?FSM1_S7_READY:FSM1_S6_STOP;
	FSM1_S7_READY:     rt_r_fsm1_state <= FSM1_S0_IDLE;
    endcase
  end
end

assign rt_w_bit_cnt_ce = (rt_r_fsm1_state == FSM1_S2_DATA);
assign rt_w_i2c_start  = (rt_r_fsm1_state == FSM1_S1_START);
assign rt_w_i2c_stop   = (rt_r_fsm1_state == FSM1_S6_STOP);
always@(*) begin
  case(rt_r_fsm1_state)
  FSM1_S0_IDLE:begin
    rt_r_scl_en       = CONST_DISABLE;
    rt_r_i2c_data_en  = CONST_DISABLE;
	rt_r_sda_latch_en = CONST_DISABLE;
	rt_r_sda_valid_en = CONST_DISABLE;
  end	
  FSM1_S1_START:begin
    rt_r_scl_en       = CONST_ENABLE;
    rt_r_i2c_data_en  = CONST_DISABLE;
	rt_r_sda_latch_en = CONST_DISABLE;
	rt_r_sda_valid_en = CONST_ENABLE;
  end
  FSM1_S2_DATA:begin
    rt_r_scl_en       = CONST_ENABLE;
    rt_r_i2c_data_en  = CONST_ENABLE;
	rt_r_sda_latch_en = CONST_ENABLE;
	rt_r_sda_valid_en = CONST_ENABLE;
  end
  FSM1_S3_DATA8:begin
    rt_r_scl_en       = CONST_ENABLE;
    rt_r_i2c_data_en  = CONST_ENABLE;
	rt_r_sda_latch_en = CONST_ENABLE;
	rt_r_sda_valid_en = CONST_DISABLE;
  end
  FSM1_S4_ACK:begin
    rt_r_scl_en       = CONST_ENABLE;
    rt_r_i2c_data_en  = CONST_ENABLE;
	rt_r_sda_latch_en = CONST_DISABLE;
	rt_r_sda_valid_en = CONST_DISABLE;
  end
  FSM1_S5_BLANKING:begin
    rt_r_scl_en       = CONST_ENABLE;
    rt_r_i2c_data_en  = CONST_DISABLE;
	rt_r_sda_latch_en = CONST_DISABLE;
	rt_r_sda_valid_en = CONST_DISABLE;
  end
  FSM1_S6_STOP:begin
    rt_r_scl_en       = CONST_ENABLE;
    rt_r_i2c_data_en  = CONST_DISABLE;
	rt_r_sda_latch_en = CONST_DISABLE;
	rt_r_sda_valid_en = CONST_DISABLE;
  end
  FSM1_S7_READY:begin
    rt_r_scl_en       = CONST_DISABLE;
    rt_r_i2c_data_en  = CONST_DISABLE;
	rt_r_sda_latch_en = CONST_DISABLE;
	rt_r_sda_valid_en = CONST_DISABLE;
  end
  endcase
end

always@(posedge rt_i_clk) begin
  if(~rt_w_bit_cnt_ce)
    rt_r_bit_cnt <= 7'd1;
  else if(rt_w_bit_cnt_ce&rt_w_phase_sync[3])
    rt_r_bit_cnt <= {rt_r_bit_cnt[6:0], 1'b0};
end

assign rt_w_fsm2_step  = ~rt_w_div_cnt_eqnz&rt_r_scl_en;
assign rt_w_phase_sync = rt_r_fsm2_state&{4{~rt_w_div_cnt_eqnz}};
always@(posedge rt_i_clk) begin
  if(rt_i_rst)
    rt_r_fsm2_state <= FSM2_S0_PHASE_0;
  else if(rt_w_fsm2_step)
    rt_r_fsm2_state <= {rt_r_fsm2_state[2:0], rt_r_fsm2_state[3]};
end

always@(posedge rt_i_clk) begin
  rt_o_ready <= (rt_r_fsm1_state == FSM1_S6_STOP)& rt_w_phase_sync[3];
end

endmodule