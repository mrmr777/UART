module uart_tx #(
    parameter DATAWIDTH = 8,
    parameter SB_TICK   = 16
)(
    input  wire clk,
    input  wire tx_rst,
    input  wire tx_en,
    input  wire tx_start,
    input  wire [DATAWIDTH-1:0] din,
    input  wire s_tick,
    output reg tx,
    output reg tx_done,
    output reg tx_busy
);

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] state, state_n;
    reg [7:0] s_cnt, s_cnt_n;
    reg [3:0] bit_cnt, bit_cnt_n;
    reg [DATAWIDTH-1:0] shift, shift_n;
    reg tx_n, done_n;

    always @(posedge clk or posedge tx_rst) begin
        if (tx_rst) begin
            state   <= IDLE;
            s_cnt   <= 0;
            bit_cnt <= 0;
            shift   <= 0;
            tx      <= 1;
            tx_done <= 0;
            tx_busy <= 0;
        end else begin
            state   <= state_n;
            s_cnt   <= s_cnt_n;
            bit_cnt <= bit_cnt_n;
            shift   <= shift_n;
            tx      <= tx_n;
            tx_done <= done_n;
            tx_busy <= (state_n != IDLE);
        end
    end

    always @* begin
        state_n   = state;
        s_cnt_n   = s_cnt;
        bit_cnt_n = bit_cnt;
        shift_n   = shift;
        tx_n      = tx;
        done_n    = 0;
        if (tx_en) begin
            case (state)
                IDLE: begin
                    tx_n = 1;
                    if (tx_start) begin
                        shift_n = din;
                        s_cnt_n = 0;
                        state_n = START;
                    end
                end
                START: begin
                    tx_n = 0;
                    if (s_tick) begin
                        if (s_cnt == SB_TICK-1) begin
                            s_cnt_n   = 0;
                            bit_cnt_n = 0;
                            state_n   = DATA;
                        end else s_cnt_n = s_cnt + 1;
                    end
                end
                DATA: begin
                    tx_n = shift[bit_cnt];
                    if (s_tick) begin
                        if (s_cnt == SB_TICK-1) begin
                            s_cnt_n = 0;
                            if (bit_cnt == DATAWIDTH-1)
                                state_n = STOP;
                            else
                                bit_cnt_n = bit_cnt + 1;
                        end else s_cnt_n = s_cnt + 1;
                    end
                end
                STOP: begin
                    tx_n = 1;
                    if (s_tick) begin
                        if (s_cnt == SB_TICK-1) begin
                            state_n = IDLE;
                            done_n  = 1;
                            s_cnt_n = 0;
                        end else s_cnt_n = s_cnt + 1;
                    end
                end
            endcase
        end
    end
endmodule
