module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       pixel_finish, pixel_dataout, pixel_addr,
	       pixel_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output	reg			so_data, so_valid;
output  reg			pixel_finish, pixel_wr;
output  reg [7:0] 	pixel_addr;
output  reg [7:0] 	pixel_dataout;

reg 		pixel_addr_flag;
reg [1:0] 	state;
reg [4:0] 	len_cnt_so, n_bit_reg;
reg [2:0]	len_cnt_pixel;
reg [31:0]	so_data_buf;

wire [4:0]	n_bit_wire;
assign n_bit_wire = ((pi_length+1) << 3) - 1;

always @ (posedge clk or posedge reset) begin
	if(reset) begin
		so_data <= 0;
		so_valid <= 0;
		pixel_finish <= 0;
		pixel_wr <= 0;
		pixel_addr <= 0;
		pixel_dataout <= 0;
		state <= 0;
		so_data_buf <= 0;
		pixel_addr_flag <= 0;
	end
	else begin
		case(state)
			2'd0: begin // load				
				if(load) begin
					state <= state + 1;
					len_cnt_so <= n_bit_wire;
					n_bit_reg <= n_bit_wire;
					len_cnt_pixel <= 7;
					case(pi_length)
					2'b00: begin
						if(pi_low) begin
							so_data_buf[7:0] <= pi_data[15:8];
						end
						else begin
							so_data_buf[7:0] <= pi_data[7:0]; 
						end
					end
					2'b01: begin
						so_data_buf[15:0] <= pi_data[15:0];
					end
					default: begin // pi_lenth = 24 or 32
						if(pi_fill) begin
							so_data_buf[n_bit_wire-:16] <= pi_data[15:0];
						end
						else begin
							so_data_buf[15:0] <= pi_data[15:0];
						end
					end
					endcase
				end
			end								
			2'd1: begin					
				if(pi_msb) begin
					so_data <= so_data_buf[len_cnt_so];							
					pixel_dataout[len_cnt_pixel] <= so_data_buf[len_cnt_so];
				end
				else begin
					so_data <= so_data_buf[n_bit_reg-len_cnt_so];							
					pixel_dataout[len_cnt_pixel] <= so_data_buf[n_bit_reg-len_cnt_so];
				end

				if(len_cnt_so == 5'd0) begin					
					state <= 2;
				end
				else begin
					so_valid <= 1;
					len_cnt_so <= len_cnt_so - 1;	
				end

				if(len_cnt_pixel == 0) begin //output pixel
					pixel_wr <= 1;
					//pixel_addr <= pixel_addr + 1;
					len_cnt_pixel <= 7;	
					pixel_addr_flag <= 1;				
				end
				else begin
					pixel_wr <= 0;
					len_cnt_pixel <= len_cnt_pixel - 1;
				end
				
				if(pixel_addr_flag) begin
					pixel_addr_flag <= 0;
					pixel_addr <= pixel_addr + 1;
				end
			end
			2'd2: begin
				so_valid <= 0;
				so_data_buf <= 0;
				if(pi_end) begin
					state <= 3;
					pixel_dataout <= 0;
				end
				else begin
					state <= 0;
				end
			end
			2'd3: begin
				pixel_wr <= ~pixel_wr;
				if(pixel_wr) begin
					pixel_addr <= pixel_addr + 1;
					if(pixel_addr == 255) begin
						pixel_finish <= 1;
					end
				end
			end
		endcase
	end
end

endmodule
