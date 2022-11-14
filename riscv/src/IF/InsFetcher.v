`include "riscv\src\const.v"

module InsFetcher(
  input wire clk, 
  input wire reset,
  input wire rdy, 

  input wire [`DATA_IDX_RANGE] instr_mc2if

); 

reg [`DATA_IDX_RANGE] pc = 0;

// ICACHE
reg valid[`ICACHE_SIZE - 1 : 0];
reg [`ICACHE_TAG_RANGE] icache_tag[`ICACHE_SIZE - 1 : 0];

wire hit = valid[pc[`IDX_RANGE]] && icache_tag[pc[`IDX_RANGE]] == pc[`ICACHE_TAG_RANGE];

always @(posedge clk) begin
  if (reset) begin 
    pc <= 0;
    for (integer i = 0; i < `ICACHE_SIZE; i = i + 1) begin
      valid[i] <= 0;
      icache_tag[i] <= 0;
    end
  end 

  else if (~rdy) begin
    // pause 
  end 

  else begin

    pc <= next_pc;
  end

end

endmodule
