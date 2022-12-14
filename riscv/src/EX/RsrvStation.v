`include "const.v"

module ReserveStation (
  input wire clk,
  input wire rst, 
  input wire rdy,

  input wire rollback_signal,

  // port with dispatcher
  output wire rs_full,
  input wire rdy_from_is,
  input wire [`OPCODE_TYPE]    optype_from_is,
  input wire [`DATA_IDX_RANGE] pc_from_is,
  input wire [`REG_RANGE]      rd_alias,
  input wire [`REG_RANGE]      Qi_from_is,
  input wire [`REG_RANGE]      Qj_from_is,
  input wire [`DATA_IDX_RANGE] Vi_from_is,
  input wire [`DATA_IDX_RANGE] Vj_from_is,
  input wire [`DATA_IDX_RANGE] imm_from_is,

  // port with ALU
  output reg [`OPCODE_TYPE] optype_2alu,
  output reg [`ROB_ID_RANGE] rd_2alu,
  output reg [`DATA_IDX_RANGE] pc_2alu,
  output reg [`DATA_IDX_RANGE] Vi_2alu,
  output reg [`DATA_IDX_RANGE] Vj_2alu,
  output reg [`DATA_IDX_RANGE] imm_2alu,

  // RS's cdb result
  input wire alu_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_alu,
  input wire [`DATA_IDX_RANGE] result_from_alu,

  // LSB's cdb result
  input wire lsb_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_lsb,
  input wire [`DATA_IDX_RANGE] result_from_lsb
);

// ==== RS Table ====
reg [`RS_SIZE - 1 : 0] busy;
reg [`OPCODE_TYPE] optype[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] pc[`RS_SIZE - 1 : 0];

reg [`ROB_ID_RANGE]   ID[`RS_SIZE - 1 : 0];
reg [`ROB_ID_RANGE]   Qi[`RS_SIZE - 1 : 0];
reg [`ROB_ID_RANGE]   Qj[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] Vi[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] Vj[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] imm[`RS_SIZE - 1 : 0];
// ==================

wire [`RS_IDX_RANGE] avail_entry;
wire [`RS_IDX_RANGE] ex_entry_idx;

