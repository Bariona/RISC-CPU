`include "const.v"

module RegsiterFile (
  input wire clk,
  input wire rst,
  input wire rdy,

  input  wire rollback_signal,

  // part with dispatcher
  input  wire [`REG_RANGE] rs1_from_dsp,
  input  wire [`REG_RANGE] rs2_from_dsp,

  output wire [`ROB_ID_RANGE]   Qi_2dsp,
  output wire [`ROB_ID_RANGE]   Qj_2dsp,
  output wire [`DATA_IDX_RANGE] Vi_2dsp,
  output wire [`DATA_IDX_RANGE] Vj_2dsp,

    /* dispatcher rename rd */
  input wire ena_reg_rename,
  input wire [`REG_RANGE] target_reg,
  input wire [`ROB_ID_RANGE] targetReg_alias,

  // port with ROB
  input wire rob_has_res,
  input wire [`DATA_IDX_RANGE] result_from_rob,
  input wire [`REG_RANGE] regidx_from_rob,
  input wire [`ROB_ID_RANGE] regalias_from_rob

);

reg [`DATA_IDX_RANGE]   register[`REG_SIZE - 1 : 0];
reg [`ROB_ID_RANGE]     regAlias[`REG_SIZE - 1 : 0];

assign check_rs1 = (rob_has_res && regidx_from_rob == rs1_from_dsp && regAlias[rs1_from_dsp] == regalias_from_rob);
assign Qi_2dsp = check_rs1 ? `REG_ZERO : regAlias[rs1_from_dsp];
assign Vi_2dsp = check_rs1 ? result_from_rob : register[rs1_from_dsp];

assign check_rs2 = (rob_has_res && regidx_from_rob == rs2_from_dsp && regAlias[rs2_from_dsp] == regalias_from_rob);
assign Qj_2dsp =  check_rs2 ? `REG_ZERO : regAlias[rs2_from_dsp];

assign Vj_2dsp = check_rs2 ? result_from_rob : register[rs2_from_dsp];


integer i;

always @(posedge clk) begin
  if (rst) begin
    for (i = 0; i < `REG_SIZE; i = i + 1) begin
      register[i] <= `ZERO;
      regAlias[i] <= `ZERO;
    end
  end
  else if (~rdy) begin
  end

  else if (rollback_signal) begin
    for (i = 0; i < `REG_SIZE; i = i + 1) begin
      regAlias[i] <= `ZERO;
    end
  end

  else begin
    if (ena_reg_rename && target_reg != `REG_ZERO) begin // rename reg
      regAlias[target_reg] <= targetReg_alias;
    end

    if (rob_has_res && regidx_from_rob != 0) begin // update reg
      register[regidx_from_rob]   <= result_from_rob;
      if (regalias_from_rob == regAlias[regidx_from_rob]) begin
        regAlias[regidx_from_rob] <= `RENAMED_ZERO;
      end

    end

  end

end
endmodule