// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "IF/Icache.v"
`include "IF/InsFetcher.v"
`include "IF/Predictor.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire             io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		  // cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

// mc & mem(ram)
wire wr_mc2ram, ram_ena;
wire [`ADDR_IDX] addr_2ram;

// icache & mc
wire ena_mc_icache, valid_mc2icache;
wire [`DATA_IDX_RANGE] data_mc2icache;
wire [`ADDR_IDX] addr_2mc;

// dcache & mc
wire wr_ena;

// fetcher & icache
wire rd_ena_if_icache, instr_rdy_if_icache;
wire [`DATA_IDX_RANGE] pc_if_icache, instr_if_icache;

// fetcher & predictor
wire valid_if_pred;
wire [`DATA_IDX_RANGE] instr_2pred;
wire [`DATA_IDX_RANGE] curpc_2pred, nexpc_2if;

// fetcher & issue
wire valid_if_is, is_full;
wire [`DATA_IDX_RANGE] instr_if_is;

assign is_full       = `FALSE;
assign wr_ena        = `ZERO;

MemController MC (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .fet_ena(ena_mc_icache),
  .instr_addr(addr_2mc),
  .valid_2icache(valid_mc2icache),
  .data_2icache(data_mc2icache),

  .wr_ena(wr_ena),
  // .wr_from_dcache(),
  // .data_addr(),
  // .data_from_dcache(),

  .ram_ena(ram_ena),   // 空引脚?
  .wr_mc2ram(mem_wr),
  .addr_2ram(mem_a),
  .data_2ram(mem_dout),
  .data_from_ram(mem_din)
);

Predictor predictor (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .instr_valid(valid_if_pred),
  .instr_from_IC(instr_2pred),
  .cur_pc(curpc_2pred),
  .predict_pc(nexpc_2if)

  // .rob_commit_pc_arrived(),
  // .rob_commit_pc(),
  // .hit_res()
);

ICACHE icache (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .rdy_from_fet(rd_ena_if_icache),
  .pc(pc_if_icache),
  .instr_valid(instr_rdy_if_icache),
  .instr(instr_if_icache),

  .mc_ena(ena_mc_icache),
  .addr(addr_2mc),
  .valid_from_mc(valid_mc2icache),
  .data_from_mc(data_mc2icache)
);

InsFetcher fetcher (
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .rdy_2icache(rd_ena_if_icache),
  .pc_2icache(pc_if_icache),
  .instr_valid(instr_rdy_if_icache),
  .instr_from_icache(instr_if_icache),

  .valid_2pred(valid_if_pred),
  .instr_2pred(instr_2pred),
  .cur_pc(curpc_2pred),
  .next_pc(nexpc_2if),

  .is_full(is_full),
  .valid_2is(valid_if_is),
  .instr_2is(instr_if_is)
);


endmodule