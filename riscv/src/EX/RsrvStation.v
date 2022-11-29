`include "const.v"

`define RS_SIZE      16
`define RS_IDX_RANGE 4:0

module ReserveStation (
  input wire clk,
  input wire rst, 
  input wire rdy,

  // port with dispatcher
  output wire rs_full,
  input wire rdy_from_is,
  input wire [`OPCODE_TYPE] optype_from_is,
  input wire [`DATA_IDX_RANGE] pc_from_is,

  input wire [`REG_RANGE]      Qi_from_is,
  input wire [`REG_RANGE]      Qj_from_is,
  input wire [`DATA_IDX_RANGE] Vi_from_is,
  input wire [`DATA_IDX_RANGE] Vj_from_is,
  input wire [`DATA_IDX_RANGE] imm_from_is,

  // port with ALU
  // input wire [`DATA_IDX_RANGE] res_from_alu,
  output reg [`REG_RANGE] optype_2alu,
  output reg [`DATA_IDX_RANGE] pc_2alu,
  output reg [`DATA_IDX_RANGE] Vi_2alu,
  output reg [`DATA_IDX_RANGE] Vj_2alu,
  output reg [`DATA_IDX_RANGE] imm_2alu 

);

reg busy [`RS_SIZE - 1 : 0];
reg [`OPCODE_TYPE] optype[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] pc[`RS_SIZE - 1 : 0];

reg [`REG_RANGE]      Qi[`RS_SIZE - 1 : 0];
reg [`REG_RANGE]      Qj[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] Vi[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] Vj[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] imm[`RS_SIZE - 1 : 0];
reg [`DATA_IDX_RANGE] Res[`RS_SIZE - 1 : 0];

wire [`RS_IDX_RANGE] avail_entry;
wire [`RS_IDX_RANGE] ex_entry_idx;

assign rs_full = (avail_entry == `RS_SIZE);

assign avail_entry = (!busy[0] ? 0 : 
                        (!busy[1] ? 1 : 
                              (!busy[2] ? 2 : 
                                (!busy[3] ? 3 : 
                                  (!busy[4] ? 4 : 
                                    (!busy[5] ? 5 : 
                                      (!busy[6] ? 6 :
                                        (!busy[7] ? 7 :
                                          (!busy[8] ? 8 :
                                            (!busy[9] ? 9 :
                                              (!busy[10] ? 10 :
                                                (!busy[11] ? 11 :
                                                  (!busy[12] ? 12 :
                                                    (!busy[13] ? 13 :
                                                      (!busy[14] ? 14 :
                                                        (!busy[15] ? 15 : 16
                                                        ))))))))))))))));


assign ex_entry_idx = ((busy[0] && !Qi[0] && !Qj[0]) ? 0 : 
                    ((busy[1] && !Qi[1] && !Qj[1]) ? 1 :
                      ((busy[2] && !Qi[2] && !Qj[2]) ? 2 :
                        ((busy[3] && !Qi[3] && !Qj[3]) ? 3 :
                          ((busy[4] && !Qi[4] && !Qj[4]) ? 4 :
                            ((busy[5] && !Qi[5] && !Qj[5]) ? 5 :
                              ((busy[6] && !Qi[6] && !Qj[6]) ? 6 :
                                ((busy[7] && !Qi[7] && !Qj[7]) ? 7 :
                                  ((busy[8] && !Qi[8] && !Qj[8]) ? 8 :
                                    ((busy[9] && !Qi[9] && !Qj[9]) ? 9 :
                                      ((busy[10] && !Qi[10] && !Qj[10]) ? 10 :
                                        ((busy[11] && !Qi[11] && !Qj[11]) ? 11 :
                                          ((busy[12] && !Qi[12] && !Qj[12]) ? 12 :
                                            ((busy[13] && !Qi[13] && !Qj[13]) ? 13 :
                                              ((busy[14] && !Qi[14] && !Qj[14]) ? 14 :
                                                ((busy[15] && !Qi[15] && !Qj[15]) ? 15 : 16
                                                ))))))))))))))));

integer i;

always @(posedge clk) begin
  if (rst) begin
    for (i = 0; i < `RS_SIZE; i = i + 1) begin
      busy[i]   <= `FALSE;
      Qi[i]     <= `REG_ZERO;
      Qj[i]     <= `REG_ZERO;
      Vi[i]     <= `ZERO;
      Vj[i]     <= `ZERO;
      Res[i]    <= `ZERO;
    end

  end
  else if (~rdy) begin // pause
  end

  else begin

    if (rdy_from_is) begin // add instruction into RS
      busy[avail_entry]  <= `TRUE;

      optype[avail_entry]<= optype_from_is;
      pc[avail_entry]    <= pc_from_is;

      Qi[avail_entry]    <= Qi_from_is;
      Qj[avail_entry]    <= Qj_from_is;
      Vi[avail_entry]    <= Vi_from_is;
      Vj[avail_entry]    <= Vj_from_is;
      imm[avail_entry]   <= imm_from_is;
    end

    if (ex_entry_idx != `RS_SIZE) begin
      busy[ex_entry_idx]  <= `FALSE;
      optype_2alu         <= optype[ex_entry_idx];
      pc_2alu             <= pc[ex_entry_idx];
      Vi_2alu             <= Vi[ex_entry_idx];
      Vj_2alu             <= Vj[ex_entry_idx];
      imm_2alu            <= imm[ex_entry_idx];
    end


  end

end
endmodule