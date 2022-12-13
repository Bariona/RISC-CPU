// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "IF/Icache.v"
`include "IF/InsFetcher.v"
`include "IF/Predictor.v"
`include "ID/Decoder.v"
`include "ID/Dispatch.v"
`include "EX/ALU.v"
`include "EX/RsrvStation.v"
`include "EX/LdStBuffer.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire             io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		  // cpu register output (debugging demo)
);

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire rollback_signal;
wire [`DATA_IDX_RANGE] rollback_pc;

// full signal
wire rs_full, lsb_full, rob_full;
wire is_full = rs_full | lsb_full | rob_full;

// mc & mem(ram)
wire wr_mc2ram, ram_ena;
wire [`ADDR_IDX] addr_2ram;

// icache & mc
wire ena_mc_icache, valid_mc2icache;
wire [`DATA_IDX_RANGE] data_mc2icache;
wire [`ADDR_IDX] addr_2mc;

// lsb & mc
wire [2:0] totByte_from_lsb;
wire ena_mc_from_lsb, wr_2mc_from_lsb, rdy_mc_lsb;
wire [`OPCODE_TYPE] optype_lsb_mc;
wire [`DATA_IDX_RANGE] addr_2mc_from_lsb, data_2mc_from_lsb, data_mc_2lsb;

// fetcher & icache
wire rd_ena_if_icache, instr_rdy_if_icache;
wire [`DATA_IDX_RANGE] pc_if_icache, instr_if_icache;

// fetcher & predictor
wire valid_if_pred, pred_if_jump;
wire [`DATA_IDX_RANGE] instr_2pred;
wire [`DATA_IDX_RANGE] curpc_2pred, nexpc_2if;

// fetcher & issue
wire valid_2dsp, if_jump_2dsp;
wire [`DATA_IDX_RANGE] pc_if_dsp, instr_if_dsp;

// predictor & rob
wire ena_pre_from_rob, predict_res_from_rob;
wire [`DATA_IDX_RANGE] commit_pc_2pred;

MemController MC (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  // .rollback_signal(rollback_signal),

  .fet_ena(ena_mc_icache),
  .instr_addr(addr_2mc),
  .valid_2icache(valid_mc2icache),
  .data_2icache(data_mc2icache),

  .wr_ena(ena_mc_from_lsb),
  .wr_from_lsb(wr_2mc_from_lsb),
  .optype_from_lsb(optype_lsb_mc),
  .addr_from_lsb(addr_2mc_from_lsb),
  .data_from_lsb(data_2mc_from_lsb),
  .totByte(totByte_from_lsb),
  .valid_2lsb(rdy_mc_lsb),
  .data_2lsb(data_mc_2lsb),

  .ram_ena(ram_ena),
  .wr_mc2ram(mem_wr),
  .addr_2ram(mem_a),
  .data_2ram(mem_dout),
  
  .data_from_ram(mem_din),
  .uart_full_signal(io_buffer_full)
);

Predictor predictor (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .instr_valid(valid_if_pred),
  .instr_from_IC(instr_2pred),
  .cur_pc(curpc_2pred),
  .if_jump(pred_if_jump),
  .predict_pc(nexpc_2if),

  .rob_commit_pc_arrived(ena_pre_from_rob),
  .rob_commit_pc(commit_pc_2pred),
  .hit_res(predict_res_from_rob)
);

ICACHE icache (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .rdy_from_fet(rd_ena_if_icache),
  .pc(pc_if_icache),
  .instr_valid(instr_rdy_if_icache),
  .instr(instr_if_icache),

  .mc_ena(ena_mc_icache),
  .addr(addr_2mc),
  .valid_from_mc(valid_mc2icache),
  .data_from_mc(data_mc2icache)
);

