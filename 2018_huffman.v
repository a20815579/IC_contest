module huffman ( clk, reset, gray_valid, gray_data, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
	code_valid, HC1, HC2, HC3, HC4, HC5, HC6, M1, M2, M3, M4, M5, M6);


input 			clk;
input 			reset;
input 			gray_valid;
input 	[7:0] 	gray_data;

output reg CNT_valid;
output reg [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output reg code_valid;
output reg [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output reg [7:0] M1, M2, M3, M4, M5, M6;

reg [3:0] state, next;
reg [6:0] count;
reg [3:0] index;
reg [7:0] array [5:0]; // for bubble sort
reg [3:0] round; // the nth combination
reg [23:0] combine [3:0];
reg [23:0] result [9:0];
integer i, j, k;

always @ (posedge clk or posedge reset) begin
	if(reset) begin
		CNT_valid <= 0;
		CNT1 <= 0;
		CNT2 <= 0;
		CNT3 <= 0;
		CNT4 <= 0;
		CNT5 <= 0;
		CNT6 <= 0;
		code_valid <= 0;
		HC1 <= 0;
		HC2 <= 0;
		HC3 <= 0;
		HC4 <= 0;
		HC5 <= 0;
		HC6 <= 0;
		M1 <= 0;
		M2 <= 0;
		M3 <= 0;
		M4 <= 0;
		M5 <= 0;
		M6 <= 0;
		state <= 0;
		count <= 0;
		index <= 5;
		round <= 0;
		for(i = 0; i < 6; i = i + 1)
			array[i] <= 0;
		for(j = 0; j < 4; j = j + 1)
			combine[j] <= 0;
		for(k = 0; k < 10; k = k + 1)
			result[k] <= 0;
	end
	else begin
		state <= next;
		case(state)
			4'd0: begin
				if(gray_valid) begin
					count <= count + 1;
					case(gray_data) 
						8'h01: begin
							CNT1 <= CNT1 + 1;
						end
						8'h02: begin
							CNT2 <= CNT2 + 1;
						end
						8'h03: begin
							CNT3 <= CNT3 + 1;
						end
						8'h04: begin
							CNT4 <= CNT4 + 1;
						end
						8'h05: begin
							CNT5 <= CNT5 + 1;
						end
						default: begin
							CNT6 <= CNT6 + 1;
						end
					endcase
					if(count == 99) begin
						CNT_valid <= 1;
					end	
				end
			end
			4'd1: begin
				CNT_valid <= 0;
				array[0] <= CNT1;
				array[1] <= CNT2;
				array[2] <= CNT3;
				array[3] <= CNT4;
				array[4] <= CNT5;
				array[5] <= CNT6;
				count <= 0;
			end
			4'd2: begin // sort, (0, 1), (2, 3), (4, 5)
				count <= count + 1;
				if(array[0] < array[1]) begin
					array[0] <= array[1];
					array[1] <= array[0];
				end
				if(array[2] < array[3]) begin
					array[2] <= array[3];
					array[3] <= array[2];
				end
				if(array[4] < array[5]) begin
					array[4] <= array[5];
					array[5] <= array[4];
				end
			end
			4'd3: begin // sort, (1, 2), (3, 4)
				count <= count + 1;
				if(array[1] < array[2]) begin
					array[1] <= array[2];
					array[2] <= array[1];
				end
				if(array[3] < array[4]) begin
					array[3] <= array[4];
					array[4] <= array[3];
				end
			end
			4'd4: begin // combine
				combine[round][23:8] <= {array[index-1], array[index]};
				array[index-1] <= array[index-1] + array[index];
				array[index] <= 0;
				count <= 0;
			end
			4'd5: begin // store combination
				combine[round][7:0] <= array[index-1];
				index <= index - 1;
				round <= round + 1;
			end
			4'd6: begin
				count <= 0;
				round <= 1;
				index <= 9;
				result[0] <= {array[0], 8'h00, 8'h01};
				result[1] <= {array[1], 8'h01, 8'h01}; 
			end
			4'd7: begin // find sum and extend its HC, M
				if(result[index][23:16] == combine[4-round][7:0]) begin
					result[round<<1] <= {combine[4-round][23:16], result[index][14:8], 1'b0, result[index][6:0], 1'b1};
					result[(round<<1) + 1] <= {combine[4-round][15:8], result[index][14:8], 1'b1, result[index][6:0], 1'b1};
					index <= 9;
					round <= round + 1;
				end
				else begin
					index <= index - 1;
				end
			end
			4'd8: begin
				if(result[index][23:16] == CNT1) begin
					index <= 0;
					result[index][23:16] <= 0;
					HC1 <= result[index][15:8];
					M1 <= result[index][7:0];
				end
				else begin
					index <= index + 1;
				end
			end
			4'd9: begin
				if(result[index][23:16] == CNT2) begin
					index <= 0;
					result[index][23:16] <= 0;
					HC2 <= result[index][15:8];
					M2 <= result[index][7:0];
				end
				else begin
					index <= index + 1;
				end
			end
			4'd10: begin
				if(result[index][23:16] == CNT3) begin
					index <= 0;
					result[index][23:16] <= 0;
					HC3 <= result[index][15:8];
					M3 <= result[index][7:0];
				end
				else begin
					index <= index + 1;
				end
			end
			4'd11: begin
				if(result[index][23:16] == CNT4) begin
					index <= 0;
					result[index][23:16] <= 0;
					HC4 <= result[index][15:8];
					M4 <= result[index][7:0];
				end
				else begin
					index <= index + 1;
				end
			end
			4'd12: begin
				if(result[index][23:16] == CNT5) begin
					index <= 0;
					result[index][23:16] <= 0;
					HC5 <= result[index][15:8];
					M5 <= result[index][7:0];
				end
				else begin
					index <= index + 1;
				end
			end
			4'd13: begin
				if(result[index][23:16] == CNT6) begin
					index <= 0;
					result[index][23:16] <= 0;
					HC6 <= result[index][15:8];
					M6 <= result[index][7:0];
				end
				else begin
					index <= index + 1;
				end
			end
			default: begin
				code_valid <= 1;
			end
		endcase
	end
end
  
always @ ( * ) begin
	if(reset) begin
		next = 0;
	end
	else begin
		case(state)
			4'd0: begin
				if(count == 99)
					next = 1;
				else 
					next = state;
			end
			4'd2: begin
				if(count == index) begin
					if(round == 4)
						next = 6;
					else 
						next = 4;
				end
				else
					next = 3;
			end
			4'd3: begin
				if(count == index) begin
					if(round == 4) 
						next = 6;
					else 
						next = 4;
				end
				else 
					next = 2;
			end
			4'd5: begin
				next = 2;
			end
			4'd7: begin
				if(result[index][23:16] == combine[4-round][7:0] && round == 4)
					next = 8;
				else 
					next = state;
			end
			4'd8: begin
				if(result[index][23:16] == CNT1) 
					next = 9;
				else 
					next = state;
			end
			4'd9: begin
				if(result[index][23:16] == CNT2) 
					next = 10;
				else
					next = state;
			end
			4'd10: begin
				if(result[index][23:16] == CNT3)
					next = 11;
				else
					next = state;
			end
			4'd11: begin
				if(result[index][23:16] == CNT4)
					next = 12;
				else 
					next = state;
			end
			4'd12: begin
				if(result[index][23:16] == CNT5)
					next = 13;
				else 
					next = state;
			end
			4'd13: begin
				if(result[index][23:16] == CNT6)
					next = 15;
				else 
					next = state;
			end
			default:
				next = state + 1;
		endcase
	end
end
  
endmodule

