module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       pixel_finish, pixel_dataout, pixel_addr,
	       pixel_wr);

input			clk, reset;
input			load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input			pi_fill;

output reg			so_data, so_valid;
output reg 			pixel_finish, pixel_wr;
output reg 	[7:0] 	pixel_addr;
output reg 	[7:0] 	pixel_dataout;

reg [4:0] index;
reg [2:0] pixel_index;
reg [1:0] state, next;
reg [7:0] pixel_count;

localparam LOAD = 2'b00;
localparam PROCESS = 2'b01;
localparam TERMINATE = 2'b10;

always @ (posedge clk or posedge reset) begin
	if(reset) 
		state <= LOAD;
	else 
		state <= next;
end

always @ ( * ) begin
	case(state)
		LOAD: begin
			if(load)
				next = PROCESS;
			else if(pi_end)
				next = TERMINATE;
			else
				next = LOAD;
		end
		PROCESS: begin
			if(pi_msb) begin
				if((pi_length == 2'b00 && pi_low && index == 8) || (index == 0)) begin
					next = LOAD;
				end
				else 
					next = PROCESS;
			end
			else begin
				if((pi_length == 2'b00 && pi_low && index == 15) || (index == {pi_length, 3'b111})) begin
					next = LOAD;
				end
				else 
					next = PROCESS;
			end
		end
		TERMINATE:
			if(pixel_addr != 255)
				next = LOAD;
			else 
				next = TERMINATE;
	endcase
end

always @ (posedge clk or posedge reset) begin
	if(reset) begin
		so_data <= 0;
		so_valid <= 0;
		pixel_addr <= 0;
		pixel_dataout <= 0;
		index <= 0;
		pixel_index <= 7;
		pixel_count <= 0;
	end
	else begin
		case(state)
			LOAD: begin
				so_valid <= 0;
				pixel_wr <= 0;
				if(load) begin
					if(pi_msb) begin
						if(pi_length == 2'b00 && pi_low)
							index <= 15;
						else
							index <= {pi_length, 3'b111};
					end
					else begin
						if(pi_length == 2'b00 && pi_low)
							index <= 8;
						else 
							index <= 0;					
					end
				end
			end
			PROCESS: begin
				so_valid <= 1;				
				pixel_index <= pixel_index - 1;
				
				if(pi_msb) begin
					index <= index - 1;
				end
				else begin
					index <= index + 1;
				end
				
				if(pi_length[1] == 1) begin // 24 or 32 bit
					if(pi_fill) begin
						if(pi_length[0] == 0) begin
							if(index[4:3] == 2'b00) begin 
								so_data <= 0;
								pixel_dataout[pixel_index] <= 0;
							end
							else begin
								so_data <= pi_data[index - 8];						
								pixel_dataout[pixel_index] <= pi_data[index - 8];
							end
						end
						else begin
							if(index[4] == 0) begin
								so_data <= 0;
								pixel_dataout[pixel_index] <= 0;
							end
							else begin 
								so_data <= pi_data[index - 16];						
								pixel_dataout[pixel_index] <= pi_data[index - 16];
							end
						end
					end
					else begin
						if(index[4] == 1) begin
							so_data <= 0;
							pixel_dataout[pixel_index] <= 0;
						end
						else begin 
							so_data <= pi_data[index];
							pixel_dataout[pixel_index] <= pi_data[index];
						end
					end
				end
				else begin // 8 or 16 bit
					so_data <= pi_data[index];
					pixel_dataout[pixel_index] <= pi_data[index];
				end
				
				if(pixel_index == 0) begin
					pixel_wr <= 1;
					pixel_addr <= pixel_count;
					pixel_count <= pixel_count + 1;
				end
				else 
					pixel_wr <= 0;
			end
			TERMINATE: begin
				if(pixel_count == 255) 
					pixel_finish <= 1;
				pixel_wr <= 1;
				pixel_addr <= pixel_count;
				pixel_count <= pixel_count + 1;
				pixel_dataout <= 0;
			end
		endcase
	end
end

endmodule
