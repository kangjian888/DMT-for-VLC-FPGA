// =============================================================================
// Filename: HermitianMapping.v
// Author: KANG, Jian
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description: Mapping the signal from one path to two. one of output is the original signaland the other path is the hermitian 
// -----------------------------------------------------------------------------
`timescale 1 ns / 1 ps
module HermitianMapping(
	input CLK,
	input RST,
	input [27:0] DATA_IN_RE,
	input [27:0] DATA_IN_IM,
	input [15:0] DATA_IN_INDEX,
	input DATA_IN_VALID,
	output reg [27:0] DATA_OUT_RE,
	output reg [27:0] DATA_OUT_IM,
	output reg [15:0] DATA_OUT_INDEX,
	output reg DATA_OUT_VALID, 
	output reg [27:0] DATA_OUT_RE_HER,
	output reg [27:0] DATA_OUT_IM_HER,
	output reg [15:0] DATA_OUT_INDEX_HER,
	output reg DATA_OUT_VALID_HER
);

wire [27:0] data_im_neg_temp;
Negetive Negetive_inst(
	.ori_data(DATA_IN_IM),
	.neg_data(data_im_neg_temp)
	);
always @ (posedge CLK)
    begin
        if(RST)
            begin
        	   DATA_OUT_IM <= 28'd0;
        	   DATA_OUT_RE <= 28'd0;
        	   DATA_OUT_INDEX <= 16'd0;
        	   DATA_OUT_VALID <= 1'b0;
        	   DATA_OUT_IM_HER <= 28'd0;
        	   DATA_OUT_RE_HER <= 28'd0;
        	   DATA_OUT_INDEX_HER <= 16'd0;
        	   DATA_OUT_VALID_HER <= 1'b0;
            end
        else
            begin
        	   if(DATA_IN_VALID) 
        	    begin
        	    	DATA_OUT_VALID <= DATA_IN_VALID;
        	   		DATA_OUT_INDEX <= DATA_IN_INDEX; //the 0~4 subcarrier carry nothing. 
        	   		DATA_OUT_RE <= DATA_IN_RE;
        	   		DATA_OUT_IM <= DATA_IN_IM;
        	    	DATA_OUT_VALID_HER <= DATA_IN_VALID;
        	   		DATA_OUT_INDEX_HER <= DATA_IN_INDEX;
        	   		DATA_OUT_RE_HER <= DATA_IN_RE;
        	   		DATA_OUT_IM_HER <= data_im_neg_temp;
        	   	end
        	   else 
        	   	begin
        	   		DATA_OUT_IM <= 28'd0;
        	   		DATA_OUT_RE <= 28'd0;
        	   		DATA_OUT_INDEX <= 16'd0;
        	   		DATA_OUT_VALID <= 1'b0;
        	   		DATA_OUT_IM_HER <= 28'd0;
        	   		DATA_OUT_RE_HER <= 28'd0;
        	   		DATA_OUT_INDEX_HER <= 16'd0;
        	   		DATA_OUT_VALID_HER <= 1'b0;        	   		
        	   	end
            end
    end

endmodule

//this is the sub module used to get the negetive number
module Negetive(
		input [27:0] ori_data,
		output reg [27:0] neg_data
);
always@(*)
begin
    if (ori_data == 0) 
        begin
           neg_data <= 28'd0;
        end
    else 
        begin
            if (ori_data[27] == 1) 
                begin
                    neg_data <= {1'b0,~(ori_data[26:0] - 1'b1)};
                end
            else 
                begin
                    neg_data <= {1'b1,~ori_data[26:0] + 1'b1};
                end             
        end
end
endmodule