`include "riscv\src\const.v"

module MemController(
  input  wire clk,
  input  wire reset,
  input  wire rdy,

  // signal from if
  input  wire is_from_IF,
  input  wire [`DATA_IDX_RANGE] pc,

  // signal from data
  input  wire data_wr,
  input  wire [`DATA_IDX_RANGE] data_addr,
  input  wire [`MEM_IDX_RANGE]  data_from_dc,

  output wire [`ADDR_IDX] addr2mem,
  output wire [`MEM_IDX_RANGE] mc_wr, // write_or_read (write: 1 read: 0)
  output wire [`MEM_IDX_RANGE] data2mem
); 

assign addr2mem = is_from_IF ? pc[`ADDR_IDX] : data_addr[`ADDR_IDX];
assign mc_wr    = is_from_IF ? 1'b0 : data_wr;
assign data2mem = data_from_dc; // ? 是否需要加condition

endmodule