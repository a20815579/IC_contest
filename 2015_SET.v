module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input 			clk, rst;
input 			en;
input 	[23:0] 	central;
input 	[11:0] 	radius;
input 	[1:0] 	mode;

output 			busy;
output 			valid;
output 	[7:0] 	candidate;

reg 			busy;
reg 			valid;
reg 	[7:0] 	candidate;
reg 	[3:0]	x1, y1, x2, y2;
reg 	[3:0] 	r1, r2;
reg 	[3:0]  	x, y;
reg 			state;

wire	[3:0] 	x1_diff, x2_diff, y1_diff, y2_diff;
wire 	[7:0]	distance1, distance2;
wire 	[7:0]	R1, R2;

assign x1_diff = (x >= x1) ? x-x1 : x1-x;
assign x2_diff = (x >= x2) ? x-x2 : x2-x;
assign y1_diff = (y >= y1) ? y-y1 : y1-y;
assign y2_diff = (y >= y2) ? y-y2 : y2-y;
assign distance1 = x1_diff * x1_diff + y1_diff * y1_diff;
assign distance2 = x2_diff * x2_diff + y2_diff * y2_diff; 
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
				x1 <= central[23:20];//A
				y1 <= central[19:16];//B
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
			if(y > 8 || x > 8) begin
				busy <= 0;
				valid <= 0;
			end
			else begin	
				case(mode) 
					2'b00: begin
						if(R1 >= distance1)
							candidate <= candidate + 1;
					end//A
					2'b01: begin
						if(R1 >= distance1 && R2 >= distance2)
							candidate <= candidate + 1;
						end//A and B
					2'b10: begin
						if((R1 >= distance1 && R2 < distance2) || (R2 >= distance2 && R1 < distance1))
							candidate <= candidate + 1;
					end//(A or B) - (A and B)
				endcase
				if(y == 8) begin
					if(x == 8)
						valid <= 1;
					y <= 1;
					x <= x + 1;
				end
				else begin
					y <= y + 1;
				end
			end
		end
	end
end

endmodule
