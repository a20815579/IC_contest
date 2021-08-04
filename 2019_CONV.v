
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

reg 		[5:0] 	x, y;
reg 		[4:0] 	step, next;
reg signed	[39:0] 	tmp;
reg signed	[19:0] 	data, kernel; 

wire 	[11:0]	position;
assign	position = (y << 6) + x;

wire 	[39:0] 	multiply;
assign	multiply = data * kernel;

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
		step <= 0;
		tmp <= 0;
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
			step <= next;
			case (step)
				5'd0: begin
					iaddr <= position - 65;
					tmp <=  0;
					csel <= 3'b000;
					cwr <= 0;
				end
				5'd1: begin
					data <= $signed(idata);
					kernel <= 20'sh0A89E;
				end
				5'd2: begin
					iaddr <= position - 64;
					if(x != 0 && y != 0) begin
						tmp <= tmp + multiply;
					end
				end
				5'd3: begin
					data <= $signed(idata);
					kernel <= 20'sh092D5;
				end
				5'd4: begin
					iaddr <= position - 63;
					if(y != 0) begin
						tmp <= tmp + multiply;
					end
				end
				5'd5: begin
					data <= $signed(idata);
					kernel <= 20'sh06D43;
				end
				5'd6: begin
					iaddr <= position - 1;
					if(x != 63 && y != 0) begin
						tmp <= tmp + multiply;
					end
				end
				5'd7: begin
					data <= $signed(idata);
					kernel <= 20'sh01004;
				end
				5'd8: begin
					iaddr <= position;
					if(x != 0) begin
						tmp <= tmp + multiply;	
					end
				end
				5'd9: begin
					data <= $signed(idata);
					kernel <= 20'shF8F71;
				end
				5'd10: begin
					iaddr <= position + 1;
					tmp <= tmp + multiply;
				end
				5'd11: begin
					data <= $signed(idata);
					kernel <= 20'shF6E54;
				end
				5'd12: begin
					iaddr <= position + 63;
					if(x != 63) begin
						tmp <= tmp + multiply; 
					end
				end
				5'd13: begin
					data <= $signed(idata);
					kernel <= 20'shFA6D7;
				end
				5'd14: begin
					iaddr <= position + 64;
					if(x != 0 && y != 63) begin
						tmp <= tmp + multiply;
					end
				end
				5'd15: begin
					data <= $signed(idata);
					kernel <= 20'shFC834;
				end
				5'd16: begin
					iaddr <= position + 65;
					if(y != 63) begin
						tmp <= tmp + multiply;
					end
				end
				5'd17: begin
					data <= $signed(idata);
					kernel <= 20'shFAC19;
				end
				5'd18: begin
					if(x != 63 && y != 63) begin
						tmp <= tmp + multiply;
					end
				end
				5'd19: begin
					if(tmp[15] == 1) begin
						cdata_wr <= tmp[35:16] + 20'sh01311;
					end
					else begin
						cdata_wr <= tmp[35:16] + 20'sh01310;
					end
				end
				5'd20: begin
					csel <= 3'b001;
					cwr <= 1;
					caddr_wr <= position;
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
					csel <= 3'b001;
					cwr <= 0;
					crd <= 1;
					cdata_wr <= 0;
					caddr_rd <= 0;
					caddr_wr <= 0;
				end
				5'd22: begin
					caddr_rd <= caddr_rd + 1;
					if(cdata_rd > cdata_wr) begin
						cdata_wr <= cdata_rd;
					end
				end
				5'd23: begin
					caddr_rd <= caddr_rd + 63;
					if(cdata_rd > cdata_wr) begin
						cdata_wr <= cdata_rd;
					end
				end
				5'd24: begin
					caddr_rd <= caddr_rd + 1;
					if(cdata_rd > cdata_wr) begin
						cdata_wr <= cdata_rd;
					end		
				end
				5'd25: begin
					if(caddr_rd[6:0] == 7'b1111111) begin
						caddr_rd <= caddr_rd + 1;
						cwr <= 1;
						crd <= 0;
						csel <= 3'b011;
					end
					else begin
						caddr_rd <= caddr_rd - 63;
						cwr <= 1;
						crd <= 0;
						csel <= 3'b011;
					end				
					
					if(cdata_rd > cdata_wr) begin
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
		if(step >= 0 && step <= 19) begin
			next = step + 1;
		end
		else if(step == 20) begin
			if(x == 63 && y == 63) 
				next = 5'd21;
			else 
				next = 5'd0;		
		end
		else if(step >= 21 && step <= 25) begin
			next = step + 1;
		end
		else if(step == 26) begin	
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