InsFetcher fetcher (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .is_full(is_full),

  .rdy_to_fetch(rd_ena_if_icache), // icache
  .pc_2icache(pc_if_icache),
  .instr_valid(instr_rdy_if_icache),
  .instr_from_icache(instr_if_icache),

  .valid_2pred(valid_if_pred), // pred
  .instr_2pred(instr_2pred),
  .cur_pc(curpc_2pred),
  .if_jump(pred_if_jump),
  .next_pc(nexpc_2if),

  .valid_2dsp(valid_2dsp),  // dsp
  .if_jump_2dsp(if_jump_2dsp),
  .pc_2dsp(pc_if_dsp),
  .instr_2dsp(instr_if_dsp),

  .rollback_signal(rollback_signal),
  .rollback_pc(rollback_pc)
);

// dsp & rob
wire instr_rdy_dsp_rob, is_jump_dsp_rob, jumpRecord_dsp_rob;
wire rob_Qi_rdy, rob_Qj_rdy;
wire [`ROB_ID_RANGE] id_rob_dsp, Qi_dsp_2rob, Qj_dsp_2rob;
wire [`REG_RANGE] instr_target_rd_2rob;
wire [`OPCODE_TYPE] optype_dsp_rob;
wire [`DATA_IDX_RANGE] pc_dsp_rob, Vi_rob_2dsp, Vj_rob_2dsp;

// dsp & register file
wire ena_regfile_rename;
wire [`ROB_ID_RANGE] rd_alias_dsp_reg, Qi_rg_2dsp, Qj_rg_2dsp;
wire [`REG_RANGE] rd_dsp_reg, rs1_dsp_2reg, rs2_dsp_2reg;
wire [`DATA_IDX_RANGE] Vi_rg_2dsp, Vj_rg_2dsp;

// dsp & RS
wire ena_dsp_rs;
wire [`ROB_ID_RANGE] rd_alias_dsp_rs, Qi_dsp_rs, Qj_dsp_rs;
wire [`OPCODE_TYPE] optype_dsp_rs;
wire [`DATA_IDX_RANGE] pc_dsp_rs, Vi_dsp_rs, Vj_dsp_rs, imm_dsp_rs;

// dsp & lsb
wire ena_dsp_lsb;
wire [`ROB_ID_RANGE] rd_alias_dsp_lsb, Qi_dsp_lsb, Qj_dsp_lsb;
wire [`OPCODE_TYPE] optype_dsp_lsb;
wire [`DATA_IDX_RANGE] Vi_dsp_lsb, Vj_dsp_lsb, imm_dsp_lsb, pc_dsp_lsb;

// alu CDB
wire alu_has_result;
wire [`ROB_ID_RANGE] alias_from_alu;
wire [`DATA_IDX_RANGE] result_from_alu;

// LSB CDB
wire lsb_has_result;
wire [`ROB_ID_RANGE] alias_from_lsb;
wire [`DATA_IDX_RANGE] result_from_lsb;

Dispatcher dispatcher (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .rollback_signal(rollback_signal),

  .is_full(is_full),
  
  .valid_from_fet(valid_2dsp),  // instr fetcher
  .if_jump_from_fet(if_jump_2dsp),
  .pc_from_fet(pc_if_dsp),
  .instr_from_fet(instr_if_dsp),

  .id_from_rob(id_rob_dsp), // rob
  .instr_rdy_2rob(instr_rdy_dsp_rob),
  .pc_2rob(pc_dsp_rob),
  .instr_tar_rd(instr_target_rd_2rob),
  .is_jump_2rob(is_jump_dsp_rob),
  .jumpRecord_2rob(jumpRecord_dsp_rob),
  .optype_2rob(optype_dsp_rob),

  .Qi_2rob(Qi_dsp_2rob),
  .Qj_2rob(Qj_dsp_2rob),
  .rob_Qi_rdy(rob_Qi_rdy),
  .rob_Qj_rdy(rob_Qj_rdy),
  .Vi_from_rob(Vi_rob_2dsp),
  .Vj_from_rob(Vj_rob_2dsp),

  .ena_regfile_rename(ena_regfile_rename), // regsiter
  .rd_2reg(rd_dsp_reg),
  .rd_alias(rd_alias_dsp_reg),
  
  .rs1_2reg(rs1_dsp_2reg),
  .rs2_2reg(rs2_dsp_2reg),
  .Qi_from_rg(Qi_rg_2dsp),
  .Qj_from_rg(Qj_rg_2dsp),
  .Vi_from_rg(Vi_rg_2dsp),
  .Vj_from_rg(Vj_rg_2dsp),

  .ena_rs(ena_dsp_rs), // RS
  .rd_alias_2rs(rd_alias_dsp_rs),
  .optype_2rs(optype_dsp_rs),
  .pc_2rs(pc_dsp_rs),
  .Qi_2rs(Qi_dsp_rs),
  .Qj_2rs(Qj_dsp_rs),
  .Vi_2rs(Vi_dsp_rs),
  .Vj_2rs(Vj_dsp_rs),
  .imm_2rs(imm_dsp_rs),

  .ena_lsb(ena_dsp_lsb), // LSB
  .pc_2lsb(pc_dsp_lsb),
  .rd_alias_2lsb(rd_alias_dsp_lsb),
  .optype_2lsb(optype_dsp_lsb),
  .Qi_2lsb(Qi_dsp_lsb),
  .Qj_2lsb(Qj_dsp_lsb),
  .Vi_2lsb(Vi_dsp_lsb),
  .Vj_2lsb(Vj_dsp_lsb),
  .imm_2lsb(imm_dsp_lsb),

  // cdb info
  .alu_has_result(alu_has_result),  // alu cdb
  .alias_from_alu(alias_from_alu),
  .result_from_alu(result_from_alu),

  .lsb_has_result(lsb_has_result),  // lsb cdb
  .alias_from_lsb(alias_from_lsb),
  .result_from_lsb(result_from_lsb)
);

// rs & alu
wire [`OPCODE_TYPE] opetype_rs_alu;
wire [`ROB_ID_RANGE] rd_2alu;
wire [`DATA_IDX_RANGE] pc_rs_alu, Vi_rs_alu, Vj_rs_alu, imm_rs_alu;

