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
  output reg instr_valid,
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

reg valid [`ICACHE_ENTRY - 1 : 0];
reg [`ICACHE_TAG_RANGE] icache_tag [`ICACHE_ENTRY - 1 : 0];
reg [`DATA_IDX_RANGE]   icache_inst[`ICACHE_INSTR_CNT - 1 : 0];

wire [`ICACHE_IDX_RANGE] idx = pc[`PC_IDX_RANGE];

wire hit = valid[idx] && icache_tag[idx] == pc[`ICACHE_TAG_RANGE];

integer i;
always @(posedge clk) begin
  if (rst) begin      // clear
    status        <= `IC_VALID;
    instr_valid   <= `FALSE;
    instr         <= `ZERO;
    mc_ena        <= `FALSE;
    counter       <= `ZERO;
    addr          <= `ZERO;
    for (i = 0; i < `ICACHE_ENTRY; i = i + 1) begin
      valid[i]        <= `FALSE;
      icache_tag[i]   <= 0;
    end
    for (i = 0; i < `ICACHE_INSTR_CNT; i = i + 1) begin
      icache_inst[i] <= `ZERO;
    end
  end
  else if (~rdy) begin  // pause
  end

  else if (rdy_from_fet) begin
    
      if (hit) begin
        instr_valid <= `TRUE;
        instr       <=  icache_inst[pc[10:2]];
        mc_ena      <= `FALSE;
      end
      else begin
        instr_valid <= `FALSE;
        if (status == `IC_VALID) begin          // fill the block(i.e. entry)
          status          <= `IC_STALL;
          mc_ena          <= `TRUE;
          counter         <= `ONE;                // not zero ?

          valid[idx]      <= `FALSE;
          icache_tag[idx] <= pc[`ICACHE_TAG_RANGE];
          addr            <= {pc[16:4], 4'b0000};
        end
        else begin
          if (valid_from_mc) begin 
            icache_inst[addr[10:2]] <= data_from_mc;
            if (counter <= `BLOCK_INS_CNT - 1) begin
              counter       <= counter + `ONE;
              addr          <= addr    +    4;
            end
            else begin
              status        <= `IC_VALID;
              counter       <= `ZERO;
              valid[idx]    <= `TRUE;
              mc_ena        <= `FALSE;
            end
          end
        end
      end

  end
  else begin
    instr_valid <= `FALSE;
  end
end

endmodule