`include "const.v"

`define NORM    3'b000
`define LOADING 3'b001
`define STORING 3'b010
`define RBACK   3'b111
// `define UPDATE  3'b111

module LoadStoreBuffer 
#(
  parameter ADDR_BITS = 4
) (
  input wire clk,
  input wire rst,
  input wire rdy,   

  // port with ROB
  input wire prepared_to_commit,
  input wire [`ROB_ID_RANGE] store_commit_alias,

  // port with dispatcher
  output wire lsb_full,

  input wire rdy_from_is,
  input wire [`DATA_IDX_RANGE] pc_from_dsp,
  input wire [`OPCODE_TYPE]    optype_from_is,
  input wire [`ROB_ID_RANGE]   rd_alias_from_is,
  input wire [`ROB_ID_RANGE]   Qi_from_is,
  input wire [`ROB_ID_RANGE]   Qj_from_is,
  input wire [`DATA_IDX_RANGE] Vi_from_is,
  input wire [`DATA_IDX_RANGE] Vj_from_is,
  input wire [`DATA_IDX_RANGE] imm_from_is,

  // port with memory controller
  output reg ena_mc,
  output reg wr_2mc,
  output reg [`OPCODE_TYPE]    optype_2mc,
  output reg [`DATA_IDX_RANGE] addr_2mc,
  output reg [`DATA_IDX_RANGE] data_2mc,
  output reg [2:0]             totByte,
  input wire rdy_from_mc,
  input wire [`DATA_IDX_RANGE] data_from_mc,

  // RS's cdb result
  input wire alu_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_alu,
  input wire [`DATA_IDX_RANGE] result_from_alu,

  // LSB's cdb result
  output reg lsb_has_result,
  output reg  [`ROB_ID_RANGE]   alias_from_lsb,
  output reg [`DATA_IDX_RANGE] result_from_lsb,

  input wire rollback_signal
);

reg [2:0] status;

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

// ==== ISSUE =====
wire [`ROB_ID_RANGE] Qi_2queue, Qj_2queue;
wire [`DATA_IDX_RANGE] Vi_2queue, Vj_2queue;

wire checkQi_from_lsb = (rdy_from_mc && status != `RBACK && alias_from_lsb == Qi_from_is);
wire checkQi_from_alu = (alu_has_result && alias_from_alu == Qi_from_is);

wire checkQj_from_lsb = (rdy_from_mc && status != `RBACK && alias_from_lsb == Qj_from_is);
wire checkQj_from_alu = (alu_has_result && alias_from_alu == Qj_from_is);

assign Qi_2queue = checkQi_from_lsb ? `RENAMED_ZERO : (checkQi_from_alu ? `RENAMED_ZERO : Qi_from_is);
assign Qj_2queue = checkQj_from_lsb ? `RENAMED_ZERO : (checkQj_from_alu ? `RENAMED_ZERO : Qj_from_is);

assign Vi_2queue = checkQi_from_lsb ? data_from_mc : (checkQi_from_alu ? result_from_alu : Vi_from_is);
assign Vj_2queue = checkQj_from_lsb ? data_from_mc : (checkQj_from_alu ? result_from_alu : Vj_from_is); 

// ================

// ==== EX part ====
wire check = (optype[head] >= `OPTYPE_SB && optype[head] <= `OPTYPE_SW) ? (prepared_to_commit && ID[head] == store_commit_alias) : `TRUE;
wire ready = (head != tail) && (!Qi[head] && !Qj[head] && check);

wire [`DATA_IDX_RANGE] rs1, rs2, imm;
assign rs1 = Vi[head];
assign rs2 = Vj[head];
assign imm = immediate[head];
// =================

assign lsb_full = (next_tail == head); // whether is full

integer i;

`ifdef Debug
  integer outfile;
  initial begin
    outfile = $fopen("lsb.out");
  end
`endif 

