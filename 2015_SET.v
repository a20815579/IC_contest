module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input 			clk, rst;
input 			en;
input 	[23:0] 	central;
input 	[11:0] 	radius;
input 	[1:0] 	mode;
output reg 			busy;
output reg			valid;
output reg 	[7:0] 	candidate;

reg 	[3:0]	x1, y1, x2, y2, r1, r2;
reg 	[3:0]  	x, y;

wire	[3:0] 	x1_diff, x2_diff, y1_diff, y2_diff;
wire 	[7:0]	p1_diff, p2_diff;
wire 	[7:0]	R1, R2;

assign x1_diff = (x > x1) ? x-x1 : x1-x;
assign y1_diff = (y > y1) ? y-y1 : y1-y;
assign x2_diff = (x > x2) ? x-x2 : x2-x;
assign y2_diff = (y > y2) ? y-y2 : y2-y;
assign p1_diff = x1_diff * x1_diff + y1_diff * y1_diff;
assign p2_diff = x2_diff * x2_diff + y2_diff * y2_diff; 
assign R1 = r1 * r1;
assign R2 = r2 * r2;

always @ (posedge clk or posedge rst) begin
	if(rst) begin
		busy <= 0;
		valid <= 0;
		candidate <= 8'd0;
		x1 <= 0;
		x2 <= 0;
		y1 <= 0;
		y2 <= 0;
		r1 <= 0;
		r2 <= 0;
		x <= 1;
		y <= 1;
	end
	else begin
		if(!busy) begin
			if(en) begin
				x1 <= central[23:20];
				y1 <= central[19:16];
				x2 <= central[15:12];
				y2 <= central[11:8];
				r1 <= radius[11:8];
				r2 <= radius[7:4];
				busy <= 1;
				x <= 4'd1;
				y <= 4'd1;
				candidate <= 0;
			end
		end
		else begin
			if(valid) begin
				busy <= 0;
				valid <= 0;
			end
			else begin	
				case(mode) 
					2'b00: begin
						if(R1 >= p1_diff)
							candidate <= candidate + 1;
					end
					2'b01: begin
						if(R1 >= p1_diff && R2 >= p1_diff)
							candidate <= candidate + 1;
					end
					2'b10: begin
						if((R1 >= p1_diff && R2 < p2_diff) || (R2 >= p2_diff && R1 < p1_diff))
							candidate <= candidate + 1;
					end
				endcase
				if(x == 4'd8) begin
					x <= 1;
					y <= y + 1;
					if(y == 4'd8)
						valid <= 1;					
				end
				else begin
					x <= x + 1;
				end
			end
		end
	end
end

endmodule
