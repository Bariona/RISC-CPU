`include "const.v"

`define INS_FETCH 2'b01
`define INS_HOLD  2'b00
`define INS_RBACK 2'b11

module InsFetcher(
  input wire clk, 
  input wire rst,
  input wire rdy, 
  
  input  wire is_full,    // isfull = lsb_full | rs_full | rob_full

  // signal to icahce
  output reg  rdy_to_fetch,              // ready to fetch an instruction
  output reg  [`DATA_IDX_RANGE] pc_2icache,
  input  wire instr_valid,              // whether icache has send instr back
  input  wire [`DATA_IDX_RANGE] instr_from_icache,

  // from predictor
  output wire [`DATA_IDX_RANGE] instr_2pred,
  output wire [`DATA_IDX_RANGE] cur_pc,
  input  wire if_jump,
  input  wire [`DATA_IDX_RANGE] next_pc,

  // port with dispatcher
  output reg valid_2dsp,
  output reg if_jump_2dsp,
  output reg [`DATA_IDX_RANGE] pc_2dsp,
  output reg [`DATA_IDX_RANGE] instr_2dsp,

  // port with ROB
  input  wire rollback_signal,
  input  wire [`DATA_IDX_RANGE] rollback_pc
); 

reg [1:0] status;
reg [`DATA_IDX_RANGE] pc;

// to predictor
assign cur_pc       = pc;
assign instr_2pred  = instr_from_icache;

always @(posedge clk) begin
  if (rst) begin 
    rdy_to_fetch  <= `FALSE;
    valid_2dsp    <= `FALSE;
    if_jump_2dsp  <= `FALSE;
    status        <= `INS_HOLD;
    pc            <= `ZERO;
    pc_2icache    <= `ZERO;
    pc_2dsp       <= `ZERO;
    instr_2dsp    <= `ZERO;
  end 
  else if (~rdy) begin // pause 
  end 

  else if (rollback_signal) begin
    pc            <= rollback_pc;
    // pc_2icache    <= `ZERO; 
    // rdy_to_fetch  <= `FALSE;
    // you can't suddenly change pc_2icache/rdy_to_fetch, 
    // it's will affect i$'s hit result, and then leads `INS_RBACK to immediately detect instr_valid = 1 -> status changed

    pc_2dsp       <= `ZERO;
    status        <= (status == `INS_FETCH) ? `INS_RBACK : `INS_HOLD;
    
    valid_2dsp    <= `FALSE;
  end

  else begin
    if (status == `INS_RBACK) begin
      if (instr_valid) begin
        status        <= `INS_HOLD;
        rdy_to_fetch  <= `FALSE;
        pc_2icache    <= `ZERO;
      end
    end
    else if (status == `INS_FETCH && ~is_full) begin
      if (instr_valid) begin
        status  <= `INS_HOLD;
        pc      <= next_pc;

        // to dispatcher
        if_jump_2dsp <= if_jump;
        valid_2dsp   <= `TRUE;
        instr_2dsp   <= instr_from_icache;
        pc_2dsp      <= pc;
        rdy_to_fetch <= `FALSE;
        pc_2icache   <= `ZERO;
      end
    end
    else if (status == `INS_HOLD) begin
      // valid_2dsp      <= `FALSE; // TODO: check where to place valid_2dsp
      // instr_2dsp      <= `ZERO;
      // pc_2dsp         <= `ZERO;

      if (~is_full) begin
        valid_2dsp    <= `FALSE;
        instr_2dsp    <= `ZERO;
        pc_2dsp       <= `ZERO;

        rdy_to_fetch  <= `TRUE;
        status        <= `INS_FETCH;
        pc_2icache    <= pc;
      end
      else begin
        // valid_2dsp    <= `FALSE;
        rdy_to_fetch  <= `FALSE;
        pc_2icache    <= `ZERO;
      end
    end

  end

end

// assign instr_if2is = fetched_instr;

endmodule
