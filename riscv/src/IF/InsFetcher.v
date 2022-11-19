`include "const.v"

module InsFetcher(
  input wire clk, 
  input wire rst,
  input wire rdy, 

  // from mem controller
  // input wire  instr_mc2if_arrived,
  // input wire  [`DATA_IDX_RANGE] instr_mc2if,

  // signal to icahce
  output wire rdy_2icache,              // ready to fetch an instruction
  output wire [`DATA_IDX_RANGE] pc_2icache,
  input  wire instr_valid,              // whether icache has send instr back
  input  wire [`DATA_IDX_RANGE] instr_from_icache,

  // from predictor
  output wire valid_2pred,
  output reg  [`DATA_IDX_RANGE] instr_2pred,
  output reg  [`DATA_IDX_RANGE] cur_pc, // ??? reg or wire
  input wire  [`DATA_IDX_RANGE] next_pc,

  // Issue part
  input  wire is_full,
  output wire valid_2is,
  output wire [`DATA_IDX_RANGE] instr_2is
); 

// 后续会有predict失败的roll_back

reg [`DATA_IDX_RANGE] pc;

assign rdy_2icache = ~is_full;
assign pc_2icache  = pc;

assign valid_2is   = instr_valid;
assign instr_2is   = instr_from_icache;

assign valid_2pred = (instr_valid) ? `TRUE : `FALSE;

always @(posedge clk) begin
  if (rst) begin 
    pc <= 0;
  end 
  else if (~rdy) begin // pause 
  end 

  else begin
    if (rdy_2icache) begin
      if (instr_valid) begin // ??? until get a instr
        instr_2pred <= instr_from_icache;
        cur_pc      <= pc;
        pc          <= pc + 4;
      end
    end
  end

end

// assign instr_if2is = fetched_instr;

endmodule
