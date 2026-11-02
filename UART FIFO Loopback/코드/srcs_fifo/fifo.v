`timescale 1ns / 1ps

module fifo #(
    parameter DEPTH = 4,
    A_BIT_WIDTH = $clog2(DEPTH),
    D_BIT_WIDTH = 8
) (
    input                      clk,
    input                      rst,
    input                      push,
    input                      pop,
    input  [D_BIT_WIDTH - 1:0] push_data,
    output [D_BIT_WIDTH - 1:0] pop_data,
    output                     full,
    output                     empty
);
    wire [A_BIT_WIDTH - 1 : 0] w_wptr, w_rptr;

    register_file #(
        .DEPTH      (DEPTH),
        .D_BIT_WIDTH(D_BIT_WIDTH)
    ) U_REG_FILE (
        .clk  (clk),
        .we   ((~full & push)),
        .wdata(push_data),
        .waddr(w_wptr),
        .raddr(w_rptr),
        .rdata(pop_data)
    );

    control_unit #(
        .A_BIT_WIDTH(A_BIT_WIDTH)
    ) U_CONTROL_UNIT (
        .clk  (clk),
        .rst  (rst),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file #(
    parameter DEPTH = 4,
    A_BIT_WIDTH = $clog2(DEPTH),
    D_BIT_WIDTH = 8
) (
    input                       clk,
    input                       we,
    input  [D_BIT_WIDTH -1 : 0] wdata,
    input  [A_BIT_WIDTH -1 : 0] waddr,
    input  [A_BIT_WIDTH -1 : 0] raddr,
    output [D_BIT_WIDTH -1 : 0] rdata
);
    //ram
    reg [D_BIT_WIDTH -1 : 0] register_file[0 : DEPTH -1];
    // write SL
    always @(posedge clk) begin
        if (we == 1) begin
            register_file[waddr] <= wdata;
        end
    end
    // read CL
    assign rdata = register_file[raddr];
endmodule

module control_unit #(
    parameter A_BIT_WIDTH = 2
) (
    input clk,
    input rst,
    input push,
    input pop,
    output [A_BIT_WIDTH -1 : 0] wptr,
    output [A_BIT_WIDTH -1 : 0] rptr,
    output full,
    output empty
);

    reg [A_BIT_WIDTH-1:0] wptr_reg, wptr_next;
    reg [A_BIT_WIDTH-1:0] rptr_reg, rptr_next;

    reg full_reg, full_next;
    reg empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge rst) begin
        if (rst == 1) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case ({
            push, pop
        })  // 결합 연산자 사용해서?
            2'b10: begin  // push only
                if (!full_reg) begin // 꽉 차있지 않아야 함. 꽉 차있는데 계속해서 입력처리 하면 안 됨.
                    empty_next = 1'b0;  // 들어왔으니 비어있지 않다.
                    wptr_next  = wptr_reg + 1; // 증가, 만약 if(!full reg)가 없었다면 
                    if(wptr_next == rptr_reg) begin // 순환 구조이기에 다음 쓰기 위치가 rptr과 같으면 꽉 채워진거
                        full_next = 1'b1;  // 꽉 찬거다.
                    end
                end

            end

            2'b01: begin  // pop only
                if (!empty_reg) begin
                    full_next = 1'b0; // pop 신호이니 읽어서 나갔으니까 꽉 차지 않은 상태가 된다.
                    rptr_next = rptr_reg + 1; // 읽기 모드니까 들어온 순서대로 진행
                    if (rptr_next == wptr_reg) begin  // 다 읽으면
                        empty_next = 1'b1;  // 텅 빈거다.
                    end
                end

            end

            2'b11: begin  // 동시 입력
                if (full_reg == 1) begin  // 꽉 차있으면
                    rptr_next = rptr_reg + 1;  // pop만 처리
                    full_next = 1'b0;  // 나갔으니까 full이 아니다.
                end else if (empty_reg == 1) begin  // 텅 비었으면
                    wptr_next  = wptr_reg + 1;  // push만 처리
                    empty_next = 1'b0;  // 들어왔으니 empty가 아니다.
                end else begin  // 중간 상태
                    wptr_next = wptr_reg + 1;  // 읽기
                    rptr_next = rptr_reg + 1; // 쓰기 독립적인 처리가 가능(FIFO 특징)
                end
            end
        endcase
    end
endmodule

