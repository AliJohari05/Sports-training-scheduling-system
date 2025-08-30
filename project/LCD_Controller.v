// LCD_Controller.v
// HD44780-compatible character LCD controller (8-bit bus, write-only)
// Shows: line1 = exercise_name (16 chars), line2 = "Time: XX sec    "
// Notes:
//  - Designed for a ~1ms tick at 50 MHz (adjust DIV if your clk differs).
//  - RW is tied low internally; do NOT connect lcd_rw at top-level.

module LCD_Controller(
    input         clk,              // e.g., 50 MHz
    input         reset,
    input  [127:0] exercise_name,   // 16 ASCII chars (MSB-first: [127:120] is first char)
    input  [5:0]  time_remain,      // 0..59 seconds

    output reg [7:0] lcd_data,
    output reg       lcd_rs,
    output reg       lcd_en
);

    // ----------------------------------------------------------------
    // RW is fixed low (write-only). If your board exposes RW, tie it to GND.
    // ----------------------------------------------------------------
    wire lcd_rw = 1'b0;

    // ----------------------------------------------------------------
    // 1 ms tick generator @50 MHz  (adjust DIV for other clocks)
    // ----------------------------------------------------------------
    localparam integer DIV = 50_000 - 1; // 50,000 cycles ≈ 1 ms at 50 MHz

    reg [15:0] div_cnt;
    reg        tick;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt <= 16'd0;
            tick    <= 1'b0;
        end else begin
            if (div_cnt == DIV) begin
                div_cnt <= 16'd0;
                tick    <= 1'b1;        // 1-cycle pulse
            end else begin
                div_cnt <= div_cnt + 16'd1;
                tick    <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------------------
    // ASCII digits for time_remain (tens and ones)
    // ----------------------------------------------------------------
    wire [7:0] tens_ascii = ((time_remain / 10) % 10) + 8'd48; // '0'..'5'
    wire [7:0] ones_ascii = (time_remain % 10) + 8'd48;        // '0'..'9'

    // ----------------------------------------------------------------
    // State machine (coded as localparams for Verilog-2001)
    // ----------------------------------------------------------------
    localparam [3:0]
        S_INIT0 = 4'd0,
        S_INIT1 = 4'd1,
        S_INIT2 = 4'd2,
        S_INIT3 = 4'd3,
        S_CLR   = 4'd4,    // (not used separately; CLR is in INIT2)
        S_EMS   = 4'd5,    // (not used separately; EMS is in INIT3)
        S_SETL1 = 4'd6,
        S_WL1   = 4'd7,
        S_SETL2 = 4'd8,
        S_WL2   = 4'd9,
        S_IDLE  = 4'd10;

    reg [3:0] state;            // current state
    reg [5:0] idx;              // 0..31 (we use 0..15 per line)
    reg [7:0] chr;              // current character to write
    reg       en_phase;         // 0: prepare data/rs, 1: pulse EN and advance

    // ----------------------------------------------------------------
    // Character selection for each line (combinational)
    // ----------------------------------------------------------------
    always @(*) begin
        chr = 8'h20; // default ' '
        if (state == S_WL1) begin
            // Line 1: exercise_name[127:120] ... [7:0], idx 0..15
            case (idx[3:0])
                4'd0:  chr = exercise_name[127:120];
                4'd1:  chr = exercise_name[119:112];
                4'd2:  chr = exercise_name[111:104];
                4'd3:  chr = exercise_name[103:96];
                4'd4:  chr = exercise_name[95:88];
                4'd5:  chr = exercise_name[87:80];
                4'd6:  chr = exercise_name[79:72];
                4'd7:  chr = exercise_name[71:64];
                4'd8:  chr = exercise_name[63:56];
                4'd9:  chr = exercise_name[55:48];
                4'd10: chr = exercise_name[47:40];
                4'd11: chr = exercise_name[39:32];
                4'd12: chr = exercise_name[31:24];
                4'd13: chr = exercise_name[23:16];
                4'd14: chr = exercise_name[15:8];
                4'd15: chr = exercise_name[7:0];
                default: chr = 8'h20;
            endcase
        end else if (state == S_WL2) begin
            // Line 2: "Time: XX sec    "
            case (idx[3:0])
                4'd0:  chr = "T";
                4'd1:  chr = "i";
                4'd2:  chr = "m";
                4'd3:  chr = "e";
                4'd4:  chr = ":";
                4'd5:  chr = " ";
                4'd6:  chr = tens_ascii;
                4'd7:  chr = ones_ascii;
                4'd8:  chr = " ";
                4'd9:  chr = "s";
                4'd10: chr = "e";
                4'd11: chr = "c";
                4'd12: chr = " ";
                4'd13: chr = " ";
                4'd14: chr = " ";
                4'd15: chr = " ";
                default: chr = 8'h20;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // LCD command constants
    // ----------------------------------------------------------------
    localparam [7:0] CMD_FUNCSET  = 8'h38; // 8-bit, 2-line, 5x8 dots
    localparam [7:0] CMD_DISPON   = 8'h0C; // display on, cursor off, blink off
    localparam [7:0] CMD_CLEAR    = 8'h01; // clear display
    localparam [7:0] CMD_ENTRY    = 8'h06; // entry mode: increment, no shift
    localparam [7:0] CMD_DDRAM_L1 = 8'h80; // set DDRAM address 0x00
    localparam [7:0] CMD_DDRAM_L2 = 8'hC0; // set DDRAM address 0x40

    // ----------------------------------------------------------------
    // Main FSM: drives RS/DATA and generates EN pulses using en_phase
    // ----------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= S_INIT0;
            idx      <= 6'd0;
            lcd_en   <= 1'b0;
            lcd_rs   <= 1'b0;
            lcd_data <= 8'h00;
            en_phase <= 1'b0;
        end else if (tick) begin
            case (state)

                // Initialization sequence (four commands)
                S_INIT0: begin
                    lcd_rs   <= 1'b0;
                    lcd_data <= CMD_FUNCSET;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        state  <= S_INIT1;
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                S_INIT1: begin
                    lcd_rs   <= 1'b0;
                    lcd_data <= CMD_DISPON;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        state  <= S_INIT2;
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                S_INIT2: begin
                    lcd_rs   <= 1'b0;
                    lcd_data <= CMD_CLEAR;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        state  <= S_INIT3;
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                S_INIT3: begin
                    lcd_rs   <= 1'b0;
                    lcd_data <= CMD_ENTRY;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        state  <= S_SETL1;  // go write line1
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                // Set DDRAM to line1, then write 16 chars from exercise_name
                S_SETL1: begin
                    lcd_rs   <= 1'b0;
                    lcd_data <= CMD_DDRAM_L1;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        idx    <= 6'd0;
                        state  <= S_WL1;
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                S_WL1: begin
                    lcd_rs   <= 1'b1;
                    lcd_data <= chr;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        if (idx == 6'd15) begin
                            state <= S_SETL2;
                            idx   <= 6'd0;
                        end else begin
                            idx <= idx + 6'd1;
                        end
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                // Set DDRAM to line2, then write "Time: XX sec    "
                S_SETL2: begin
                    lcd_rs   <= 1'b0;
                    lcd_data <= CMD_DDRAM_L2;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        idx    <= 6'd0;
                        state  <= S_WL2;
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                S_WL2: begin
                    lcd_rs   <= 1'b1;
                    lcd_data <= chr;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        if (idx == 6'd15) begin
                            state <= S_IDLE;  // enter refresh mode
                            idx   <= 6'd0;
                        end else begin
                            idx <= idx + 6'd1;
                        end
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                // Idle: periodically re-write line2 to update time
                S_IDLE: begin
                    lcd_rs   <= 1'b0;
                    lcd_data <= CMD_DDRAM_L2;
                    en_phase <= ~en_phase;
                    if (en_phase) begin
                        lcd_en <= 1'b0;
                        idx    <= 6'd0;
                        state  <= S_WL2;     // only refresh line2
                    end else begin
                        lcd_en <= 1'b1;
                    end
                end

                default: begin
                    state <= S_INIT0;
                end
            endcase
        end
    end

endmodule
