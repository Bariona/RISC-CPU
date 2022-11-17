`include "const.v"

module InsFetcher(
  input wire clk, 
  input wire rst,
  input wire rdy, 

  // from mem controller
  // input wire  instr_mc2if_arrived,
  // input wire  [`DATA_IDX_RANGE] instr_mc2if,

  // signal to icahce
  output wire rd_ena,
  output wire [`DATA_IDX_RANGE] pc2icache,
  input  wire instr_rdy,
  input  wire [`DATA_IDX_RANGE] instr_from_icache,

  // from predictor
  output reg  [`DATA_IDX_RANGE] instr_2pred,
  output reg  [`DATA_IDX_RANGE] cur_pc, // ? reg or wire
  input wire  [`DATA_IDX_RANGE] next_pc,

  // Issue part
  input  wire is_full,
  output wire [`DATA_IDX_RANGE] instr2is
); 

// 后续会有predict失败的roll_back

reg [`DATA_IDX_RANGE] pc;

assign rd_ena     = ~is_full;
assign pc2icache  = pc;

assign instr2is   = (instr_rdy) ? instr_from_icache : 32'h0;

always @(posedge clk) begin
  if (rst) begin 
    pc <= 0;
  end 
  else if (~rdy) begin // pause 
  end 

  else begin
    if (instr_rdy) begin
      instr_2pred <= instr_from_icache;
    end
    cur_pc      <= pc;
    pc          <= next_pc;
  end

end

// assign instr_if2is = fetched_instr;

endmodule
