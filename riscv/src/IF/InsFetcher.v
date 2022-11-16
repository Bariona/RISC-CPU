`include "riscv\src\const.v"

module ICACHE (
);
// waited to be transfered...
endmodule

module InsFetcher(
  input wire clk, 
  input wire reset,
  input wire rdy, 

  // from mem controller
  input wire  instr_mc2if_arrived,
  input wire  [`DATA_IDX_RANGE] instr_mc2if,
  
  // from predictor
  output reg cur_pc,
  input wire next_pc,

  output reg [`DATA_IDX_RANGE] instr_if2is
); 

reg [`DATA_IDX_RANGE] pc;

// ICACHE
reg valid[`ICACHE_SIZE - 1 : 0];
reg [`ICACHE_TAG_RANGE] icache_tag[`ICACHE_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] icache_store[`ICACHE_SIZE - 1 : 0];

wire hit = valid[pc[`ICACHE_IDX_RANGE]] && icache_tag[pc[`ICACHE_IDX_RANGE]] == pc[`ICACHE_TAG_RANGE];
// wire fetched_instr = (hit) ? icache_store[pc[`ICACHE_IDX_RANGE]] : instr_mc2if;

always @(posedge clk) begin
  if (reset) begin 
    pc <= 0;
    for (integer i = 0; i < `ICACHE_SIZE; i = i + 1) begin
      valid[i]      <= 0;
      icache_tag[i] <= 0;
    end
  end 

  else if (~rdy) begin
    // pause 
  end 

  else begin
    if (~hit) begin   // update i$
      valid[pc[`ICACHE_IDX_RANGE]]         <= 1;
      icache_tag[pc[`ICACHE_IDX_RANGE]]    <= pc[`ICACHE_TAG_RANGE];
      icache_store[pc[`ICACHE_IDX_RANGE]]  <= instr_mc2if;
      instr_if2is                          <= instr_mc2if;
    end
    else begin 
      instr_if2is                          <= icache_store[pc[`ICACHE_IDX_RANGE]];
    end
    pc <= next_pc;
  end

end

// assign instr_if2is = fetched_instr;

endmodule
