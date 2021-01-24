// =============================================================================
// Filename: MainControlUnit.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:
// -----------------------------------------------------------------------------
module MainControlUnit#(
    parameter OFDM_FRAME_NUM = 100
)
(
	input SYS_CLK, 
    input SYMBOL_CLK,
    input S_MCU_RST, //high active, syn to SYS_CLK
    input S_SYM_RST,
	input SEND_ENABLE, //syn to SYS_CLK, inpulse means begin to transmission.
    input TRANSMISSION_DONE,
    output reg PHY_RST, //initalize other module of transmitter
    output reg SHORT_ACK, //short sequences transmission start signal
    output reg LONG_ACK, //long sequences transmission enable signal
    output reg DATA_REQ //require data transmission to mac layer
);

//********************************************************************************//
//PART 1: FSM  to txstart_req generation
//********************************************************************************//
reg txstart_req;
reg [1:0] state_reg, state_next;

localparam IDLE=0;
localparam BEGIN_TRANSMISSION=1;
localparam TRANSMISSION_PROCESS=2;

//Outputs
always @ (*) 
    begin
        case (state_reg)
            IDLE:
                begin
                    txstart_req = 1'b0;
                end
            BEGIN_TRANSMISSION:
                begin
                    txstart_req = 1'b1;
                end
            TRANSMISSION_PROCESS:
                begin
                    txstart_req = 1'b0;
                end
            default:
                begin
                    txstart_req = 1'b0;
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
                    if (SEND_ENABLE) 
                        begin
                            state_next = BEGIN_TRANSMISSION;
                        end
                    else 
                        begin
                            state_next = IDLE;
                        end
                end
            BEGIN_TRANSMISSION:
                begin
                    state_next = TRANSMISSION_PROCESS;
                end
            TRANSMISSION_PROCESS:
                begin
                    if (TRANSMISSION_DONE) 
                        begin
                            state_next = IDLE;                           
                        end
                    else 
                        begin
                            state_next = TRANSMISSION_PROCESS;
                        end
                end
            default:
                begin
                    state_next = IDLE;
                end
        endcase
    end

//Update state
always @ (posedge SYMBOL_CLK)
    begin
        if(S_SYM_RST)
            begin
                state_reg <= IDLE;
            end
        else
            begin
                state_reg <= state_next;
            end
    end



//********************************************************************************//
//PART 2: Generate the reset signal
//********************************************************************************//
//inner reg
reg phy_reset_cont;
reg [3:0] phy_reset_counter; //phy_reset continue 10 cycle sys_clk
reg phy_reset_done; //physical layer reset done