ReserveStation RS (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .rollback_signal(rollback_signal),

  .rs_full(rs_full), // with dispatcher
  .rdy_from_is(ena_dsp_rs),
  .optype_from_is(optype_dsp_rs),
  .pc_from_is(pc_dsp_rs),
  .rd_alias(rd_alias_dsp_rs),
  .Qi_from_is(Qi_dsp_rs),
  .Qj_from_is(Qj_dsp_rs),
  .Vi_from_is(Vi_dsp_rs),
  .Vj_from_is(Vj_dsp_rs),
  .imm_from_is(imm_dsp_rs),

  .optype_2alu(opetype_rs_alu), // ALU
  .rd_2alu(rd_2alu),
  .pc_2alu(pc_rs_alu),
  .Vi_2alu(Vi_rs_alu),
  .Vj_2alu(Vj_rs_alu),
  .imm_2alu(imm_rs_alu),  

  .alu_has_result(alu_has_result),  // alu cdb
  .alias_from_alu(alias_from_alu),
  .result_from_alu(result_from_alu),

  .lsb_has_result(lsb_has_result),  // lsb cdb
  .alias_from_lsb(alias_from_lsb),
  .result_from_lsb(result_from_lsb)
);

// alu & rob
wire if_jump_from_alu;
wire [`DATA_IDX_RANGE] target_pc_from_alu;

ALU alu (
  .optype(opetype_rs_alu),
  .rd_alias_from_rs(rd_2alu),
  .pc(pc_rs_alu),
  .rs1(Vi_rs_alu),
  .rs2(Vj_rs_alu),
  .imm(imm_rs_alu),

  .has_result(alu_has_result),
  .rd_alias(alias_from_alu),
  .result(result_from_alu),
  .target_pc(target_pc_from_alu),
  .if_jump(if_jump_from_alu)
);

wire prepared_to_commit;
wire [`ROB_ID_RANGE] store_alias_2lsb;

