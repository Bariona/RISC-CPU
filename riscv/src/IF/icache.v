`include "const.v"

`define IC_VALID 1'b1
`define IC_STALL 1'b0

module ICACHE (
  input wire clk,
  input wire rst,
  input wire rdy,

  // port with fetcher
  input wire rdy_from_fet,
  input wire [`DATA_IDX_RANGE] pc,
  output wire instr_valid,
  // output wire [`DATA_IDX_RANGE] instr,
  output reg [`DATA_IDX_RANGE] instr,

  // port with mem_controller
  output reg  mc_ena,
  output reg  [`ADDR_IDX] addr,
  input  wire valid_from_mc,
  input  wire [`DATA_IDX_RANGE] data_from_mc
);

// ICACHE components
reg status;
reg [`DATA_IDX_RANGE] counter;

reg [`ICACHE_ENTRY - 1 : 0] valid;
reg [`ICACHE_TAG_RANGE]   icache_tag  [`ICACHE_ENTRY - 1 : 0];
reg [`ICACHE_BLOCK_RANGE] icache_store[`ICACHE_ENTRY - 1 : 0];

// wire[1:0] addr_ins  = pc[`INSTR_RANGE];

// wire[`ICACHE_IDX_RANGE] idx = pc[`ICACHE_IDX_RANGE];
// wire  hit = (rdy_from_fet) ? (valid[idx] && icache_tag[idx] == pc[`ICACHE_TAG_RANGE]) : `TRUE;

// assign    instr     = (addr_ins[1]) ? (addr_ins[0] ? icache_store[idx][`INS_11] : icache_store[idx][`INS_10]) : 
//                                   (addr_ins[0] ? icache_store[idx][`INS_01] : icache_store[idx][`INS_00]);

reg [1:0] addr_ins;
reg [`ICACHE_IDX_RANGE] idx;
reg hit;

assign instr_valid  =  hit;
// assign mc_ena       = ~hit;

always @(*) begin
  addr_ins  = pc[`INSTR_RANGE];
  idx       = pc[`ICACHE_IDX_RANGE];

  if (rdy_from_fet) begin
    hit = valid[idx] && icache_tag[idx] == pc[`ICACHE_TAG_RANGE];
  end
  else begin
    hit = `TRUE;
  end

  case (addr_ins[1:0])
    2'b00: instr = icache_store[idx][`INS_00];
    2'b01: instr = icache_store[idx][`INS_01];
    2'b10: instr = icache_store[idx][`INS_10];
    default: instr = icache_store[idx][`INS_11];
  endcase

end


integer i;
always @(posedge clk) begin
  if (rst) begin      // clear
    status        <= `IC_VALID;
    counter       <= `ZERO;
    addr          <= `ZERO;
    mc_ena        <= `FALSE;
    for (i = 0; i < `ICACHE_ENTRY; i = i + 1) begin
      valid[i]        <= `FALSE;
      icache_tag[i]   <= 0;
      icache_store[i] <= 0;
    end
  end
  else if (~rdy) begin  // pause
  end

  else begin
     //if (rdy_from_fet) begin
      if (hit) begin
        status      <= `IC_VALID;
        mc_ena      <= `FALSE;
      end
      else if (status == `IC_VALID) begin          // fill the block(i.e. entry)
        status          <= `IC_STALL;
        mc_ena          <= `TRUE;
        counter         <= `ONE;                // not zero ?

        valid[idx]      <= `FALSE;              /// TODO: this is very important!
        icache_tag[idx] <= pc[`ICACHE_TAG_RANGE];
        addr            <= {pc[16:4], 4'b0000};
      end
      else begin
        if (valid_from_mc) begin 
          case (counter)
            32'h1 : icache_store[idx][`INS_00] <= data_from_mc;
            32'h2 : icache_store[idx][`INS_01] <= data_from_mc;
            32'h3 : icache_store[idx][`INS_10] <= data_from_mc;
            32'h4 : icache_store[idx][`INS_11] <= data_from_mc;
          endcase

          if (counter <= `BLOCK_INS_CNT - 1) begin
            counter       <= counter + `ONE;
            addr          <= addr    +    4;    // next instruction
          end
          else begin
            status        <= `IC_VALID;
            counter       <= `ZERO;
            valid[idx]    <= `TRUE;
            mc_ena        <= `FALSE;
          end
        end
      end
    //end

  end

end

endmodule