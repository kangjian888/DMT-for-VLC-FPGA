// =============================================================================
// Filename: HermitianSym.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description: This module is used for 128 IFFT, 63 subcarriers are used, and 48
// subcarriers are used to load the data, 4 carriers are used to load pilot, the reset
// subcarrier loads nothing. 
// -----------------------------------------------------------------------------
module HermitianSym #(
    parameter USED_SUBCARRIER = 59//the range is from 0-65535
)
(
	input CLK, //used for input clock
  input CLK_2X, //used for output clock
	input RST,
	input [27:0] DATA_IN_RE_ORI,
	input [27:0] DATA_IN_IM_ORI,
	input [15:0] DATA_INDEX_IN_ORI,
	input DATA_IN_EN_ORI,
  input [27:0] DATA_IN_RE_HER,
  input [27:0] DATA_IN_IM_HER,
  input [15:0] DATA_INDEX_IN_HER,
  input DATA_IN_EN_HER,
	output reg [27:0] DATA_OUT_RE,
	output reg [27:0] DATA_OUT_IM,
  output reg DATA_OUT_LAST,
	output reg DATA_OUT_READY		
);
// Inner register
reg [27:0] data_temp_re_ori;
reg [27:0] data_temp_im_ori;
reg data_enable_temp_ori;
reg [5:0] data_index_temp_ori;

reg [27:0] data_temp_re_her;
reg [27:0] data_temp_im_her;
reg data_enable_temp_her;
reg [5:0] data_index_temp_her;

reg write_enable_ori; //enable write
reg [6:0] write_address_ori;
reg write_address_control_ori;
reg [27:0] ram_temp_re_ori;
reg [27:0] ram_temp_im_ori;

reg write_enable_her; //enable write
reg [6:0] write_address_her;
reg write_address_control_her;
reg [27:0] ram_temp_re_her;
reg [27:0] ram_temp_im_her;

reg pilot_insert_enable;//enable pilot insertion progressing
wire pilot_insert_scamber_out; //if this value is 0, pilot is [1,-1,1,1], if this value is 1, pilot is [-1,1-1,-1]
reg [3:0] pilot_insert_state; // onehot code is used in FSM

reg read_enable; //enable read
reg read_enable_delay; 
reg data_out_enable; //enable data output
wire read_enable_mix;
wire [7:0] read_address;
wire [7:0] read_address_delayed;
wire [7:0] read_address_delayed_two_step;
wire [27:0] ram_re_out_1, ram_re_out_2;
wire [27:0] ram_im_out_1, ram_im_out_2;
wire [27:0] ram_re_out;
wire [27:0] ram_im_out;
// One stage 
always @ (posedge CLK)
    begin
        if(RST)
            begin
        	   data_temp_im_ori <= 28'd0;
        	   data_temp_re_ori <= 28'd0;
        	   data_index_temp_ori <= 6'd0;
        	   data_enable_temp_ori <= 1'b0;
             data_temp_im_her <= 28'd0;
             data_temp_re_her <= 28'd0;
             data_index_temp_her <= 6'd0;
             data_enable_temp_her <= 1'b0;             
            end
        else
            begin
        	   if(DATA_IN_EN_ORI && DATA_IN_EN_HER) 
        	    begin
        	   		data_temp_im_ori <= DATA_IN_IM_ORI;
        	   		data_temp_re_ori <= DATA_IN_RE_ORI;
        	   		data_enable_temp_ori <= DATA_IN_EN_ORI;
        	   		data_index_temp_ori <= DATA_INDEX_IN_ORI[5:0];
                data_temp_im_her <= DATA_IN_IM_HER;
                data_temp_re_her <= DATA_IN_RE_HER;
                data_enable_temp_her <= DATA_IN_EN_HER;
                data_index_temp_her <= DATA_INDEX_IN_HER[5:0];                
        	   	end
        	   else 
        	   	begin
        	   		data_temp_im_ori <= 28'd0;
        	   		data_temp_re_ori <= 28'd0;
        	   		data_index_temp_ori <= 6'd0;
        	   		data_enable_temp_ori <= 1'b0;
                data_temp_im_her <= 28'd0;
                data_temp_re_her <= 28'd0;
                data_index_temp_her <= 6'd0;
                data_enable_temp_her <= 1'b0;        	   		
        	   	end
            end
    end