LoadStoreBuffer #(.ADDR_BITS(4)) LSB (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .prepared_to_commit(prepared_to_commit),
  .store_commit_alias(store_alias_2lsb),

  .lsb_full(lsb_full),

  .rdy_from_is(ena_dsp_lsb), // dsp
  .pc_from_dsp(pc_dsp_lsb),
  .optype_from_is(optype_dsp_lsb),
  .rd_alias_from_is(rd_alias_dsp_lsb),
  .Qi_from_is(Qi_dsp_lsb),
  .Qj_from_is(Qj_dsp_lsb),
  .Vi_from_is(Vi_dsp_lsb),
  .Vj_from_is(Vj_dsp_lsb),
  .imm_from_is(imm_dsp_lsb),

  .ena_mc(ena_mc_from_lsb), // mc
  .wr_2mc(wr_2mc_from_lsb),
  .optype_2mc(optype_lsb_mc),
  .addr_2mc(addr_2mc_from_lsb),
  .data_2mc(data_2mc_from_lsb),
  .totByte(totByte_from_lsb),
  .rdy_from_mc(rdy_mc_lsb),
  .data_from_mc(data_mc_2lsb),

  .alu_has_result(alu_has_result),
  .alias_from_alu(alias_from_alu),
  .result_from_alu(result_from_alu),

  .lsb_has_result(lsb_has_result),
  .alias_from_lsb(alias_from_lsb),
  .result_from_lsb(result_from_lsb),

  .rollback_signal(rollback_signal)
);

// rob & regfile
wire res_rdy_rob_reg;
wire [`DATA_IDX_RANGE] res_rob_reg;
wire [`REG_RANGE] regidx_rob_reg;
wire [`ROB_ID_RANGE] reg_alias_rob_reg;

ROB rob (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .rob_full(rob_full),
  .rollback_signal(rollback_signal),
  .rollback_pc(rollback_pc),

  .ena_pred(ena_pre_from_rob), // predictor
  .predict_res(predict_res_from_rob),
  .commit_pc_2pred(commit_pc_2pred),

  .instr_rdy_from_dsp(instr_rdy_dsp_rob), // dsp
  .pc_from_dsp(pc_dsp_rob),
  .instr_rd_from_dsp(instr_target_rd_2rob),
  .is_jump_from_dsp(is_jump_dsp_rob),
  .jumpRecord_from_dsp(jumpRecord_dsp_rob),
  .optype_from_dsp(optype_dsp_rob),

  .renameid_2dsp(id_rob_dsp),
  .Qi_query_from_dsp(Qi_dsp_2rob),
  .Qj_query_from_dsp(Qj_dsp_2rob),
  .rob_Qi_rdy(rob_Qi_rdy),
  .rob_Qj_rdy(rob_Qj_rdy),
  .Vi_2dsp(Vi_rob_2dsp),
  .Vj_2dsp(Vj_rob_2dsp),

  .store_prepared_to_commit(prepared_to_commit),
  .store_alias_2lsb(store_alias_2lsb),
  
  .alu_has_result(alu_has_result), // alu
  .alias_from_alu(alias_from_alu),
  .result_from_alu(result_from_alu),
  .jump_res_from_alu(if_jump_from_alu),
  .jumpTaken_pc_from_alu(target_pc_from_alu),

  .lsb_has_result(lsb_has_result),  // lsb
  .alias_from_lsb(alias_from_lsb),
  .result_from_lsb(result_from_lsb),

  .res_rdy_2reg(res_rdy_rob_reg), // reg
  .res_2reg(res_rob_reg),
  .regidx_2regfile(regidx_rob_reg),
  .reg_alias(reg_alias_rob_reg)
);


RegsiterFile regfile (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .rollback_signal(rollback_signal),

  .rs1_from_dsp(rs1_dsp_2reg), // dsp
  .rs2_from_dsp(rs2_dsp_2reg),

  .Qi_2dsp(Qi_rg_2dsp),
  .Qj_2dsp(Qj_rg_2dsp),
  .Vi_2dsp(Vi_rg_2dsp),
  .Vj_2dsp(Vj_rg_2dsp),

  .ena_reg_rename(ena_regfile_rename),
  .target_reg(rd_dsp_reg),
  .targetReg_alias(rd_alias_dsp_reg),

  .rob_has_res(res_rdy_rob_reg), // rob
  .result_from_rob(res_rob_reg),
  .regidx_from_rob(regidx_rob_reg),
  .regalias_from_rob(reg_alias_rob_reg)
);

endmodule