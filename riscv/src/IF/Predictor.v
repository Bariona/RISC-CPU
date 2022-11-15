`include "riscv\src\const.v"

`define MAP_IDX 11:0
`define PREDICTOR_SIZE 12'hFFF

// Two-way branch predictor
module Predictor
(
  input wire clk,
  input wire reset, 
  input wire rdy,

  // query whether to jump
  input wire [`DATA_IDX_RANGE] instr_from_IC,
  input wire [`DATA_IDX_RANGE] cur_pc,
  output wire[`DATA_IDX_RANGE] predict_pc,

  // update info
  input wire [`DATA_IDX_RANGE] rob_commit_pc,
  input wire hit_res
);

reg [1:0] state[`PREDICTOR_SIZE - 1 : 0];

wire if_jump      = state[instr_from_IC[`MAP_IDX]] > 1;
wire offset       = 0;  // ?complete offset 
assign predict_pc = instr_from_IC + offset;

always @(posedge clk) begin
  if (reset) begin      // reset
    for (integer i = 0; i < `PREDICTOR_SIZE; i = i + 1) 
      state[i] <= 0;
  end
  else if (~rdy) begin  // pause 
  end

  else begin
    if (~hit_res) begin
      state[rob_commit_pc[`MAP_IDX]] <= state[rob_commit_pc[`MAP_IDX]] + (state[rob_commit_pc[`MAP_IDX]] < 2) ? 1 : -1;
    end
    else begin
      state[rob_commit_pc[`MAP_IDX]] <= (state[rob_commit_pc[`MAP_IDX]] < 2) ? 0 : 3;
    end
  end

end

endmodule