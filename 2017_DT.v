module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di
	);

reg [3:0] state;
reg [3:0] cnt;

always @(posedge clk or negedge reset) begin
	if (!reset) begin
		// reset
		done <= 0;
		sti_rd <= 0;
		sti_addr <= 0;
		res_wr <= 0;
		res_rd <= 0;
		res_addr <= 0;
		res_do <= 0;	
		state <= 0;			
	end
	else begin
		case(state)
			4'd0: begin //initial
				res_wr <= 1;				
				sti_rd <= 1;
				res_rd <= 1;	
				cnt <= 4'd14;
				state <= state + 1;
			end
			4'd1: begin // forward
				cnt <= cnt - 1;
				if(cnt == 4'd0) begin					
					if(sti_addr == 10'd1023) begin
						state <= 4'd6;
						cnt <= 4'd1;
					end	
					else begin
						sti_addr <= sti_addr + 1;		
					end				
				end
				if(sti_di[cnt]) begin // object
					res_addr <= res_addr - 128;
					state <= state + 1;
					res_wr <= 0;
				end
				else begin //background
					res_addr <= res_addr + 1;
					res_do <= 0;
					res_wr <= 1;					
				end
			end
			4'd2: begin //read NW
				res_do <= res_di;
				res_addr <= res_addr + 1;
				state <= state + 1;
			end
			4'd3: begin //read N
				res_do <= (res_di < res_do) ? res_di : res_do;
				res_addr <= res_addr + 1;
				state <= state + 1;
			end
			4'd4: begin //read NE
				res_do <= (res_di < res_do) ? res_di : res_do;
				res_addr <= res_addr + 126;
				state <= state + 1;
			end
			4'd5: begin //read W & right min+1 at next posedge clk
				res_do <= (res_di < res_do) ? res_di+1 : res_do+1;
				res_addr <= res_addr + 1;
				res_wr <= 1;
				state <= 4'd1;
			end
			4'd6: begin // back
				cnt <= cnt + 1;
				res_wr <= 0;
				if(cnt == 4'd15) begin
					sti_addr <= sti_addr - 1;
					if(sti_addr == 10'd8) begin
						done <= 1;
					end					
				end
				if(sti_di[cnt]) begin // object
					res_addr <= res_addr + 128;
					state <= state + 1;
				end
				else begin //background
					res_addr <= res_addr - 1;					
				end
			end
			4'd7: begin //read SE
				res_do <= res_di;
				res_addr <= res_addr - 1;
				state <= state + 1;
			end
			4'd8: begin //read S
				res_do <= (res_di < res_do) ? res_di : res_do;
				res_addr <= res_addr - 1;
				state <= state + 1;
			end
			4'd9: begin //read SW
				res_do <= (res_di < res_do) ? res_di : res_do;
				res_addr <= res_addr - 126;
				state <= state + 1;
			end
			4'd10: begin //read E
				res_do <= (res_di < res_do) ? res_di : res_do;
				res_addr <= res_addr - 1;
				state <= state + 1;
			end
			4'd11: begin //compare p(x,y) with z+1, right min at next posedge clk
				res_do <= (res_di < res_do+1) ? res_di : res_do+1;
				res_wr <= 1;
				state <= 4'd6;
			end
		endcase
	end
end

endmodule
