`timescale 1ns / 1ps

// 트러블슈팅 해결 전 / 후 비교용 (두 프로젝트에서 같은 TB 사용)
module tb_trouble ();

    parameter BAUD_PERIOD = 104_167;  // 9600 baud, 1bit = 104.167us
    parameter MS          = 1_000_000;

    reg clk, rst;
    reg [3:0] sw;
    reg       sw_disp;
    reg btnR, btnL, btnU, btnD;
    reg rx;
    reg echo;
    wire tx, trig;
    wire dht11_io;
    wire [3:0] fnd_com;
    wire [7:0] fnd_font;
    wire [1:0] led;

    project_top dut (
        .clk     (clk),
        .rst     (rst),
        .sw      (sw),
        .sw_disp (sw_disp),
        .btnR    (btnR),
        .btnL    (btnL),
        .btnU    (btnU),
        .btnD    (btnD),
        .rx      (rx),
        .tx      (tx),
        .echo    (echo),
        .trig    (trig),
        .dht11_io(dht11_io),
        .fnd_com (fnd_com),
        .fnd_font(fnd_font),
        .led     (led)
    );

    always #5 clk = ~clk;

    // PC -> FPGA : UART 1바이트 전송 (start, data 8bit LSB first, stop)
    integer i;
    task uart_send(input [7:0] data);
        begin
            rx = 1'b0;
            #(BAUD_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BAUD_PERIOD);
            end
            rx = 1'b1;
            #(BAUD_PERIOD);
        end
    endtask

    // FPGA -> PC : 받은 문자 (파형 radix ASCII 로 확인)
    integer j;
    reg [7:0] rx_shift;
    reg [7:0] pc_rx_data;
    reg pc_rx_done;  // 한 글자 받을 때마다 펄스 (같은 글자 연속 구분용)
    initial begin
        pc_rx_done = 0;
        pc_rx_data = 8'h20;  // 시작값 공백 (X 표시 방지)
    end
    always begin
        @(negedge tx);
        #(BAUD_PERIOD / 2);
        for (j = 0; j < 8; j = j + 1) begin
            #(BAUD_PERIOD);
            rx_shift[j] = tx;
        end
        #(BAUD_PERIOD);
        pc_rx_data = 8'h20;  // 1ns 공백 -> 같은 글자 연속도 칸 구분
        #1;
        pc_rx_data = rx_shift;
        pc_rx_done = 1'b1;
        #(BAUD_PERIOD / 4);
        pc_rx_done = 1'b0;
    end

    // SR04 모델 : trig 끝나고 50us 뒤 echo_time_us 동안 HIGH, 0 이면 응답 없음
    integer echo_time_us;
    always @(negedge trig) begin
        if (echo_time_us > 0) begin
            #50_000;
            echo = 1'b1;
            #(echo_time_us * 1000);
            echo = 1'b0;
        end
    end

    // DHT11 모델 : FPGA start(LOW 18ms 이상) 후 응답 + 40bit 전송, dht_ack = 0 이면 응답 없음
    reg dht_low;    // 1 : 센서가 선을 LOW 로 당김
    reg dht_ack;
    reg [39:0] dht_frame;  // {습도 정수, 습도 소수, 온도 정수, 온도 소수, checksum}
    integer k;
    assign dht11_io = (dht_low) ? 1'b0 : 1'bz;
    pullup (dht11_io);

    always @(negedge dht11_io) begin
        if (!dht_low) begin
            #1000;
            if (dht11_io == 1'b0) begin
                @(posedge dht11_io);
                if (dht_ack) begin
                    #40_000;
                    dht_low = 1'b1;  #80_000;  // 응답 LOW 80us
                    dht_low = 1'b0;  #80_000;  // 응답 HIGH 80us
                    for (k = 39; k >= 0; k = k - 1) begin
                        dht_low = 1'b1;  #50_000;              // 비트 시작 LOW 50us
                        dht_low = 1'b0;
                        if (dht_frame[k]) #70_000;             // '1' : HIGH 70us
                        else              #26_000;             // '0' : HIGH 26us
                    end
                    dht_low = 1'b1;  #50_000;
                    dht_low = 1'b0;
                end
            end
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        sw = 4'b0000;
        sw_disp = 1'b0;
        btnR = 0; btnL = 0; btnU = 0; btnD = 0;
        rx = 1;
        echo = 0;
        echo_time_us = 0;
        dht_low = 0;
        dht_ack = 1;
        dht_frame = {8'd45, 8'd0, 8'd25, 8'd3, 8'd73};  // 습도 45.0%, 온도 25.3C
        #100;
        rst = 0;
        #1000;

        // 1. UART '1' : 모드 전환 직후 송신 -> 전 : 00:00:00:00 / 후 : 12:00:00:00
        uart_send("1");
        #(15 * MS);

        // 2. sw = 10 : SR04 측정 후 송신 -> 전 : 0000cm / 후 : 0010cm
        echo_time_us = 580;
        sw[1:0] = 2'b10;
        #(14 * MS);

        // 3. UART '1', '0' 연속 -> 전 : 응답 1개 / 후 : 응답 2개
        uart_send("1");
        uart_send("0");
        #(30 * MS);

        // 4. sw = 11 : DHT11 무응답 -> 전 : 송신 없음 / 후 : xxxx
        dht_ack = 0;
        sw[1:0] = 2'b11;
        #(32 * MS);

        // 5. UART '3' : DHT11 정상 -> 전 : 025.03C, 줄바꿈 X / 후 : 025.30C + CR LF
        dht_ack = 1;
        uart_send("3");
        #(50 * MS);

        $stop;
    end

endmodule
