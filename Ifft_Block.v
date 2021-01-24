// =============================================================================
// Filename: Ifft_Block.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:
// -----------------------------------------------------------------------------
module Ifft_Block(
	input SYS_CLK,
	input RST,
	//data input interface
	input [27:0] S_DATA_RE_IN,
	input [27:0] S_DATA_IM_IN,
	input S_DATA_VALID,
	input S_DATA_LAST,
	output S_DATA_READY,
	//data output interface
	output reg [27:0] M_DATA_RE_OUT,
	output reg [27:0] M_DATA_IM_OUT,
	output reg [6:0] M_DATA_OUT_INDEX, 
	output reg M_DATA_LAST,
	output reg M_DATA_VALID,
	//event output interface
    output EVENT_FRAME_STARTED,                // output wire event_frame_started
    output EVENT_TLAST_UNEXPECTED,          // output wire event_tlast_unexpected
    output EVENT_TLAST_MISSING,                // output wire event_tlast_missing
    output EVENT_FFT_OVERFLOW,                  // output wire event_fft_overflow
    output EVENT_DATA_IN_CHANNEL_HALT 
);

wire s_axis_config_tready;
wire s_axis_config_tvalid;
wire [15:0] s_axis_config_tdata;

//configure part
control_gen #(
	//.CP_LEN(7'd32),//the legth of cp is 16
	.FWD_INV(1'b0),//IFFT in transmitter side, and we have just one channel
	.SCALE_SCH({2'd1,2'd2,2'd2,2'd2})//because we use pepline
)
control_gen_inst
(
	.CLK(SYS_CLK),
	.RST(RST),
	//interface of configure port to ifft or fft
	.m_axis_config_tready(s_axis_config_tready),
	.m_axis_config_tdata(s_axis_config_tdata),
	.m_axis_config_tvalid(s_axis_config_tvalid)
);


wire [63:0] s_data_in;
assign s_data_in = {4'b0,S_DATA_IM_IN,4'b0,S_DATA_RE_IN};//add padding and combine two path data together.

wire [15:0] m_data_user_temp; //[6:0] is the index information
wire [63:0] m_data_out_temp;
wire m_data_valid_temp;
wire m_data_last_temp;




//ifft ip core instance
ifft_fft_core ifft_inst (
  .aclk(SYS_CLK), 											   // input wire aclk
  .aresetn(~RST),                                            // reset signal, active low
  .s_axis_config_tdata(s_axis_config_tdata),                // input wire [15 : 0] s_axis_config_tdata
  .s_axis_config_tvalid(s_axis_config_tvalid),              // input wire s_axis_config_tvalid
  .s_axis_config_tready(s_axis_config_tready),              // output wire s_axis_config_tready
  .s_axis_data_tdata(s_data_in),                    // input wire [63 : 0] s_axis_data_tdata
  .s_axis_data_tvalid(S_DATA_VALID),                  // input wire s_axis_data_tvalid
  .s_axis_data_tready(S_DATA_READY),                  // output wire s_axis_data_tready
  .s_axis_data_tlast(S_DATA_LAST),                    // input wire s_axis_data_tlast
  .m_axis_data_tdata(m_data_out_temp),                    // output wire [63 : 0] m_axis_data_tdata
  .m_axis_data_tuser(m_data_user_temp),                    // output wire [15 : 0] m_axis_data_tuser
  .m_axis_data_tvalid(m_data_valid_temp),                  // output wire m_axis_data_tvalid
  .m_axis_data_tready(1'b1),                    // input wire m_axis_data_tready
  .m_axis_data_tlast(m_data_last_temp),                    // output wire m_axis_data_tlast
  .m_axis_status_tdata(),                // output wire [7 : 0] m_axis_status_tdata
  .m_axis_status_tvalid(),              // output wire m_axis_status_tvalid
  .m_axis_status_tready(1'b1),                // input wire m_axis_status_tready
  .event_frame_started(EVENT_FRAME_STARTED),                // output wire event_frame_started
  .event_tlast_unexpected(EVENT_TLAST_UNEXPECTED),          // output wire event_tlast_unexpected
  .event_tlast_missing(EVENT_TLAST_MISSING),                // output wire event_tlast_missing
  .event_fft_overflow(EVENT_FFT_OVERFLOW),                  // output wire event_fft_overflow
  .event_data_in_channel_halt(EVENT_DATA_IN_CHANNEL_HALT)  // output wire event_data_in_channel_halt
);

//output pipline
always @ (posedge SYS_CLK)
	begin
		if (RST) 
		    begin
				M_DATA_RE_OUT <= 28'd0;
				M_DATA_IM_OUT <= 28'd0;
				M_DATA_OUT_INDEX <= 7'd0;
				M_DATA_LAST <= 1'b0;
				M_DATA_VALID <= 1'b0;		
			end
		else 
			begin
				if (m_data_valid_temp) 
				    begin
						M_DATA_IM_OUT <= m_data_out_temp[59:32];
						M_DATA_RE_OUT <= m_data_out_temp[27:0];
						M_DATA_OUT_INDEX <= m_data_user_temp[6:0];
						M_DATA_VALID <= 1'b1;
						M_DATA_LAST <= m_data_last_temp;				        
				    end
				else 
				    begin
						M_DATA_RE_OUT <= 28'd0;
						M_DATA_IM_OUT <= 28'd0;
						M_DATA_OUT_INDEX <= 7'd0;
						M_DATA_LAST <= 1'b0;
						M_DATA_VALID <= 1'b0;					        
				    end
				
			end
	end
endmodule