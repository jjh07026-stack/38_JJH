`timescale 1ns / 1ps

module tb_fifo ();

    parameter DEPTH = 4;

    reg clk, rst, push, pop;
    reg  [7:0] push_data;
    wire [7:0] pop_data;
    wire full, empty;
    reg [7:0] compare_buffer[0:DEPTH -1];
    integer i, pass_cnt, fail_cnt;
    reg [1:0] push_cnt, pop_cnt;

    wire [2:0] data_cnt = full ? DEPTH : {1'b0, (dut.w_wptr - dut.w_rptr)};

    fifo #(
        .DEPTH(DEPTH)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .push     (push),
        .pop      (pop),
        .push_data(push_data),
        .pop_data (pop_data),
        .full     (full),
        .empty    (empty)
    );

    always #5 clk = ~clk;

    initial begin
        clk       = 0;
        rst       = 1;
        push      = 0;
        pop       = 0;
        push_data = 0;
        i         = 0;
        pass_cnt  = 0;
        fail_cnt  = 0;
        push_cnt  = 0;
        pop_cnt   = 0;

        @(negedge clk);
        @(negedge clk);

        rst = 0;
        @(negedge clk);
        if (full == 0) begin
            $display("%t : pass full signal", $stime);
        end else begin
            $display("%t : fail full signal", $stime);
        end

        if (empty == 1) begin
            $display("%t : pass empty signal", $stime);
        end else begin
            $display("%t : fail empty signal", $stime);
        end

        $display("--- 1. push only ---");
        for (i = 0; i < 5; i = i + 1) begin
            @(negedge clk);
            push_data = 8'h0a + i;
            push      = 1'b1;
            if (!full) begin
                compare_buffer[push_cnt] = push_data;
                push_cnt                 = push_cnt + 1;
                $display("%t : push data = %h, data_cnt = %0d", $stime,
                         push_data, data_cnt + 1);
            end else begin
                $display("%t : full -> push data = %h ignored", $stime,
                         push_data);
            end
        end
        @(negedge clk);
        push = 1'b0;
        if (full == 1) begin
            $display("%t : pass full signal", $stime);
        end else begin
            $display("%t : fail full signal", $stime);
        end

        repeat (3) @(negedge clk);

        $display("--- 2. pop only ---");
        for (i = 0; i < 5; i = i + 1) begin
            @(negedge clk);
            pop = 1'b1;
            if (!empty) begin
                if (pop_data == compare_buffer[pop_cnt]) begin
                    pass_cnt = pass_cnt + 1;
                    $display("%t : pass pop data = %h", $stime, pop_data);
                end else begin
                    fail_cnt = fail_cnt + 1;
                    $display("%t : fail pop data = %h, compare = %h", $stime,
                             pop_data, compare_buffer[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end else begin
                $display("%t : empty -> pop ignored", $stime);
            end
        end
        if (empty == 1) begin
            $display("%t : pass empty signal", $stime);
        end else begin
            $display("%t : fail empty signal", $stime);
        end
        @(negedge clk);
        pop = 1'b0;

        repeat (3) @(negedge clk);

        $display("--- 3. wrap-around ---");
        for (i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            push_data = 8'h11 * (i + 1);
            push      = 1'b1;
            if (!full) begin
                compare_buffer[push_cnt] = push_data;
                push_cnt                 = push_cnt + 1;
            end
        end
        @(negedge clk);
        push = 1'b0;

        for (i = 0; i < 2; i = i + 1) begin
            @(negedge clk);
            pop = 1'b1;
            if (!empty) begin
                if (pop_data == compare_buffer[pop_cnt]) begin
                    pass_cnt = pass_cnt + 1;
                    $display("%t : pass pop data = %h", $stime, pop_data);
                end else begin
                    fail_cnt = fail_cnt + 1;
                    $display("%t : fail pop data = %h, compare = %h", $stime,
                             pop_data, compare_buffer[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end
        end
        @(negedge clk);
        pop = 1'b0;

        for (i = 3; i < 6; i = i + 1) begin
            @(negedge clk);
            push_data = 8'h11 * (i + 1);
            push      = 1'b1;
            if (!full) begin
                compare_buffer[push_cnt] = push_data;
                push_cnt                 = push_cnt + 1;
            end
        end
        @(negedge clk);
        push = 1'b0;
        if (full == 1) begin
            $display("%t : pass full signal (wrap-around)", $stime);
        end else begin
            $display("%t : fail full signal (wrap-around)", $stime);
        end

        repeat (3) @(negedge clk);

        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            pop = 1'b1;
            if (!empty) begin
                if (pop_data == compare_buffer[pop_cnt]) begin
                    pass_cnt = pass_cnt + 1;
                    $display("%t : pass pop data = %h", $stime, pop_data);
                end else begin
                    fail_cnt = fail_cnt + 1;
                    $display("%t : fail pop data = %h, compare = %h", $stime,
                             pop_data, compare_buffer[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end
        end
        @(negedge clk);
        pop = 1'b0;
        if (empty == 1) begin
            $display("%t : pass empty signal", $stime);
        end else begin
            $display("%t : fail empty signal", $stime);
        end

        repeat (3) @(negedge clk);

        $display("--- 4. push & pop ---");
        for (i = 0; i < 5; i = i + 1) begin
            @(negedge clk);
            push      = 1'b1;
            push_data = 8'h0f - i;
            if (!full) begin
                compare_buffer[push_cnt] = push_data;
                push_cnt                 = push_cnt + 1;
            end
            pop = 1'b1;
            if (!empty) begin
                if (pop_data == compare_buffer[pop_cnt]) begin
                    pass_cnt = pass_cnt + 1;
                    $display("%t : pass pop data = %h", $stime, pop_data);
                end else begin
                    fail_cnt = fail_cnt + 1;
                    $display("%t : fail pop data = %h, compare = %h", $stime,
                             pop_data, compare_buffer[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end
        end

        @(negedge clk);
        push = 1'b0;
        pop  = 1'b1;
        if (!empty) begin
            if (pop_data == compare_buffer[pop_cnt]) begin
                pass_cnt = pass_cnt + 1;
                $display("%t : pass pop data = %h", $stime, pop_data);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("%t : fail pop data = %h, compare = %h", $stime,
                         pop_data, compare_buffer[pop_cnt]);
            end
            pop_cnt = pop_cnt + 1;
        end
        @(negedge clk);
        pop = 1'b0;
        @(negedge clk);

        $display("*** Directed test result : pass = %0d, fail = %0d ***",
                 pass_cnt, fail_cnt);

        $display("to start random test");
        pass_cnt = 0;
        fail_cnt = 0;
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk);
            push      = $random() % 2;
            pop       = $random() % 2;
            push_data = $random() % 256;

            if (push == 1 & (!full)) begin
                compare_buffer[push_cnt] = push_data;
                push_cnt                 = push_cnt + 1;
            end
            if (pop == 1 & (!empty)) begin
                if (pop_data == compare_buffer[pop_cnt]) begin
                    pass_cnt = pass_cnt + 1;
                end else begin
                    fail_cnt = fail_cnt + 1;
                    $display("%t : fail pop data = %h, compare = %h", $stime,
                             pop_data, compare_buffer[pop_cnt]);
                end
                pop_cnt = pop_cnt + 1;
            end
        end

        #10;
        $display("*** Random test result ***");
        $display("*total random test    = %4d", i);
        $display("*pass count           = %4d", pass_cnt);
        $display("*fail count           = %4d", fail_cnt);

        $finish;
    end
endmodule
