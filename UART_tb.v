`timescale 1ns/1ps

module uart_tb;

    localparam CLK_FREQ  = 100_000_000;
    localparam BAUDRATE  = 9600;
    localparam SB_TICK   = 16;
    localparam DATAWIDTH = 8;

    reg clk, rst;
    reg tx_en, rx_en, tx_rst, rx_rst, tx_start;
    reg [DATAWIDTH-1:0] tx_din;
    wire tx, tx_done, tx_busy;
    wire [DATAWIDTH-1:0] rx_dout;
    wire rx_done, rx_busy, rx_err;
    wire s_tick;

    initial clk = 0;
    always #5 clk = ~clk;

    baudrate_gen #(.BAUDRATE(BAUDRATE), .CLK_FREQ(CLK_FREQ)) b0 (
        .clk(clk), .reset(rst), .tick(s_tick)
    );

    uart_tx #(.DATAWIDTH(DATAWIDTH), .SB_TICK(SB_TICK)) tx0 (
        .clk(clk), .tx_rst(tx_rst), .tx_en(tx_en),
        .tx_start(tx_start), .din(tx_din),
        .s_tick(s_tick), .tx(tx),
        .tx_done(tx_done), .tx_busy(tx_busy)
    );

    uart_rx #(.DATAWIDTH(DATAWIDTH), .SB_TICK(SB_TICK)) rx0 (
        .clk(clk), .rx_rst(rx_rst), .rx_en(rx_en),
        .rx(tx), .s_tick(s_tick),
        .dout(rx_dout), .rx_done(rx_done),
        .rx_busy(rx_busy), .rx_error(rx_err)
    );

    initial begin
        rst      = 1;
        tx_rst   = 1;
        rx_rst   = 1;
        tx_en    = 0;
        rx_en    = 0;
        tx_din   = 0;
        tx_start = 0;
        #50  rst = 0;
        tx_rst   = 0;
        rx_rst   = 0;
        tx_en    = 1;
        rx_en    = 1;
        #1000;
        tx_din   = 8'hC1;
        @(negedge clk) tx_start = 1;
        @(negedge clk) tx_start = 0;
        wait (rx_done);
        $display("TX=%02h RX=%02h ERR=%b", tx_din, rx_dout, rx_err);
        if (rx_dout == 8'hC1 && !rx_err)
            $display("PASS");
        else
            $display("FAIL");
        #2000 $finish;
    end
endmodule
