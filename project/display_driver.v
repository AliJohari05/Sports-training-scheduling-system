module display_driver(
    input clk,                 // refresh clock (e.g., 1kHz)
    input rst,
    input [7:0] T,             // input value (e.g., 8-bit number)
    output reg [3:0] anode,    // anode control for each digit
    output [6:0] seg           // output to 7-segment display
);

    reg [3:0] digit;
    reg [1:0] mux_index;
    reg [3:0] digits[3:0]; // thousands, hundreds, tens, ones

    // Digit separation logic
    always @(*) begin
        digits[0] = T % 10;              // ones
        digits[1] = (T / 10) % 10;       // tens
        digits[2] = (T / 100) % 10;      // hundreds
        digits[3] = (T / 1000) % 10;     // thousands
    end

    // Digit multiplexing logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            mux_index <= 0;
        else
            mux_index <= mux_index + 1;
    end

    always @(*) begin
        case (mux_index)
            2'd0: begin anode = 4'b1110; digit = digits[0]; end // ones
            2'd1: begin anode = 4'b1101; digit = digits[1]; end // tens
            2'd2: begin anode = 4'b1011; digit = digits[2]; end // hundreds
            2'd3: begin anode = 4'b0111; digit = digits[3]; end // thousands
        endcase
    end

    seven_segment_decoder decoder (
        .digit(digit),
        .seg(seg)
    );

endmodule
