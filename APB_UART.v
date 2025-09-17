module apb_uart #(
    parameter DATAWIDTH = 8,
    parameter CLK_FREQ  = 100_000_000
)(
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [31:0] PADDR,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output reg         PREADY,
    input  wire        rx,
    output wire        tx
);

    reg        tx_en, rx_en;
    reg        tx_rst, rx_rst;
    reg [DATAWIDTH-1:0] tx_buf;
    wire [DATAWIDTH-1:0] rx_buf;
    wire tx_done, tx_busy;
    wire rx_done, rx_busy, rx_err;
    reg [31:0] bauddiv;
    reg tx_start;

    wire s_tick;
    baudrate_gen #(
        .BAUDRATE (9600),
        .CLK_FREQ (CLK_FREQ)
    ) baud_i (
        .clk   (PCLK),
        .reset (~PRESETn),
        .tick  (s_tick)
    );

    uart_tx #(
        .DATAWIDTH(DATAWIDTH)
    ) tx_i (
        .clk      (PCLK),
        .tx_rst   (tx_rst),
        .tx_en    (tx_en),
        .tx_start (tx_start),
        .din      (tx_buf),
        .s_tick   (s_tick),
        .tx       (tx),
        .tx_done  (tx_done),
        .tx_busy  (tx_busy)
    );

    uart_rx #(
        .DATAWIDTH(DATAWIDTH)
    ) rx_i (
        .clk     (PCLK),
        .rx_rst  (rx_rst),
        .rx_en   (rx_en),
        .rx      (rx),
        .s_tick  (s_tick),
        .dout    (rx_buf),
        .rx_done (rx_done),
        .rx_busy (rx_busy),
        .rx_error(rx_err)
    );

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            {tx_en, rx_en, tx_rst, rx_rst} <= 4'b0;
            tx_buf    <= 0;
            bauddiv   <= 0;
            tx_start  <= 0;
            PREADY    <= 0;
            PRDATA    <= 0;
        end else begin
            PREADY    <= 0;
            tx_start  <= 0;
            if (PSEL && PENABLE) begin
                PREADY <= 1;
                if (PWRITE) begin
                    case (PADDR[4:0])
                        5'h00: {tx_en, rx_en, tx_rst, rx_rst} <= PWDATA[3:0];
                        5'h02: begin
                            tx_buf   <= PWDATA[DATAWIDTH-1:0];
                            tx_start <= 1;
                        end
                        5'h04: bauddiv <= PWDATA;
                    endcase
                end else begin
                    case (PADDR[4:0])
                        5'h00: PRDATA <= {28'b0, tx_en, rx_en, tx_rst, rx_rst};
                        5'h01: PRDATA <= {27'b0, rx_err, tx_done, rx_done, tx_busy, rx_busy};
                        5'h02: PRDATA <= {24'b0, tx_buf};
                        5'h03: PRDATA <= {24'b0, rx_buf};
                        5'h04: PRDATA <= bauddiv;
                        default: PRDATA <= 0;
                    endcase
                end
            end
        end
    end
endmodule
