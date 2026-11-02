`timescale 1ns / 1ps

module uart_rx (
    input        clk,
    input        rst,
    input        b_tick,
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);
    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] c_state, n_state;
    reg [3:0] b_tick_cnt, b_tick_cnt_next;
    reg [3:0] bit_cnt, bit_cnt_next;
    reg [7:0] data_reg, data_next;
    reg rx_done_reg, rx_done_next;

    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state     <= IDLE;
            b_tick_cnt  <= 4'h0;
            bit_cnt     <= 3'b000;
            rx_done_reg <= 1'b0;
            data_reg    <= 8'h00;
        end else begin
            c_state     <= n_state;
            b_tick_cnt  <= b_tick_cnt_next;
            bit_cnt     <= bit_cnt_next;
            data_reg    <= data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt;
        bit_cnt_next    = bit_cnt;
        data_next       = data_reg;
        rx_done_next    = rx_done_reg;
        case (c_state)
            IDLE: begin
                b_tick_cnt_next = 0;
                rx_done_next = 1'b0;
                if (b_tick) begin
                    if (!rx) begin
                        n_state = START;
                    end
                end
            end
            START: begin
                if (b_tick)
                    if (b_tick_cnt == 7) begin
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        data_next       = 8'h00;
                        n_state         = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
            end

            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt == 15) begin
                        b_tick_cnt_next = 0;
                        data_next    = {rx, data_reg[7:1]};
                        if (bit_cnt == 7) begin
                            n_state = STOP;
                        end else begin
                            //DATA state
                            bit_cnt_next = bit_cnt + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt == 15) begin
                        if (rx) begin
                            b_tick_cnt_next = 0;
                            rx_done_next = 1'b1;
                            n_state = IDLE;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt + 1;
                    end
                end else begin
                    n_state = STOP;
                end
            end
        endcase
    end
endmodule
/*module uart_rx (
    input       clk,
    input       rst,
    input       b_tick,
    input       rx,
    output [7:0] rx_data,
    output       rx_done
);
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [2:0] c_state, n_state;
    
    reg [7:0] data_reg, data_next;
    reg rx_reg, rx_next;
    reg rx_done_reg, tx_done_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            bit_count_reg <= 3'b0;
            data_reg <= 8'h0;
        end else begin
            c_state       <= n_state;
            
            data_reg      <= data_next;
        end
    end

    always @(*) begin
        n_state        = c_state;
        
        data_next      = data_reg;
        case (c_state)
            IDLE: begin
                if(b_tick == 1)begin
                    if (rx ==0) begin
                        n_state = start;
                    end
                end
            end
            START : begin
                if (b_tick_cnt ==7) begin
                    b_tick_cnt = 0;
                    n_state= DATA;
                end else begin
                    n_state = START;
                end
            end

            DATA : begin
                if(b_tick ==1) begin
                    if(b_tick == 15) begin
                        data_reg = rx[bit_cnt];
                        if (bit_cnt == 15)begin
                            b_tick_cnt = 0;
                            n_state = stop;
                        end else begin
                            b_tick_cnt = 0;
                            bin_cnt = bit_cnt +1;
                        end
                    end else begin
                        n_state = DATA;
                    end
                end else begin
                    n_state = DATA;
                end
            end

            STOP : begin
                if(b_tick == 1) begin
                    if(b_tick_cnt == 1) begin
                        if (rx == 1) begin
                            b_tick_cnt = 0;
                            rx_done =1;
                            n_state = IDLE;
                        end 
                    end else begin
                        n_state = STOP;
                    end
                end else begin
                    n_state = STOP;
                end
            end

        endcase
    end
endmodule
*/
