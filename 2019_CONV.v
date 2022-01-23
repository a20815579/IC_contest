
`timescale 1ns/10ps

module  CONV(
	input				clk,
	input				reset,
	output	reg			busy,	
	input				ready,	
			
	output	reg [11:0]	iaddr,
	input		[19:0]	idata,	
	
	output	reg  		cwr,
	output	reg [11:0]	caddr_wr,
	output	reg [19:0]	cdata_wr,
	
	output	reg 		crd,
	output	reg [11:0]	caddr_rd,
	input		[19:0] 	cdata_rd,
	
	output	reg	[2:0] 	csel
	);

localparam 	K1 = 20'sh0A89E,
			K2 = 20'sh092D5,
			K3 = 20'sh06D43,
			K4 = 20'sh01004,
			K5 = 20'shF8F71,
			K6 = 20'shF6E54,
			K7 = 20'shFA6D7,
			K8 = 20'shFC834,
			K9 = 20'shFAC19,
			bias = 20'sh01310;

reg 		[5:0] 	x, y;
reg 		[4:0] 	state, next;
reg signed	[39:0] 	sum;
reg signed	[19:0] 	data, kernel; 

wire 	[11:0]	position;
assign	position = (y << 6) + x;

wire 	[39:0] 	multi;
assign	multi = data * kernel;

wire bigger;
assign bigger = (cdata_rd > cdata_wr);

always @ (posedge clk or posedge reset) begin
	if(reset) begin
		busy <= 0;
		iaddr <= 0;
		cwr <= 0;
		caddr_wr <= 0;
		cdata_wr <= 0;
		crd <= 0;
		caddr_rd <= 0;
		csel <= 0;
		state <= 0;
		sum <= 0;
		x <= 0;
		y <= 0;
	end
	else begin
		if(!busy) begin
			if(ready) begin
				busy <= 1;
			end
		end
		else begin
			state <= next;
			case (state)
				5'd0: begin
					iaddr <= position - 65;
					sum <=  0;
					csel <= 3'b000;
					cwr <= 0;
				end
				5'd1: begin
					data <= $signed(idata);
					kernel <= K1;
				end
				5'd2: begin
					iaddr <= position - 64;
					if(x != 0 && y != 0) begin
						sum <= sum + multi;
					end
				end
				5'd3: begin
					data <= $signed(idata);
					kernel <= K2;
				end
				5'd4: begin
					iaddr <= position - 63;
					if(y != 0) begin
						sum <= sum + multi;
					end
				end
				5'd5: begin
					data <= $signed(idata);
					kernel <= K3;
				end
				5'd6: begin
					iaddr <= position - 1;
					if(x != 63 && y != 0) begin
						sum <= sum + multi;
					end
				end
				5'd7: begin
					data <= $signed(idata);
					kernel <= K4;
				end
				5'd8: begin
					iaddr <= position;
					if(x != 0) begin
						sum <= sum + multi;	
					end
				end
				5'd9: begin
					data <= $signed(idata);
					kernel <= K5;
				end
				5'd10: begin
					iaddr <= position + 1;
					sum <= sum + multi;
				end
				5'd11: begin
					data <= $signed(idata);
					kernel <= K6;
				end
				5'd12: begin
					iaddr <= position + 63;
					if(x != 63) begin
						sum <= sum + multi; 
					end
				end
				5'd13: begin
					data <= $signed(idata);
					kernel <= K7;
				end
				5'd14: begin
					iaddr <= position + 64;
					if(x != 0 && y != 63) begin
						sum <= sum + multi;
					end
				end
				5'd15: begin
					data <= $signed(idata);
					kernel <= K8;
				end
				5'd16: begin
					iaddr <= position + 65;
					if(y != 63) begin
						sum <= sum + multi;
					end
				end
				5'd17: begin
					data <= $signed(idata);
					kernel <= K9;
				end
				5'd18: begin
					if(x != 63 && y != 63) begin
						sum <= sum + multi;
					end
				end
				5'd19: begin
					if(sum[15] == 1) begin
						cdata_wr <= sum[35:16] + bias + 1;
					end
					else begin
						cdata_wr <= sum[35:16] + bias;
					end
				end
				5'd20: begin
					csel <= 3'b001;
					cwr <= 1;
					caddr_wr <= position;
					// ReLU					
					if(cdata_wr[19] == 1) begin
						cdata_wr <= 0; 
					end				
					if(x == 63 && y == 63) begin
						x <= 0;
						y <= 0;
					end
					else begin
						if(x == 63) begin
							x <= 0;
							y <= y + 1;
						end
						else begin
							x <= x + 1;
						end
					end
				end
				5'd21: begin
					//csel <= 3'b001;
					cwr <= 0;
					crd <= 1;
					cdata_wr <= 0;
					caddr_rd <= 0;
					caddr_wr <= 0;
				end
				5'd22: begin // max pool
					caddr_rd <= caddr_rd + 1;
					if(bigger) begin
						cdata_wr <= cdata_rd;
					end
				end
				5'd23: begin
					caddr_rd <= caddr_rd + 63;
					if(bigger) begin
						cdata_wr <= cdata_rd;
					end
				end
				5'd24: begin
					caddr_rd <= caddr_rd + 1;
					if(bigger) begin
						cdata_wr <= cdata_rd;
					end		
				end
				5'd25: begin
					cwr <= 1;
					crd <= 0;
					csel <= 3'b011;
					if(caddr_rd[6:0] == 7'b1111111) begin // change row
						caddr_rd <= caddr_rd + 1;					
					end
					else begin
						caddr_rd <= caddr_rd - 63;						
					end									
					if(bigger) begin
						cdata_wr <= cdata_rd;
					end
				end
				5'd26: begin
					if(caddr_wr == 1023) begin
						csel <= 3'b000;
						cwr <= 0;
						crd <= 0;
						busy <= 0;
					end
					else begin
						csel <= 3'b001;
						cwr <= 0;
						crd <= 1;
						cdata_wr <= 0;
						caddr_wr <= caddr_wr + 1;
					end
				end
			endcase
		end
	end
end

always @ (*) begin
	next = 0;
	if(busy) begin 
		if(state >= 0 && state <= 19) begin
			next = state + 1;
		end
		else if(state == 20) begin
			if(x == 63 && y == 63) 
				next = 5'd21;
			else 
				next = 5'd0;		
		end
		else if(state >= 21 && state <= 25) begin
			next = state + 1;
		end
		else if(state == 26) begin	
			if(caddr_wr == 1023) 
				next = 5'd26;
			else	
				next = 5'd22;
		end
		else begin
			next = 0;
		end
	end
end

endmodule

