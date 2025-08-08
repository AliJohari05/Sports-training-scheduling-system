module clock_divider(
    input clk,       // main clock (e.g., 50MHz)
    input rst,
    output reg clk_1hz,
    output reg clk_2khz
);

    reg [25:0] cnt_1hz;
    reg [15:0] cnt_2khz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1hz <= 0;
            clk_1hz <= 0;
        end else if (cnt_1hz == 25_000_000 - 1) begin
            cnt_1hz <= 0;
            clk_1hz <= ~clk_1hz;
        end else begin
            cnt_1hz <= cnt_1hz + 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_2khz <= 0;
            clk_2khz <= 0;
        end else if (cnt_2khz == 12_500 - 1) begin
            cnt_2khz <= 0;
            clk_2khz <= ~clk_2khz;
        end else begin
            cnt_2khz <= cnt_2khz + 1;
        end
    end

endmodule
