`include "const.v"

module ALU (
  input wire [`OPCODE_TYPE] optype,
  input wire [`ROB_ID_RANGE] rd_alias_from_rs,
  input wire [`DATA_IDX_RANGE] pc,
  input wire [`DATA_IDX_RANGE] rs1,
  input wire [`DATA_IDX_RANGE] rs2,
  input wire [`DATA_IDX_RANGE] imm,
  
  output reg has_result,
  output reg [`ROB_ID_RANGE] rd_alias,
  output reg [`DATA_IDX_RANGE] result, 
  output reg [`DATA_IDX_RANGE] target_pc,
  output reg if_jump
);

// `ifdef Debug
//   integer outfile;
//   initial begin
//     outfile = $fopen("alu.out");
//   end
// `endif 

always @(*) begin
  
  has_result  = (optype != `NOP);
  rd_alias    = rd_alias_from_rs;
  if_jump     = `FALSE;
  
  case (optype)
    `OPTYPE_LUI:   result = imm;
    `OPTYPE_AUIPC: result = pc + imm;

    `OPTYPE_JAL: begin
      if_jump   = `TRUE;
      result    = pc + 4;
      target_pc = pc + imm;
      
    end
    `OPTYPE_JALR: begin
      if_jump   = `TRUE;
      result    = pc + 4;
      target_pc = (rs1 + imm) & ~1;
    end

    
    `OPTYPE_BEQ: begin
      if_jump   = rs1 == rs2;
      target_pc = pc + imm;
    end
    `OPTYPE_BNE: begin
      if_jump   = rs1 != rs2;
      target_pc = pc + imm;
    end
    `OPTYPE_BLT: begin
      if_jump   = $signed(rs1) < $signed(rs2);
      target_pc = pc + imm;
    end
    `OPTYPE_BGE: begin
      if_jump   = $signed(rs1) > $signed(rs2);
      target_pc = pc + imm;
    end
    `OPTYPE_BLTU: begin
      if_jump   = rs1 < rs2;
      target_pc = pc + imm;
    end
    `OPTYPE_BGEU: begin
      if_jump   = rs1 >= rs2;
      target_pc = pc + imm;
    end

    `OPTYPE_ADDI: result = rs1 + imm;
    `OPTYPE_ADD:  result = rs1 + rs2;
    `OPTYPE_SUB:  result = rs1 - rs2;

    `OPTYPE_SLTI: result = $signed(rs1) < $signed(imm);
    `OPTYPE_SLTIU:result = rs1 < imm;
    
    `OPTYPE_SLT:  result = $signed(rs1) < $signed(rs2);
    `OPTYPE_SLTU: result = rs1 < rs2;
    
    `OPTYPE_XORI: result = rs1 ^ imm;
    `OPTYPE_XOR:  result = rs1 ^ rs2;
    `OPTYPE_ORI:  result = rs1 | imm;
    `OPTYPE_OR:   result = rs1 | rs2;
    `OPTYPE_ANDI: result = rs1 & imm;
    `OPTYPE_AND:  result = rs1 & rs2;
    
    `OPTYPE_SLL:  result = rs1 << rs2;
    `OPTYPE_SRL:  result = rs1 >> rs2;
    `OPTYPE_SLLI: result = rs1 << imm;
    `OPTYPE_SRLI: result = rs1 >> imm;    
    `OPTYPE_SRA:  result = rs1 >>> rs2;
    `OPTYPE_SRAI: result = rs1 >>> imm;

  endcase
end

endmodule