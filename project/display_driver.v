// display_driver.v
// 4-digit multiplexed driver with internal refresh tick.
// Works on ISE (Verilog-2001). No $clog2. No runtime % on non-powers-of-two.
// Assumes board uses COMMON-ANODE (active-LOW anodes/segments).
// *** Map section lets you reorder bits to match your PCB wiring. ***

module display_driver #(
    parameter CLK_HZ       = 50_000_000,
    parameter REFRESH_HZ   = 2000,       // full-display refresh
    parameter COMMON_ANODE = 1,          // 1 => invert segments/anodes
    // If your board's segment header is {a,b,c,d,e,f,g,dp} use MAP_ABCD=1.
    // Many Spartan3 kits route {g,f,e,d,c,b,a,dp} → use MAP_GFED=1.
    parameter MAP_GFED     = 1           // set 1 for g..a order, 0 for a..g
)(
    input        clk,
    input        rst,
    input  [7:0] T,           // 0..255
    output reg [3:0] an,      // digit enables
    output      [7:0] seg     // {dp,g,f,e,d,c,b,a} after mapping+polarity
);
    // ----------------- make ~1/ (REFRESH_HZ*4) tick -----------------
    localparam integer TICK_DIV = CLK_HZ / (REFRESH_HZ * 4);
    reg [31:0] div = 32'd0;
    reg        tick = 1'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div  <= 32'd0;
            tick <= 1'b0;
        end else if (div == TICK_DIV-1) begin
            div  <= 32'd0;
            tick <= 1'b1;
        end else begin
            div  <= div + 32'd1;
            tick <= 1'b0;
        end
    end

    // ----------------- Binary(8) -> BCD -----------------
    wire [3:0] bcd_h, bcd_t, bcd_o;
    bin8_to_bcd b2b(.bin(T), .hundreds(bcd_h), .tens(bcd_t), .ones(bcd_o));

    wire [3:0] d3 = 4'd0;   // thousands (not used)
    wire [3:0] d2 = bcd_h;
    wire [3:0] d1 = bcd_t;
    wire [3:0] d0 = bcd_o;

    // ----------------- digit scan -----------------
    reg [1:0] sel = 2'd0;
    always @(posedge clk or posedge rst) begin
        if (rst) sel <= 2'd0;
        else if (tick) sel <= sel + 2'd1;
    end

    reg [3:0] cur;
    always @(*) begin
        case (sel)
            2'd0: begin cur = d0; an = (COMMON_ANODE ? 4'b1110 : 4'b0001); end
            2'd1: begin cur = d1; an = (COMMON_ANODE ? 4'b1101 : 4'b0010); end
            2'd2: begin cur = d2; an = (COMMON_ANODE ? 4'b1011 : 4'b0100); end
            2'd3: begin cur = d3; an = (COMMON_ANODE ? 4'b0111 : 4'b1000); end
        endcase
    end

    // Decode to ACTIVE-HIGH base order {dp,g,f,e,d,c,b,a}
    wire [7:0] raw_ah;
    seven_segment_decoder dec(.digit(cur), .seg_ah(raw_ah));

    // Re-order for PCB, then apply polarity for common-anode
    wire [7:0] ordered_ah =
        (MAP_GFED)
        // desired order on pins: {dp, a,b,c,d,e,f,g}? or {dp,g,f,e,d,c,b,a}?
        // Many AVA3S400 headers are g..a then dp → create GFEDCBA order:
        ? { raw_ah[7], raw_ah[1], raw_ah[2], raw_ah[3], raw_ah[4], raw_ah[5], raw_ah[6], raw_ah[0] }
        // ABCDEFG order (a..g then dp at MSB):
        : { raw_ah[7], raw_ah[6], raw_ah[5], raw_ah[4], raw_ah[3], raw_ah[2], raw_ah[1], raw_ah[0] };

    assign seg = (COMMON_ANODE ? ~ordered_ah : ordered_ah);
endmodule

// ---------- Double-Dabble: 8-bit binary to BCD ----------
module bin8_to_bcd(
    input  [7:0] bin,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);
    integer i;
    reg [19:0] sh; // [19:16]=hund, [15:12]=tens, [11:8]=ones, [7:0]=bin
    always @(*) begin
        sh = 20'd0;
        sh[7:0] = bin;
        for (i=0; i<8; i=i+1) begin
            if (sh[19:16] >= 5) sh[19:16] = sh[19:16] + 4'd3;
            if (sh[15:12] >= 5) sh[15:12] = sh[15:12] + 4'd3;
            if (sh[11:8]  >= 5) sh[11:8]  = sh[11:8]  + 4'd3;
            sh = sh << 1;
        end
        hundreds = sh[19:16];
        tens     = sh[15:12];
        ones     = sh[11:8];
    end
endmodule
