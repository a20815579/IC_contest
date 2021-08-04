module S2(clk, rst, S2_done, RB2_RW, RB2_A, RB2_D, RB2_Q, sen, sd);

input clk, rst;
output reg S2_done, RB2_RW;
output reg [2:0] RB2_A;
output reg [17:0] RB2_D;
input [17:0] RB2_Q;
input sen, sd;

reg [1:0] state, next;
reg [4:0] count;

always @ (posedge clk or posedge rst) begin
	if(rst) begin
		S2_done <= 0;
		RB2_RW <= 1;
		RB2_A <= 0;
		RB2_D <= 0;
		state <= 0;
		count <= 2;
	end
	else begin
		state <= next;
		case(state)
			2'd0: begin // set address
				RB2_RW <= 1;
				if(!sen) begin
					RB2_A[count] <= sd;
					if(count > 0)
						count <= count - 1;
					else
						count <= 17;
				end
			end
			2'd1: begin // set output
				if(!sen) begin
					RB2_D[count] <= sd;
					count <= count - 1;
				end
			end
			2'd2: begin 
				RB2_RW <= 0;
				count <= 2;
			end
			default: begin
				S2_done <= 1;
			end
		endcase
	end
end

always @ (*) begin
	if(rst) begin
		next = 0;
	end
	else begin
		case(state)
			2'd0: begin
				if(!sen) begin
					if(count > 0) 
						next = 0;
					else 
						next = 1;
				end
				else 
					next = 0;
			end
			2'd1: begin
				if(!sen) begin
					if(count > 0)
						next = 1;
					else 
						next = 2;
				end
				else 
					next = 0;
			end
			2'd2: begin
				if(RB2_A == 7)
					next = 3;
				else 
					next = 0;
			end
			default: begin
				next = 3;
			end
		endcase
	end
end  
 
endmodule
