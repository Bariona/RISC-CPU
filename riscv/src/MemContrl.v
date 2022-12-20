`include "const.v"
// `timescale 1ps/1ps

`define STALL       3'b000
`define LdStSTALL   3'b110
`define NORM        3'b111
`define FETCH       3'b001
`define LOAD        3'b010
`define LOAD_STALL  3'b100
`define STROE       3'b011

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
  input  wire [`OPCODE_TYPE]    optype_from_lsb,
  input  wire [`DATA_IDX_RANGE]  addr_from_lsb,
  input  wire [`DATA_IDX_RANGE] data_from_lsb,
  input  wire [2:0]             totByte,
  output reg  valid_2lsb,
  output reg  [`DATA_IDX_RANGE] data_2lsb,

  // port with ram
  output reg  ram_ena,
  output reg  wr_mc2ram,              // write_or_read (write: 1 read: 0)
  output reg  [`DATA_IDX_RANGE] addr_2ram,
  output reg  [`MEM_IDX_RANGE]  data_2ram,

  input  wire [`MEM_IDX_RANGE]  data_from_ram,
  input  wire uart_full_signal
); 

reg [2:0] status;
reg [`DATA_IDX_RANGE] counter;

// assign wr_mc2ram  = wr_ena ? wr_from_lsb : (fet_ena ? `LOAD_MEM : 0);

`ifdef Debug
  integer outfile;
  initial begin
    outfile = $fopen("mc.out");
  end
`endif 

always @(posedge clk) begin
  if (rst) begin
    status  <= `NORM;
    counter <= `ZERO;
    ram_ena <= `FALSE;
    wr_mc2ram     <= `LOAD_MEM;
    addr_2ram     <= `ZERO;
    data_2ram     <= `ZERO;
    valid_2icache <= `FALSE;
    data_2icache  <= `ZERO;
    valid_2lsb    <= `FALSE;
    data_2lsb     <= `ZERO;
  end
  else if (~rdy) begin //pause
  end
  else if (uart_full_signal) begin
  end

  else begin
    if (status == `NORM) begin 
      
      valid_2icache <= `FALSE;
      valid_2lsb    <= `FALSE;

      if (wr_ena) begin
        if (wr_from_lsb) begin
          status      <= `STROE;
          ram_ena     <= `FALSE;
          wr_mc2ram   <= `LOAD_MEM;
          addr_2ram   <= `ZERO;
          data_2ram   <= `ZERO;
        end
        else begin
          status      <= `LOAD;
          data_2lsb   <= `ZERO;
          ram_ena     <= `TRUE;
          wr_mc2ram   <= `LOAD_MEM;
          addr_2ram   <= addr_from_lsb;
        end
        counter       <= `ZERO;
        
      end
      else if (fet_ena) begin
        ram_ena       <= `TRUE;
        wr_mc2ram     <= `LOAD_MEM;

        status        <= `FETCH;
        counter       <= `ZERO;
        addr_2ram     <= instr_addr; 
      end
      else begin  
        ram_ena       <= `FALSE;
        wr_mc2ram     <= `LOAD_MEM;
        counter       <= `ZERO;
        addr_2ram     <= `ZERO;
      end
    end

    else if (status == `FETCH) begin
      case (counter)
        // cost 1 cycle to get mem
        32'h1 : data_2icache[7:0]   <= data_from_ram;
        32'h2 : data_2icache[15:8]  <= data_from_ram;
        32'h3 : data_2icache[23:16] <= data_from_ram;
        32'h4 : data_2icache[31:24] <= data_from_ram;
      endcase
      
      
      if (counter <= `INSTR_PER_BYTE - 1) begin
        counter   <= counter    + `ONE;
        addr_2ram <= addr_2ram  + `ONE;
      end
      else begin
        status        <= `STALL; // update to icache costs 1 cycle
        counter       <= `ZERO;
        addr_2ram     <= `ZERO;
        valid_2icache <= `TRUE;
        ram_ena       <= `FALSE;
      end
    end
    else if (status == `STROE && !uart_full_signal) begin
      wr_mc2ram   <= `STORE_MEM;
      case (counter)
        32'h0: data_2ram  <= data_from_lsb[7:0];
        32'h1: data_2ram  <= data_from_lsb[15:8];
        32'h2: data_2ram  <= data_from_lsb[23:16];
        32'h3: data_2ram  <= data_from_lsb[31:24];
      endcase

      if (counter <= totByte - 1) begin
        counter     <= counter + `ONE;
        ram_ena     <= `TRUE;
        addr_2ram   <= (counter == 0) ? addr_from_lsb : addr_2ram + `ONE;
      end
      else begin
        status      <= `LdStSTALL;
        valid_2lsb  <= `TRUE;
        counter     <= `ZERO;
        addr_2ram   <= `ZERO;
        ram_ena     <= `FALSE;
        wr_mc2ram   <= `LOAD_MEM;
      end
    end
    else if (status == `LOAD) begin
      case (counter)
        // cost 1 cycle to get mem
        32'h1 : data_2lsb[7:0]   <= data_from_ram;
        32'h2 : data_2lsb[15:8]  <= data_from_ram;
        32'h3 : data_2lsb[23:16] <= data_from_ram;
        32'h4 : data_2lsb[31:24] <= data_from_ram;
      endcase

      if (counter <= totByte - 1) begin
        counter     <= counter   + `ONE;
        addr_2ram   <= addr_2ram + `ONE;
      end
      else begin
        counter     <= `ZERO;
        addr_2ram   <= `ZERO;

        if (optype_from_lsb == `OPTYPE_LB || optype_from_lsb == `OPTYPE_LH) begin
          status      <= `LOAD_STALL;
          ram_ena     <= `FALSE;
        end
        else begin
          status      <= `LdStSTALL;
          valid_2lsb  <= `TRUE;
          ram_ena     <= `FALSE;
        end
        
      end
    end
    else if (status == `LdStSTALL) begin // STALL
      status        <= `STALL;
      valid_2icache <= `FALSE;
      valid_2lsb    <= `FALSE;
      addr_2ram   <= `ZERO;
    end
    else if (status == `STALL) begin // STALL
      status        <= `NORM;
      valid_2icache <= `FALSE;
      valid_2lsb    <= `FALSE;
      addr_2ram   <= `ZERO;
    end
    else if (status == `LOAD_STALL) begin
      valid_2lsb  <= `TRUE;
      status      <= `LdStSTALL;
      addr_2ram   <= `ZERO;
      if (optype_from_lsb == `OPTYPE_LB) begin
        data_2lsb <= {{25{data_2lsb[7]}}, data_2lsb[6:0]};
      end
      else if(optype_from_lsb == `OPTYPE_LH) begin
        data_2lsb <= {{17{data_2lsb[15]}}, data_2lsb[14:0]};
      end
    end

  end

end
endmodule