`include "const.v"
// `timescale 1ps/1ps

`define NORM  3'b111
`define STALL 3'b000
`define FETCH 3'b001
`define LOAD  3'b010
`define STROE 3'b011

module MemController (
  input  wire clk,
  input  wire rst,
  input  wire rdy,

  // port with icache
  input  wire fet_ena,
  input  wire [`ADDR_IDX] instr_addr,
  output reg  valid_2icache,
  output reg  [`DATA_IDX_RANGE] data_2icache,

  // signal from LSB
  input  wire wr_ena,
  input  wire wr_from_lsb,
  input  wire [`DATA_IDX_RANGE] data_addr,
  input  wire [`MEM_IDX_RANGE]  data_from_lsb,
  output reg  valid_2lsb,
  output reg  [`MEM_IDX_RANGE] data_2lsb,

  // port with ram
  output reg  ram_ena,
  output wire wr_mc2ram,              // write_or_read (write: 1 read: 0)
  output reg  [`DATA_IDX_RANGE] addr_2ram,
  output reg  [`MEM_IDX_RANGE]  data_2ram,
  input  wire [`MEM_IDX_RANGE]  data_from_ram
); 

reg [2:0] status;
reg [`DATA_IDX_RANGE] counter;

assign wr_mc2ram  = wr_ena ? wr_from_lsb : (fet_ena ? `LOAD_MEM : `FALSE);
assign data_2mem  = data_from_lsb; // ? 是否需要加condition

// initial begin
//   $display("status is %d at %t", valid_2icache, $realtime);
//   # 40; $display("status is %d at %t", valid_2icache, $time);
// end

always @(posedge clk) begin
  if (rst) begin
    status  <= `NORM;
    counter <= `ZERO;
    ram_ena <= `FALSE;
    valid_2icache <= `FALSE;
    valid_2lsb <= `FALSE;
  end
  else if (~rdy) begin //pause
  end

  else begin
    if (status == `NORM) begin 
      if (wr_ena) begin
        ram_ena       <= `TRUE;
        status        <= (wr_from_lsb) ? `STROE : `LOAD;
        valid_2lsb    <= `FALSE;
        addr_2ram     <= data_addr;
        data_2ram     <= data_from_lsb;
      end
      else if (fet_ena) begin
        ram_ena       <= `TRUE;
        status        <= `FETCH;
        valid_2icache <= `FALSE;
        ram_ena       <= `TRUE;
        counter       <= `ZERO;
        addr_2ram     <= instr_addr; 
      end
      
      else begin
        valid_2icache <= `FALSE;
        valid_2lsb    <= `FALSE;
        ram_ena       <= `FALSE;
        counter       <= `ZERO;
        addr_2ram     <= `ZERO;
      end
    end

    else if (status == `FETCH) begin
      case (counter)
        // 花费一个cycle得到mem
        32'h1 : data_2icache[7:0]   <= data_from_ram;
        32'h2 : data_2icache[15:8]  <= data_from_ram;
        32'h3 : data_2icache[23:16] <= data_from_ram;
        32'h4 : data_2icache[31:24] <= data_from_ram;
      endcase
      
      addr_2ram   <= addr_2ram + `ONE; // +1是因为下一个周期才能拿到数据
      if (counter <= `INSTR_PER_BYTE - 1) begin
        counter   <= counter + `ONE;
      end
      else begin
        status        <= `STALL; // update to icache costs 1 cycle
        counter       <= `ZERO;
        valid_2icache <= `TRUE;
        ram_ena       <= `FALSE;
      end
    end
    else if (status == `STROE) begin
      status        <= `NORM;
      ram_ena       <= `FALSE;
    end
    else if (status == `LOAD) begin
      valid_2lsb    <= `TRUE;
      data_2lsb     <= data_from_ram;
      status        <= `NORM; /// ??? 这里可以加速, 多读一个unit
      ram_ena       <= `FALSE;
    end
    else begin // STALL
      status        <= `NORM;
      valid_2icache <= `FALSE;
      valid_2lsb    <= `FALSE;
    end

  end

end
endmodule