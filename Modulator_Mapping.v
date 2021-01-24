// =============================================================================
// Filename: Modulator_Mapping.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description: Output is 14bits, the first bit is sign bit, 1 bit is integer, 12 bits is fraction.
// -----------------------------------------------------------------------------
module Modulator_Mapping(
	input SYMBOL_CLK,
	input RST,
    input [15:0] SUBCARRIER_INDEX,
	input [3:0] ALLOCATED_BIT_NUM,
	input [9:0] PARALLEL_BIT_IN,
    input PARALLEL_BIT_IN_VALID,
	output reg [27:0] MODULATED_DATA_OUT_RE,
    output reg [27:0] MODULATED_DATA_OUT_IM,
    output reg MODULATED_DATA_OUT_VALID,
    output reg [15:0] MODULATED_DATA_OUT_INDEX
);

wire [13:0] energy_on_each_subcarrier;//1 bit is sign, 1 bit is interger, 12 bits are fractional
Energy_Allocation_Mem Energy_Allocation_Mem_Inst (
  .clka(SYMBOL_CLK),    // input wire clka
  .ena(PARALLEL_BIT_IN_VALID),      // input wire ena
  .wea(1'b0),      // input wire [0 : 0] wea
  .addra(SUBCARRIER_INDEX),  // input wire [15 : 0] addra
  .dina(14'd0),    // input wire [13 : 0] dina
  .douta(energy_on_each_subcarrier)  // output wire [13 : 0] douta
);

// register or wire used inner module
reg [13:0] modualted_data_without_energy_mul_re;
reg [13:0] modualted_data_without_energy_mul_im;
reg modualted_data_without_energy_mul_valid;
reg [15:0] modualted_data_without_energy_mul_index;

always @ (posedge SYMBOL_CLK)
    begin
        if(RST)
            begin
        	   modualted_data_without_energy_mul_re <= 14'd0;
               modualted_data_without_energy_mul_im <= 14'd0;
            end
        else
            begin
                if (PARALLEL_BIT_IN_VALID) 
                    begin
                        modualted_data_without_energy_mul_valid <= 1'b1;
                        modualted_data_without_energy_mul_index <= SUBCARRIER_INDEX;
                        if (ALLOCATED_BIT_NUM == 4'd0) 
                         begin
                            modualted_data_without_energy_mul_re <= 14'd0;
                            modualted_data_without_energy_mul_im <= 14'd0;   
                         end
                        else if (ALLOCATED_BIT_NUM == 4'd1)
                            begin
                                case (PARALLEL_BIT_IN[9]) 
                                    1'b0:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1100_0000_0000_00;
                                            modualted_data_without_energy_mul_im <= 14'd0;
                                        end
                                    1'b1:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0100_0000_0000_00;
                                            modualted_data_without_energy_mul_im <= 14'd0;
                                        end
                                endcase
                            end
                        else if (ALLOCATED_BIT_NUM == 4'd2) 
                            begin
                                case (PARALLEL_BIT_IN[9]) 
                                    1'b0:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1101_0010_1100_00;
                                        end
                                    1'b1:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0010_1101_0100_00;
                                        end
                                endcase
                                case (PARALLEL_BIT_IN[8]) 
                                    2'b0:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0010_1101_0100_00;
                                        end
                                    2'b1:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1101_0010_1100_00;
                                        end
                                endcase
                            end
                        else if(ALLOCATED_BIT_NUM == 4'd3)
                             begin
                                case (PARALLEL_BIT_IN[9:8]) 
                                    2'b00:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1011_0001_1001_11;
                                        end
                                    2'b01:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1110_0101_1110_00;
                                        end
                                    2'b11:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0001_1010_0010_00;
                                        end
                                    2'b10:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0100_1110_0110_01;
                                        end
                                endcase
                                case (PARALLEL_BIT_IN[7])
                                    1'b0:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0001_1010_0010_00;
                                        end
                                    1'b1:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1110_0101_1110_00;
                                        end                         
                                endcase
                             end
                        else if(ALLOCATED_BIT_NUM == 4'd4)
                            begin
                                case (PARALLEL_BIT_IN[9:8]) 
                                    2'b00:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1100_0011_0100_10;
                                        end
                                    2'b01:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1110_1011_1100_01;
                                        end
                                    2'b11:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0001_0100_0011_11;
                                        end
                                    2'b10:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0011_1100_1011_10;
                                        end
                                endcase
                                case (PARALLEL_BIT_IN[7:6])
                                    2'b00:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0011_1100_1011_10;
                                        end
                                    2'b01:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0001_0100_0011_11;
                                        end
                                    2'b11:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1110_1011_1100_01;
                                        end
                                    2'b10:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1100_0011_0100_10;
                                        end                        
                                endcase
                            end
                        else if(ALLOCATED_BIT_NUM == 4'd5)      
                            begin
                                case (PARALLEL_BIT_IN[9:5]) 
                                    5'b00000:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1101_0101_0001_00;
                                            modualted_data_without_energy_mul_im <= 14'b0100_0111_1000_11;
                                        end
                                    5'b00001:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1111_0001_1011_00;
                                            modualted_data_without_energy_mul_im <= 14'b0100_0111_1000_11;
                                        end
                                    5'b10001:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0000_1110_0101_00;
                                            modualted_data_without_energy_mul_im <= 14'b0100_0111_1000_11;
                                        end
                                    5'b10000:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0010_1010_1111_00;
                                            modualted_data_without_energy_mul_im <= 14'b0100_0111_1000_11;
                                        end
                                    5'b00100:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1011_1000_0111_01;
                                            modualted_data_without_energy_mul_im <= 14'b0010_1010_1111_00;
                                        end
                                    5'b01100:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1101_0101_0001_00;
                                            modualted_data_without_energy_mul_im <= 14'b0010_1010_1111_00;
                                        end
                                    5'b01000:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1111_0001_1011_00;
                                            modualted_data_without_energy_mul_im <= 14'b0010_1010_1111_00;
                                        end
                                    5'b11000:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0000_1110_0101_00;
                                            modualted_data_without_energy_mul_im <= 14'b0010_1010_1111_00;
                                        end
                                    5'b11100:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0010_1010_1111_00;
                                            modualted_data_without_energy_mul_im <= 14'b0010_1010_1111_00;
                                        end
                                    5'b10100:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0100_0111_1000_11;
                                            modualted_data_without_energy_mul_im <= 14'b0010_1010_1111_00;
                                        end
                                    5'b00101:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1011_1000_0111_01;
                                            modualted_data_without_energy_mul_im <= 14'b0000_1110_0101_00;
                                        end
                                    5'b01101:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1101_0101_0001_00;
                                            modualted_data_without_energy_mul_im <= 14'b0000_1110_0101_00;
                                        end
                                    5'b01001:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1111_0001_1011_00;
                                            modualted_data_without_energy_mul_im <= 14'b0000_1110_0101_00;
                                        end
                                    5'b11001:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0000_1110_0101_00;
                                            modualted_data_without_energy_mul_im <= 14'b0000_1110_0101_00;
                                        end
                                    5'b11101:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0010_1010_1111_00;
                                            modualted_data_without_energy_mul_im <= 14'b0000_1110_0101_00;
                                        end
                                    5'b10101:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0100_0111_1000_11;
                                            modualted_data_without_energy_mul_im <= 14'b0000_1110_0101_00;
                                        end
                                    5'b00111:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1011_1000_0111_01;
                                            modualted_data_without_energy_mul_im <= 14'b1111_0001_1011_00;
                                        end
                                    5'b01111:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1101_0101_0001_00;
                                            modualted_data_without_energy_mul_im <= 14'b1111_0001_1011_00;
                                        end
                                    5'b01011:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1111_0001_1011_00;
                                            modualted_data_without_energy_mul_im <= 14'b1111_0001_1011_00;
                                        end
                                    5'b11011:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0000_1110_0101_00;
                                            modualted_data_without_energy_mul_im <= 14'b1111_0001_1011_00;
                                        end
                                    5'b11111:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0010_1010_1111_00;
                                            modualted_data_without_energy_mul_im <= 14'b1111_0001_1011_00;
                                        end
                                    5'b10111:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0100_0111_1000_11;
                                            modualted_data_without_energy_mul_im <= 14'b1111_0001_1011_00;
                                        end
                                    5'b00110:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1011_1000_0111_01;
                                            modualted_data_without_energy_mul_im <= 14'b1101_0101_0001_00;
                                        end
                                    5'b01110:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1101_0101_0001_00;
                                            modualted_data_without_energy_mul_im <= 14'b1101_0101_0001_00;
                                        end
                                    5'b01010:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1111_0001_1011_00;
                                            modualted_data_without_energy_mul_im <= 14'b1101_0101_0001_00;
                                        end
                                    5'b11010:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0000_1110_0101_00;
                                            modualted_data_without_energy_mul_im <= 14'b1101_0101_0001_00;
                                        end
                                    5'b11110:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0010_1010_1111_00;
                                            modualted_data_without_energy_mul_im <= 14'b1101_0101_0001_00;
                                        end
                                    5'b10110:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0100_0111_1000_11;
                                            modualted_data_without_energy_mul_im <= 14'b1101_0101_0001_00;
                                        end
                                    5'b00010:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1101_0101_0001_00;
                                            modualted_data_without_energy_mul_im <= 14'b1011_1000_0111_01;
                                        end
                                    5'b00011:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1111_0001_1011_00;
                                            modualted_data_without_energy_mul_im <= 14'b1011_1000_0111_01;
                                        end
                                    5'b10011:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0000_1110_0101_00;
                                            modualted_data_without_energy_mul_im <= 14'b1011_1000_0111_01;
                                        end
                                    5'b10010:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0010_1010_1111_00;
                                            modualted_data_without_energy_mul_im <= 14'b1011_1000_0111_01;
                                        end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
                                endcase
                            end 
                        else if(ALLOCATED_BIT_NUM == 4'd6)
                            begin
                                case (PARALLEL_BIT_IN[9:7]) 
                                    3'b000:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1011_1010_1110_00;
                                        end
                                    3'b001:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1100_1110_1010_00;
                                        end
                                    3'b011:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1110_0010_0110_00;
                                        end
                                    3'b010:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b1111_0110_0010_00;
                                        end
                                    3'b110:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0000_1001_1110_00;
                                        end
                                    3'b111:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0001_1101_1010_00;
                                        end
                                    3'b101:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0011_0001_0110_00;
                                        end
                                    3'b100:
                                        begin
                                            modualted_data_without_energy_mul_re <= 14'b0100_0101_0010_00;
                                        end                                        
                                endcase
                                case (PARALLEL_BIT_IN[6:4])
                                    3'b000:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0100_0101_0010_00;
                                        end
                                    3'b001:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0011_0001_0110_00;
                                        end
                                    3'b011:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0001_1101_1010_00;
                                        end
                                    3'b010:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b0000_1001_1110_00;
                                        end 
                                    3'b110:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1111_0110_0010_00;
                                        end
                                    3'b111:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1110_0010_0110_00;
                                        end
                                    3'b101:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1100_1110_1010_00;
                                        end
                                    3'b100:
                                        begin
                                            modualted_data_without_energy_mul_im <= 14'b1011_1010_1110_00;
                                        end                                                               
                                endcase
                            end
                        else if(ALLOCATED_BIT_NUM == 4'd7)
                            begin
                                if (PARALLEL_BIT_IN[9:6] == 4'b0011 || PARALLEL_BIT_IN[9:6] == 4'b0010 || PARALLEL_BIT_IN[9:6] == 4'b0110 || PARALLEL_BIT_IN[9:6] == 4'b0111 || PARALLEL_BIT_IN[9:6] == 4'b0101 || PARALLEL_BIT_IN[9:6] == 4'b0100 || PARALLEL_BIT_IN[9:6] == 4'b1100 || PARALLEL_BIT_IN[9:6] == 4'b1101 || PARALLEL_BIT_IN[9:6] == 4'b1111 || PARALLEL_BIT_IN[9:6] == 4'b1110 || PARALLEL_BIT_IN[9:6] == 4'b1010 || PARALLEL_BIT_IN[9:6] == 4'b1011 ) 
                                    begin
                                        case(PARALLEL_BIT_IN[9:6]) 
                                            4'b0011:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1011_0010_0100_00;
                                                end
                                            4'b0010:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1100_0000_0110_01;
                                                end
                                            4'b0110:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1100_1110_1000_10;
                                                end
                                            4'b0111:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1101_1100_1010_10;
                                                end
                                            4'b0101:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1110_1010_1100_11;
                                                end
                                            4'b0100:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1111_1000_1111_00;
                                                end
                                            4'b1100:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0000_0111_0001_00;
                                                end 
                                            4'b1101:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0001_0101_0011_01;
                                                end
                                            4'b1111:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0010_0011_0101_10;
                                                end
                                            4'b1110:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0011_0001_0111_10;
                                                end
                                            4'b1010:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0011_1111_1001_11;
                                                end 
                                            4'b1011:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0100_1101_1100_00;
                                                end                                                                                                                                                                                                        
                                        endcase
                                        case (PARALLEL_BIT_IN[5:3]) 
                                            3'b000:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b0011_0001_0111_10;
                                                end
                                            3'b001:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b0010_0011_0101_10;
                                                end
                                            3'b011:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b0001_0101_0011_01;
                                                end
                                            3'b010:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b0000_0111_0001_00;
                                                end
                                            3'b110:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b1111_1000_1111_00;
                                                end
                                            3'b111:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b1110_1010_1100_11;
                                                end
                                            3'b101:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b1101_1100_1010_10;
                                                end
                                            3'b100:
                                                begin
                                                    modualted_data_without_energy_mul_im <= 14'b1100_1110_1000_10;
                                                end                                                                                                                                                                                                                                                                                                
                                        endcase                                        
                                    end
                                else 
                                    begin
                                        case (PARALLEL_BIT_IN[9:3]) 
                                            7'b0000001:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1100_1110_1000_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b0001001:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1101_1100_1010_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b0001011:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1110_1010_1100_11;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b0000011:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1111_1000_1111_00;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b1000011:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0000_0111_0001_00;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b1001011:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0001_0101_0011_01;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b1001001:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0010_0011_0101_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b1000001:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0011_0001_0111_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0100_1101_1100_00;
                                                end
                                            7'b0000000:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1100_1110_1000_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b0001000:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1101_1100_1010_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b0001010:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1110_1010_1100_11;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b0000010:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1111_1000_1111_00;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b1000010:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0000_0111_0001_00;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b1001010:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0001_0101_0011_01;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b1001000:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0010_0011_0101_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b1000000:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0011_0001_0111_10;
                                                    modualted_data_without_energy_mul_im <= 14'b0011_1111_1001_11;
                                                end
                                            7'b0000100:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1100_1110_1000_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b0001100:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1101_1100_1010_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b0001110:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1110_1010_1100_11;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b0000110:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1111_1000_1111_00;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b1000110:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0000_0111_0001_00;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b1001110:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0001_0101_0011_01;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b1001100:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0010_0011_0101_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b1000100:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0011_0001_0111_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1100_0000_0110_01;
                                                end
                                            7'b0000101:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1100_1110_1000_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end
                                            7'b0001101:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1101_1100_1010_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end
                                            7'b0001111:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1110_1010_1100_11;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end
                                            7'b0000111:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b1111_1000_1111_00;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end
                                            7'b1000111:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0000_0111_0001_00;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end
                                            7'b1001111:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0001_0101_0011_01;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end
                                            7'b1001101:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0010_0011_0101_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end
                                            7'b1000101:
                                                begin
                                                    modualted_data_without_energy_mul_re <= 14'b0011_0001_0111_10;
                                                    modualted_data_without_energy_mul_im <= 14'b1011_0010_0100_00;
                                                end                                                                                                                                                                                                                                               
                                        endcase
                                    end

                            end
                        else if(ALLOCATED_BIT_NUM == 4'd8)
                            begin
                                case (PARALLEL_BIT_IN[9:6]) 
                                    4'b0000:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1011_0110_0110_00;
                                        end
                                    4'b0001:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1100_0000_0011_00;
                                        end
                                    4'b0011:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1100_1010_0000_00;
                                        end
                                    4'b0010:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1101_0011_1101_01;
                                        end 
                                    4'b0110:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1101_1101_1010_01;
                                        end
                                    4'b0111:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1110_0111_0111_01;
                                        end
                                    4'b0101:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1111_0001_0100_10;
                                        end
                                    4'b0100:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b1111_1011_0001_10;
                                        end 
                                    4'b1100:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0000_0100_1110_10;
                                        end
                                    4'b1101:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0000_1110_1011_10;
                                        end
                                    4'b1111:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0001_1000_1000_11;
                                        end
                                    4'b1110:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0010_0010_0101_11;
                                        end 
                                    4'b1010:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0010_1100_0010_11;
                                        end
                                    4'b1011:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0011_0110_0000_00;
                                        end
                                    4'b1001:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0011_1111_1101_00;
                                        end
                                    4'b1000:
                                        begin
                                            modualted_data_without_energy_mul_re <=14'b0100_1001_1010_00;
                                        end                                                                                                                        
                                endcase
                                case (PARALLEL_BIT_IN[5:2]) 
                                    4'b0000:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0100_1001_1010_00;
                                        end
                                    4'b0001:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0011_1111_1101_00;
                                        end
                                    4'b0011:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0011_0110_0000_00;
                                        end
                                    4'b0010:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0010_1100_0010_11;
                                        end 
                                    4'b0110:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0010_0010_0101_11;
                                        end
                                    4'b0111:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0001_1000_1000_11;
                                        end
                                    4'b0101:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0000_1110_1011_10;
                                        end
                                    4'b0100:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b0000_0100_1110_10;
                                        end 
                                    4'b1100:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1111_1011_0001_10;
                                        end
                                    4'b1101:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1111_0001_0100_10;
                                        end
                                    4'b1111:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1110_0111_0111_01;
                                        end
                                    4'b1110:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1101_1101_1010_01;
                                        end 
                                    4'b1010:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1101_0011_1101_01;
                                        end
                                    4'b1011:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1100_1010_0000_00;
                                        end
                                    4'b1001:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1100_0000_0011_00;
                                        end
                                    4'b1000:
                                        begin
                                            modualted_data_without_energy_mul_im <=14'b1011_0110_0110_00;
                                        end 
                                endcase
                            end
//                        else if(ALLOCATED_BIT_NUM== 4'd9)
//                            begin
//
//                            end
//                        else if(ALLOCATED_BIT_NUM == 4'd10)
//                            begin
//
//                            end
                        else //maximum bit number per subcarrier is 10 bits
                            begin
                                modualted_data_without_energy_mul_re <= 14'd0;
                                modualted_data_without_energy_mul_im <= 14'd0;          
                            end                 
                    end
                else 
                    begin
                        modualted_data_without_energy_mul_re <= 14'd0;
                        modualted_data_without_energy_mul_im <= 14'd0;  
                        modualted_data_without_energy_mul_valid <= 1'b0;
                        modualted_data_without_energy_mul_index <= 16'd0;                        
                    end        	   
            end
    end
//multiply the modulation result with the normalized energy value
wire [27:0] data_real_mul_output;
wire [27:0] data_imag_mul_output;

energy_mul_real energy_mul_real_inst (
  .CLK(SYMBOL_CLK),    // input wire CLK
  .A(modualted_data_without_energy_mul_re),        // input wire [13 : 0] A
  .B(energy_on_each_subcarrier),        // input wire [13 : 0] B
  .SCLR(RST),  // input wire SCLR
  .P(data_real_mul_output)        // output wire [27 : 0] P
);

energy_mul_imag energy_mul_imag_inst (
  .CLK(SYMBOL_CLK),    // input wire CLK
  .A(modualted_data_without_energy_mul_im),        // input wire [13 : 0] A
  .B(energy_on_each_subcarrier),        // input wire [13 : 0] B
  .SCLR(RST),  // input wire SCLR
  .P(data_imag_mul_output)        // output wire [27 : 0] P
);
 
//Delay modualted_data_without_energy_mul_valid 3 cycles to align with the output 
wire [3:0] modualted_data_valid_temp;
wire modualted_data_valid_delay;
assign modualted_data_valid_temp[0] =  modualted_data_without_energy_mul_valid;
assign modualted_data_valid_delay = modualted_data_valid_temp[3];
generate
    genvar index_4;
    for (index_4 = 0; index_4 < 3; index_4 = index_4 + 1)
    begin:delay_4//Add name here
        FDRE #(
         .INIT (1'b0)
        ) data_sync_reg2 (
        .C  (SYMBOL_CLK),
        .D  (modualted_data_valid_temp[index_4]),
        .Q  (modualted_data_valid_temp[index_4+1]),
        .CE (1'b1),
        .R  (RST)
        );
    end
endgenerate
//Delay modualted_data_without_energy_mul_index to align with the output
reg [15:0] modualted_data_index_temp [2:0];
reg [15:0] modualted_data_index_delay;
generate
    genvar index_5;
    for (index_5 = 0; index_5 < 3; index_5 = index_5 + 1)
    begin:delay_5//Add name here
        always @ (posedge SYMBOL_CLK)
            begin
                if(RST)
                    begin
                        if (index_5 == 2) 
                            begin
                                modualted_data_index_delay <= 16'd0;
                            end
                        else 
                            begin
                                modualted_data_index_temp[index_5] <= 16'd0;                               
                            end
                    end
                else
                    begin
                        if (index_5 == 0) 
                            begin
                                modualted_data_index_temp[index_5] <= modualted_data_without_energy_mul_index;
                            end
                        else if(index_5 == 2)
                            begin
                                modualted_data_index_delay <= modualted_data_index_temp[index_5-1];
                            end
                        else 
                            begin
                                modualted_data_index_temp[index_5] <= modualted_data_index_temp[index_5-1];
                            end                      
                    end
            end
    end
endgenerate

//ouput stage
always @ (posedge SYMBOL_CLK)
    begin
        if(RST)
            begin
                MODULATED_DATA_OUT_RE <= 28'd0;
                MODULATED_DATA_OUT_IM <= 28'd0;
                MODULATED_DATA_OUT_VALID <= 1'b0;
                MODULATED_DATA_OUT_INDEX <= 16'd0;       
            end
        else
            begin
                MODULATED_DATA_OUT_RE <= data_real_mul_output;
                MODULATED_DATA_OUT_IM <= data_imag_mul_output;
                MODULATED_DATA_OUT_VALID <= modualted_data_valid_delay;
                MODULATED_DATA_OUT_INDEX <= modualted_data_index_delay;                 
            end
    end
endmodule