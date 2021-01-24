// =============================================================================
// Filename: TransmitterTop.v
// Author: KANG, Jian
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:
// -----------------------------------------------------------------------------
`timescale 1 ns / 1 ps
module TransmitterTop(
	input SYS_CLK_P, //system differencial clock, used for clock generation module.
	input SYS_CLK_N,
	input A_GLB_RST_N,
	input SEND_ENABLE_BUTTON_N, //This signal needed to be debounced in the real implementation
	output led_1,
	output led_2,
	output led_3,
	output DAC1_WRT,
	output DAC1_CLK,
	output reg [13:0] DAC1_DATA, 
	output reg DAC1_DATA_VALID
	//output S_SYM_RST //used in simulation		
);
// global parameters
parameter OFDM_FRAME_NUM = 200;//this parameters could be adjusted directly without modification other parameters

assign led_1 = 1;
assign led_2 = 1;
assign led_3 = 1;
// Globle wire or reg
wire s_mcu_rst;
wire s_mac_rst;
wire s_sym_rst;
// Clock wire
wire serial_clk; //this is the clock of prbs signal generator generator, equal 10*f(symbol_clk)
wire symbol_clk; // this is the time domain symbol clock, the frequency is equal to 20Mhz in this design
wire sys_clk; // this is the output sampling clock, equal 2*f(symbol_clk)
wire a_clock_locked;
wire dac_clk;
reg dac_clk_enable;

wire a_glb_rst;
wire send_enable_button;

assign send_enable_button = ~SEND_ENABLE_BUTTON_N;
assign a_glb_rst = ~A_GLB_RST_N;
//this part is used for simulation
//assign S_SYM_RST = s_sym_rst;

// Clock generation module
ClockGen ClockGen_inst(
	.SYS_CLK_P(SYS_CLK_P),
	.SYS_CLK_N(SYS_CLK_N),
	.A_GLB_RST(a_glb_rst), //global reset input
	.LOCKED(a_clock_locked),
    .DAC_CLK_ENABLE(dac_clk_enable),
    .DAC_CLK(dac_clk),
    .SERIAL_CLK(serial_clk),
    .SYMBOL_CLK(symbol_clk),
    .SYS_CLK(sys_clk)		
);

assign DAC1_CLK = dac_clk;
assign DAC1_WRT = dac_clk;

ResetGen ResetGen_inst(
	.SERIAL_CLK(serial_clk),
	.SYS_CLK(sys_clk),
	.SYMBOL_CLK(symbol_clk),
	.LOCKED(a_clock_locked), //high active means
	.S_MCU_RST(s_mcu_rst),
	.S_MAC_RST(s_mac_rst),
	.S_SYM_RST(s_sym_rst)
);

//Debounce button
wire send_enable_pulse;
reg send_enable;
debounce #(
	.CLK_PERIOD(25)//1000/25 = 40Mhz, this is data in this application
)
debounce_inst
(
	.clk(sys_clk),
	.key(send_enable_button),//input key signal
	.key_pulse(send_enable_pulse)//generated pulse		
);

always @ (posedge sys_clk)
    begin
        if(s_mcu_rst)
            begin
        	   send_enable <= 1'b0;
            end
        else
            begin
        	   if (send_enable_pulse) //now the code is in the simulation situation
        	    begin
        	   		send_enable <= ~send_enable;
        	   	end
        	   else 
        	   	begin
        	   		send_enable <= send_enable;
        	   	end
            end
    end
//Wire output from main control unit
wire phy_rst;
wire short_ack;
wire long_ack;
wire data_req;
reg transmission_done;
MainControlUnit#(
    .OFDM_FRAME_NUM(OFDM_FRAME_NUM)
)
MainControlUnit_inst
(
	.SYS_CLK(sys_clk), 
	.SYMBOL_CLK(symbol_clk),
    .S_MCU_RST(s_mcu_rst), //high active, syn to SYS_CLK
    .S_SYM_RST(s_sym_rst),
	.SEND_ENABLE(send_enable), //syn to SYS_CLK, inpulse means begin to transmission.
	.TRANSMISSION_DONE(transmission_done),
    .PHY_RST(phy_rst), //initalize other module of transmitter
    .SHORT_ACK(short_ack), //short sequences transmission start signal
    .LONG_ACK(long_ack), //long sequences transmission enable signal
    .DATA_REQ(data_req) //require data transmission to mac layer
);

wire data_bit_seq_valid;
wire data_bit_seq_ready;
wire data_bit_seq;
wire [15:0] subcarrier_index;
wire [3:0] allocated_bit_num;
wire [9:0] parallel_data_output;
wire parallel_data_output_valid;
MAC_PRBS MAC_PRBS_inst(
	.SERIAL_CLK(serial_clk),//the frequency of the clock is 200Mhz 
	.MAC_RST(s_mac_rst),
	.PHY_RST(phy_rst),
	.READ_ENABLE(data_bit_seq_ready),
	.DATA_OUTPUT(data_bit_seq),
    .DATA_OUTPUT_VALID(data_bit_seq_valid)	
);

wire [27:0] short_training_seq;
wire [8:0] short_training_seq_index;
wire short_training_seq_valid;
ShortTrainingSeqGen ShortTrainingSeqGen_inst(
	.SYS_CLK(sys_clk),
	.PHY_RST(phy_rst),
	.SHORT_ACK(short_ack), //Short training sequence sending enable
	.SHORT_TRAINING_SEQ(short_training_seq),
	.SHORT_TRAINING_SEQ_INDEX(short_training_seq_index),
	.SHORT_TRAINING_SEQ_VALID(short_training_seq_valid)
);

wire [27:0] long_training_seq;
wire [8:0] long_training_seq_index;
wire long_training_seq_valid;
LongTrainingSeqGen LongTrainingSeqGen_inst(
	.SYS_CLK(sys_clk),
	.PHY_RST(phy_rst),
	.LONG_ACK(long_ack), //LONG training sequence sending enable
	.LONG_TRAINING_SEQ(long_training_seq),
	.LONG_TRAINING_SEQ_INDEX(long_training_seq_index),
	.LONG_TRAINING_SEQ_VALID(long_training_seq_valid)
);

Modulator_Bit_Energy_Allocation#(
    .USED_SUBCARRIER(59)
)
Modulator_Bit_Energy_Allocation_inst
(
	.SERIAL_CLK(serial_clk), //200Mhz
	.SYMBOL_CLK(symbol_clk),
	.DATA_REQ(data_req),
	.RST(phy_rst),
	.DATA_IN(data_bit_seq),
	.DATA_IN_VALID(data_bit_seq_valid),
	.DATA_IN_READY(data_bit_seq_ready),
	.SUBCARRIER_INDEX(subcarrier_index),
    .ALLOCATED_BIT_NUM(allocated_bit_num),
    .PARALLEL_DATA_OUTPUT(parallel_data_output),
    .PARALLEL_DATA_OUTPUT_VALID(parallel_data_output_valid)
);

wire [27:0] modulated_data_out_re;
wire [27:0] modulated_data_out_im;
wire  modulated_data_out_valid;
wire [15:0] modulated_data_out_index;
Modulator_Mapping Modulator_Mapping_inst(
	.SYMBOL_CLK(symbol_clk),
	.RST(phy_rst),
    .SUBCARRIER_INDEX(subcarrier_index),
	.ALLOCATED_BIT_NUM(allocated_bit_num),
	.PARALLEL_BIT_IN(parallel_data_output),
    .PARALLEL_BIT_IN_VALID(parallel_data_output_valid),
	.MODULATED_DATA_OUT_RE(modulated_data_out_re),
    .MODULATED_DATA_OUT_IM(modulated_data_out_im),
    .MODULATED_DATA_OUT_VALID(modulated_data_out_valid),
    .MODULATED_DATA_OUT_INDEX(modulated_data_out_index)
);

wire [27:0] modulated_data_out_re_ori;
wire [27:0] modulated_data_out_im_ori;
wire [15:0] modulated_data_out_index_ori;
wire modulated_data_out_valid_ori;
wire [27:0] modulated_data_out_re_her;
wire [27:0] modulated_data_out_im_her;
wire [15:0] modulated_data_out_index_her;
wire modulated_data_out_valid_her;
HermitianMapping HermitianMapping_inst(
	.CLK(symbol_clk),
	.RST(phy_rst),
	.DATA_IN_RE(modulated_data_out_re),
	.DATA_IN_IM(modulated_data_out_im),
	.DATA_IN_INDEX(modulated_data_out_index),
	.DATA_IN_VALID(modulated_data_out_valid),
	.DATA_OUT_RE(modulated_data_out_re_ori),
	.DATA_OUT_IM(modulated_data_out_im_ori),
	.DATA_OUT_INDEX(modulated_data_out_index_ori),
	.DATA_OUT_VALID(modulated_data_out_valid_ori), 
	.DATA_OUT_RE_HER(modulated_data_out_re_her),
	.DATA_OUT_IM_HER(modulated_data_out_im_her),
	.DATA_OUT_INDEX_HER(modulated_data_out_index_her),
	.DATA_OUT_VALID_HER(modulated_data_out_valid_her)
);

wire [27:0] hermitian_data_re;
wire [27:0] hermitian_data_im;
wire hermitian_data_last;
wire hermitian_data_valid;
HermitianSym#(
    .USED_SUBCARRIER(59)
)
HermitianSym_inst(
	.CLK(symbol_clk), //used for input clock
  	.CLK_2X(sys_clk), //used for output clock
	.RST(phy_rst),
	.DATA_IN_RE_ORI(modulated_data_out_re_ori),
	.DATA_IN_IM_ORI(modulated_data_out_im_ori),
	.DATA_INDEX_IN_ORI(modulated_data_out_index_ori),
	.DATA_IN_EN_ORI(modulated_data_out_valid_ori),
    .DATA_IN_RE_HER(modulated_data_out_re_her),
    .DATA_IN_IM_HER(modulated_data_out_im_her),
    .DATA_INDEX_IN_HER(modulated_data_out_index_her),
    .DATA_IN_EN_HER(modulated_data_out_valid_her),
	.DATA_OUT_RE(hermitian_data_re),
	.DATA_OUT_IM(hermitian_data_im),
    .DATA_OUT_LAST(hermitian_data_last),
	.DATA_OUT_READY(hermitian_data_valid)		
);


wire ifft_ready;
wire [27:0] data_from_ifft_re;
wire [27:0] data_from_ifft_im;
wire [6:0] data_from_ifft_index;
wire data_from_ifft_last;
wire data_from_ifft_valid;
wire event_frame_started;                // output wire event_frame_started
wire event_tlast_unexpected;         // output wire event_tlast_unexpected
wire event_tlast_missing;           // output wire event_tlast_missing
wire event_fft_overflow;                  // output wire event_fft_overflow
wire event_data_in_channel_halt;
Ifft_Block Ifft_Block_inst(
	.SYS_CLK(sys_clk),
	.RST(phy_rst),
	.S_DATA_RE_IN(hermitian_data_re),
	.S_DATA_IM_IN(hermitian_data_im),
	.S_DATA_VALID(hermitian_data_valid),
	.S_DATA_LAST(hermitian_data_last),
	.S_DATA_READY(ifft_ready),
	.M_DATA_RE_OUT(data_from_ifft_re),
	.M_DATA_IM_OUT(data_from_ifft_im),
	.M_DATA_OUT_INDEX(data_from_ifft_index), 
	.M_DATA_LAST(data_from_ifft_last),
	.M_DATA_VALID(data_from_ifft_valid),
    .EVENT_FRAME_STARTED(event_frame_started),                // output wire event_frame_started
    .EVENT_TLAST_UNEXPECTED(event_tlast_unexpected),          // output wire event_tlast_unexpected
    .EVENT_TLAST_MISSING(event_tlast_missing),                // output wire event_tlast_missing
    .EVENT_FFT_OVERFLOW(event_fft_overflow),                  // output wire event_fft_overflow
    .EVENT_DATA_IN_CHANNEL_HALT(event_data_in_channel_halt) 
);

wire [27:0] data_adding_cp;
wire data_adding_cp_valid;
wire data_adding_cp_last;
CPWindowAdding CPWindowAdding_inst(
	.SYS_CLK(sys_clk),
	.RST(phy_rst),
	.DATA_IN(data_from_ifft_re),
	.DATA_INDEX_IN(data_from_ifft_index),
	.DATA_IN_VALID(data_from_ifft_valid),
	.DATA_OUT(data_adding_cp),
	.DATA_OUT_LAST(data_adding_cp_last),
	.DATA_OUT_VALID(data_adding_cp_valid) 
);
//transmission done generation
reg [15:0] ofdm_symbol_counter;
always @ (posedge sys_clk)
    begin
        if(s_sym_rst)
            begin
        	   ofdm_symbol_counter <= 16'd0;
        	   transmission_done <= 1'b0;
            end
        else
            begin
        	   if (data_adding_cp_last) 
        	    begin
        	   		ofdm_symbol_counter <= ofdm_symbol_counter + 1'b1;	
        	   	end
        	   else if(ofdm_symbol_counter == OFDM_FRAME_NUM)
        	   	begin
        	   		transmission_done <= 1'b1;
        	   		ofdm_symbol_counter <= 16'd0;
        	   	end
        	   else 
        	   	begin
        	   		ofdm_symbol_counter <= ofdm_symbol_counter;
        	   		transmission_done <= 1'b0;
        	   	end
            end
    end

// Output stage
// 1 sign bit, 3 integer bis and 10 fractional bits is assigned to output
// bacause LEDs on board low active, DAC1_DATA_VALID is also low active
reg [27:0] signed_output;
reg signed_output_valid;
always @ (posedge sys_clk)
    begin
        if(s_mcu_rst)
            begin
        	   signed_output <= 28'd0;
        	   signed_output_valid <= 1'b0;
               //dac_clk_enable <= 1'b0;
            end
        else
            begin
        	   if(short_training_seq_valid && ~long_training_seq_valid && ~data_adding_cp_valid)
        	   	begin
        	   		signed_output <= short_training_seq;
        	   		signed_output_valid <= 1'b1;
                    //dac_clk_enable <= 1'b1;
        	   	end
        	   else if (short_training_seq_valid && long_training_seq_valid && ~data_adding_cp_valid) 
        	    begin
        	   		signed_output <= short_training_seq + long_training_seq;
        	   		signed_output_valid <= 1'b1;
                    //dac_clk_enable <= 1'b1;	
        	   	end
        	    else if (~short_training_seq_valid && long_training_seq_valid && ~data_adding_cp_valid) 
        	        begin
        	    		signed_output <= long_training_seq;
        	    		signed_output_valid <= 1'b1;
                        //dac_clk_enable <= 1'b1;
        	    	end
        	   	else if(~short_training_seq_valid && long_training_seq_valid && data_adding_cp_valid)
        	   	begin
        	   		signed_output <= long_training_seq + data_adding_cp;
        	   		signed_output_valid <= 1'b1;
                    //dac_clk_enable <= 1'b1;
        	   	end
        	    else if (~short_training_seq_valid && ~long_training_seq_valid && data_adding_cp_valid) 
        	        begin
        	    		signed_output <= data_adding_cp;
        	    		signed_output_valid <= 1'b1;
                        //dac_clk_enable <= 1'b1;
        	    	end
        	    else 
        	    	begin
        	    		signed_output <= 28'd0;
        	    		signed_output_valid <= 1'b0;
                        //dac_clk_enable <= 1'b0;
        	    	end
            end
    end

//28bits to 14bits, loss some accuracy and signed becomes unsigned.
always @ (posedge sys_clk)
    begin
        if(s_mcu_rst)
            begin
            	DAC1_DATA <= 14'b10_0000_0000_0000;
            	DAC1_DATA_VALID <= 1'b1;//low active  
                dac_clk_enable <= 1'b0;             
            end
        else
            begin
        	   if (signed_output_valid) 
        	    begin
        	   		DAC1_DATA <= signed_output[23:10] + 14'b10_0000_0000_0000;
        	   		DAC1_DATA_VALID <= 1'b0;//low active
                    dac_clk_enable <= 1'b1;
        	   	end
        	   else 
        	   	begin
        	   		DAC1_DATA <= 14'b10_0000_0000_0000;
        	   		DAC1_DATA_VALID <= 1'b1;
                    dac_clk_enable <= 1'b0;
        	   	end        	   
            end
    end
endmodule