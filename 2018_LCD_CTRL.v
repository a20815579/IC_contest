module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;

reg [7:0] data [63:0];
//reg [3:0] cmd_reg;
reg [2:0] x,y;
reg [8:0] tmp1,tmp2;
//reg [9:0] tmp3;

wire [5:0] pos;
assign pos = (y << 3) + x ;

wire [7:0] min;
assign min = (tmp1 < tmp2) ? tmp1 : tmp2;
wire [7:0] max;
assign max = (tmp1 > tmp2) ? tmp1 : tmp2;
wire [7:0] avg;
assign avg = 10'b0000000000 + (tmp1 + tmp2) >> 2;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        IROM_rd <= 1;
        IROM_A <= 0;
        IRAM_valid <= 0;
        IRAM_D <= 0;
        IRAM_A <= 0;
        busy <= 1;
        done <= 0;
        tmp1 <= 0;
        tmp2 <= 0;
        x <= 4;
        y <= 4;
    end
    else begin
        if(IROM_rd) begin // read ROM
            data[IROM_A] <= IROM_Q;
            IROM_A <= IROM_A + 1;
            if(IROM_A == 6'd63) begin
                IROM_rd <= 0;
                busy <= 0;                
            end
        end
        else begin
            case(cmd)
                4'd0: begin
                    if(busy) begin // step 2
                        IRAM_A <= IRAM_A + 1;
                        IRAM_D <= data[IRAM_A+1];
                        if(IRAM_A == 6'd63) begin
                            done <= 1;
                            busy <= 0;
                            IRAM_valid <= 0 ;
                        end                        
                    end
                    else begin //step 1
                        busy <= 1;
                        IRAM_valid <= 1;
                        IRAM_A <= 0;
                        IRAM_D <= data[0];
                    end
                end
                4'd1: begin
                    y <= (y-1 < 3'd1) ? 3'd1 : y-1;
                end
                4'd2: begin
                    y <= (y+1 > 3'd7) ? 3'd7 : y+1;
                end
                4'd3: begin
                    x <= (x-1 < 3'd1) ? 3'd1 : x-1;
                end
                4'd4: begin
                    x <= (x+1 > 3'd7) ? 3'd7 : x+1;
                end
                4'd5: begin
                    if(busy) begin // step 2
                        data[pos-9] <= max;
                        data[pos-8] <= max;
                        data[pos-1] <= max;
                        data[pos] <= max;
                        busy <= 0;
                    end
                    else begin //step 1
                        busy <= 1;
                        tmp1 <= (data[pos-9] > data[pos-8])? data[pos-9] : data[pos-8];
                        tmp2 <= (data[pos-1] > data[pos])? data[pos-1] : data[pos];
                    end                   
                end
                4'd6: begin
                    if(busy) begin // step 2
                        data[pos-9] <= min;
                        data[pos-8] <= min;
                        data[pos-1] <= min;
                        data[pos] <= min;
                        busy <= 0;
                    end
                    else begin //step 1
                        busy <= 1;
                        tmp1 <= (data[pos-9] < data[pos-8])? data[pos-9] : data[pos-8];
                        tmp2 <= (data[pos-1] < data[pos])? data[pos-1] : data[pos];
                    end
                   
                end
                4'd7: begin
                    if(busy) begin //step2
                        data[pos-9] <= avg;
                        data[pos-8] <= avg;
                        data[pos-1] <= avg;
                        data[pos-0] <= avg;
                        busy <= 0;
                    end
                    else begin // step1
                        busy <= 1;
                        tmp1 <= data[pos-9] + data[pos-8];
                        tmp2 <= data[pos-1] + data[pos];
                    end
                end
                4'd8: begin
                    data[pos-9] <= data[pos-8];
                    data[pos-8] <= data[pos];
                    data[pos] <= data[pos-1];
                    data[pos-1] <= data[pos-9];
                end
                4'd9: begin
                    data[pos-9] <= data[pos-1];
                    data[pos-1] <= data[pos];
                    data[pos] <= data[pos-8];
                    data[pos-8] <= data[pos-9];        
                end
                4'd10: begin
                    data[pos-9] <= data[pos-1];
                    data[pos-1] <= data[pos-9];
                    data[pos] <= data[pos-8];
                    data[pos-8] <= data[pos];        
                end
                4'd11: begin
                    data[pos-9] <= data[pos-8];
                    data[pos-8] <= data[pos-9];
                    data[pos] <= data[pos-1];
                    data[pos-1] <= data[pos];        
                end
            endcase
        end
    end
end

endmodule