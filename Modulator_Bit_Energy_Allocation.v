// =============================================================================
// Filename: Modulator_Bit_Energy_Allocation.v
// Author: KANG, Jian
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description: Each subcarrier could send 10 bits.
// -----------------------------------------------------------------------------
`timescale 1 ns / 1 ps
module Modulator_Bit_Energy_Allocation#(
    parameter USED_SUBCARRIER = 59//the range is from 0-65535
)
(
	input SERIAL_CLK, //200Mhz
    input SYMBOL_CLK,
	input DATA_REQ,
    input RST,
	input DATA_IN,
	input DATA_IN_VALID,
	output reg DATA_IN_READY,
    output reg [15:0] SUBCARRIER_INDEX,
    output reg [3:0] ALLOCATED_BIT_NUM,
    output reg [9:0] PARALLEL_DATA_OUTPUT,
    output reg PARALLEL_DATA_OUTPUT_VALID
);

reg [0:0] state_reg, state_next;
reg [3:0] bit_counter_reg, bit_counter_next;
reg [15:0] carrier_counter_reg, carrier_counter_next;
reg [3:0] bit_counter_one_beat;
reg [15:0] carrier_counter_one_beat;
reg [0:0] state_reg_one_beat;
reg [15:0] carrier_counter_two_beats;
reg [3:0] bit_counter_two_beats;
reg [0:0] state_reg_two_beats;
reg [3:0] bit_counter_three_beats;
reg [0:0] state_reg_three_beats;
reg [0:0] state_reg_four_beats;
reg [3:0] bit_counter_four_beats;
reg [3:0] bit_counter_five_beats;
reg [0:0] state_reg_five_beats;

reg data_in_ready;
// memory to store the bit and energy allcoation information
reg read_allocation_enable;
wire [3:0] bit_num;
Bit_Allocation_Mem Bit_Allocation_Mem_inst(
  .clka(SERIAL_CLK),    // input wire clka
  .ena(read_allocation_enable),      // input wire ena
  .wea(1'b0),      // input wire [0 : 0] wea
  .addra(carrier_counter_reg),  // input wire [15 : 0] addra
  .dina(4'd0),    // input wire [3 : 0] dina
  .douta(bit_num)  // output wire [3 : 0] douta
);


localparam IDLE = 0;
localparam MODULATION=1;
//Output add register stage for time constrain
always @ (posedge SERIAL_CLK)
    begin
        if(RST)
            begin
               DATA_IN_READY <= 1'b0;
            end
        else
            begin
               DATA_IN_READY <= data_in_ready;
            end
    end
//Outputs2
always @ (*)
    begin
        if (state_reg_two_beats) 
            begin
                if (bit_counter_two_beats < bit_num) 
                    begin
                        data_in_ready <= 1'b1;
                    end
                else 
                    begin
                        data_in_ready <= 1'b0;
                    end
            end
        else 
            begin
                data_in_ready <= 1'b0;
            end
    end
//Outputs
always @ (*) 
    begin
        case (state_reg)
            IDLE:
                begin
                    read_allocation_enable = 1'b0;
                end
            MODULATION:
                begin
                    read_allocation_enable = 1'b1; 
                end
            default:
                begin
                    read_allocation_enable = 1'b0;
                end
        endcase
    end

//States
always @ (*)
    begin
        state_next = state_reg;
        carrier_counter_next = carrier_counter_reg;
        bit_counter_next = bit_counter_reg;
        case (state_reg)
            IDLE:
                begin
                	if (DATA_REQ) 
                	    begin
                	        state_next = MODULATION;		
                		end
                	else 
                		begin
                			state_next = IDLE;
                		end
                end
            MODULATION:
                begin  
                    if (carrier_counter_reg == USED_SUBCARRIER - 1) 
                        begin
                         if (bit_counter_reg == 16'd9) 
                            begin
                                bit_counter_next = 0;
                                carrier_counter_next = 0;
                                if (DATA_REQ) //keep the modualtion could be transmitted continously
                                    begin
                                        state_next = MODULATION;
                                    end
                                else 
                                    begin
                                        state_next = IDLE;
                                    end
                            end
                        else 
                            begin
                                bit_counter_next = bit_counter_reg + 1'b1;
                            end                      
                        end
                    else 
                        begin
                             if (bit_counter_reg == 16'd9) 
                                begin
                                    bit_counter_next = 0;
                                    carrier_counter_next = carrier_counter_reg + 1'b1;
                                end
                            else 
                                begin
                                    bit_counter_next = bit_counter_reg + 1'b1;
                                end                            
                        end

                    end
            default:
                begin
                    bit_counter_next = 0;
                    carrier_counter_next =0;
                    state_next = IDLE;
                end
        endcase
    end

//Update state
always @ (posedge SERIAL_CLK)
    begin
        if(RST)
            begin
                state_reg <= IDLE;
                bit_counter_reg <= 4'd0;
                carrier_counter_reg <= 16'd0;
            end
        else
            begin
                state_reg <= state_next;
                bit_counter_reg <= bit_counter_next;
                carrier_counter_reg <= carrier_counter_next;
            end
    end

// Dealy one clock beat for bit_counter and carrier_counter
// Dealy two clock beats for bit_conter and carrier_counter 
always @ (posedge SERIAL_CLK)
    begin
        if(RST)
            begin
               bit_counter_one_beat <= 4'd0;
               carrier_counter_one_beat <= 16'd0;
               state_reg_one_beat <= IDLE;
               bit_counter_two_beats <= 4'd0;
               bit_counter_three_beats <= 4'd0;
               carrier_counter_two_beats <= 16'd0;
               state_reg_two_beats <= IDLE;
               state_reg_three_beats <= IDLE;
               state_reg_four_beats <= IDLE;
               state_reg_five_beats <= IDLE;
               bit_counter_four_beats <= 4'd0;
               bit_counter_five_beats <= 4'd0;
            end
        else
            begin
               bit_counter_one_beat <= bit_counter_reg;
               carrier_counter_one_beat <= carrier_counter_reg;
               state_reg_one_beat <= state_reg;
               bit_counter_two_beats <= bit_counter_one_beat;
               bit_counter_three_beats <= bit_counter_two_beats;
               carrier_counter_two_beats <= carrier_counter_one_beat;
               state_reg_two_beats <= state_reg_one_beat;
               state_reg_three_beats <= state_reg_two_beats;
               state_reg_four_beats <= state_reg_three_beats;
               state_reg_five_beats <= state_reg_four_beats;
               bit_counter_four_beats <= bit_counter_three_beats;
               bit_counter_five_beats <= bit_counter_four_beats;
            end
    end

// state need to 13 cycle serial_clk delay to generate the parallel_data_output
reg [0:0] state_reg_fifteen_beats_temp [14:0];
reg [0:0] state_reg_fifteen_beats;
generate
    genvar index_0;
    for (index_0 = 0; index_0 < 15; index_0 = index_0 + 1)
    begin:delay_0//Add name here
        always @ (posedge SERIAL_CLK)
            begin
                if(RST)
                    begin
                        if (index_0 == 14) 
                            begin
                                state_reg_fifteen_beats <= 1'd0;
                            end
                        else 
                            begin
                                state_reg_fifteen_beats_temp[index_0] <= 1'd0;                               
                            end
                    end
                else
                    begin
                        if (index_0 == 0) 
                            begin
                                state_reg_fifteen_beats_temp[index_0] <= state_reg;
                            end
                        else if(index_0 == 14)
                            begin
                                state_reg_fifteen_beats <= state_reg_fifteen_beats_temp[index_0-1];
                            end
                        else 
                            begin
                                state_reg_fifteen_beats_temp[index_0] <= state_reg_fifteen_beats_temp[index_0-1];
                            end                      
                    end
            end
    end
endgenerate

//Serial bit sequence to parallet
reg [9:0] parallel_temp; //it is uesed to store the bit sequence temporaryly
reg [9:0] parallel_data_output;
reg parallel_data_output_valid;
always @ (posedge SERIAL_CLK)
    begin
        if(RST)
            begin
               parallel_temp <= 10'd0;
               parallel_data_output <= 10'd0;
               parallel_data_output_valid <= 1'b0;
            end
        else
            begin
                if (state_reg_five_beats) 
                    begin
                        if (DATA_IN_VALID) 
                            begin
                                parallel_temp[9:0] <= {parallel_temp[8:0],DATA_IN};
                            end
                        else 
                            begin
                                parallel_temp[9:0] <= {parallel_temp[8:0],1'b0}; //the blank bit is filled useing zero
                            end
                    end
                else 
                    begin
                        parallel_temp <= 10'd0;
                    end
                if (state_reg_fifteen_beats)
                    begin
                        if (bit_counter_five_beats == 4'd0 && carrier_couter_delay != USED_SUBCARRIER - 1) 
                            begin
                                parallel_data_output <= parallel_temp;
                                parallel_data_output_valid <= 1'b1;
                            end
                        else 
                            begin
                                parallel_data_output <= parallel_data_output;
                                parallel_data_output_valid <= 1'b1;                                
                            end
                    end        
                else 
                    begin
                        parallel_data_output <= 10'd0;
                        parallel_data_output_valid <= 1'b0;
                    end
            end
    end
////used for output alignment
//// parallel_data_output_valid need 10 cycle serial_clk delay to align with the parallel_data_output
//wire [10:0] parallel_data_output_valid_temp;
//wire parallel_data_output_valid_delay;
//assign parallel_data_output_valid_temp[0] = parallel_data_output_valid;
//assign parallel_data_output_valid_delay = parallel_data_output_valid_temp[10];
//generate
//    genvar index_1;
//    for (index_1 = 0; index_1 < 10; index_1 = index_1 + 1)
//    begin:delay_1//Add name here
//        FDRE #(
//         .INIT (1'b0)
//        ) data_sync_reg1 (
//        .C  (SERIAL_CLK),
//        .D  (parallel_data_output_valid_temp[index_1]),
//        .Q  (parallel_data_output_valid_temp[index_1+1]),
//        .CE (1'b1),
//        .R  (RST)
//        );
//    end
//endgenerate

// bit_num need to 12 cycle serial_clk delay to align with the parallel_data_output
reg [3:0] bit_num_temp [11:0];
reg [3:0] bit_num_delay;
generate
    genvar index_2;
    for (index_2 = 0; index_2 < 12; index_2 = index_2 + 1)
    begin:delay_2//Add name here
        always @ (posedge SERIAL_CLK)
            begin
                if(RST)
                    begin
                        if (index_2 == 11) 
                            begin
                                bit_num_delay <= 4'd0;
                            end
                        else 
                            begin
                                bit_num_temp[index_2] <= 4'd0;                               
                            end
                    end
                else
                    begin
                        if (index_2 == 0) 
                            begin
                                bit_num_temp[index_2] <= bit_num;
                            end
                        else if(index_2 == 11)
                            begin
                                bit_num_delay <= bit_num_temp[index_2-1];
                            end
                        else 
                            begin
                                bit_num_temp[index_2] <= bit_num_temp[index_2-1];
                            end                      
                    end
            end
    end
endgenerate
// carrier_counter_two_beats need 14 cycle serial_clk delay to align with the parallel_data_output
reg [15:0] carrier_counter_temp [13:0];
reg [15:0] carrier_couter_delay;
generate
    genvar index_3;
    for (index_3 = 0; index_3 < 14; index_3 = index_3 + 1)
    begin:delay_3//Add name here
        always @ (posedge SERIAL_CLK)
            begin
                if(RST)
                    begin
                        if (index_3 == 13) 
                            begin
                                carrier_couter_delay <= 16'd0;
                            end
                        else 
                            begin
                                carrier_counter_temp[index_3] <= 16'd0;                               
                            end
                    end
                else
                    begin
                        if (index_3 == 0) 
                            begin
                                carrier_counter_temp[index_3] <= carrier_counter_two_beats;
                            end
                        else if(index_3 == 13)
                            begin
                                carrier_couter_delay <= carrier_counter_temp[index_3-1];
                            end
                        else 
                            begin
                                carrier_counter_temp[index_3] <= carrier_counter_temp[index_3-1];
                            end                      
                    end
            end
    end
endgenerate

//output stage of this mnodule
always @ (posedge SYMBOL_CLK)
    begin
        if(RST)
            begin
                SUBCARRIER_INDEX <= 16'd0;
                ALLOCATED_BIT_NUM <= 4'd0;
                PARALLEL_DATA_OUTPUT <= 10'd0;
                PARALLEL_DATA_OUTPUT_VALID <= 1'b0;              
            end
        else
            begin
               if (parallel_data_output_valid) 
                   begin
                       SUBCARRIER_INDEX <= carrier_couter_delay;
                       ALLOCATED_BIT_NUM <= bit_num_delay; 
                       PARALLEL_DATA_OUTPUT <= parallel_data_output;
                       PARALLEL_DATA_OUTPUT_VALID <= 1'b1;
                   end
               else 
                   begin
                        SUBCARRIER_INDEX <= 16'd0;
                        ALLOCATED_BIT_NUM <= 4'd0;
                        PARALLEL_DATA_OUTPUT <= 10'd0;
                        PARALLEL_DATA_OUTPUT_VALID <= 1'b0;                        
                   end
            end
    end
endmodule