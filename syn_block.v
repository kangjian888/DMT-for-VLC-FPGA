// =============================================================================
// Filename: syn_block.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:This module transform asynchrounous signal to a 
// specific domain. We use four flip-flops in this module to do
// this work
// -----------------------------------------------------------------------------
`timescale 1 ns / 1 ps

(*dont_touch = "yes" *)
module  syn_block #(
	parameter INITIALISE = 1'b0,
	parameter DEPTH = 5
)

(
	input clk,//clock to be sync'ed to
	input data_in,//data to be synced
  input enable,
	output data_out//synced data
);
//------------------------------- Internal Signal ----------------------------------------
	wire data_sync0;
	wire data_sync1;
	wire data_sync2;
	wire data_sync3;
	wire data_sync4;
	wire data_sync5;
//-----------------------------------------------------------------------------

  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  FDRE #(
    .INIT (INITIALISE[0])
  ) data_sync_reg0 (
    .C  (clk),
    .D  (data_in),
    .Q  (data_sync0),
	.CE (enable),
    .R  (1'b0)
  );

  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  FDRE #(
   .INIT (INITIALISE[0])
  ) data_sync_reg1 (
  .C  (clk),
  .D  (data_sync0),
  .Q  (data_sync1),
  .CE (enable),
  .R  (1'b0)
  );

  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  FDRE #(
   .INIT (INITIALISE[0])
  ) data_sync_reg2 (
  .C  (clk),
  .D  (data_sync1),
  .Q  (data_sync2),
  .CE (enable),
  .R  (1'b0)
  );

  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  FDRE #(
   .INIT (INITIALISE[0])
  ) data_sync_reg3 (
  .C  (clk),
  .D  (data_sync2),
  .Q  (data_sync3),
  .CE (enable),
  .R  (1'b0)
  );

  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  FDRE #(
   .INIT (INITIALISE[0])
  ) data_sync_reg4 (
  .C  (clk),
  .D  (data_sync3),
  .Q  (data_sync4),
  .CE (enable),
  .R  (1'b0)
  );

  assign data_out = data_sync4;

endmodule