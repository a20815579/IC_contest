module S1(clk, rst, RB1_RW, RB1_A, RB1_D, RB1_Q, sen, sd);

input clk, rst;
output reg RB1_RW; 
output reg [4:0] RB1_A; 
output reg [7:0] RB1_D; 
input [7:0] RB1_Q; 
output reg sen, sd;

reg [2:0] state, next;
reg [4:0] count, data_index;
reg [2:0] addr_bit;
reg [7:0] data[17:0];

integer i;

always @ (negedge clk or posedge rst) begin
	if(rst) begin
		RB1_RW <= 1;
		sen <= 1;
		sd <= 0;
		RB1_A <= 0;
		RB1_D <= 0;
		state <= 0;
		count <= 0;
		addr_bit <= 2;
		data_index <= 17;
		for(i = 0; i < 18; i = i + 1)
			data[i] <= 0;
	end
	else begin
		state <= next;
		RB1_D <= 0;
		case(state)
			3'd0: begin
				RB1_A <= count;
				RB1_RW <= 1; // read
			end
			3'd1: begin // store data
				data[count] <= RB1_Q;
				count <= count + 1;
			end
			3'd2: begin
				count <= 0;
				addr_bit <= 2;
				data_index <= 17;
			end
			3'd3: begin // send address
				sen <= 0;
				sd <= count[addr_bit];
				addr_bit <= addr_bit - 1;
			end
			3'd4: begin // send data
				sen <= 0;
				sd <= data[data_index][7 - count];
				data_index <= data_index - 1;
			end
			3'd5: begin
				sen <= 1;
				count <= count + 1;
				addr_bit <= 2;
				data_index <= 17;
			end
			default: begin
				sen <= 1;
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
			3'd0: begin
				next = 1;
			end
			3'd1: begin
				if(count < 18) 
					next = 0;
				else begin
					next = 2;
				end
			end
			3'd2: begin
				next = 3;
			end
			3'd3: begin
				if(addr_bit > 0) 
					next = 3;
				else 
					next = 4;
			end
			3'd4: begin
				if(data_index > 0)
					next = 4;
				else 
					next = 5;
			end
			3'd5: begin
				if(count < 7)
					next = 3;
				else 
					next = 6;
			end
			default: begin
				next = 6;
			end
		endcase
	end
end  
 
endmodule
