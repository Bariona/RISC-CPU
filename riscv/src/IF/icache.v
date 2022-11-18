`include "const.v"

`define VALID                  1'b1
`define STALL                  1'b0
`define INS_00                 31:0
`define INS_01                 63:32
`define INS_10                 95:64
`define INS_11                127:96

module ICACHE (
  input wire clk,
  input wire rst,
  input wire rdy,

  // port with fetcher
  input wire rdy_from_fet,
  input wire [`DATA_IDX_RANGE] pc,
  output wire instr_valid,
  output wire [`DATA_IDX_RANGE] instr,

  // port with mem_controller
  output wire mc_ena,
  output reg  [`ADDR_IDX] addr,
  input  wire valid_from_mc,
  input  wire [`DATA_IDX_RANGE] data_from_mc
);

// ICACHE components
reg status;
reg [`DATA_IDX_RANGE] counter;

reg valid[`ICACHE_ENTRY - 1 : 0];
reg [`ICACHE_TAG_RANGE]   icache_tag[`ICACHE_ENTRY - 1 : 0];
reg [`ICACHE_BLOCK_RANGE] icache_store[`ICACHE_ENTRY - 1 : 0];

wire      idx       = pc[`ICACHE_IDX_RANGE];
wire      hit       = (rdy_from_fet) ? (valid[idx] && icache_tag[idx] == pc[`ICACHE_TAG_RANGE]) : `TRUE;

wire[1:0] addr_ins  = pc[`INSTR_RANGE];
assign    instr     = (addr_ins[1]) ? (addr_ins[0] ? icache_store[idx][`INS_11] : icache_store[idx][`INS_10]) : 
                                  (addr_ins[0] ? icache_store[idx][`INS_01] : icache_store[idx][`INS_00]);

assign instr_valid  =  hit;
assign mc_ena       = ~hit;

integer i;
always @(posedge clk) begin
  if (rst) begin      // clear
    status  <= `VALID;
    counter <= `ZERO;
    for (i = 0; i < `ICACHE_ENTRY; i = i + 1) begin
      valid[i]        <= 0;
      icache_tag[i]   <= 0;
      icache_store[i] <= 0;
    end
  end
  else if (~rdy) begin  // pause
  end

  else begin
    if (~hit && status == `VALID) begin         // fill the block(i.e. entry)
      status          <= `STALL;
      counter         <= `ZERO;
      addr            <= {pc[16:4], 4'b0000}; // ??? hardcoding, waited to be removed
    end
    else if (~hit) begin
      // $display("counter", counter);
      if (valid_from_mc) begin 
        case (counter)
          32'h1 : icache_store[idx][`INS_00] <= data_from_mc;
          32'h2 : icache_store[idx][`INS_01] <= data_from_mc;
          32'h3 : icache_store[idx][`INS_10] <= data_from_mc;
          32'h4 : icache_store[idx][`INS_11] <= data_from_mc;
        endcase

        // valid[idx]        <= 1;
        if (counter < 32'h04) begin
          counter     <= counter + `ONE;
          addr        <= addr    + 32'h4;    // next instruction
        end
        else begin
          status      <= `VALID;
          counter     <= `ZERO;
        end
      end

    end
  end

end

endmodule