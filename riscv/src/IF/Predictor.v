`include "const.v"

`define MAP_IDX 9:2

`define PREDICTOR_SIZE 8'hFF

// Two-way branch predictor
module Predictor (
  input wire clk,
  input wire rst, 
  input wire rdy,

  // port with fetcher
  input wire [`DATA_IDX_RANGE] instr_from_IC,
  input wire [`DATA_IDX_RANGE] cur_pc,
  output wire if_jump,
  output wire [`DATA_IDX_RANGE] predict_pc,

  // port with ROB
  input wire rob_commit_pc_arrived,
  input wire [`DATA_IDX_RANGE] rob_commit_pc,
  input wire hit_res
);

reg [1:0] state[`PREDICTOR_SIZE - 1 : 0];

wire [`DATA_IDX_RANGE] jalImm   = {{12{instr_from_IC[31]}}, instr_from_IC[19:12], instr_from_IC[20], instr_from_IC[30:21], 1'b0};
wire [`DATA_IDX_RANGE] brcImm   = {{20{instr_from_IC[31]}}, instr_from_IC[7], instr_from_IC[30:25], instr_from_IC[11:8], 1'b0};  

wire [`DATA_IDX_RANGE] offset   = (instr_from_IC[`OPCODE_RANGE] == `JAL_TYPE) ? jalImm : brcImm;

assign if_jump    = (instr_from_IC[`OPCODE_RANGE] == `JAL_TYPE) ? `TRUE : 
                      ((instr_from_IC[`OPCODE_RANGE] == `B_TYPE) ? state[cur_pc[`MAP_IDX]][1]: `FALSE); // cur_pc(√) instr_from_IC(×)
assign predict_pc = (if_jump) ? cur_pc + offset : cur_pc + 4;

integer i;

always @(posedge clk) begin
  if (rst) begin      // reset
    for (i = 0; i < `PREDICTOR_SIZE; i = i + 1) 
      state[i] <= 0;
  end
  else if (~rdy) begin  // pause 
  end

  else begin
    if (rob_commit_pc_arrived) begin
      if (~hit_res) begin
        state[rob_commit_pc[`MAP_IDX]] <= state[rob_commit_pc[`MAP_IDX]] + ((state[rob_commit_pc[`MAP_IDX]][1]) ? -1 : 1);
      end
      else begin
        state[rob_commit_pc[`MAP_IDX]] <= (state[rob_commit_pc[`MAP_IDX]][1]) ? 3 : 0;
      end
    end
  end

end

endmodule