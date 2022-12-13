`include "const.v"

module Dispatcher (
  input wire clk,
  input wire rst,
  input wire rdy,

  input wire rollback_signal,

  input wire is_full,

  // port with InsFetcher
  input  wire valid_from_fet,
  input  wire if_jump_from_fet,
  input  wire [`DATA_IDX_RANGE] pc_from_fet,
  input  wire [`DATA_IDX_RANGE] instr_from_fet,

  // from ROB
  // input  wire rob_full,
  input  wire [`ROB_ID_RANGE] id_from_rob, // alias of current instruction
    /* insert instruction in rob */
  output reg  instr_rdy_2rob,
  output reg  [`DATA_IDX_RANGE] pc_2rob,
  output reg [`REG_RANGE]    instr_tar_rd,
  output reg is_jump_2rob,
  output reg jumpRecord_2rob,
  output reg [`OPCODE_TYPE] optype_2rob,

  output wire [`ROB_ID_RANGE] Qi_2rob, 
  output wire [`ROB_ID_RANGE] Qj_2rob,
  input  wire rob_Qi_rdy,   // rs1's state
  input  wire rob_Qj_rdy,   // rs2's state
  input  wire [`DATA_IDX_RANGE] Vi_from_rob,
  input  wire [`DATA_IDX_RANGE] Vj_from_rob,

  // port with register
  output reg  ena_regfile_rename,
  output reg  [`REG_RANGE]      rd_2reg,
  output reg  [`ROB_ID_RANGE]   rd_alias,

  output wire [`REG_RANGE]      rs1_2reg,
  output wire [`REG_RANGE]      rs2_2reg,
  input  wire [`ROB_ID_RANGE]   Qi_from_rg,
  input  wire [`ROB_ID_RANGE]   Qj_from_rg,
  input  wire [`DATA_IDX_RANGE] Vi_from_rg,
  input  wire [`DATA_IDX_RANGE] Vj_from_rg,

  // port with RS
  // input wire rs_full,
  output reg ena_rs,
  output reg [`ROB_ID_RANGE]   rd_alias_2rs,
  output reg [`OPCODE_TYPE]    optype_2rs,
  output reg [`DATA_IDX_RANGE] pc_2rs,
  output reg [`ROB_ID_RANGE]   Qi_2rs,
  output reg [`ROB_ID_RANGE]   Qj_2rs,
  output reg [`DATA_IDX_RANGE] Vi_2rs,
  output reg [`DATA_IDX_RANGE] Vj_2rs,
  output reg [`DATA_IDX_RANGE] imm_2rs,

  // port with LSB
  // input wire lsb_full,
  output reg ena_lsb,
  output reg [`ROB_ID_RANGE]   rd_alias_2lsb,
  output reg [`OPCODE_TYPE]    optype_2lsb,
  output reg [`DATA_IDX_RANGE] pc_2lsb,
  output reg [`ROB_ID_RANGE]   Qi_2lsb,
  output reg [`ROB_ID_RANGE]   Qj_2lsb,
  output reg [`DATA_IDX_RANGE] Vi_2lsb,
  output reg [`DATA_IDX_RANGE] Vj_2lsb,
  output reg [`DATA_IDX_RANGE] imm_2lsb,

  // RS's cdb result
  input wire alu_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_alu,
  input wire [`DATA_IDX_RANGE] result_from_alu,

  // LSB's cdb result
  input wire lsb_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_lsb,
  input wire [`DATA_IDX_RANGE] result_from_lsb
);

wire is_ls, is_jump;
wire [`OPCODE_TYPE] optype;
wire [`REG_RANGE] rd, rs1, rs2; // TODO: send rd to whom?
wire [`DATA_IDX_RANGE] imm;

assign rs1_2reg = rs1;
assign rs2_2reg = rs2;

assign Qi_2rob  = Qi_from_rg;
assign Qj_2rob  = Qj_from_rg;


// ==== ISSUE =====

