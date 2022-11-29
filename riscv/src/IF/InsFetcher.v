`include "const.v"

module InsFetcher(
  input wire clk, 
  input wire rst,
  input wire rdy, 

  // signal to icahce
  output wire rdy_2icache,              // ready to fetch an instruction
  output reg  [`DATA_IDX_RANGE] pc_2icache,
  input  wire instr_valid,              // whether icache has send instr back
  input  wire [`DATA_IDX_RANGE] instr_from_icache,

  // from predictor
  output wire valid_2pred,
  output wire [`DATA_IDX_RANGE] instr_2pred,
  output wire [`DATA_IDX_RANGE] cur_pc, // ??? reg or wire
  input  wire [`DATA_IDX_RANGE] next_pc,

  // Issue part
  input  wire is_full,
  output wire valid_2is,
  output wire [`DATA_IDX_RANGE] pc_2is,
  output wire [`DATA_IDX_RANGE] instr_2is
); 

// 后续会有predict失败的roll_back

reg [`DATA_IDX_RANGE] pc;

assign rdy_2icache = ~is_full;

assign valid_2is   = instr_valid;
assign instr_2is   = instr_from_icache;
assign pc_2is      = pc;

// to predictor
assign valid_2pred = (instr_valid) ? `TRUE : `FALSE;
assign cur_pc      = pc;
assign instr_2pred = instr_from_icache;

always @(posedge clk) begin
  if (rst) begin 
    pc <= 0;
  end 
  else if (~rdy) begin // pause 
  end 

  else begin
    pc <= (instr_valid) ? next_pc : pc;

    if (rdy_2icache) begin   // able to fetch another instruction
      pc_2icache <= pc;
    end 
    else begin
      pc <= `ZERO;
    end

  end

end

// assign instr_if2is = fetched_instr;

endmodule
