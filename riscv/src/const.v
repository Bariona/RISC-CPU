// `define Debug 
// ↑ enable Debug mode

// consts
`define TRUE              1'b1
`define FALSE             1'b0
`define ZERO             32'b0
`define REG_ZERO          5'h00
`define ONE              32'b1
`define LOAD_MEM          1'b0
`define STORE_MEM         1'b1

// i$ relevant
`define ICACHE_ENTRY            128
`define ICACHE_INSTR_CNT        512
// `define ICACHE_BLOCK_RANGE    127:0  // each entry with 4 instructions
`define BLOCK_IDX_CNT            2
`define ICACHE_TAG_RANGE       31:11
`define PC_IDX_RANGE           10:4
`define PC_INSTR_RANGE          3:2

`define ICACHE_BLK_IDX_RANGE    8:0
`define ICACHE_IDX_RANGE        6:0

`define INSTR_RANGE             3:2
`define INSTR_PER_BYTE           4
`define BLOCK_INS_CNT          32'h4

// index range
`define ADDR_IDX          31:0
`define DATA_IDX_RANGE    31:0
`define MEM_IDX_RANGE      7:0

// ROB
`define ROB_SIZE           32
`define ROB_ID_RANGE       4:0
`define RENAMED_ZERO      5'h00 // means don't have to be renamed

// RS
`define RS_SIZE      16 // 16
`define RS_IDX_RANGE 4:0 // 4:0


// LSB
`define LSB_SIZE            16
`define LSB_ID_RANGE       4:0

// constant for size
`define ADDR_WIDTH          17
`define ADDR_RANGE        16:0

// regsiterFile 
`define REG_SIZE            32
`define REG_RANGE          4:0

// Instruction relevant
`define OPCODE_TYPE        6:0
`define OPCODE_RANGE       6:0
`define FUNCT3_RANGE      14:12
`define RD_IDX            11:7
`define RS1_IDX           19:15
`define RS2_IDX           24:20

`define LUI_TYPE        7'b0110111
`define AUIPC_TYPE      7'b0010111
`define JAL_TYPE        7'b1101111
`define JALR_TYPE       7'b1100111
`define L_TYPE          7'b0000011
`define B_TYPE          7'b1100011
`define R_TYPE          7'b0110011
`define S_TYPE          7'b0100011
`define A_TYPE          7'b0010011

`define NOP            6'd0
`define OPTYPE_LUI     6'd1
`define OPTYPE_AUIPC   6'd2

`define OPTYPE_JAL     6'd3
`define OPTYPE_JALR    6'd4

`define OPTYPE_BEQ     6'd5
`define OPTYPE_BNE     6'd6
`define OPTYPE_BLT     6'd7 
`define OPTYPE_BGE     6'd8
`define OPTYPE_BLTU    6'd9 
`define OPTYPE_BGEU    6'd10 

// === load/store ===
`define OPTYPE_LB      6'd11 
`define OPTYPE_LH      6'd12 
`define OPTYPE_LW      6'd13 
`define OPTYPE_LBU     6'd14 
`define OPTYPE_LHU     6'd15
 
`define OPTYPE_SB      6'd16 
`define OPTYPE_SH      6'd17 
`define OPTYPE_SW      6'd18 
// =============

`define OPTYPE_ADD     6'd19 
`define OPTYPE_SUB     6'd20 
`define OPTYPE_SLL     6'd21 
`define OPTYPE_SLT     6'd22 
`define OPTYPE_SLTU    6'd23 
`define OPTYPE_XOR     6'd24 
`define OPTYPE_SRL     6'd25 
`define OPTYPE_SRA     6'd26
`define OPTYPE_OR      6'd27 
`define OPTYPE_AND     6'd28

`define OPTYPE_ADDI    6'd29
`define OPTYPE_SLTI    6'd30
`define OPTYPE_SLTIU   6'd31
`define OPTYPE_XORI    6'd32
`define OPTYPE_ORI     6'd33
`define OPTYPE_ANDI    6'd34
`define OPTYPE_SLLI    6'd35
`define OPTYPE_SRLI    6'd36
`define OPTYPE_SRAI    6'd37