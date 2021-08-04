module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);

input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;

output reg match;
output reg [4:0] match_index;
output reg valid;

reg [7:0] string [33:0];
reg [7:0] pattern [8:0];
reg [5:0] s_len, s_start;
reg [3:0] p_len, p_cnt;
reg finish,match_tmp,new_str,new_pat,spec_start;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        match <= 0;
        match_tmp <= 1;
        match_index <= 0;
        valid <= 0;
        s_len <= 1;
        p_len <= 0;
        s_start <= 0;
        p_cnt <= 0;
        string[0] <= 8'h20; // let the string start with a space
        finish <= 0;
        new_str <= 1;
        new_pat <= 1;
        spec_start <= 0;
    end
    else begin
        if(isstring) begin
            if(new_str) begin
                new_str <= 0;
                s_len <= 2;
                string[1] <= chardata;
                valid <= 0;
            end
            else begin
                s_len <= s_len + 1;
                string[s_len] <= chardata;
            end
        end
        else if(ispattern) begin
            p_len <= p_len + 1;            
            // replace ^,$ with space
            if(chardata == 8'h5E) begin
                spec_start <= 1;
                pattern[p_len] <= 8'h20;
            end
            else if(chardata == 8'h24) begin
                pattern[p_len] <= 8'h20;
            end
            else begin
                pattern[p_len] <= chardata;
            end            
            if(!new_str) begin
                string[s_len] <= 8'h20; // append a space to string                
                s_len <= s_len + 1;
                new_str <= 1;
            end
            if(new_pat) begin
                s_start <= 0;
                new_pat <= 0;
                valid <= 0;
            end
        end
        else begin
            if(finish) begin // finish the process of match
                match_tmp <= 1;
                finish <= 0;
                p_cnt <= 0;
                if(match_tmp) begin
                    match <= 1;
                    valid <= 1;
                    p_len <= 0;
                    new_pat <= 1; 
                    spec_start <= 0;   
                    if(s_start == 0 || spec_start)    
                        match_index <= s_start;
                    else
                        match_index <= s_start-1;  
                end
                else begin
                    if(s_start + p_len == s_len) begin // all unmatch
                        match <= 0;
                        valid <= 1;                        
                        p_len <= 0;
                        new_pat <= 1;
                        spec_start <= 0;
                    end
                    else begin // continue compare
                        s_start <= s_start + 1;                        
                    end
                end
            end
            else begin
                p_cnt <= p_cnt + 1;
                if(pattern[p_cnt] != string[s_start+p_cnt] 
                    && pattern[p_cnt] != 8'h2E) begin
                    match_tmp <= 0;                    
                end
                if(p_cnt == p_len-1) begin
                    finish <= 1;   
                end             
            end
        end
    end    
end

endmodule