always @(posedge clk) begin
  if (rst) begin
    status     <= `NORM;
    ena_mc     <= `FALSE;
    head       <= 0;
    tail       <= 0;
    totByte    <= `ZERO;
    lsb_has_result <= `FALSE;
  end

  else if (~rdy) begin // pause
  end
  else if (rollback_signal) begin
    status  <= (status == `LOADING) ? `RBACK : `NORM;
    head    <= 0;
    tail    <= 0;
  end

  else begin
// `ifdef Debug
//       $fdisplay(outfile, "time = %d, LSB's status = %d\nhead = %d, tail = %d\nQi = %d, Qj = %d\n", $time, status, head, tail, Qi[head], Qj[head]);
// `endif
    if (rdy_from_is) begin // TODO: is_full?

// `ifdef Debug
//       $fdisplay(outfile, "time = %d, pc = %x, add instrution (%d)\nhead = %d, optype = %d\nVi = %x, Vj = %x, Qi = %d, Qj = %d\n", 
//                         $time, pc_from_dsp, tail, head, optype_from_is, Vi_from_is, Vj_2queue, Qi_2queue, Qj_2queue);
// `endif
      tail          <= next_tail;

      optype[tail]  <= optype_from_is;
      ID[tail]      <= rd_alias_from_is;
      Qi[tail]      <= Qi_2queue;
      Qj[tail]      <= Qj_2queue;
      Vi[tail]      <= Vi_2queue;
      Vj[tail]      <= Vj_2queue;
      immediate[tail] <= imm_from_is;
    end

     // use ALU's result to update RS
    if (alu_has_result) begin
// `ifdef Debug
//       $fdisplay(outfile, "time = %d, ALU's alias = %d\n", $time, alias_from_alu);
// `endif
      for (i = 0; i < (2 ** ADDR_BITS); i = i + 1) begin
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

    if (status == `NORM) begin
      
      lsb_has_result  <= `FALSE;

      if (ready) begin     
        head            <= next_head;
        alias_from_lsb  <= ID[head];
        
        ena_mc          <= `TRUE;
        optype_2mc      <= optype[head];
        addr_2mc        <= rs1 + imm;
`ifdef Debug
      $fdisplay(outfile, "time = %d, optype = %d, address = %x, data = %d\n", $time, optype[head], rs1 + imm, rs2);
`endif

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
            status    <= `STORING;
            wr_2mc    <= `STORE_MEM;
            data_2mc  <= rs2;
            totByte   <= 1;
          end

          `OPTYPE_SH: begin
            status    <= `STORING;
            wr_2mc    <= `STORE_MEM;
            data_2mc  <= rs2;
            totByte   <= 2;
          end

          `OPTYPE_SW: begin
            status    <= `STORING;
            wr_2mc    <= `STORE_MEM;
            data_2mc  <= rs2;
            totByte   <= 4;
          end
        endcase
      end
      else begin
        ena_mc     <= `FALSE;
        optype_2mc <= `NOP;
      end
    end

    else if (status == `LOADING) begin
      if (rdy_from_mc) begin
        ena_mc  <= `FALSE;
        status  <= `NORM;
        totByte <= 0;
        lsb_has_result  <= `TRUE;
        result_from_lsb <= data_from_mc;
        
        for (i = 0; i < (2**ADDR_BITS); i = i + 1) begin
          if (Qi[i] == alias_from_lsb) begin
            Qi[i]   <= `RENAMED_ZERO;
            Vi[i]   <= data_from_mc;
          end
          if (Qj[i] == alias_from_lsb) begin
            Qj[i]   <= `RENAMED_ZERO;
            Vj[i]   <= data_from_mc;
          end
        end
// `ifdef Debug
//       if (counter > 0) begin
//           $fdisplay(outfile, "time = %d, load || address = %x, data acquired : %x\n", $time, addr_2mc, data_from_mc);
//       end
// `endif
      end
    end

    else if (status == `STORING) begin
      if (rdy_from_mc) begin
        ena_mc  <= `FALSE;
        wr_2mc  <= `FALSE;
        status  <= `NORM;

        totByte <= 0;
        lsb_has_result  <= `TRUE;
        result_from_lsb <= `ZERO;
// `ifdef Debug
//         if (counter == 0)
//           $fdisplay(outfile, "time = %d, store || address = %x, data acquired : %x\n", $time, addr_2mc + 1, data_written[15:8]);
//         if (counter == 1)
//           $fdisplay(outfile, "time = %d, store || address = %x, data acquired : %x\n", $time, addr_2mc + 1, data_written[23:16]);
//         if (counter == 2)
//           $fdisplay(outfile, "time = %d, store || address = %x, data acquired : %x\n", $time, addr_2mc + 1, data_written[31:24]);
// `endif

      end
    end
    else if (status == `RBACK) begin
      if (rdy_from_mc) begin
        status          <= `NORM;
        ena_mc          <= `FALSE;
        lsb_has_result  <= `FALSE;
        totByte         <= 0;
      end
    end
  end

end

endmodule