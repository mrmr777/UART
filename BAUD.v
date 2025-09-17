module baudrate_gen #(
    parameter integer BAUDRATE = 9600,
    parameter integer CLK_FREQ = 100_000_000
)(
    input  wire clk,
    input  wire reset,
    output reg  tick
);

    localparam integer DIVISOR = (CLK_FREQ + (16*BAUDRATE - 1)) / (16*BAUDRATE);
    reg [15:0] cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt  <= 0;
            tick <= 0;
        end else if (cnt == DIVISOR-1) begin
            cnt  <= 0;
            tick <= 1;
        end else begin
            cnt  <= cnt + 1;
            tick <= 0;
        end
    end
endmodule
