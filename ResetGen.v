// =============================================================================
// Filename: ResetGen.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:
// -----------------------------------------------------------------------------
module ResetGen(
    input SERIAL_CLK,
	input SYS_CLK,
    input SYMBOL_CLK,
	input LOCKED, //high active means
	output reg S_MCU_RST = 1'b0,//this is
    output reg S_MAC_RST = 1'b0,
    output reg S_SYM_RST = 1'b0
);

wire locked_sync_sys_clk;
reg locked_sync_sys_clk_continue = 1'b0;

//synchronized locked clock generation
syn_block sync_block_0(
	.clk(SYS_CLK),
	.data_in(LOCKED),
	.data_out(locked_sync_sys_clk),
	.enable(1'b1)
	);

// generate synchronized global reset signal in sys clock domain
always @ (posedge SYS_CLK)
    begin
        if(locked_sync_sys_clk &&!locked_sync_sys_clk_continue)
        	begin
        		S_MCU_RST <= 1'b1;
        		locked_sync_sys_clk_continue <= 1'b1;
        	end
        else if(!locked_sync_sys_clk)
        	begin
        		locked_sync_sys_clk_continue <= 1'b0;
        	end
        else 
            begin
                S_MCU_RST <= 1'b0;
            end
    end


wire locked_sync_serial_clk;
reg locked_sync_serial_clk_continue = 1'b0;
//synchronized locked clock generation
syn_block sync_block_1(
    .clk(SERIAL_CLK),
    .data_in(LOCKED),
    .data_out(locked_sync_serial_clk),
    .enable(1'b1)
    );

// generate synchronized global reset signal in serial clock domain
always @ (posedge SERIAL_CLK)
    begin
        if(locked_sync_serial_clk &&!locked_sync_serial_clk_continue)
            begin
                S_MAC_RST <= 1'b1;
                locked_sync_serial_clk_continue <= 1'b1;
            end
        else if(!locked_sync_serial_clk)
            begin
                locked_sync_serial_clk_continue <= 1'b0;
            end
        else 
            begin
                S_MAC_RST <= 1'b0;
            end
    end

wire locked_sync_symbol_clk;
reg locked_sync_symbol_clk_continue = 1'b0;
//synchronized locked clock generation
syn_block sync_block_2(
    .clk(SYMBOL_CLK),
    .data_in(LOCKED),
    .data_out(locked_sync_symbol_clk),
    .enable(1'b1)
    );

// generate synchronized global reset signal in serial clock domain
always @ (posedge SYMBOL_CLK)
    begin
        if(locked_sync_symbol_clk &&!locked_sync_symbol_clk_continue)
            begin
                S_SYM_RST <= 1'b1;
                locked_sync_symbol_clk_continue <= 1'b1;
            end
        else if(!locked_sync_symbol_clk)
            begin
                locked_sync_symbol_clk_continue <= 1'b0;
            end
        else 
            begin
                S_SYM_RST <= 1'b0;
            end
    end
endmodule