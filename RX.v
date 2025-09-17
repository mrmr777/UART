module uart_rx #(
    parameter DATAWIDTH = 8,
    parameter SB_TICK   = 16
)(
    input  wire clk,
    input  wire rx_rst,
    input  wire rx_en,
    input  wire rx,
    input  wire s_tick,
    output reg [DATAWIDTH-1:0] dout,
    output reg rx_done,
    output reg rx_busy,
    output reg rx_error
);

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] state, state_n;
    reg [DATAWIDTH-1:0] data, data_n;
    reg [3:0] bit_cnt, bit_cnt_n;
    reg [7:0] s_cnt, s_cnt_n;

    always @(posedge clk or posedge rx_rst) begin
        if (rx_rst) begin
            state   <= IDLE;
            data    <= 0;
            bit_cnt <= 0;
            s_cnt   <= 0;
            dout    <= 0;
            rx_done <= 0;
            rx_busy <= 0;
            rx_error<= 0;
        end else begin
            state   <= state_n;
            data    <= data_n;
            bit_cnt <= bit_cnt_n;
            s_cnt   <= s_cnt_n;
            dout    <= data;
        end
    end

  always @(*) begin
        state_n   = state;
        data_n    = data;
        bit_cnt_n = bit_cnt;
        s_cnt_n   = s_cnt;
        rx_done   = 0;
        rx_busy   = (state != IDLE);
        rx_error  = 0;
        if (rx_en) begin
            case (state)
                IDLE: if (!rx) begin
                          state_n = START;
                          s_cnt_n = 0;
                      end
                START: if (s_tick) begin
                           if (s_cnt == 7) begin
                               state_n   = DATA;
                               s_cnt_n   = 0;
                               bit_cnt_n = 0;
                           end else s_cnt_n = s_cnt + 1;
                       end
                DATA: if (s_tick) begin
                          if (s_cnt == 15) begin
                              data_n = {rx, data[DATAWIDTH-1:1]};
                              s_cnt_n = 0;
                              if (bit_cnt == DATAWIDTH-1)
                                  state_n = STOP;
                              else
                                  bit_cnt_n = bit_cnt + 1;
                          end else s_cnt_n = s_cnt + 1;
                      end
                STOP: if (s_tick) begin
                          if (s_cnt == SB_TICK-1) begin
                              if (!rx) rx_error = 1;
                              state_n = IDLE;
                              rx_done = 1;
                          end else s_cnt_n = s_cnt + 1;
                      end
            endcase
        end
    end
endmodule