// check register File & ROB (not commited instuction)
wire [`ROB_ID_RANGE]   Qi_tmp = rob_Qi_rdy ? `RENAMED_ZERO : Qi_from_rg;
wire [`ROB_ID_RANGE]   Qj_tmp = rob_Qj_rdy ? `RENAMED_ZERO : Qj_from_rg;
wire [`DATA_IDX_RANGE] Vi_tmp = rob_Qi_rdy ? Vi_from_rob : Vi_from_rg;
wire [`DATA_IDX_RANGE] Vj_tmp = rob_Qj_rdy ? Vj_from_rob : Vj_from_rg;

wire checkQi_from_lsb = (lsb_has_result && alias_from_lsb == Qi_tmp);
wire checkQi_from_alu = (alu_has_result && alias_from_alu == Qi_tmp);

wire checkQj_from_lsb = (lsb_has_result && alias_from_lsb == Qj_tmp);
wire checkQj_from_alu = (alu_has_result && alias_from_alu == Qj_tmp);

wire [`ROB_ID_RANGE] Qi = checkQi_from_lsb ? `RENAMED_ZERO : (checkQi_from_alu ? `RENAMED_ZERO : Qi_tmp);
wire [`ROB_ID_RANGE] Qj = checkQj_from_lsb ? `RENAMED_ZERO : (checkQj_from_alu ? `RENAMED_ZERO : Qj_tmp);

wire [`DATA_IDX_RANGE] Vi = checkQi_from_lsb ? result_from_lsb : (checkQi_from_alu ? result_from_alu : Vi_tmp);
wire [`DATA_IDX_RANGE] Vj = checkQj_from_lsb ? result_from_lsb : (checkQj_from_alu ? result_from_alu : Vj_tmp); 
// ================

Decoder decoder (
  .instr(instr_from_fet),

  .is_ls(is_ls),
  .is_jump(is_jump),
  .optype(optype),
  .rd(rd),
  .rs1(rs1),
  .rs2(rs2),
  .imm(imm)
);

`ifdef Debug
  integer outfile;
  initial begin
    outfile = $fopen("dsp.out");
  end
`endif 

always @(posedge clk) begin
  if (rst || rollback_signal) begin
    ena_lsb <= `FALSE;
    ena_rs  <= `FALSE;
    ena_regfile_rename  <= `FALSE;
    instr_rdy_2rob      <= `FALSE;
  end

  else if(~rdy) begin // pause
  end

  else if (valid_from_fet && ~is_full) begin
    // rename register file
    

    ena_regfile_rename  <= `TRUE;
    rd_2reg         <= rd;
    rd_alias        <= id_from_rob;

    // update rob
    instr_rdy_2rob  <= `TRUE;
    pc_2rob         <= pc_from_fet; 
    instr_tar_rd    <= rd;
    is_jump_2rob    <= is_jump;
    jumpRecord_2rob <= if_jump_from_fet;
    optype_2rob     <= optype;

    if (is_ls) begin // to LoadStoreBuffer
      ena_lsb   <= `TRUE;
      ena_rs    <= `FALSE;
`ifdef Debug
    $fdisplay(outfile, "time = %d, pc = %x, instruction = %x", $time, pc_from_fet, instr_from_fet);
    $fdisplay(outfile, "instr = %x, optype = %d, alu: %d, lsb: %d, Qi = %d, Qj = %d, Vi = %d, Vj = %d\n", instr_from_fet, optype, alu_has_result, lsb_has_result, Qi, Qj, Vi, Vj);
`endif
      optype_2lsb   <= optype;
      rd_alias_2lsb <= id_from_rob;
      pc_2lsb   <= pc_from_fet;
      Qi_2lsb   <= Qi;
      Qj_2lsb   <= Qj;
      Vi_2lsb   <= Vi;
      Vj_2lsb   <= Vj;
      imm_2lsb  <= imm;
    end

    else begin  // to Reservation Station
      ena_rs  <= `TRUE;
      ena_lsb <= `FALSE;

      optype_2rs    <= optype;
      rd_alias_2rs  <= id_from_rob;
      pc_2rs  <= pc_from_fet;
      Qi_2rs  <= Qi;
      Qj_2rs  <= Qj;
      Vi_2rs  <= Vi;
      Vj_2rs  <= Vj;
      imm_2rs <= imm;
    end  
  end 

  else begin
    ena_lsb <= `FALSE;
    ena_rs  <= `FALSE;
    ena_regfile_rename  <= `FALSE;
    instr_rdy_2rob      <= `FALSE;
  end

end

endmodule