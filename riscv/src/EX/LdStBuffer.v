`include "const.v"

`define NORM    3'b000
`define LOADING 3'b001
`define WRITING 3'b010
`define UPDATE  3'b111

module LoadStoreBuffer 
# (
  parameter ADDR_BITS = 4
) (
  input wire clk,
  input wire rst,
  input wire rdy,   

  // port with ROB
  input wire prepared_to_commit,

  // port with dispatcher
  output wire lsb_full,

  input wire rdy_from_is,
  input wire [`OPCODE_TYPE]   optype_from_is,
  input wire [`ROB_ID_RANGE]   rd_alias_from_is,
  input wire [`ROB_ID_RANGE]   Qi_from_is,
  input wire [`ROB_ID_RANGE]   Qj_from_is,
  input wire [`DATA_IDX_RANGE] Vi_from_is,
  input wire [`DATA_IDX_RANGE] Vj_from_is,
  input wire [`DATA_IDX_RANGE] imm_from_is,

  // port with memory controller
  output reg ena_mc,
  output reg wr_2mc,
  output reg [`DATA_IDX_RANGE] addr_2mc,
  output reg [`MEM_IDX_RANGE] data_2mc,
  input wire rdy_from_mc,
  input wire [`MEM_IDX_RANGE] data_from_mc,

  // RS's cdb result
  input wire alu_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_alu,
  input wire [`DATA_IDX_RANGE] result_from_alu,

  // LSB's cdb result
  output reg lsb_has_result,
  output reg [`ROB_ID_RANGE]   alias_from_lsb,
  output wire [`DATA_IDX_RANGE] result_from_lsb,

  input wire rollback_signal
);

reg [2:0] status;
reg [`DATA_IDX_RANGE] counter, totByte;
reg [`DATA_IDX_RANGE] data_acquired, data_written;
reg [`OPCODE_TYPE] dealing_optype;

// ===== FIFO =====
reg [ADDR_BITS - 1 : 0] head, tail;
reg [`OPCODE_TYPE]    optype[2**ADDR_BITS - 1 : 0];
reg [`ROB_ID_RANGE]   ID[2**ADDR_BITS - 1 : 0];
reg [`ROB_ID_RANGE]   Qi[2**ADDR_BITS - 1 : 0];
reg [`ROB_ID_RANGE]   Qj[2**ADDR_BITS - 1 : 0];
reg [`DATA_IDX_RANGE] Vi[2**ADDR_BITS - 1 : 0];
reg [`DATA_IDX_RANGE] Vj[2**ADDR_BITS - 1 : 0];
reg [`DATA_IDX_RANGE] immediate[2**ADDR_BITS - 1 : 0];

wire [ADDR_BITS - 1 : 0] next_head = (head == 2 ** ADDR_BITS - 1) ? 0 : head + 1;
wire [ADDR_BITS - 1 : 0] next_tail = (tail == 2 ** ADDR_BITS - 1) ? 0 : tail + 1;
// ================

wire check = (optype[head] >= `OPTYPE_SB && optype[head] <= `OPTYPE_SW) ? prepared_to_commit : `TRUE;
wire ready = (head != tail) && (!Qi[head] && !Qj[head] && check);

wire [`DATA_IDX_RANGE] rs1, rs2, imm;
assign rs1 = Vi[head];
assign rs2 = Vj[head];
assign imm = immediate[head];

assign lsb_full = (next_tail == head); // whether is full
assign result_from_lsb = data_acquired;

integer i;