blk_mem_hermitian_sym ram_re_ori (
  .clka(CLK),    // input wire clka
  .wea(write_enable_ori),      // input wire [0 : 0] wea
  .addra(write_address_ori),  // input wire [6 : 0] addra
  .dina(ram_temp_re_ori),    // input wire [27 : 0] dina
  .clkb(CLK_2X),    // input wire clkb
  .enb(read_enable_mix && ~read_address_delayed[6]),      // input wire enb
  .addrb({read_address[7],read_address[5:0]}),  // input wire [6 : 0] addrb
  .doutb(ram_re_out_1)  // output wire [27 : 0] doutb
);

blk_mem_hermitian_sym ram_im_ori (
  .clka(CLK),    // input wire clka
  .wea(write_enable_ori),      // input wire [0 : 0] wea
  .addra(write_address_ori),  // input wire [6 : 0] addra
  .dina(ram_temp_im_ori),    // input wire [27 : 0] dina
  .clkb(CLK_2X),    // input wire clkb
  .enb(read_enable_mix && ~read_address_delayed[6]),      // input wire enb
  .addrb({read_address[7],read_address[5:0]}),  // input wire [6 : 0] addrb
  .doutb(ram_im_out_1)  // output wire [27 : 0] doutb
);

blk_mem_hermitian_sym ram_re_her (
  .clka(CLK),    // input wire clka
  .wea(write_enable_her),      // input wire [0 : 0] wea
  .addra(write_address_her),  // input wire [6 : 0] addra
  .dina(ram_temp_re_her),    // input wire [27 : 0] dina
  .clkb(CLK_2X),    // input wire clkb
  .enb(read_enable_mix && read_address_delayed[6]),      // input wire enb
  .addrb({read_address[7],read_address[5:0]}),  // input wire [6 : 0] addrb
  .doutb(ram_re_out_2)  // output wire [27 : 0] doutb
);

blk_mem_hermitian_sym ram_im_her (
  .clka(CLK),    // input wire clka
  .wea(write_enable_her),      // input wire [0 : 0] wea
  .addra(write_address_her),  // input wire [6 : 0] addra
  .dina(ram_temp_im_her),    // input wire [27 : 0] dina
  .clkb(CLK_2X),    // input wire clkb
  .enb(read_enable_mix && read_address_delayed[6]),      // input wire enb
  .addrb({read_address[7],read_address[5:0]}),  // input wire [6 : 0] addrb
  .doutb(ram_im_out_2)  // output wire [27 : 0] doutb
);

