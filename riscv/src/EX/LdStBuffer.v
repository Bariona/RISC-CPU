`include "const.v"

`define NORM    3'b000
`define WORKING 3'b001

module LoadStoreBuffer 
# (
  parameter ADDR_BITS = 4
) (
  input wire clk,
  input wire rst,
  input wire rdy,   

  // port with ROB
  input wire ready_to_commit,

  // port with dispatcher
  output wire lsb_full,
  input wire rdy_from_is,
  input wire [`OPCODE_TYPE]    optype_from_is,
  input wire [`REG_RANGE]      Qi_from_is,
  input wire [`REG_RANGE]      Qj_from_is,
  input wire [`DATA_IDX_RANGE] Vi_from_is,
  input wire [`DATA_IDX_RANGE] Vj_from_is,
  input wire [`DATA_IDX_RANGE] imm_from_is,

  // port with dcache
  output reg ena_dcache,
  output reg [`DATA_IDX_RANGE] addr_2dcache,
  input wire rdy_from_dcache,
  input wire [`MEM_IDX_RANGE] data_from_dcache,

  // port with CDB
  output reg rdy_from_lsb,
  output reg [`DATA_IDX_RANGE] data_acquired
);

reg [2:0] status;
reg [`DATA_IDX_RANGE] counter, totByte;
reg [`OPCODE_TYPE] dealOpt;

// ===== FIFO =====
reg [ADDR_BITS - 1 : 0] head, tail;
reg [`OPCODE_TYPE]    optype[2**ADDR_BITS - 1 : 0];
reg [`REG_RANGE]      Qi[2**ADDR_BITS - 1 : 0];
reg [`REG_RANGE]      Qj[2**ADDR_BITS - 1 : 0];
reg [`DATA_IDX_RANGE] Vi[2**ADDR_BITS - 1 : 0];
reg [`DATA_IDX_RANGE] Vj[2**ADDR_BITS - 1 : 0];
reg [`DATA_IDX_RANGE] immediate[2**ADDR_BITS - 1 : 0];

wire [ADDR_BITS - 1 : 0] next_head = (head == 2 ** ADDR_BITS - 1) ? 0 : head + 1;
wire [ADDR_BITS - 1 : 0] next_tail = (tail == 2 ** ADDR_BITS - 1) ? 0 : tail + 1;
// ================

wire check = (optype[head] >= `OPTYPE_SB && optype[head] <= `OPTYPE_SW) ? ready_to_commit : `TRUE;
wire ready = (head != tail) && (!Qi[head] && !Qj[head] && check);

wire [`DATA_IDX_RANGE] rs1, rs2, imm;
assign rs1 = Vi[head];
assign rs2 = Vj[head];
assign imm = immediate[head];

assign lsb_full = (next_tail == head); // whether is full

always @(posedge clk) begin
  if (rst) begin
    status     <= `NORM;
    ena_dcache <= `FALSE;
    head       <= 0;
    tail       <= 0;
    counter    <= `ZERO;
    totByte    <= `ZERO;
    rdy_from_lsb <= `FALSE;
  end

  else if (~rdy) begin // pause
  end

  else begin
    if (rdy_from_is && !lsb_full) begin // ??? is_full?
      optype[tail]  <= optype_from_is;
      Qi[tail]      <= Qi_from_is;
      Qj[tail]      <= Qj_from_is;
      Vi[tail]      <= Vi_from_is;
      Vj[tail]      <= Vj_from_is;
      immediate[tail] <= imm_from_is;
      tail          <= next_tail;
    end

    if (status == `NORM) begin
      if (ready) begin
        status  <= `WORKING;
        dealOpt <= optype[head];
        counter <= `ZERO;
        head    <= next_head;


        case (optype[head]) 
          `OPTYPE_LB, `OPTYPE_LBU: begin
            ena_dcache    <= `TRUE;
            addr_2dcache  <= rs1 + imm;
            totByte       <= 1;
          end
          `OPTYPE_LH, `OPTYPE_LHU: begin
            ena_dcache    <= `TRUE;
            addr_2dcache  <= rs1 + imm;
            totByte       <= 2;
          end

          `OPTYPE_LW: begin
            ena_dcache    <= `TRUE;
            addr_2dcache  <= rs1 + imm;
            totByte       <= 4;
          end

          // Write Through Strategy.
          `OPTYPE_SB: begin

          end

          `OPTYPE_SH: begin
          end

          `OPTYPE_SW: begin
          end
        endcase
      end
    end
    else if (status == `WORKING) begin
      if (rdy_from_dcache) begin
        case (counter)
          32'h0: data_acquired[7:0]   <= data_from_dcache;
          32'h1: data_acquired[15:8]  <= data_from_dcache;
          32'h2: data_acquired[23:16] <= data_from_dcache;
          32'h3: data_acquired[31:24] <= data_from_dcache;
        endcase

        counter <= counter + 1;
        if (counter == totByte - 1) begin
          status  <= `NORM;
          counter <= `ZERO;
          rdy_from_lsb <= `TRUE;
        end

      end
    end

  end

end

endmodule