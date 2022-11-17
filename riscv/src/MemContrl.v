`include "const.v"

`define STALL 2'b00
`define FETCH 2'b01
`define LOAD  2'b01
`define STROE 2'b11

module MemController(
  input  wire clk,
  input  wire rst,
  input  wire rdy,

  // port with icache
  input  wire fet_ena,
  input  wire [`ADDR_IDX] addr,
  output reg  [`ICACHE_BLOCK_RANGE] data2icache,

  // signal from dcache
  input  wire wr_ena,
  input  wire wr_from_dcache,
  input  wire [`DATA_IDX_RANGE] data_addr,
  input  wire [`MEM_IDX_RANGE]  data_from_dcache,

  // port with ram
  output wire  wr_mc2ram,         // write_or_read (write: 1 read: 0)
  output wire [`ADDR_IDX] addr2ram,
  input  wire [`MEM_IDX_RANGE] data_from_ram
); 

reg [1:0] status;
reg [`DATA_IDX_RANGE] counter;

assign mc_wr    = fet_ena ? 1'b0 : wr_from_dcache;
assign data2mem = data_from_dcache; // ? 是否需要加condition

always @(posedge clk) begin
  if (rst) begin
    status  <= `STALL;
    counter <= `ZERO;
  end
  else if (~rdy) begin //pause
  end
  else begin
    status  <= (fet_ena) ? `FETCH : (wr_ena ? (wr_from_dcache ? `STROE : `LOAD) : `STALL);
    if (status == `FETCH) begin
      case (counter)
        32'h00 : data2icache[7:0]   <= data_from_ram;
        32'h01 : data2icache[15:8]  <= data_from_ram;
        32'h02 : data2icache[23:16] <= data_from_ram;
        32'h03 : data2icache[31:24] <= data_from_ram;
      endcase
            
      if (counter == 32'h03) begin
        counter <= `ZERO;
        status  <= `STALL;
      end
      else begin
        counter <= counter + `ONE;
      end
    end
    else if (status == `STROE) begin
    end
    else if (status == `STALL) begin
    end

  end

end
endmodule