assign ram_re_out = (~read_address_delayed_two_step[6])? ram_re_out_1 : ram_re_out_2;
assign ram_im_out = (~read_address_delayed_two_step[6])? ram_im_out_1 : ram_im_out_2;
//adjust the order of data
always @ (posedge CLK)
    begin
        if(RST)
            begin
        	   write_address_ori <= 7'd0;
        	   write_address_control_ori <= 1'b0;
        	   write_enable_ori <= 1'b0;
        	   ram_temp_im_ori <= 28'd0;
        	   ram_temp_re_ori <= 28'd0;
             write_address_her <= 7'd0;
             write_address_control_her <= 1'b0;
             write_enable_her <= 1'b0;
             ram_temp_im_her <= 28'd0;
             ram_temp_re_her <= 28'd0;  
             read_enable <= 1'b0;  
             data_out_enable <= 1'b0; 
             pilot_insert_enable <= 1'b0;   
             pilot_insert_state <= 4'b0001;
            end
        else
            begin
        	   if (data_enable_temp_ori && data_enable_temp_her) 
               begin
                case (data_index_temp_ori) 
                    0,1,2,3,4,5://six
                        begin
                          write_address_ori[5:0] <= data_index_temp_ori + 1;
                        end
                    6,7,8,9,10,11,12,13,14,15,16,17,18:
                        begin
                          write_address_ori[5:0] <= data_index_temp_ori + 2;
                        end
                    19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39:
                        begin
                          write_address_ori[5:0] <= data_index_temp_ori + 3;
                        end
                    40,41,42,43,44,45,46,47,48,49,50,51,52:
                        begin
                          write_address_ori[5:0] <= data_index_temp_ori + 4;
                        end
                    53,54,55,56,57,58:   
                        begin
                          write_address_ori[5:0] <= data_index_temp_ori + 5;
                        end                                             
                    default:
                        begin
                          write_address_ori[5:0] <= 6'd0;
                        end
                endcase
                write_address_ori[6] <= write_address_control_ori;
                write_enable_ori <= 1'b1;
                ram_temp_re_ori <= data_temp_re_ori;
                ram_temp_im_ori <= data_temp_im_ori;
                case (data_index_temp_her) 
                    0,1,2,3,4,5:
                        begin
                          write_address_her[5:0] <= 7'd63-data_index_temp_her;
                        end
                    6,7,8,9,10,11,12,13,14,15,16,17,18:
                        begin
                          write_address_her[5:0] <= 7'd63-data_index_temp_her-1; 
                        end
                    19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39:
                        begin
                          write_address_her[5:0] <= 7'd63-data_index_temp_her-2; 
                        end
                    40,41,42,43,44,45,46,47,48,49,50,51,52:
                        begin
                          write_address_her[5:0] <= 7'd63-data_index_temp_her-3;
                        end
                    53,54,55,56,57,58:
                        begin
                          write_address_her[5:0] <= 7'd63-data_index_temp_her-4;
                        end                            
                    default:
                        begin
                          write_address_ori[5:0] <= 6'd0;
                        end
                endcase
                write_address_her[6] <= write_address_control_her;
                write_enable_her <= 1'b1;
                ram_temp_re_her <= data_temp_re_her;
                ram_temp_im_her <= data_temp_im_her; 
                if(data_index_temp_ori == USED_SUBCARRIER - 1)
                  begin
                      pilot_insert_enable <= 1'b1;
                  end                
               end
             else if (pilot_insert_enable)
                begin
                  write_address_ori[6] <= write_address_control_ori;
                  write_enable_ori <= 1'b1;
                  write_address_her[6] <= write_address_control_her;
                  write_enable_her <= 1'b1;
                  if(!pilot_insert_scamber_out)
                    begin
                      case (pilot_insert_state) 
                          4'b0001:
                              begin
                                  ram_temp_re_ori <= 28'b0001_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b0001_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 7;
                                  write_address_her[5:0] <= 57;                               
                                  pilot_insert_state <= 4'b0010;
                              end
                          4'b0010:
                              begin
                                  ram_temp_re_ori <= 28'b1111_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b1111_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 21;
                                  write_address_her[5:0] <= 43;                              
                                  pilot_insert_state <= 4'b0100;
                              end
                          4'b0100:
                              begin
                                  ram_temp_re_ori <= 28'b0001_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b0001_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 43;
                                  write_address_her[5:0] <= 21;                              
                                  pilot_insert_state <= 4'b1000;
                              end
                          4'b1000:
                              begin
                                  ram_temp_re_ori <= 28'b0001_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b0001_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 57;
                                  write_address_her[5:0] <= 7;
                                  pilot_insert_state <= 4'b0001;
                                  pilot_insert_enable <= 1'b0;
                                  read_enable <= 1'b1;
                                  write_address_control_ori <= ~write_address_control_ori; //bit inverse
                                  write_address_control_her <= ~write_address_control_her; //bit inverse
                              end                              
                      endcase
                    end
                  else 
                    begin
                      case (pilot_insert_state) 
                          4'b0001:
                              begin
                                  ram_temp_re_ori <= 28'b1111_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b1111_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 7;
                                  write_address_her[5:0] <= 57;                               
                                  pilot_insert_state <= 4'b0010;
                              end
                          4'b0010:
                              begin
                                  ram_temp_re_ori <= 28'b0001_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b0001_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 21;
                                  write_address_her[5:0] <= 43;                              
                                  pilot_insert_state <= 4'b0100;
                              end
                          4'b0100:
                              begin
                                  ram_temp_re_ori <= 28'b1111_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b1111_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 43;
                                  write_address_her[5:0] <= 21;                              
                                  pilot_insert_state <= 4'b1000;
                              end
                          4'b1000:
                              begin
                                  ram_temp_re_ori <= 28'b1111_0000_0000_0000_0000_0000_0000; //1 bit is sign, 3 bits are integer, 24 bits are fraction
                                  ram_temp_im_ori <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  ram_temp_re_her <= 28'b1111_0000_0000_0000_0000_0000_0000;
                                  ram_temp_im_her <= 28'b0000_0000_0000_0000_0000_0000_0000;
                                  write_address_ori[5:0] <= 57;
                                  write_address_her[5:0] <= 7;
                                  pilot_insert_state <= 4'b0001;
                                  pilot_insert_enable <= 1'b0;
                                  read_enable <= 1'b1;
                                  write_address_control_ori <= ~write_address_control_ori; //bit inverse
                                  write_address_control_her <= ~write_address_control_her; //bit inverse
                              end                              
                      endcase                      
                    end
                end
             else 
               begin
                  write_address_ori[5:0] <= 6'd0;
                  write_address_her[5:0] <= 6'd0;
                  write_enable_ori <= 1'b0;
                  write_enable_her <= 1'b0;
                  ram_temp_im_ori <= 28'd0;
                  ram_temp_re_ori <= 28'd0;
                  ram_temp_im_her <= 28'd0;
                  ram_temp_re_her <= 28'd0;                                    
               end
            end
            if (read_address == 127 || read_address == 255) //we nust have a main control unit to prove it is process like our design
                begin
                    read_enable <= 1'b0;
                end
            if (read_enable) 
                begin
                  data_out_enable <= 1'b1;
                end
            else 
                begin
                  data_out_enable<= 1'b0;
                end
    end
