module fpga_wrapper_A (
    input        clk_fpga,          // e.g., 50MHz
    input        btn_reset,         // active-LOW on many boards -> debouncer handles inversion if needed
    input        btn_start,
    input        btn_skip,
    input  [7:0] sw_P,              // packed switches: {G, MET[1:0], Cal[1:0], W[2:0]}

    // LCD pins to board header
    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_en,

    // Buzzer pin
    output       buzzer_pin,

    // 7-seg pins (common-anode, active-low segments assumed)
    output [7:0] seg,               // {dp,g,f,e,d,c,b,a} or as your decoder maps
    output [3:0] an
);
    // debounced buttons (level)
    wire reset_n, start, skip;
    debounce db_rst   (.clk(clk_fpga), .rst(1'b0), .noisy(btn_reset), .clean(reset_n));
    debounce db_start (.clk(clk_fpga), .rst(1'b0), .noisy(btn_start), .clean(start));
    debounce db_skip  (.clk(clk_fpga), .rst(1'b0), .noisy(btn_skip),  .clean(skip));


    wire reset = ~reset_n;  


    wire clk_1hz, clk_2khz;
    clock_divider clkdiv (
        .clk(clk_fpga),
        .rst(reset),
        .clk_1hz(clk_1hz),
        .clk_2khz(clk_2khz)
    );


    wire [7:0] T;
    TopModule_FPGA core (
        .clk   (clk_1hz),     ‌
        .reset (reset),
        .start (start),
        .skip  (skip),
        .P     (sw_P),
        .lcd_data(lcd_data),
        .lcd_rs (lcd_rs),
        .lcd_en (lcd_en),
        .buzzer(buzzer_pin),
        .T     (T)
    );


    display_driver disp (
        .clk (clk_2khz),
        .rst (reset),
        .T   (T),
        .an  (an),
        .seg (seg)
    );

endmodule
