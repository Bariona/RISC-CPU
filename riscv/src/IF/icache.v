`include "const.v"

`define INS_00                 31:0
`define INS_01                 63:32
`define INS_10                 95:64
`define INS_11                127:96

module ICACHE (
  input wire clk,
  input wire rst,
  input wire rdy,

  input wire rd_ena,
  input wire [`DATA_IDX_RANGE] pc,
  
  // output instruction and send it to fetcher
  output wire instr_rdy,
  output wire [`DATA_IDX_RANGE] instr,

  // port with mem_controller
  output wire mc_ena,
  output reg  [`ADDR_IDX] addr,
  input  wire [`ICACHE_BLOCK_RANGE] data_from_mc
);

// ICACHE components
reg valid[`ICACHE_ENTRY - 1 : 0];
reg [`ICACHE_TAG_RANGE]   icache_tag[`ICACHE_ENTRY - 1 : 0];
reg [`ICACHE_BLOCK_RANGE] icache_store[`ICACHE_ENTRY - 1 : 0];

wire[1:0] addr_ins  = pc[`INSTR_RANGE];
wire      idx       = pc[`ICACHE_IDX_RANGE];
wire      hit       = (rd_ena) ? (valid[idx] && icache_tag[idx] == pc[`ICACHE_TAG_RANGE]) : `FALSE;

assign    instr     = (addr_ins[1]) ? (addr_ins[0] ? icache_store[idx][`INS_11] : icache_store[idx][`INS_10]) : 
                                  (addr_ins[0] ? icache_store[idx][`INS_01] : icache_store[idx][`INS_00]);
assign instr_rdy    =  hit;
assign mc_ena       = ~hit;

integer i;
always @(posedge clk) begin
  if (rst) begin      // clear
    for (i = 0; i < `ICACHE_ENTRY; i = i + 1) begin
      valid[i]      <= 0;
      icache_tag[i] <= 0;
    end
  end
  else if (~rdy) begin  // pause
  end

  else begin
    if (~hit) begin // fill the block(i.e. entry)
      addr              <= {pc[16:4], 2'b00}; // ? hardcoding, waited to be removed
      icache_store[idx] <= data_from_mc;
      valid[idx]        <= 1;
    end
  end
end

endmodule