// delay one clock cycle CLK_2X read_enable
always @ (posedge CLK_2X)
    begin
        if(RST)
            begin
                read_enable_delay <= 1'b0;             
            end
        else
            begin
                read_enable_delay <= read_enable;
            end
    end
assign read_enable_mix = read_enable || read_enable_delay; //to get all the value in the memergy
//implement counter to generate the read address
counter_256 READ_ADRESS_GEN(
  .clk(CLK_2X),
  .RST(RST),
  .enable(read_enable),
  .counter_256(read_address),
  .counter_256_delayed(read_address_delayed),
  .counter_256_delayed_two_step(read_address_delayed_two_step)
  );
// read the out from ram, the speed of read is times to write.
always @ (posedge CLK_2X)
    begin
        if(RST)
          begin
            DATA_OUT_RE <= 28'd0;
            DATA_OUT_IM <= 28'd0;
            DATA_OUT_READY <= 1'b0;
            DATA_OUT_LAST <= 1'b0;
          end
        else
          begin
            if (data_out_enable) 
                begin
                    DATA_OUT_RE <= ram_re_out;
                    DATA_OUT_IM <= ram_im_out;
                    DATA_OUT_READY <= 1'b1;
                    if (read_address_delayed == 8'd128 || read_address_delayed == 8'd0) 
                      begin
                          DATA_OUT_LAST <= 1'b1;
                      end
                    else 
                      begin
                          DATA_OUT_LAST <= 1'b0;
                      end
                end
            else 
                begin
                    DATA_OUT_RE <= 28'd0;
                    DATA_OUT_IM <= 28'd0;
                    DATA_OUT_READY <= 1'b0;  
                    DATA_OUT_LAST <= 1'b0;                  
                end
          end
    end

// This is used to generate the pilot_insert_scamber
reg [6:0] pilot_insert_scamber_reg = 7'b1111_111;
reg pilot_insert_scamber;
assign pilot_insert_scamber_out = pilot_insert_scamber;
always @ (posedge CLK)
    begin
        if(RST)
            begin
                pilot_insert_scamber_reg = 7'b1111_111;
                pilot_insert_scamber = 1'b0;
            end
        else
            begin
                if (data_index_temp_ori == 1'b1 && data_enable_temp_ori) //means the beginning of one OFDM symbol
                  begin
                      pilot_insert_scamber = pilot_insert_scamber_reg[6]^pilot_insert_scamber_reg[3];
                      pilot_insert_scamber_reg = {pilot_insert_scamber_reg[5:0],pilot_insert_scamber};
                  end
                else 
                  begin
                      pilot_insert_scamber = pilot_insert_scamber;
                      pilot_insert_scamber_reg = pilot_insert_scamber_reg;
                  end
            end
    end
endmodule

//the module of 256 counter
module counter_256(
  input clk,
  input RST,
  input enable,
  output reg [7:0] counter_256,
  output reg [7:0] counter_256_delayed,
  output reg [7:0] counter_256_delayed_two_step
  );

always @ (posedge clk)
    begin
        if(RST)
            begin
              counter_256 <= 8'd0;
              counter_256_delayed <= 8'd0;
              counter_256_delayed_two_step <= 8'd0;
            end
        else
            begin
              if (enable) 
                begin
                  counter_256 <= counter_256 + 1'b1; 
                  counter_256_delayed <= counter_256;
                  counter_256_delayed_two_step <= counter_256_delayed;
                end
              else 
                begin
                  counter_256 <= counter_256;
                  counter_256_delayed <= counter_256;
                  counter_256_delayed_two_step <= counter_256_delayed;
                end
            end
    end
endmodule