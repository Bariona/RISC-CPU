`include "const.v"

module Decoder (
  input wire [`DATA_IDX_RANGE] instr,

  output reg is_ls,
  output reg is_jump,
  output reg [`OPCODE_TYPE] optype,

  output reg [`REG_RANGE] rd,
  output reg [`REG_RANGE] rs1,
  output reg [`REG_RANGE] rs2,
  output reg [`DATA_IDX_RANGE] imm
);

wire [`OPCODE_RANGE] instrType = instr[`OPCODE_RANGE];
wire [`FUNCT3_RANGE] funct3    = instr[`FUNCT3_RANGE];


always @(*) begin
  rd      = instr[`RD_IDX];
  rs1     = instr[`RS1_IDX];
  rs2     = instr[`RS2_IDX];
  imm     = `ZERO;
  optype  = `NOP;
  
  is_ls   = (instrType == `S_TYPE || instrType == `L_TYPE);
  is_jump = `FALSE;

  case (instrType)
    `LUI_TYPE, `AUIPC_TYPE: begin
      imm     = {instr[31:12], 12'b0};
      if (instrType == `LUI_TYPE) 
        optype  = `OPTYPE_LUI;
      else 
        optype  = `OPTYPE_AUIPC;
    end

    `JAL_TYPE: begin
      is_jump = `TRUE;
      imm     = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      optype  = `OPTYPE_JAL;
    end

    `JALR_TYPE: begin
      is_jump = `TRUE;
      imm     = {{21{instr[31]}}, instr[30:20]};
      optype  = `OPTYPE_JALR;
    end

    `B_TYPE: begin
      rd      = `REG_ZERO;
      imm     = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      is_jump = `TRUE;
      case (funct3)
        3'b000: optype = `OPTYPE_BEQ;
        3'b001: optype = `OPTYPE_BNE;
        3'b100: optype = `OPTYPE_BLT;
        3'b101: optype = `OPTYPE_BGE;
        3'b110: optype = `OPTYPE_BLTU;
        3'b111: optype = `OPTYPE_BGEU;
      endcase
    end

    `L_TYPE: begin
      imm   = {{21{instr[31]}}, instr[30:20]};
      case (funct3)
        3'b000: optype = `OPTYPE_LB;
        3'b001: optype = `OPTYPE_LH;
        3'b010: optype = `OPTYPE_LW;
        3'b100: optype = `OPTYPE_LBU;
        3'b101: optype = `OPTYPE_LHU;
      endcase
    end

    `A_TYPE: begin
      imm = {{21{instr[31]}}, instr[30:20]};
      case (funct3) 
        3'b000: optype = `OPTYPE_ADDI;
        3'b010: optype = `OPTYPE_SLTI;
        3'b011: optype = `OPTYPE_SLTIU;
        3'b100: optype = `OPTYPE_XORI;
        3'b110: optype = `OPTYPE_ORI;
        3'b111: optype = `OPTYPE_ANDI;
        3'b001: begin
          optype = `OPTYPE_SLLI;
          imm    = {26'b0, instr[24:20]};
        end
        3'b101: begin
          optype = instr[30] ? `OPTYPE_SRAI : `OPTYPE_SRLI;
          imm    = {26'b0, instr[24:20]};
        end
      endcase
    end

    `R_TYPE: begin
      imm = `ZERO;
      case (funct3)
        3'b000: optype = instr[30] ? `OPTYPE_SUB : `OPTYPE_ADD;
        3'b001: optype = `OPTYPE_SLL;
        3'b010: optype = `OPTYPE_SLT;
        3'b011: optype = `OPTYPE_SLTU;
        3'b100: optype = `OPTYPE_XOR;
        3'b101: optype = instr[30] ? `OPTYPE_SRA : `OPTYPE_SRL;
        3'b110: optype = `OPTYPE_OR;
        3'b111: optype = `OPTYPE_AND;
      endcase
    end
    
    `S_TYPE: begin
      rd  = `REG_ZERO;
      imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
      case (funct3)
        3'b000: optype = `OPTYPE_SB;
        3'b001: optype = `OPTYPE_SH;
        3'b010: optype = `OPTYPE_SW;
      endcase
    end

    default begin
      imm     = `ZERO;
      optype  = `NOP;
    end
      
  endcase

end

endmodule
