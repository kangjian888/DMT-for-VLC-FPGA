// =============================================================================
// Filename: control_gen.v
// Author: KANG, Jian
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:This is an AXI-S driver of the FFT ip-core
// it is the slave of the data generation module and the master of ifft or fft calculation module
// -----------------------------------------------------------------------------
`timescale 1 ns / 1 ps
module control_gen #(
    //parameter [6:0] CP_LEN = 7'd16,//the legth of cp is 16
    parameter [0:0] FWD_INV = 1'b0,//IFFT in transmitter side, and we have just one channel
    parameter [7:0] SCALE_SCH = {2'b01,2'b10,2'b10,2'b10}//because we use pepline
)
(
	input CLK,
	input RST,
	//interface of configure port to ifft or fft
	input m_axis_config_tready,
	output reg [15:0] m_axis_config_tdata,
	output reg m_axis_config_tvalid
);





reg [1:0] state_reg, state_next;

localparam IDLE=0;
localparam CONFIG=1;
localparam CONFIG_DONE=2;


//Outputs
always @ (*) 
    begin
        case (state_reg)
            IDLE:
                begin
                    m_axis_config_tdata = 24'd0;
                    m_axis_config_tvalid = 1'b0;
                end
            CONFIG:
                begin
                    m_axis_config_tdata = {7'b0000000,SCALE_SCH,FWD_INV};
                    m_axis_config_tvalid = 1'b1;
                end
            CONFIG_DONE:
                begin
                    m_axis_config_tdata = 24'd0;
                    m_axis_config_tvalid = 1'b0;
                end
            default:
                begin
                    m_axis_config_tdata = 24'd0;
                    m_axis_config_tvalid = 1'b0;
                end
        endcase
    end

//States
always @ (*)
    begin
        state_next = state_reg;
        case (state_reg)
            IDLE:
                begin
                    if (m_axis_config_tready) 
                        begin
                            state_next = CONFIG;
                        end
                    else 
                        begin
                            state_next = state_reg;
                        end
                end
            CONFIG:
                begin
                    state_next = CONFIG_DONE;
                end
            CONFIG_DONE:
                begin
                    state_next = state_reg;
                end
            default:
                begin
                    state_next = IDLE;
                end
        endcase
    end

//Update state
always @ (posedge CLK)
    begin
        if(RST)
            begin
                state_reg <= IDLE;
            end
        else
            begin
                state_reg <= state_next;
            end
    end



endmodule