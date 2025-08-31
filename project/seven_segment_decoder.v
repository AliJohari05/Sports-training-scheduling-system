// seven_segment_decoder.v
// Produces ACTIVE-HIGH patterns for hex digits 0..9 (dp bit is separate).
// Order here is: {dp, g, f, e, d, c, b, a} == seg[7:0]
module seven_segment_decoder(
    input  [3:0] digit,
    output reg [7:0] seg_ah  // active-HIGH
);
    always @(*) begin
        case (digit)
            4'b0000: seg_ah = 8'b0_0111111; // 0
            4'b0001: seg_ah = 8'b0_0000110; // 1
            4'b0010: seg_ah = 8'b0_1011011; // 2
            4'b0011: seg_ah = 8'b0_1001111; // 3
            4'b0100: seg_ah = 8'b0_1100110; // 4
            4'b0101: seg_ah = 8'b0_1101101; // 5
            4'b0110: seg_ah = 8'b0_1111101; // 6
            4'b0111: seg_ah = 8'b0_0000111; // 7
            4'b1000: seg_ah = 8'b0_1111111; // 8
            4'b1001: seg_ah = 8'b0_1101111; // 9
            default: seg_ah = 8'b0_0000000; // blank
        endcase
    end
endmodule
