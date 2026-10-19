`timescale 1ns / 1ps
module watch_control_unit (
    input            clk,
    input            reset,
    input            btnL,
    input            btnR,
    input            btnU,
    input            btnD,
    output reg [1:0] current_digit,
    output reg       up,
    output reg       down
);

    parameter S1 = 2'b00, S10 = 2'b01, S100 = 2'b10, S1000 = 2'b11;
    reg [1:0] c_state, n_state;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= S1;
        end else begin
            c_state <= n_state;
        end
    end


    always @(*) begin
        n_state       = c_state;
        up            = btnU;
        down          = btnD;
        current_digit = c_state;
        case (c_state)
            S1: begin
                if (btnR == 1'b1) begin
                    n_state = S1000;
                end else if (btnL == 1'b1) begin
                    n_state = S10;
                end 
            end
            S10: begin
                if (btnR == 1'b1) begin
                    n_state = S1;
                end else if (btnL == 1'b1) begin
                    n_state = S100;
                end 
            end
            S100: begin
                if (btnR == 1'b1) begin
                    n_state = S10;
                end else if (btnL == 1'b1) begin
                    n_state = S1000;
                end 
            end
            S1000: begin
               if (btnR == 1'b1) begin
                    n_state = S100;
                end else if (btnL == 1'b1) begin
                    n_state = S1;
                end 
            end
        endcase
    end
endmodule
