
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  reg [13:0]  gray_addr;  
output  reg         gray_req;   
input               gray_ready; 
input       [7:0]   gray_data;
output  reg [13:0]  lbp_addr;   
output  reg         lbp_valid;  
output  reg [7:0]   lbp_data;
output  reg         finish;
//====================================================================

reg  [7:0]   data [8:0];
reg  [3:0]   state;

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        gray_addr <= 0;
        gray_req <= 1;
        lbp_addr <= 14'd126;
        lbp_valid <= 0;
        lbp_data <= 0;
        finish <= 0;
        state <= 0;
    end
    else begin        
        if(gray_ready) begin           
            case(state)
                // read left 6 pixel
                // data[8:0] order
                // |0|3|6|
                // |1|4|7|
                // |2|5|8|
                // 
                // lbp_data[7:0] order
                // |0|1|2|
                // |3| |4|
                // |5|6|7|
                4'd0: begin
                    lbp_valid <= 0;
                    data[0] <= gray_data;
                    gray_addr <= gray_addr + 128; 
                    state <= state + 1;                   
                end
                4'd1: begin
                    data[1] <= gray_data;
                    gray_addr <= gray_addr + 128;
                    state <= state + 1;
                end
                4'd2: begin
                    data[2] <= gray_data;
                    gray_addr <= gray_addr - 255;  
                    state <= state + 1;                  
                end
                4'd3: begin
                    data[3] <= gray_data;
                    gray_addr <= gray_addr + 128;
                    state <= state + 1;
                end
                4'd4: begin
                    data[4] <= gray_data;
                    gray_addr <= gray_addr + 128;  
                    state <= state + 1;                  
                end
                4'd5: begin
                    data[5] <= gray_data;
                    gray_addr <= gray_addr - 255;
                    state <= state + 1;
                end
                4'd6: begin                                
                    lbp_valid <= 0;

                    //check last lbp_addr
                    if(lbp_addr[6:1] == 6'b111111) begin
                        lbp_addr <= lbp_addr + 3;
                        lbp_data[1] <= (data[3] >= data[4]) ? 1 : 0;
                        lbp_data[6] <= (data[5] >= data[4]) ? 1 : 0;
                    end
                    else begin                        
                        lbp_addr <= lbp_addr + 1;
                        data[0] <= data[3];  
                        data[1] <= data[4];
                        data[2] <= data[5]; 
                        data[3] <= data[6];  
                        data[4] <= data[7];
                        data[5] <= data[8];
                        lbp_data[1] <= (data[6] >= data[7]) ? 1 : 0;
                        lbp_data[6] <= (data[8] >= data[7]) ? 1 : 0;
                    end                        

                    data[6] <= gray_data;
                    gray_addr <= gray_addr + 128;     
                    state <= state + 1;               
                end
                4'd7: begin
                    lbp_data[0] <= (data[0] >= data[4]) ? 1 : 0;                    
                    lbp_data[3] <= (data[1] >= data[4]) ? 1 : 0;
                    lbp_data[5] <= (data[2] >= data[4]) ? 1 : 0;                                 

                    data[7] <= gray_data;
                    gray_addr <= gray_addr + 128;  
                    state <= state + 1;               
                end
                4'd8: begin
                    lbp_data[2] <= (data[6] >= data[4]) ? 1 : 0; 
                    lbp_data[4] <= (data[7] >= data[4]) ? 1 : 0;
                    lbp_data[7] <= (gray_data >= data[4]) ? 1 : 0;

                    data[8] <= gray_data; 
                    gray_addr <= gray_addr - 255;   
                    lbp_valid <= 1;

                    if(lbp_addr[6:1] == 6'b111111) begin
                        if(lbp_addr[13:8] == 6'b1111111) begin
                            state <= 9;
                        end
                        else begin
                            state <= 0;
                        end                        
                    end
                    else begin                        
                        state <= 6;
                    end

                end
                4'd9: begin
                    lbp_valid <= 0;
                    finish <= 1;
                    gray_req <= 0;
                end
            endcase
        end
    end
end
//====================================================================
endmodule
