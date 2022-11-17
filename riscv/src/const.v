`define TRUE              1'b1
`define FALSE             1'b0
`define ZERO             32'b0
`define ONE              32'b1

// i$ relevant
`define ICACHE_ENTRY            256
`define ICACHE_BLOCK_RANGE    127:0  // each entry with 4 instructions
`define ICACHE_TAG_RANGE       31:12
`define ICACHE_IDX_RANGE       11:4
`define INSTR_RANGE             3:2

// index range
`define ADDR_IDX          16:0
`define DATA_IDX_RANGE    31:0
`define MEM_IDX_RANGE      7:0

// constant for size
`define ADDR_WIDTH   17

// Instruction relevant
`define OPCODE_RANGE       6:0
`define BRANCH_TYPE        7'b1100011
`define JAL_TYPE           7'b1101111