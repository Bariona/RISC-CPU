`include "riscv\src\const.v"

module Predictor(
  input wire clk,
  input wire reset, 
  input wire rdy,

  input [`DATA_IDX_RANGE] instr,
  output wire predict
);

reg [1:0] state[`PREDICTOR_SIZE - 1 : 0];


endmodule