`include "const.v"

`define FETCH 2'b01
`define HOLD  2'b00

module InsFetcher(
  input wire clk, 
  input wire rst,
  input wire rdy, 
  
  input  wire is_full,    // isfull = lsb_full | rs_full | rob_full

  // signal to icahce
  output reg rdy_to_fetch,              // ready to fetch an instruction
  output reg  [`DATA_IDX_RANGE] pc_2icache,
  input  wire instr_valid,              // whether icache has send instr back
  input  wire [`DATA_IDX_RANGE] instr_from_icache,

  // from predictor
  output wire valid_2pred,
  output wire [`DATA_IDX_RANGE] instr_2pred,
  output wire [`DATA_IDX_RANGE] cur_pc, // ??? reg or wire
  input  wire if_jump,
  input  wire [`DATA_IDX_RANGE] next_pc,

  // port with dispatcher
  output wire valid_2dsp,
  output wire if_jump_2dsp,
  output wire [`DATA_IDX_RANGE] pc_2dsp,
  output wire [`DATA_IDX_RANGE] instr_2dsp,

  // port with ROB
  input  wire rollback_signal,
  input  wire [`DATA_IDX_RANGE] rollback_pc
); 

// 后续会有predict失败的roll_back
reg [1:0] status;
reg [`DATA_IDX_RANGE] pc;

// assign rdy_to_fetch = ~is_full;
// assign pc_2icache   = pc;

// to dispatcher
assign if_jump_2dsp = if_jump;
assign valid_2dsp   = instr_valid;
assign instr_2dsp   = instr_from_icache;
assign pc_2dsp      = pc;

// to predictor
assign valid_2pred  = (instr_valid) ? `TRUE : `FALSE;
assign cur_pc       = pc;
assign instr_2pred  = instr_from_icache;

always @(posedge clk) begin
  if (rst) begin 
    status <= `HOLD;
    pc     <= 0;
  end 
  else if (~rdy) begin // pause 
  end 

  else if (rollback_pc) begin
    pc <= rollback_pc;
    status  <= `HOLD;
    rdy_to_fetch  <= `FALSE;
  end

  else begin
    /*
    pc <= (instr_valid) ? next_pc : pc;

    if (rdy_to_fetch) begin   // able to fetch another instruction
      pc_2icache <= pc;
    end 
    // else begin
    //   pc <= `ZERO;
    // end
  */
    if (status == `FETCH) begin
      if (instr_valid) begin
        status  <= `HOLD;
        pc      <= next_pc;
      end
    end
    else if (status == `HOLD) begin
      if (~is_full) begin
        rdy_to_fetch  <= `TRUE;
        status        <= `FETCH;
        pc_2icache    <= pc;
      end
      else begin
        rdy_to_fetch  <= `FALSE;
      end
    end

  end

end

// assign instr_if2is = fetched_instr;

endmodule