always @(posedge clk) begin
  if (rst || rollback_signal) begin
    status     <= `NORM;
    ena_mc     <= `FALSE;
    head       <= 0;
    tail       <= 0;
    counter    <= `ZERO;
    totByte    <= `ZERO;
    lsb_has_result <= `FALSE;
  end

  else if (~rdy) begin // pause
  end

  else begin

    if (rdy_from_is && !lsb_full) begin // ??? is_full?
      optype[tail]  <= optype_from_is;
      ID[tail]      <= rd_alias_from_is;
      Qi[tail]      <= Qi_from_is;
      Qj[tail]      <= Qj_from_is;
      Vi[tail]      <= Vi_from_is;
      Vj[tail]      <= Vj_from_is;
      immediate[tail] <= imm_from_is;
      tail          <= next_tail;
    end

    if (status == `NORM) begin
      if (ready) begin     
        ena_mc          <= `TRUE;
        lsb_has_result  <= `FALSE;
        alias_from_lsb  <= ID[head];
        data_acquired   <= `ZERO;
        dealing_optype  <= optype[head];
        counter         <= `ZERO;
        head            <= next_head;        

        addr_2mc        <= rs1 + imm;
        data_written    <= rs2;

        case (optype[head]) 
          `OPTYPE_LB, `OPTYPE_LBU: begin
            status    <= `LOADING;
            wr_2mc    <= `LOAD_MEM;
            totByte   <= 1;
          end
          `OPTYPE_LH, `OPTYPE_LHU: begin
            status    <= `LOADING;
            wr_2mc    <= `LOAD_MEM;
            totByte   <= 2;
          end

          `OPTYPE_LW: begin
            status    <= `LOADING;
            wr_2mc    <= `LOAD_MEM;
            totByte   <= 4;
          end

          // Write Through Strategy.
          `OPTYPE_SB: begin
            status    <= `WRITING;
            wr_2mc    <= `WRITE_MEM;
            totByte   <= 1;
          end

          `OPTYPE_SH: begin
            status    <= `WRITING;
            wr_2mc    <= `WRITE_MEM;
            totByte   <= 2;
          end

          `OPTYPE_SW: begin
            status    <= `WRITING;
            wr_2mc    <= `WRITE_MEM;
            totByte   <= 4;
          end
        endcase
      end

    end

    else if (status == `LOADING) begin
      if (rdy_from_mc) begin
        case (counter)
          32'h0: data_acquired[7:0]   <= data_from_mc;
          32'h1: data_acquired[15:8]  <= data_from_mc;
          32'h2: data_acquired[23:16] <= data_from_mc;
          32'h3: data_acquired[31:24] <= data_from_mc;
        endcase

        counter <= counter + 1;

        if (counter == totByte - 1) begin
          lsb_has_result<= `TRUE;
          status        <= `UPDATE; /// ??? norm 状态下 但是不ready就会一直有has result; 但好像没差别..data_acquierd一直是正确的ld
          ena_mc        <= `FALSE;
          totByte       <= `ZERO;
          counter       <= `ZERO;

          if (dealing_optype == `OPTYPE_LB) begin
            data_acquired <= {{25{data_acquired[7]}}, data_acquired[6:0]};
          end
          else if (dealing_optype == `OPTYPE_LH) begin
            data_acquired <= {{17{data_acquired[15]}}, data_acquired[14:0]};
          end
        
        end
      end
    end

    else if (status == `WRITING) begin
      case (counter)
        32'h0: data_2mc   <= data_written[7:0];
        32'h1: data_2mc   <= data_written[15:8];
        32'h2: data_2mc   <= data_written[23:16];
        32'h3: data_2mc   <= data_written[31:24];
      endcase

      counter <= counter + 1;

      if (counter == totByte - 1) begin
        status        <= `NORM; 
        ena_mc        <= `FALSE;
        totByte       <= `ZERO;
        counter       <= `ZERO;
      end
    end
      
    else if (status == `UPDATE) begin
      // use the result update LSB
      status  <= `NORM;
      for (i = 0; i < (2**ADDR_BITS); i = i + 1) begin // ??? 感觉这里会更新一些空的entry
        if (Qi[i] == alias_from_lsb) begin
          Qi[i]   <= `RENAMED_ZERO;
          Vi[i]   <= data_acquired;
        end
        if (Qj[i] == alias_from_lsb) begin
          Qj[i]   <= `RENAMED_ZERO;
          Vj[i]   <= data_acquired;
        end
      end
    end

    // use ALU's result to update RS

    if (alu_has_result) begin
      for (i = 0; i < (2 ** ADDR_BITS); i = i + 1) begin // ??? 感觉这里会更新一些空的entry
        if (Qi[i] == alias_from_alu) begin
          Qi[i]   <= `RENAMED_ZERO;
          Vi[i]   <= result_from_alu;
        end
        if (Qj[i] == alias_from_alu) begin
          Qj[i]   <= `RENAMED_ZERO;
          Vj[i]   <= result_from_alu;
        end
      end
    end

  end

end

endmodule