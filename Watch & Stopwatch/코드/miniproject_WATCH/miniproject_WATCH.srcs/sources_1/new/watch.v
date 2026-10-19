`timescale 1ns / 1ps

module watch (
    input        clk,
    input        rst,
    input        btnL,
    input        btnR,
    input        btnU,
    input        btnD,
    input  [1:0] sw,
    output [3:0] fnd_com,
    output [7:0] fnd_font
);

    parameter MSEC_BIT_WIDTH = 7;
    parameter SEC_BIT_WIDTH = 6;
    parameter MIN_BIT_WIDTH = 6;
    parameter HOUR_BIT_WIDTH = 5;

    wire w_btnL, w_btnR, w_btnU, w_btnD;
    wire w_sw_en, w_watch_en;

    // stopwatch
    wire w_sw_run_stop, w_sw_clear, w_sw_mode;
    wire [MSEC_BIT_WIDTH-1:0] w_sw_msec;
    wire [ SEC_BIT_WIDTH-1:0] w_sw_sec;
    wire [ MIN_BIT_WIDTH-1:0] w_sw_min;
    wire [HOUR_BIT_WIDTH-1:0] w_sw_hour;

    // watch
    wire [1:0] w_current_digit;
    wire w_up, w_down;
    wire [MSEC_BIT_WIDTH-1:0] w_w_msec;
    wire [ SEC_BIT_WIDTH-1:0] w_w_sec;
    wire [ MIN_BIT_WIDTH-1:0] w_w_min;
    wire [HOUR_BIT_WIDTH-1:0] w_w_hour;

    // fnd
    wire [MSEC_BIT_WIDTH-1:0] w_msec;
    wire [ SEC_BIT_WIDTH-1:0] w_sec;
    wire [ MIN_BIT_WIDTH-1:0] w_min;
    wire [HOUR_BIT_WIDTH-1:0] w_hour;

    // button debounce (1 per button)
    btn_debounce U_BTN_L (
        .clk  (clk),
        .reset(rst),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );
    btn_debounce U_BTN_R (
        .clk  (clk),
        .reset(rst),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );
    btn_debounce U_BTN_U (
        .clk  (clk),
        .reset(rst),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );
    btn_debounce U_BTN_D (
        .clk  (clk),
        .reset(rst),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );

    // button gating (after debounce)
    assign w_sw_en    = sw[0];
    assign w_watch_en = ~sw[0];

    // stopwatch
    control_unit U_SW_CONTROL_UNIT (
        .clk         (clk),
        .reset       (rst),
        .btn_clear   (w_btnL & w_sw_en),
        .btn_mode    (w_btnU & w_sw_en),
        .btn_run_stop(w_btnR & w_sw_en),
        .run_stop    (w_sw_run_stop),
        .clear       (w_sw_clear),
        .mode        (w_sw_mode)
    );

    stopwatch_datapath U_SW_DATAPATH (
        .clk     (clk),
        .rst     (rst),
        .run_stop(w_sw_run_stop),
        .clear   (w_sw_clear),
        .mode    (w_sw_mode),
        .msec    (w_sw_msec),
        .sec     (w_sw_sec),
        .min     (w_sw_min),
        .hour    (w_sw_hour)
    );

    // watch
    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk          (clk),
        .reset        (rst),
        .btnL         (w_btnL & w_watch_en),
        .btnR         (w_btnR & w_watch_en),
        .btnU         (w_btnU & w_watch_en),
        .btnD         (w_btnD & w_watch_en),
        .current_digit(w_current_digit),
        .up           (w_up),
        .down         (w_down)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk          (clk),
        .rst          (rst),
        .current_digit(w_current_digit),
        .up           (w_up),
        .down         (w_down),
        .sw_mode      (sw[1]),
        .msec         (w_w_msec),
        .sec          (w_w_sec),
        .min          (w_w_min),
        .hour         (w_w_hour)
    );

    // display select : sw[0] = 1 -> stopwatch, 0 -> watch
    assign w_msec = sw[0] ? w_sw_msec : w_w_msec;
    assign w_sec  = sw[0] ? w_sw_sec : w_w_sec;
    assign w_min  = sw[0] ? w_sw_min : w_w_min;
    assign w_hour = sw[0] ? w_sw_hour : w_w_hour;

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .rst        (rst),
        .sw_fnd_mode(sw[1]),
        .msec       (w_msec),
        .sec        (w_sec),
        .min        (w_min),
        .hour       (w_hour),
        .fnd_com    (fnd_com),
        .fnd_font   (fnd_font)
    );

endmodule