always @ (posedge SYMBOL_CLK)
    begin
        if(S_SYM_RST)
            begin
               phy_reset_done <=  1'b0;
               PHY_RST <= 1'b0;
               phy_reset_counter <= 4'd0;
            end
        else
            begin
                if (txstart_req) 
                    begin
                        phy_reset_cont <= 1'b0;
                        PHY_RST <= 1'b1;
                        phy_reset_cont <= 1'b1;
                    end
                if (phy_reset_cont == 1'b1) 
                    begin
                        phy_reset_counter <= phy_reset_counter + 1'b1;
                    end
                if (phy_reset_counter == 4'd10) 
                    begin
                        phy_reset_cont <= 1'b0; 
                        PHY_RST <= 1'b0;
                        phy_reset_done <= 1'b1;
                        phy_reset_counter <= 4'd0;
                    end
                if (phy_reset_done == 1'b1) 
                    begin
                        phy_reset_done <= ~phy_reset_done;
                    end
            end
    end

//********************************************************************************//
//PART 3: This part is used to control signal transmission
//********************************************************************************//
//inner register
reg counter_64_TS_delay_enable;
wire TS_delay_done;
reg counter_1024_enable;
wire [9:0] counter_1024_value;

counter_64_TS_delay counter_64_TS_delay_inst (
  .CLK(SYS_CLK),          // input wire CLK
  .CE(counter_64_TS_delay_enable),            // input wire CE
  .SCLR(S_MCU_RST|PHY_RST),        // input wire SCLR
  .THRESH0(TS_delay_done),  // output wire THRESH0
  .Q()              // output wire [5 : 0] Q
);
counter_1024 counter_1024_inst(
    .CLK(SYS_CLK),
    .SCLR(S_MCU_RST|PHY_RST),
    .CE(counter_1024_enable),
    .Q(counter_1024_value)
	);

always @ (posedge SYS_CLK)
    begin
        if(S_MCU_RST|PHY_RST)
        	begin
        		counter_64_TS_delay_enable <= 1'b0;
                counter_1024_enable <= 1'b0;
        		SHORT_ACK <= 1'b0;
        		LONG_ACK <= 1'b0;
        	end
        else
        	begin
        		if (phy_reset_done) 
        		    begin
        		        counter_64_TS_delay_enable <= 1'b1;
        		    end
                if (TS_delay_done)
                    begin
                        counter_64_TS_delay_enable <= 1'b0;
                        counter_1024_enable <= 1'b1;
                        SHORT_ACK <= 1'b1;
                    end
        		if(counter_1024_value == 10'd320)
        			begin
        				SHORT_ACK <= 1'b0;
        			end
        		if (counter_1024_value == 10'd319) 
        		    begin
        		        LONG_ACK <= 1'b1;
        		    end
        		if (counter_1024_value == 10'd608) 
        		    begin
        		        counter_1024_enable <= 1'b0;
        		        LONG_ACK <= 1'b0;
        		    end
        	end
    end


//********************************************************************************//
//PART 4: This part is used to data signal transmission
//********************************************************************************//
reg counter_data_txstart_gen_enable;
reg [15:0] n_ofdm_data; //counter for the byte number of one psdu, add one bit as sign bit
wire data_txstart;
reg counter_data_req_gen_enable;
wire data_req;

counter_data_txstart_gen counter_data_txstart_gen_inst(
    .CLK(SYS_CLK),
    .CE(counter_data_txstart_gen_enable),
    .SCLR(S_MCU_RST|PHY_RST),
    .THRESH0(data_txstart),
    .Q()
    );

counter_data_req_gen counter_data_req_gen_inst (
  .CLK(SYS_CLK),          // input wire CLK
  .CE(counter_data_req_gen_enable),            // input wire CE
  .SCLR(S_MCU_RST|PHY_RST),        // input wire SCLR
  .THRESH0(data_req),  // output wire THRESH0
  .Q()              // output wire [5 : 0] Q
);
always @ (posedge SYS_CLK)
    begin
        if(S_MCU_RST|PHY_RST)
            begin
                counter_data_txstart_gen_enable <= 1'b0;
                counter_data_req_gen_enable <= 1'b0;
                n_ofdm_data <= 16'd0;
                DATA_REQ <= 1'b0;
            end
        else
            begin
                if (phy_reset_done) 
                    begin
                        counter_data_txstart_gen_enable <= 1'b1;
                        n_ofdm_data <= OFDM_FRAME_NUM;
                    end
                if (data_txstart) 
                    begin
                        counter_data_txstart_gen_enable <= 1'b0;
                        counter_data_req_gen_enable <= 1'b1;
                    end
                if (data_req) 
                    begin
                        DATA_REQ <= 1'b1; //this should include request both symbol domain and data domain data.
                        n_ofdm_data <= n_ofdm_data - 1'b1;// one ofdm symbol include 52 16-qam symbol which is 26 bytes in default situation.
                    end
                else 
                    begin
                        DATA_REQ <= 1'b0;
                    end
                if(n_ofdm_data == 0)
                    begin
                        counter_data_req_gen_enable <= 1'b0;
                    end
            end
    end
endmodule