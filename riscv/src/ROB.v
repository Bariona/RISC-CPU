`include "const.v"

module ROB (
  input wire clk,
  input wire rst, 
  input wire rdy,

  // port with dispatcher
  output wire [`ROB_ID_RANGE] id_2dsp,
  output wire Qi_rdy,
  output wire Qj_rdy,
  output wire [`DATA_IDX_RANGE] Vi_2dsp,
  output wire [`DATA_IDX_RANGE] Vj_2dsp,

);


always @(posedge clk) begin
  if (rst) begin

  end

  else if (~rdy) begin // pause
  end

  else begin

  end
end
endmodule