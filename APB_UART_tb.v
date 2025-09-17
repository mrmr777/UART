`timescale 1ns/1ps

module apb_uart_tb;

    localparam DATAWIDTH  = 8;
    localparam CLK_PERIOD = 10;

    reg  PCLK;
    reg  PRESETn;
    reg  PSEL;
    reg  PENABLE;
    reg  PWRITE;
    reg  [31:0] PADDR;
    reg  [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire PREADY;

    wire tx;
    wire rx;
    assign rx = tx;  // loopback

    reg [31:0] status;
    reg [31:0] tx_data;
    reg [31:0] rx_data;

    apb_uart #(
        .DATAWIDTH(DATAWIDTH),
        .CLK_FREQ(100_000_000)
    ) dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .rx(rx),
        .tx(tx)
    );

    initial PCLK = 0;
    always #(CLK_PERIOD/2) PCLK = ~PCLK;

    initial begin
        PRESETn = 0;
        #50 PRESETn = 1;
    end

    task apb_write(input [4:0] addr, input [31:0] data);
    begin
        @(posedge PCLK);
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 1;
        PADDR   = addr;
        PWDATA  = data;

        @(posedge PCLK);
        PENABLE = 1;

        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
    end
    endtask

    task apb_read(input [4:0] addr, output [31:0] data);
    begin
        @(posedge PCLK);
        PSEL    = 1;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = addr;

        @(posedge PCLK);
        PENABLE = 1;

        @(posedge PCLK);
        data = PRDATA;

        PSEL    = 0;
        PENABLE = 0;
    end
    endtask

    initial begin
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;

        @(posedge PRESETn);

        apb_write(5'h00, 4'b1100); // reset tx/rx
        apb_write(5'h00, 4'b0011); // enable tx/rx

        apb_write(5'h02, 8'hA5);   // transmit 0xA5

        repeat (2000) begin
            apb_read(5'h01, status);
            if (status[0]) break; // assuming bit0 = rx_done
        end

        apb_read(5'h01, status);
        $display("Status: %h", status);

        apb_read(5'h02, tx_data);
        $display("TX Data: %h", tx_data);

        apb_read(5'h03, rx_data);
        $display("RX Data: %h", rx_data);

        if (rx_data == 8'hA5)
            $display("PASS: UART loopback successful");
        else
            $display("FAIL: expected 0xA5, got %h", rx_data);

        $finish;
    end

endmodule
