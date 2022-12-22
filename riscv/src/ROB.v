`include "const.v"

module ROB (
  input wire clk,
  input wire rst, 
  input wire rdy,

  output wire rob_full,
  output reg  rollback_signal,
  output reg  [`DATA_IDX_RANGE] rollback_pc,

  // port with predictor
  output reg ena_pred,
  output reg predict_res,
  output reg [`DATA_IDX_RANGE] commit_pc_2pred,

  // port with dispatcher
  input  wire instr_rdy_from_dsp,
  input  wire [`DATA_IDX_RANGE] pc_from_dsp,
  input  wire [`REG_RANGE] instr_rd_from_dsp,
  input  wire is_jump_from_dsp,
  input  wire jumpRecord_from_dsp,
  input  wire [`OPCODE_TYPE] optype_from_dsp,

  output wire [`ROB_ID_RANGE] renameid_2dsp,
  input  wire [`ROB_ID_RANGE] Qi_query_from_dsp,  // rs1's alias
  input  wire [`ROB_ID_RANGE] Qj_query_from_dsp,  // rs2's alias
  output wire rob_Qi_rdy,
  output wire rob_Qj_rdy,
  output wire [`DATA_IDX_RANGE] Vi_2dsp, // rs1's value
  output wire [`DATA_IDX_RANGE] Vj_2dsp, // rs2's value

  // port with LSB
  output wire store_prepared_to_commit,
  output wire [`ROB_ID_RANGE] store_alias_2lsb,

  // ALU's cdb result
  input wire alu_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_alu,
  input wire [`DATA_IDX_RANGE] result_from_alu,
  input wire jump_res_from_alu,
  input wire [`DATA_IDX_RANGE] jumpTaken_pc_from_alu,


  // LSB's cdb result
  input wire lsb_has_result,
  input wire [`ROB_ID_RANGE]   alias_from_lsb,
  input wire [`DATA_IDX_RANGE] result_from_lsb, 

  // port with reg file
  output reg res_rdy_2reg,
  output reg [`DATA_IDX_RANGE] res_2reg,
  output reg [`REG_RANGE] regidx_2regfile,
  output reg [`ROB_ID_RANGE] reg_alias,

  output wire [`DATA_IDX_RANGE] debug_out
);

