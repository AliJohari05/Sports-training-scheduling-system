
module fpga_wrapper_A (
    input        clk_fpga,   // e.g., 50MHz or 100MHz (set DIV inside clock_divider accordingly)
    input        btn_reset,
    input        btn_start,
    input        btn_skip,
    input  [7:0] sw_P,       // packed switches: {G, MET[1:0], Cal[1:0], W[2:0]}

    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_en,
    output       buzzer_pin
);

    // Debounced buttons
    wire reset, start, skip;
    debounce db_rst   (.clk(clk_fpga), .rst(1'b0), .noisy(btn_reset), .clean(reset));
    debounce db_start (.clk(clk_fpga), .rst(1'b0), .noisy(btn_start), .clean(start));
    debounce db_skip  (.clk(clk_fpga), .rst(1'b0), .noisy(btn_skip),  .clean(skip));

    // Clock divider: generate 1Hz and ~2kHz from clk_fpga
    wire clk_1hz, clk_2khz;
    clock_divider clkdiv (
        .clk(clk_fpga),
        .rst(reset),
        .clk_1hz(clk_1hz),
        .clk_2khz(clk_2khz)
    );

    // Core top (logic)
    TopModule_FPGA core (
        .clk_sys(clk_fpga),     // LCD needs fast clock (keep as board clock)
        .clk_1hz(clk_1hz),
        .clk_2khz(clk_2khz),
        .reset(reset),
        .start(start),
        .skip(skip),
        .P(sw_P),
        .lcd_data(lcd_data),
        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en),
        .buzzer(buzzer_pin)
    );

endmodule
