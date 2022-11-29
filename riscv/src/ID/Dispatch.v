`include "const.v"

module Dispatcher (
  input wire clk,
  input wire rst,
  input wire rdy,

  // port with InsFetcher
  
  // output wire is_full,
  input  wire valid_from_fet,
  input  wire [`DATA_IDX_RANGE] pc,
  input  wire [`DATA_IDX_RANGE] instr_from_fet,

  // from ROB
  output wire [`REG_RANGE] Qi_2rob,
  output wire [`REG_RANGE] Qj_2rob,
  input  wire [`ROB_ID_RANGE] id_from_rob,
  input  wire rob_Qi_rdy,
  input  wire rob_Qj_rdy,
  input  wire [`DATA_IDX_RANGE] Vi_from_rob,
  input  wire [`DATA_IDX_RANGE] Vj_from_rob,

  // port with register
  output wire [`REG_RANGE]      rs1_2reg,
  output wire [`REG_RANGE]      rs2_2reg,
  input  wire [`REG_RANGE]      Qi_from_rg,
  input  wire [`REG_RANGE]      Qj_from_rg,
  input  wire [`DATA_IDX_RANGE] Vi_from_rg,
  input  wire [`DATA_IDX_RANGE] Vj_from_rg,

  // port with RS
  input wire rs_full,
  output reg ena_rs,
  output reg [`OPCODE_TYPE]    optype_2rs,
  output reg [`DATA_IDX_RANGE] pc_2rs,
  output reg [`REG_RANGE]      Qi_2rs,
  output reg [`REG_RANGE]      Qj_2rs,
  output reg [`DATA_IDX_RANGE] Vi_2rs,
  output reg [`DATA_IDX_RANGE] Vj_2rs,
  output reg [`DATA_IDX_RANGE] imm_2rs,

  // port with LSB
  input wire lsb_full,
  output reg ena_lsb,
  output reg [`OPCODE_TYPE]    optype_2lsb,
  output reg [`REG_RANGE]      Qi_2lsb,
  output reg [`REG_RANGE]      Qj_2lsb,
  output reg [`DATA_IDX_RANGE] Vi_2lsb,
  output reg [`DATA_IDX_RANGE] Vj_2lsb,
  output reg [`DATA_IDX_RANGE] imm_2lsb
);

// ??? renaming part

wire is_ls, is_jump;
wire [`OPCODE_TYPE] optype;
wire [`REG_RANGE] rd, rs1, rs2; // ??? send rd to whom?
wire [`DATA_IDX_RANGE] imm;

assign rs1_2reg = rs1;
assign rs2_2reg = rs2;

assign Qi_2rob  = Qi_from_rg;
assign Qj_2rob  = Qj_from_rg;

wire [`REG_RANGE]      Qi_tmp = (!Qi_from_rg) ? `REG_ZERO : (rob_Qi_rdy ? `REG_ZERO : Qi_from_rg);
wire [`REG_RANGE]      Qj_tmp = (!Qj_from_rg) ? `REG_ZERO : (rob_Qj_rdy ? `REG_ZERO : Qj_from_rg);
wire [`DATA_IDX_RANGE] Vi_tmp = (!Qi_from_rg) ? Vi_from_rg : (rob_Qi_rdy ? Vi_from_rob : `ZERO);
wire [`DATA_IDX_RANGE] Vj_tmp = (!Qj_from_rg) ? Vj_from_rg : (rob_Qj_rdy ? Vj_from_rob : `ZERO);

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

always @(posedge clk) begin
  if (rst) begin
    ena_lsb   <= `FALSE;
    ena_rs    <= `FALSE;

    
  end

  else if(~rdy) begin // pause
  end

  else begin
    
    if (optype >= `OPTYPE_LB && optype <= `OPTYPE_SW) begin // to LoadStoreBuffer
      ena_lsb   <= `TRUE;
      ena_rs    <= `FALSE;

      optype_2lsb <= optype;

      Qi_2lsb   <= Qi_tmp;
      Qj_2lsb   <= Qj_tmp;
      Vi_2lsb   <= Vi_tmp;
      Vj_2lsb   <= Vj_tmp;
      imm_2lsb  <= imm;
    end

    else begin  // to Reservation Station
      ena_rs  <= `TRUE;
      ena_lsb <= `FALSE;

      optype_2rs <= optype;

      pc_2rs  <= pc;
      Qi_2rs  <= Qi_tmp;
      Qj_2rs  <= Qj_tmp;
      Vi_2rs  <= Vi_tmp;
      Vj_2rs  <= Vj_tmp;
      imm_2rs <= imm;
    end
    
  end

end

endmodule