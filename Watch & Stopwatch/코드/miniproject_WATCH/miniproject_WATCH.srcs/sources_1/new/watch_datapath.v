`timescale 1ns / 1ps

module watch_datapath #(
    parameter MSEC_BIT_WIDTH = 7,
    parameter SEC_BIT_WIDTH  = 6,
    parameter MIN_BIT_WIDTH  = 6,
    parameter HOUR_BIT_WIDTH = 5
) (
    input                       clk,
    input                       rst,
    input  [               1:0] current_digit,
    input                       up,
    input                       down,
    input                       sw_mode,  // 1: hour:min, 0: sec:msec
    output [MSEC_BIT_WIDTH-1:0] msec,
    output [ SEC_BIT_WIDTH-1:0] sec,
    output [ MIN_BIT_WIDTH-1:0] min,
    output [HOUR_BIT_WIDTH-1:0] hour
);

    wire w_tick_ms, w_tick_sec, w_tick_min, w_tick_hour;


    wire w_min_up = up & sw_mode & (current_digit[1] == 1'b0);
    wire w_min_down = down & sw_mode & (current_digit[1] == 1'b0);
    wire w_hour_up = up & sw_mode & (current_digit[1] == 1'b1);
    wire w_hour_down = down & sw_mode & (current_digit[1] == 1'b1);
    wire w_sec_up = up & ~sw_mode & (current_digit[1] == 1'b1);
    wire w_sec_down = down & ~sw_mode & (current_digit[1] == 1'b1);
    wire w_sel_1or10 = current_digit[0];

    watch_tick_counter #(
        .TIMES(24),
        .BIT_WIDTH(HOUR_BIT_WIDTH),
        .RESET_HOUR(12)
    ) U_HOUR_COUNTER (
        .clk        (clk),
        .rst        (rst),
        .i_tick     (w_tick_hour),
        .i_up       (w_hour_up),
        .i_down     (w_hour_down),
        .i_sel_1or10(w_sel_1or10),
        .time_count (hour),
        .o_tick     ()
    );
    watch_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(MIN_BIT_WIDTH),
        .RESET_HOUR(0)
    ) U_MIN_COUNTER (
        .clk        (clk),
        .rst        (rst),
        .i_tick     (w_tick_min),
        .i_up       (w_min_up),
        .i_down     (w_min_down),
        .i_sel_1or10(w_sel_1or10),
        .time_count (min),
        .o_tick     (w_tick_hour)
    );
    watch_tick_counter #(
        .TIMES(60),
        .BIT_WIDTH(SEC_BIT_WIDTH),
        .RESET_HOUR(0)
    ) U_SEC_COUNTER (
        .clk        (clk),
        .rst        (rst),
        .i_tick     (w_tick_sec),
        .i_up       (w_sec_up),
        .i_down     (w_sec_down),
        .i_sel_1or10(w_sel_1or10),
        .time_count (sec),
        .o_tick     (w_tick_min)
    );
    watch_tick_counter #(
        .TIMES(100),
        .BIT_WIDTH(MSEC_BIT_WIDTH),
        .RESET_HOUR(0)
    ) U_MSEC_COUNTER (
        .clk        (clk),
        .rst        (rst),
        .i_tick     (w_tick_ms),
        .i_up       (1'b0),
        .i_down     (1'b0),
        .i_sel_1or10(1'b0),
        .time_count (msec),
        .o_tick     (w_tick_sec)
    );

    watch_tick_gen U_TICK_GEN_100HZ (
        .clk   (clk),
        .rst   (rst),
        .o_tick(w_tick_ms)
    );


endmodule

module watch_tick_counter #(
    parameter TIMES = 100,
    BIT_WIDTH = 7,
    RESET_HOUR = 0
) (
    input                      clk,
    input                      rst,
    input                      i_tick,
    input                      i_up,
    input                      i_down,
    input                      i_sel_1or10,
    output     [BIT_WIDTH-1:0] time_count,
    output reg                 o_tick
);

    reg [$clog2(TIMES)-1:0] counter_reg;

    assign time_count = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= RESET_HOUR;
            o_tick <= 1'b0;
        end else begin
            o_tick <= 1'b0;
            if (i_tick) begin
                // time run
                if (counter_reg == TIMES - 1) begin
                    counter_reg <= 0;
                    o_tick <= 1'b1;
                end else begin
                    counter_reg <= counter_reg + 1;
                end
            end else if (i_up) begin
                if (i_sel_1or10 == 1'b0) begin
                    // +1
                    if (counter_reg == TIMES - 1) begin
                        counter_reg <= 0;
                    end else begin
                        counter_reg <= counter_reg + 1;
                    end
                end else begin
                    // +10
                    if (TIMES == 24) begin
                        if (counter_reg >= 20) begin
                            counter_reg <= counter_reg - 20;
                        end else if (counter_reg >= 14) begin
                            counter_reg <= counter_reg - 10;
                        end else begin
                            counter_reg <= counter_reg + 10;
                        end
                    end else begin
                        if (counter_reg >= TIMES - 10) begin
                            counter_reg <= counter_reg + 10 - TIMES;
                        end else begin
                            counter_reg <= counter_reg + 10;
                        end
                    end

                end
            end else if (i_down == 1'b1) begin
                if (i_sel_1or10 == 1'b0) begin
                    // -1
                    if (counter_reg == 0) begin
                        counter_reg <= TIMES - 1;
                    end else begin
                        counter_reg <= counter_reg - 1;
                    end
                end else begin
                    // -10
                    if (TIMES == 24) begin
                        if (counter_reg < 4) begin
                            counter_reg <= counter_reg + 20;
                        end else if (counter_reg < 10) begin
                            counter_reg <= counter_reg + 10;
                        end else begin
                            counter_reg <= counter_reg - 10;
                        end
                    end else begin
                        if (counter_reg < 10) begin
                            counter_reg <= counter_reg + TIMES - 10;
                        end else begin
                            counter_reg <= counter_reg - 10;
                        end
                    end
                end
            end
        end
    end
endmodule


module watch_tick_gen (
    input clk,
    input rst,
    output reg o_tick  // 100hz tick
);

    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                o_tick <= 1'b0;
            end
        end
    end
endmodule
