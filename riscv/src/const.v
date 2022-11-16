`define TRUE              1'b1
`define FALSE             1'b0

// index range
`define ADDR_IDX          16:0
`define DATA_IDX_RANGE    31:0
`define ICACHE_TAG_RANGE  31:8
`define ICACHE_IDX_RANGE   7:0
`define MEM_IDX_RANGE      7:0

// constant for size
`define ICACHE_SIZE 256
`define ADDR_WIDTH   17

// Instruction relevant
`define OPCODE_RANGE       6:0
`define BRANCH_TYPE        7'b1100011
`define JAL_TYPE           7'b1101111