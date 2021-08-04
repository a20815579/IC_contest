module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

reg [2:0] cnt, base, now;
reg [9:0] x [5:0];
reg [9:0] y [5:0];
reg [9:0] xx,yy;
reg [3:0] state;
reg signed [20:0] cross_p;
reg signed [10:0] mul1, mul2, sub1, sub2;

wire signed [20:0] multiply; 
assign multiply = mul1 * mul2;

wire signed [10:0] substract; 
assign substract = sub1 - sub2;

// wire [2:0] base1;
// assign base1 = base + 1;
// wire [2:0] base2;
// assign base2 = base + 2;
// wire [2:0] base3;
// assign base3 = base + 3;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        valid <= 0;
        is_inside <= 0;
        cnt <= 0;
        state <= 0;
		mul1 <= 0;
		mul2 <= 0;
    end
    else begin
        case(state)
            4'd0: begin
				cnt <= 0;
                valid <= 0;
                xx <= X;
                yy <= Y;
                state <= 1;
            end
            4'd1: begin                
                x[cnt] <= X;
                y[cnt] <= Y;                
                if(cnt == 3'd5) begin
                    state <= 2;
                    base <= 5;
                    now <= 0;
                    cnt <= 0;
                end
                else begin
                    cnt <= cnt + 1;
                end
            end
            4'd2: begin
                //x[base] - x[0] //x1
                sub1 <= x[now];
                sub2 <= x[0];
                state <= 3;
            end
            4'd3: begin
                // y[now] - y[0] //y2
                sub1 <= y[now+1];
                sub2 <= y[0];
                mul1 <= substract;
                state <= 4;
            end
            4'd4: begin
                sub1 <= x[now+1];
                sub2 <= x[0];
                mul2 <= substract;
                state <= 5;
            end
            4'd5: begin
                cross_p <= multiply;
                sub1 <= y[now];
                sub2 <= y[0];
                mul1 <= substract;
                state <= 6;
            end
            4'd6: begin
                mul2 <= substract;
                state <= 7;
            end
            4'd7: begin
                if(cross_p > multiply) begin // change order                                      
                    x[now+1] <= x[now];
                    y[now+1] <= y[now];
                    x[now] <= x[now+1];                             
                    y[now] <= y[now+1];                    
                end                  
                if(now + 1 == base) begin                                                
                    if(base == 1) begin
                        state <= 8;
                        is_inside <= 1;
                    end
                    else begin
                        base <= base - 1;
                        now <= 0;
                        state <= 4'd2;
                    end
                end
                else begin
                    now <= now + 1;
                    state <= 4'd2;
                end
            end
            4'd8: begin
                //x[cnt] - xx // x1
                sub1 <= x[cnt];
                sub2 <= xx;
                state <= 9;
            end
            4'd9: begin
                if(cnt == 5)
                    sub1 <= y[0];
                else
                    sub1 <= y[cnt+1];
                sub2 <= y[cnt];
                mul1 <= substract;
                state <= 10;
            end
            4'd10: begin
                if(cnt == 5)
                    sub1 <= x[0];
                else
                    sub1 <= x[cnt+1];
                sub2 <= x[cnt];
                mul2 <= substract;
                state <= 11;
            end
            4'd11: begin
                cross_p <= multiply;
                sub1 <= y[cnt];
                sub2 <= yy;
                mul1 <= substract;
                state <= 12;
            end
            4'd12: begin
                mul2 <= substract;
                state <= 13;
            end
            4'd13: begin
                if(cross_p > multiply) begin
                    is_inside <= 0;
                    state <= 14;
                end
                else begin
                    if(cnt == 5) begin
                        state <= 14;
                    end
                    else begin
                        state <= 4'd8;
                        cnt <= cnt + 1;
                    end
                end                
            end
            4'd14: begin
                valid <= 1;
                state <= 15;
            end
			4'd15: begin
				valid <= 0;
				state <= 4'd0;
			end
        endcase
    end
end

endmodule

