// =============================================================================
// Filename: MAC_PRBS.v
// Author: KANG, Jian
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:
// -----------------------------------------------------------------------------
`timescale 1 ns / 1 ps
module MAC_PRBS(
	input SERIAL_CLK,//the frequency of the clock is 200Mhz 
	input MAC_RST,
  input PHY_RST, //this is improve every the content of every frame is the same
	input READ_ENABLE,
	output reg DATA_OUTPUT,
  output reg DATA_OUTPUT_VALID	
);


//inner reg and wire
reg data_out_valid;
wire data_output;
PRBS_ANY #(
  //--------------------------------------------		
  // Configuration parameters
  //--------------------------------------------		
   .CHK_MODE(0),
   .INV_PATTERN(0),
   .POLY_LENGHT(7),
   .POLY_TAP(1),
   .NBITS(1)
)
PRBS_ANY_inst( //--------------------------------------------		
  // Input/Outputs
  //--------------------------------------------		
   .RST(MAC_RST|PHY_RST),
   .CLK(SERIAL_CLK),
   .DATA_IN(1'd0),
   .EN(READ_ENABLE),
   .DATA_OUT(data_output)
);

//DATA_OUT_VALID generation
always @ (posedge SERIAL_CLK)
    begin
        if(MAC_RST|PHY_RST)
            begin
                data_out_valid <=1'b0;
            end
        else
            begin
                data_out_valid <= READ_ENABLE;
            end
    end
//Output stage register
always @ (posedge SERIAL_CLK)
    begin
        if(MAC_RST|PHY_RST)
            begin
                DATA_OUTPUT_VALID <= 1'b0;
                DATA_OUTPUT <= 1'b0;
            end
        else
            begin
                if (data_out_valid) 
                  begin
                    DATA_OUTPUT_VALID <= 1'b1;
                    DATA_OUTPUT <= data_output;
                  end
                else 
                  begin
                    DATA_OUTPUT_VALID <= 1'b0;
                    DATA_OUTPUT <= 1'b0;
                  end
            end
    end
endmodule