// ===== FIFO =====
// the queue should start from index 1
reg [`ROB_ID_RANGE]       head, tail;
reg [`ROB_SIZE - 1 : 0]       ready;
reg [`ROB_SIZE - 1 : 0]     is_jump;
reg [`ROB_SIZE - 1 : 0]   jumpRecord;
reg [`ROB_SIZE - 1 : 0]   jumpResult;
reg [`OPCODE_TYPE]         optype[`ROB_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE]          pc[`ROB_SIZE - 1 : 0]; // current pc
reg [`DATA_IDX_RANGE]      result[`ROB_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] jumpTakenPc[`ROB_SIZE - 1 : 0]; // if jump, pc will be what
reg [`REG_RANGE]        target_rd[`ROB_SIZE - 1 : 0];

wire [`ROB_ID_RANGE] next_head = (head == `ROB_SIZE - 1) ? 1 : head + 1;
wire [`ROB_ID_RANGE] next_tail = (tail == `ROB_SIZE - 1) ? 1 : tail + 1;
// ================

wire rob_empty  = (tail == head);
assign rob_full = (next_tail == head);
 
// dsp
assign renameid_2dsp  = tail;
assign rob_Qi_rdy     = ready[Qi_query_from_dsp];
assign rob_Qj_rdy     = ready[Qj_query_from_dsp];
assign Vi_2dsp        = result[Qi_query_from_dsp];
assign Vj_2dsp        = result[Qj_query_from_dsp];

// lsb
assign store_prepared_to_commit = (~rob_empty) && (optype[head] >= `OPTYPE_LB && optype[head] <= `OPTYPE_SW);
assign store_alias_2lsb         = head;

integer i;

`ifdef Debug
 integer outfile;
 initial begin
   outfile = $fopen("test.out");
 end
`endif

assign debug_out = pc[head];

always @(posedge clk) begin
  if (rst || rollback_signal) begin
    rollback_signal <= `FALSE;
    rollback_pc     <= `ZERO;
    head            <= 1;
    tail            <= 1;
    ena_pred        <= `FALSE;
    predict_res     <= `FALSE;
    res_rdy_2reg    <= `FALSE;
    res_2reg        <= `ZERO;
    reg_alias       <= `RENAMED_ZERO;
    regidx_2regfile <= `REG_ZERO;
    commit_pc_2pred <= `ZERO;
    
    for (i = 0; i < `ROB_SIZE; i = i + 1) begin
      ready[i]      <= `FALSE;
      is_jump[i]    <= `FALSE;
      jumpRecord[i] <= `FALSE;
      jumpResult[i] <= `FALSE;
      pc[i]         <= `ZERO;
      result[i]     <= `ZERO;
      jumpTakenPc[i]<= `ZERO;
      target_rd[i]  <= `REG_ZERO;
    end
  end

  else if (~rdy) begin // pause
  end

  else begin
    if (~rob_empty && ready[head]) begin

    // if (rob_full) begin
    //   $fdisplay(outfile, "time = %d, ---- ROB is full ----", $time);
    // end

`ifdef Debug
    // $fdisplay(outfile, "pc = %x", pc[head]);
    $fdisplay(outfile, "time = %d, pc = %x, optype = %d", $time, pc[head], optype[head]);
`endif
    
`ifdef Debug
      $fdisplay(outfile, "time = %d, \nrd = %d, commited pc: %x, optype = %d", $time, target_rd[head], pc[head], optype[head]);
      $fdisplay(outfile, "after commit: current head(%d), tail(%d)\n", head, tail);
      if (is_jump[head]) begin
        $fdisplay(outfile, "jumprecord = %d, ALU's result = %d, branch instr result: %d, pc_Taken = %x\n", 
                                jumpRecord[head], jumpResult[head], jumpRecord[head] == jumpResult[head], jumpTakenPc[head]);
      end
`endif

      head              <= next_head;
      ready[head]       <= `FALSE;
      jumpRecord[head]  <= `FALSE;
      is_jump[head]     <= `FALSE;
      
      if (is_jump[head]) begin
        // branch instruction 
        ena_pred        <= `TRUE;
        commit_pc_2pred <= pc[head];

        if (jumpRecord[head] != jumpResult[head]) begin
          predict_res       <= `FALSE;
          rollback_signal   <= `TRUE;
          rollback_pc       <= jumpResult[head] ? jumpTakenPc[head] : pc[head] + 4;
        end
        else begin
          predict_res       <= `TRUE;
          rollback_signal   <= `FALSE;
        end
      end
      else begin
        ena_pred  <= `FALSE;
      end
`ifdef Debug
      $fdisplay(outfile, "-> target register[%d], result = %x, alias = %x\n", target_rd[head], result[head], head);
`endif
      if (target_rd[head] != 0) begin
        res_rdy_2reg    <= `TRUE;
        regidx_2regfile <= target_rd[head];
        res_2reg        <= result[head];
        reg_alias       <= head;
      end
      else begin
        res_rdy_2reg    <= `FALSE;
      end

    end
    else begin
      ena_pred      <= `FALSE;
      res_rdy_2reg  <= `FALSE;
      commit_pc_2pred <= `ZERO;
    end

    if (alu_has_result) begin
      ready[alias_from_alu]       <= `TRUE;
      result[alias_from_alu]      <= result_from_alu;
      jumpResult[alias_from_alu]  <= jump_res_from_alu;
      jumpTakenPc[alias_from_alu] <= jumpTaken_pc_from_alu;
    end

    if (lsb_has_result) begin
      ready[alias_from_lsb]     <= `TRUE;
      result[alias_from_lsb]    <= result_from_lsb;
    end
    if (instr_rdy_from_dsp) begin
`ifdef Debug
      $fdisplay(outfile, "time = %d, \n current head(%d), add instruction: (%d) \n pc = %x, optype = %d, jumpRecord = %d\n", 
                            $time, head, tail, pc_from_dsp, optype_from_dsp, jumpRecord_from_dsp);
`endif
      tail              <= next_tail;
      ready[tail]       <= `FALSE;
      result[tail]      <= `ZERO;
      pc[tail]          <= pc_from_dsp;
      target_rd[tail]   <= instr_rd_from_dsp;
      optype[tail]      <= optype_from_dsp;
      is_jump[tail]     <= is_jump_from_dsp;
      jumpRecord[tail]  <= jumpRecord_from_dsp;
    end
  end
end

endmodule