module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);

input 			clk;
input 			reset;
input 	[7:0] 	IROM_Q;
input 	[2:0] 	cmd;
input 			cmd_valid;

output reg 		 IROM_EN;
output reg [5:0] IROM_A;
output reg 		 IRB_RW;
output reg [7:0] IRB_D;
output reg [5:0] IRB_A;
output reg 		 busy;
output reg		 done;

reg [7:0] buffer [63:0];
reg [6:0] count;
reg [2:0] x, y;

wire [5:0] TopLeft, TopRight, BottomLeft, BottomRight;
assign BottomRight = (y << 3) + x;
assign TopLeft = BottomRight - 9;
assign TopRight = BottomRight - 8;
assign BottomLeft = BottomRight - 1;

wire [9:0] average;
assign average = ((buffer[TopLeft] + buffer[TopRight]) + (buffer[BottomLeft] + buffer[BottomRight])) >> 2;

integer i;

always @ (posedge clk or posedge reset) begin
	if(reset) begin
		IROM_EN <= 0;
		IROM_A <= 6'd0;
		IRB_RW <= 1;
		IRB_D <= 8'd0;
		IRB_A <= 6'd0;
		busy <= 1;
		done <= 0;
		for(i = 0; i < 64; i = i + 1) 
			buffer[i] <= 8'd0;
		count <= 7'd0;
		x <= 3'd4;
		y <= 3'd4;
	end
	else begin
		if(busy) begin
			if(!IROM_EN) begin
				if(count == 7'd65) begin
					count <= 0;
					busy <= 0;
					IROM_EN <= 1;
				end
				else begin
					buffer[count-1] <= IROM_Q;
					IROM_A <= IROM_A + 1;
					count <= count + 1;
				end
			end
			else begin
				case(cmd)
					3'd0: begin // Write
						if(count == 7'd63) begin
							busy <= 0;
							done <= 1;
						end
						else begin
							IRB_D <= buffer[IRB_A+1];
							IRB_A <= IRB_A + 1;
							count <= count + 1;
						end	
					end
					3'd1: begin // Shift Up
						y <= (y == 1) ? y : y-1; 
						busy <= 0;
					end
					3'd2: begin // Shift Down
						y <= (y == 7) ? y : y+1;
						busy <= 0;
					end
					3'd3: begin // Shift Left
						x <= (x == 1) ? x : x-1;
						busy <= 0;
					end
					3'd4: begin // Shift Right
						x <= (x == 7) ? x : x+1;
						busy <= 0;
					end
					3'd5: begin // Average
						buffer[TopLeft]	<= average;
						buffer[TopRight] <= average;
						buffer[BottomLeft] <= average;
						buffer[BottomRight]	<= average;
						busy <= 0;
					end
					3'd6: begin // Mirror X
						buffer[TopLeft]	<=	buffer[BottomLeft];
						buffer[TopRight]	<= 	buffer[BottomRight];
						buffer[BottomLeft]	<= 	buffer[TopLeft];
						buffer[BottomRight]	<= 	buffer[TopRight];
						busy <= 0;
					end
					3'd7: begin // Mirror Y
						buffer[TopLeft]	<= buffer[TopRight];
						buffer[TopRight] <= buffer[TopLeft];
						buffer[BottomLeft] <= buffer[BottomRight];
						buffer[BottomRight]	<= buffer[BottomLeft];					
						busy <= 0;
					end
				endcase
			end
		end
		else begin
			if(cmd_valid) begin
				busy <= 1;
				if(cmd == 3'd0) begin
					IRB_RW <= 0;
					IRB_D <= buffer[0];
					IRB_A <= 0;
					count <= 0;
				end
			end	
		end
	end
end

endmodule
