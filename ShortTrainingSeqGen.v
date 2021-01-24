// =============================================================================
// Filename: ShortTrainingSeqGen.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description: 1 bit is sign, 3 bits are integer, the rest are fractional.
// -----------------------------------------------------------------------------
module ShortTrainingSeqGen(
	input SYS_CLK,
	input PHY_RST,
	input SHORT_ACK, //Short training sequence sending enable
	output reg [27:0] SHORT_TRAINING_SEQ,
	output reg [8:0] SHORT_TRAINING_SEQ_INDEX,
	output reg SHORT_TRAINING_SEQ_VALID
);

reg [3:0] frame_counter;
reg [4:0] symbol_counter;
reg [27:0] short_rom [31:0];

always @ (posedge SYS_CLK)
    begin
        if(PHY_RST)
        	begin
        		frame_counter <= 4'd0;
        		symbol_counter <= 5'd0;
        		SHORT_TRAINING_SEQ <= 28'd0;
        		SHORT_TRAINING_SEQ_VALID <= 1'b0;
        		SHORT_TRAINING_SEQ_INDEX <= 9'd0;
        		short_rom[0] <=  28'b0000_0000_1011_1100_0110_1001_0011;
        		short_rom[1] <=  28'b1111_1111_0000_0000_0010_1010_0001;
        		short_rom[2] <=  28'b0000_0010_0001_1110_0111_1101_0101;
        		short_rom[3] <=  28'b1111_1110_1111_1001_0111_1001_1001;
        		short_rom[4] <=  28'b1111_1111_1100_1000_1101_0000_1101;
        		short_rom[5] <=  28'b0000_0000_1011_1111_1011_1111_0101;
        		short_rom[6] <=  28'b1111_1101_1011_0111_0100_0110_0100;
        		short_rom[7] <=  28'b1111_1111_1111_1110_0110_1011_1100;
        		short_rom[8] <=  28'b0000_0001_0111_1000_1101_0010_0110;
        		short_rom[9] <=  28'b0000_0000_0000_0001_1001_0100_0100;
        		short_rom[10] <= 28'b1111_1101_1011_0111_0100_0110_0100;
        		short_rom[11] <= 28'b1111_1111_0100_0000_0100_0000_1011;
        		short_rom[12] <= 28'b1111_1111_1100_1000_1101_0000_1101;
        		short_rom[13] <= 28'b0000_0001_0000_0110_1000_0110_0111;
        		short_rom[14] <= 28'b0000_0010_0001_1110_0111_1101_0101;
        		short_rom[15] <= 28'b0000_0000_1111_1111_1101_0101_1111;
        		short_rom[16] <= 28'b0000_0000_1011_1100_0110_1001_0011;
        		short_rom[17] <= 28'b0000_0000_1100_0001_0101_0001_0010;
        		short_rom[18] <= 28'b1111_1111_1111_0110_0110_1010_1100;
        		short_rom[19] <= 28'b1111_1110_0000_1111_1011_1011_0000;
        		short_rom[20] <= 28'b1111_1110_1011_1110_0101_1100_1101;
        		short_rom[21] <= 28'b1111_1110_0101_1110_0101_1101_0101;
        		short_rom[22] <= 28'b0000_0000_0011_0011_1101_0001_1011;
        		short_rom[23] <= 28'b0000_0001_1101_0111_1111_0111_1001;
        		short_rom[24] <= 28'b0000_0000_0000_0000_0000_0000_0000;
        		short_rom[25] <= 28'b1111_1110_0010_1000_0000_1000_0111;
        		short_rom[26] <= 28'b0000_0000_0011_0011_1101_0001_1011;
        		short_rom[27] <= 28'b0000_0001_1010_0001_1010_0010_1011;
        		short_rom[28] <= 28'b1111_1110_1011_1110_0101_1100_1101;
        		short_rom[29] <= 28'b0000_0001_1111_0000_0100_0101_0000;
        		short_rom[30] <= 28'b1111_1111_1111_0110_0110_1010_1100;
        		short_rom[31] <= 28'b1111_1111_0011_1110_1010_1110_1110;
        	end
        else
        	begin
        		if (SHORT_ACK) 
        		    begin
        		        if (frame_counter <= 4'd9) 
        		            begin
        		                if (symbol_counter < 5'd31) 
        		                    begin
        		                        SHORT_TRAINING_SEQ <= short_rom[symbol_counter];
        		                        SHORT_TRAINING_SEQ_VALID <= 1'b1;
        		                        symbol_counter <= symbol_counter + 1'b1;
        		                        SHORT_TRAINING_SEQ_INDEX <= SHORT_TRAINING_SEQ_INDEX + 1'b1;
        		                        if (symbol_counter == 5'd0 && frame_counter == 4'd0) 
        		                            begin
        		                                SHORT_TRAINING_SEQ <= $signed(short_rom[symbol_counter]) >>> 1;
        		                            end
        		                    end
        		                else 
        		                    begin
        		                        SHORT_TRAINING_SEQ <= short_rom[symbol_counter];
        		                        SHORT_TRAINING_SEQ_INDEX <= SHORT_TRAINING_SEQ_INDEX + 1'b1;
        		                        SHORT_TRAINING_SEQ_VALID <= 1'b1;
        		                        symbol_counter <= 5'd0;
        		                        frame_counter <= frame_counter + 1'b1;
        		                    end
        		            end
        		        else 
        		            begin
        		                frame_counter <= 4'd0;
        		                SHORT_TRAINING_SEQ <= $signed(short_rom[symbol_counter]) >>> 1;
        		                SHORT_TRAINING_SEQ_INDEX <= SHORT_TRAINING_SEQ_INDEX + 1'b1;
        		            end
        		    end
        		else 
        		    begin
        		        SHORT_TRAINING_SEQ <= 28'd0;
        		        SHORT_TRAINING_SEQ_VALID <= 1'b0;
        		        SHORT_TRAINING_SEQ_INDEX <= 9'd0;
        		        frame_counter <= 4'd0;
        		        symbol_counter <= 5'd0;
        		    end
        	end
    end

endmodule
