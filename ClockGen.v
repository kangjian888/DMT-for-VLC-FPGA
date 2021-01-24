// =============================================================================
// Filename: ClockGen.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:
// -----------------------------------------------------------------------------
module ClockGen(
	input SYS_CLK_P,
	input SYS_CLK_N,
	input A_GLB_RST, //global reset input
  input DAC_CLK_ENABLE,
	output LOCKED,
  output DAC_CLK,
  output SERIAL_CLK,
  output SYMBOL_CLK,
	output SYS_CLK		
);

clk_gen clk_gen_inst
 (
  // Clock out ports
  .serial_clk(SERIAL_CLK),     // output serial_clk
  .symbol_clk(SYMBOL_CLK),     // output symbol_clk
  .sys_clk(SYS_CLK),     // output sys_clk
  .dac_clk(DAC_CLK),
  .dac_clk_ce(DAC_CLK_ENABLE),
  // Status and control signals
  .reset(A_GLB_RST), // input reset
  .locked(LOCKED),       // output locked
 // Clock in ports
  .clk_in1_p(SYS_CLK_P),    // input clk_in1_p
  .clk_in1_n(SYS_CLK_N));    // input clk_in1_n


endmodule