`include "riscv\src\const.v"

module InsFetcher(
  input wire clk, 
  input wire reset,
  input wire rdy, 

  input wire  [`DATA_IDX_RANGE] instr_mc2if,

  output wire [`DATA_IDX_RANGE] instr_if2is
); 

reg [`DATA_IDX_RANGE] pc, next_pc;

// ICACHE
reg valid[`ICACHE_SIZE - 1 : 0];
reg [`ICACHE_TAG_RANGE] icache_tag[`ICACHE_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] icache_store[`ICACHE_SIZE - 1 : 0];

wire hit = valid[pc[`ICACHE_IDX_RANGE]] && icache_tag[pc[`ICACHE_IDX_RANGE]] == pc[`ICACHE_TAG_RANGE];
wire fetched_instr = (hit) ? icache_store[pc[`ICACHE_IDX_RANGE]] : instr_mc2if;

assign instr_if2is = fetched_instr;

always @(posedge clk) begin
  if (reset) begin 
    pc      <= 0;
    next_pc <= 0;
    for (integer i = 0; i < `ICACHE_SIZE; i = i + 1) begin
      valid[i]      <= 0;
      icache_tag[i] <= 0;
    end
  end 

  else if (~rdy) begin
    // pause 
  end 

  else begin
    if (hit) begin 
      
    end
    else begin 
      valid[pc[`ICACHE_IDX_RANGE]]         <= 1;
      icache_tag[pc[`ICACHE_IDX_RANGE]]    <= pc[`ICACHE_TAG_RANGE];
      icache_store[pc[`ICACHE_IDX_RANGE]]  <= instr_mc2if;
    end

    pc <= next_pc;
  end

end

endmodule
