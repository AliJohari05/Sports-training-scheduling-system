module fpga_top(
    input clk_fpga,
    input btn_rst,
    input btn_start,
    input btn_skip,
    input [7:0] sw_W,
    input [7:0] sw_Cal,
    input [2:0] sw_MET,
    input sw_gender,

    output [6:0] seg,
    output [3:0] an,
    output buzzer_pin
);

    wire rst, start, skip;
    wire clk_1hz, clk_2khz;
    wire [7:0] T;
    wire alarm;

    // Debounce buttons
    debounce db_rst (
        .clk(clk_fpga), .rst(1'b0), .noisy(btn_rst), .clean(rst)
    );

    debounce db_start (
        .clk(clk_fpga), .rst(1'b0), .noisy(btn_start), .clean(start)
    );

    debounce db_skip (
        .clk(clk_fpga), .rst(1'b0), .noisy(btn_skip), .clean(skip)
    );

    // Clock Divider
    clock_divider clkdiv (
        .clk(clk_fpga),
        .rst(rst),
        .clk_1hz(clk_1hz),
        .clk_2khz(clk_2khz)
    );

    // TopModule (core logic)
    TopModule core (
        .clk(clk_1hz),
        .rst(rst),
        .start(start),
        .skip(skip),
        .weight(sw_W),
        .calorie(sw_Cal),
        .MET(sw_MET),
        .gender(sw_gender),
        .T(T),
        .alarm(alarm)
    );

    // 7 Segment Display
    display_driver disp (
        .clk(clk_fpga), 
        .rst(rst),
        .T(T),
        .anode(an),
        .seg(seg)
    );

    // Buzzer
    buzzer buzz (
        .clk(clk_2khz),
        .rst(rst),
        .alarm(alarm),
        .buzzer_out(buzzer_pin)
    );

endmodule
