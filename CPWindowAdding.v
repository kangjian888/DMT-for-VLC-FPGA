// =============================================================================
// Filename: CPWindowAdding.v
// Author: 
// Email: jkangac@connect.ust.hk
// Affiliation: Hong Kong University of Science and Technology
// Description:
// -----------------------------------------------------------------------------
module CPWindowAdding(
	input SYS_CLK,
	input RST,
	input [27:0] DATA_IN,
	input [6:0] DATA_INDEX_IN,
	input DATA_IN_VALID,
	output reg [27:0] DATA_OUT,
    output reg DATA_OUT_LAST,
	output reg DATA_OUT_VALID 
);

reg write_flag; //if flag==0, the first is written, or the secodn is written
wire write_enable_ram1;
wire write_enable_ram2;
reg read_enable;
reg data_from_ram_enable;
reg [6:0] read_address;
reg data_out_last; //the last symbol of one ofdm symbol
//RAM implenmentation
wire [27:0] read_data_out_ram1;
wire [27:0] read_data_out_ram2;

blk_mem_cp_adding ram1 (
  .clka(SYS_CLK),    // input wire clka
  .wea(write_enable_ram1),      // input wire [0 : 0] wea
  .addra(DATA_INDEX_IN),  // input wire [6 : 0] addra
  .dina(DATA_IN),    // input wire [27 : 0] dina
  .clkb(SYS_CLK),    // input wire clkb
  .enb(read_enable),      // input wire enb
  .addrb(read_address),  // input wire [6 : 0] addrb
  .doutb(read_data_out_ram1)  // output wire [27 : 0] doutb
);
blk_mem_cp_adding ram2 (
  .clka(SYS_CLK),    // input wire clka
  .wea(write_enable_ram2),      // input wire [0 : 0] wea
  .addra(DATA_INDEX_IN),  // input wire [6 : 0] addra
  .dina(DATA_IN),    // input wire [27 : 0] dina
  .clkb(SYS_CLK),    // input wire clkb
  .enb(read_enable),      // input wire enb
  .addrb(read_address),  // input wire [6 : 0] addrb
  .doutb(read_data_out_ram2)  // output wire [27 : 0] doutb
);

//RAM chosen signal

always @ (posedge SYS_CLK)
    begin
        if(RST)
        	begin
        		write_flag <= 1'b0;
        	end
        else
        	begin
        		if (DATA_INDEX_IN == 7'd127) 
        		    begin
        		        write_flag <= ~write_flag;
        		    end
        		else 
        		    begin
        		        write_flag <= write_flag;
        		    end
        	end
    end

//RAM wirte enable signal generation
assign write_enable_ram1 = DATA_IN_VALID & (~write_flag);
assign write_enable_ram2 = DATA_IN_VALID & write_flag;

//RAM read signal generation
always @ (posedge SYS_CLK)
    begin
        if(RST)
        	begin
                data_out_last <= 1'b0;
        		read_enable <= 1'b0;
                data_from_ram_enable <= 1'b0;
        	end
        else
        	begin
                data_out_last <= 1'B0;
                data_from_ram_enable <= read_enable;
        		if (DATA_INDEX_IN == 7'd126) 
        		    begin
        		        read_enable <= 1'b1;
        		    end
        		if (read_address == 7'd127) 
        		    begin
        		        read_enable <= 1'b0;
                        data_out_last <= 1'b1;
        		    end
        	end
    end

always @ (posedge SYS_CLK)
    begin
        if(RST)
        	begin
        		read_address <= 7'd0;
        	end
        else
        	begin
 				if (DATA_INDEX_IN == 7'd127 ||read_enable) 
 				    begin
 				        read_address <= read_address + 1'b1;
 				    end
 				else 
 				    begin
 				        read_address <= 7'd0;
 				    end       		
        	end
    end
//store the first value in the register
reg [27:0] first_data_ram1;//the first data when write ram1 
reg [27:0] first_data_ram2;//the first data when write ram2
always @ (posedge SYS_CLK)
    begin
        if(RST)
        	begin
        		first_data_ram1 <= 28'd0;
        		first_data_ram2 <= 28'd0;
        	end
        else
        	begin
        		if (DATA_INDEX_IN == 7'd0) 
        		    begin
        		        if(write_flag == 1'b0) 
        		            begin
        		                first_data_ram1 <= DATA_IN;
        		            end
        		        else if(write_flag == 1'b1) 
        		            begin
        		                first_data_ram2 <= DATA_IN;
        		            end
        		        else 
        		            begin
        		                first_data_ram1 <= 28'd0;
        		                first_data_ram2 <= 28'd0;
        		            end
        		    end
        		else 
        		    begin
        		        first_data_ram1 <= first_data_ram1;
        		        first_data_ram2 <= first_data_ram2;
        		    end
        	end
    end
// Output stage
always @ (posedge SYS_CLK)
    begin
        if(RST)
        	begin
        		DATA_OUT <= 28'd0;
                DATA_OUT_LAST <= 1'b0;
        		DATA_OUT_VALID <= 1'b0;
        	end
        else
        	begin
                DATA_OUT_LAST <= data_out_last;
        		if (DATA_INDEX_IN == 7'd96) 
        		    begin
        		        DATA_OUT_VALID <= 1'b1;
        		        if (~write_flag) 
        		            begin
   								DATA_OUT <= ($signed(DATA_IN) >>> 1) + ($signed(first_data_ram2) >>>1);       		                       		                
        		            end
        		        else 
        		            begin
         		        		DATA_OUT <= ($signed(DATA_IN) >>> 1) + ($signed(first_data_ram1) >>> 1);       		                
        		            end
        		    end
        		else if(DATA_INDEX_IN > 7'd96)
        		    begin
        		        DATA_OUT <= DATA_IN;
        		        DATA_OUT_VALID <= 1'b1;
        		    end
        		else 
        		    begin
        		        if (data_from_ram_enable) 
        		            begin
        		                DATA_OUT_VALID <= 1'b1;
        		                if (write_flag) 
        		                    begin
        		                        DATA_OUT <= read_data_out_ram1;
        		                    end
        		                else 
        		                    begin
        		                        DATA_OUT <= read_data_out_ram2;
        		                    end
        		            end
        		        else if((~data_from_ram_enable)&&(~DATA_IN_VALID))
        		            begin
        		                DATA_OUT <= 28'd0;
        		                DATA_OUT_VALID <= 1'b0;
        		            end
        		    end
        	end
    end
endmodule