assign rs_full = (avail_entry == `RS_SIZE);

assign avail_entry = (~busy[0] ? 0 : 
                        (~busy[1] ? 1 : 
                          (~busy[2] ? 2 : 
                            (~busy[3] ? 3 : 
                              (~busy[4] ? 4 : 
                                (~busy[5] ? 5 : 
                                  (~busy[6] ? 6 :
                                    (~busy[7] ? 7 : // 8))))))));
                                      (~busy[8] ? 8 :
                                        (~busy[9] ? 9 :
                                          (~busy[10] ? 10 :
                                            (~busy[11] ? 11 :
                                              (~busy[12] ? 12 :
                                                (~busy[13] ? 13 :
                                                  (~busy[14] ? 14 :
                                                    (~busy[15] ? 15 : 16
                                                    ))))))))))))))));


assign ex_entry_idx = ((busy[0] && !Qi[0] && !Qj[0]) ? 0 : 
                        ((busy[1] && !Qi[1] && !Qj[1]) ? 1 :
                          ((busy[2] && !Qi[2] && !Qj[2]) ? 2 :
                            ((busy[3] && !Qi[3] && !Qj[3]) ? 3 :
                              ((busy[4] && !Qi[4] && !Qj[4]) ? 4 :
                                ((busy[5] && !Qi[5] && !Qj[5]) ? 5 :
                                  ((busy[6] && !Qi[6] && !Qj[6]) ? 6 :
                                    ((busy[7] && !Qi[7] && !Qj[7]) ? 7 : // 8))))))));
                                      ((busy[8] && !Qi[8] && !Qj[8]) ? 8 :
                                        ((busy[9] && !Qi[9] && !Qj[9]) ? 9 :
                                          ((busy[10] && !Qi[10] && !Qj[10]) ? 10 :
                                            ((busy[11] && !Qi[11] && !Qj[11]) ? 11 :
                                              ((busy[12] && !Qi[12] && !Qj[12]) ? 12 :
                                                ((busy[13] && !Qi[13] && !Qj[13]) ? 13 :
                                                  ((busy[14] && !Qi[14] && !Qj[14]) ? 14 :
                                                    ((busy[15] && !Qi[15] && !Qj[15]) ? 15 : 16
                                                    ))))))))))))))));
// ==== ISSUE =====
wire [`ROB_ID_RANGE] Qi_2queue, Qj_2queue;
wire [`DATA_IDX_RANGE] Vi_2queue, Vj_2queue;

wire checkQi_from_lsb = (lsb_has_result && alias_from_lsb == Qi_from_is);
wire checkQi_from_alu = (alu_has_result && alias_from_alu == Qi_from_is);

wire checkQj_from_lsb = (lsb_has_result && alias_from_lsb == Qj_from_is);
wire checkQj_from_alu = (alu_has_result && alias_from_alu == Qj_from_is);

assign Qi_2queue = checkQi_from_lsb ? `RENAMED_ZERO : (checkQi_from_alu ? `RENAMED_ZERO : Qi_from_is);
assign Qj_2queue = checkQj_from_lsb ? `RENAMED_ZERO : (checkQj_from_alu ? `RENAMED_ZERO : Qj_from_is);

assign Vi_2queue = checkQi_from_lsb ? result_from_lsb : (checkQi_from_alu ? result_from_alu : Vi_from_is);
assign Vj_2queue = checkQj_from_lsb ? result_from_lsb : (checkQj_from_alu ? result_from_alu : Vj_from_is); 
// ================

integer i;

`ifdef Debug
  integer outfile;
  initial begin
    outfile = $fopen("RS.out");
  end
`endif 

always @(posedge clk) begin
  if (rst || rollback_signal) begin
    optype_2alu <= `NOP;
    rd_2alu     <= `REG_ZERO;
    pc_2alu     <= `ZERO;
    Vi_2alu     <= `ZERO;
    Vj_2alu     <= `ZERO;
    imm_2alu    <= `ZERO;
    for (i = 0; i < `RS_SIZE; i = i + 1) begin
      busy[i]   <= `FALSE;
      optype[i] <= `NOP;
      pc[i]     <= `ZERO;
      
      ID[i]     <= `RENAMED_ZERO;
      Qi[i]     <= `RENAMED_ZERO;
      Qj[i]     <= `RENAMED_ZERO;
      Vi[i]     <= `ZERO;
      Vj[i]     <= `ZERO;
      imm[i]    <= `ZERO;
    end
  end

  else if (~rdy) begin // pause
  end

  else begin

// `ifdef Debug  
//     if (alu_has_result) begin
//       $fdisplay(outfile, "time = %d, alias = %d, result = %x", $time, alias_from_alu, result_from_alu);
//     end
//     for (i = 0; i < `RS_SIZE; i = i + 1) begin
//       if (ID[i] == 8 && busy[i]) begin
//         $fdisplay(outfile, "time = %d, Qi = %d, Qj = %d, Vi = %d, Vj = %d\n", $time, Qi[i], Qj[i], Vi[i], Vj[i]);
//       end
//     end
// `endif
    if (rdy_from_is && !rs_full) begin // can add instruction into RS
      busy[avail_entry]  <= `TRUE;

      ID[avail_entry]    <= rd_alias;

      optype[avail_entry]<= optype_from_is;
      pc[avail_entry]    <= pc_from_is;

      Qi[avail_entry]    <= Qi_2queue;
      Qj[avail_entry]    <= Qj_2queue;
      Vi[avail_entry]    <= Vi_2queue;
      Vj[avail_entry]    <= Vj_2queue;
      imm[avail_entry]   <= imm_from_is;
    end

    if (ex_entry_idx != `RS_SIZE) begin // one instruction able to be sent to alu
      busy[ex_entry_idx]  <= `FALSE;

`ifdef Debug
  if (optype[ex_entry_idx] == `OPTYPE_BEQ) begin
    $fdisplay(outfile, "time = %d, pc = %x, rs1 = %x, rs2 = %x, imm = %x", $time, pc[ex_entry_idx], Vi[ex_entry_idx], Vj[ex_entry_idx], imm[ex_entry_idx]);
  end
`endif

      rd_2alu             <= ID[ex_entry_idx];
      optype_2alu         <= optype[ex_entry_idx];
      pc_2alu             <= pc[ex_entry_idx];
      Vi_2alu             <= Vi[ex_entry_idx];
      Vj_2alu             <= Vj[ex_entry_idx];
      imm_2alu            <= imm[ex_entry_idx];
    end
    else begin
      optype_2alu         <= `NOP;      // no excutable instruction
    end

    // update RS 
    if (alu_has_result) begin
      for (i = 0; i < `RS_SIZE; i = i + 1) begin
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

    if (lsb_has_result) begin
      for (i = 0; i < `RS_SIZE; i = i + 1) begin
        if (Qi[i] == alias_from_lsb) begin
          Qi[i]   <= `RENAMED_ZERO;
          Vi[i]   <= result_from_lsb;
        end
        if (Qj[i] == alias_from_lsb) begin
          Qj[i]   <= `RENAMED_ZERO;
          Vj[i]   <= result_from_lsb;
        end
      end
    end
    
  end

end
endmodule