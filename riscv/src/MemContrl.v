`include "const.v"
`timescale 1ps/1ps

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
  input  wire [`ADDR_IDX] instr_addr,
  output reg  valid_2icache,
  output reg  [`DATA_IDX_RANGE] data_2icache,

  // signal from dcache
  input  wire wr_ena,
  input  wire wr_from_dcache,
  input  wire [`DATA_IDX_RANGE] data_addr,
  input  wire [`MEM_IDX_RANGE]  data_from_dcache,
  output reg  valid_2dcache,

  // port with ram
  output wire ram_ena,
  output wire wr_mc2ram,         // write_or_read (write: 1 read: 0)
  output reg  [`ADDR_IDX] addr_2ram,
  output wire [`MEM_IDX_RANGE] data_2ram,
  input  wire [`MEM_IDX_RANGE] data_from_ram
); 

reg [1:0] status;
reg [`ADDR_IDX] pc_2ram;
reg [`DATA_IDX_RANGE] counter;

assign ram_ena    = fet_ena | wr_ena;
assign wr_mc2ram  = fet_ena ? 1'b0 : wr_from_dcache;
assign data_2mem  = data_from_dcache; // ? 是否需要加condition

initial begin
  $display("status is %d at %t", valid_2icache, $realtime);
  # 40; $display("status is %d at %t", valid_2icache, $time);
end

always @(posedge clk) begin
  if (rst) begin
    status  <= `STALL;
    pc_2ram <= `ZERO;
    counter <= `ZERO;

    valid_2icache <= `FALSE;
    valid_2dcache <= `FALSE;
  end
  else if (~rdy) begin //pause
  end

  else begin
    if (status == `STALL) begin 
      if (fet_ena) begin
        status        <= `FETCH;
        valid_2icache <= `TRUE;
        pc_2ram       <= instr_addr; 
      end
      else if (wr_ena) begin
        status        <= (wr_from_dcache) ? `STROE : `LOAD;
        valid_2dcache <= `TRUE;
      end
      //status  <= (fet_ena) ? `FETCH : (wr_ena ? (wr_from_dcache ? `STROE : `LOAD) : `STALL);
    end
    else if (status == `FETCH) begin
      case (counter)
        32'h1 : data_2icache[7:0]   <= data_from_ram;
        32'h2 : data_2icache[15:8]  <= data_from_ram;
        32'h3 : data_2icache[23:16] <= data_from_ram;
        32'h4 : data_2icache[31:24] <= data_from_ram;
      endcase
      
      addr_2ram <= pc_2ram;
      pc_2ram   <= pc_2ram + 32'h1;
      if (counter >= 32'h4) begin
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