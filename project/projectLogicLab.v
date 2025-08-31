module CalW60 (
    input  [1:0] Cal,     // calorie class: c1,c0
    input  [2:0] W,       // weight class:  w2,w1,w0
    output wire [7:0] o   // encoded (Cal*60)/W buckets
);

    wire c1 = Cal[1];
    wire c0 = Cal[0];
    wire w2 = W[2];
    wire w1 = W[1];
    wire w0 = W[0];

    assign o[0] = (w2 & ~w0 & ~c1) | (c0 & ~w0 & c1) | (~c0 & w1 & c1 & w0) |
                  (~w2 & w1 & c1 & ~c0) | (w1 & w2 & ~c0 & ~c1) |
                  (w1 & ~w0 & ~c0 & ~c1) | (w0 & c0 & w1 & ~c1 & ~w2);

    assign o[1] = (w1 & ~w0 & ~c1) | (c0 & w1 & ~c1) | (w1 & ~w2 & ~c1) |
                  (w2 & c0 & ~w0 & ~c1) | (w0 & ~c0 & ~w1) |
                  (~c0 & w1 & w2 & c1) | (~w2 & w1 & c0);

    assign o[2] = (~c0 & ~w2 & ~w1 & ~w0) | (w1 & ~w2 & w0 & ~c0 & ~c1) |
                  (~c1 & w2 & ~w1 & w0) | (c0 & w0 & ~c1 & ~w1) | 
                  (c0 & w1 & ~c1 & ~w0) | (c1 & ~c0 & ~w1 & ~w2) | 
                  (c1 & ~w0 & ~w1) | (c0 & c1 & w2 & ~w0) | 
                  (c0 & c1 & w0 & w1);

    assign o[3] = (~w2 & ~c1 & w0 & ~c0) | (~w2 & ~w1 & ~w0 & ~c1) |
                  (w2 & w1 & ~c1 & ~c0) | (w2 & w0 & ~w1 & ~c1) | 
                  (w2 & w0 & ~c0) |
                  (w0 & w1 & ~w2 & c0 & ~c1) | (c0 & c1 & ~w0 & w1) | 
                  (c0 & c1 & w0 & ~w1);

    assign o[4] = (w2 & w1 & ~c1) | (w2 & w0 & ~c1) |
                  (w2 & w0 & ~w1) | (~w2 & ~w1 & ~c0) |
                  (~w2 & ~w0 & ~c1 & c0) | (~w2 & w1 & c1 & w0)
                  | (w2 & w1 & c1 & ~c0 & ~w0);

    assign o[5] = (~w2 & ~c0 & ~c1) | (~w2 & ~w1 & ~w0 & ~c0)
                  | (~w2 & w1 & w0 & ~c0) | (~w2 & ~w1 & ~c1)
                  | (w2 & ~w1 & ~w0 & ~c0) | (w2 & w1 & c0)
                  | (w2 & w0 & ~w1 & c0) | (c0 & c1 & w1 & ~w0);

    assign o[6] =  (c0 & ~c1 & w1 & ~w2) | (c0 & w0 & ~w1 & ~w2)
                  | (c0 & ~c1 & ~w1 & ~w0 & w2) | (c1 & w1 & w2)
                  | (c1 & w0 & w2) | (~c0 & c1 & w1 & w0)
                  | (w2 & c1 & ~w0 & ~c0);

    assign o[7] = (c0 & c1 & ~w2) |  (c1 & ~w0 & ~w2)
                  | (c1 & ~w1 & ~w2) | (c0 & c1 & ~w1 & ~w0);

endmodule


module TimeCalculator (
    input  [7:0] cal_w60_out, // from CalW60 (encoded)
    input        gender,      // 0: male (x1.0), 1: female (~x1.125)
    input  [1:0] MET,         // 00:/1, 01:/2, 10:/4, 11:/8
    output [7:0] T            // total number of rounds
);
    reg [7:0] Gender_output; 
    reg [7:0] Met_output;

    always @(*) begin
        case (gender)
            1'b0: Gender_output = cal_w60_out;                       // male
            1'b1: Gender_output = cal_w60_out + (cal_w60_out >> 3);  // female â‰ˆ x1.125
            default: Gender_output = cal_w60_out;
        endcase
    end 

    always @(*) begin
        case (MET)
            2'b00: Met_output = Gender_output;         // /1
            2'b01: Met_output = (Gender_output >> 1);  // /2
            2'b10: Met_output = (Gender_output >> 2);  // /4
            2'b11: Met_output = (Gender_output >> 3);  // /8
            default: Met_output = Gender_output;
        endcase
    end

    assign T = Met_output;

endmodule


module fsm_workout (
    input        clk,              // MUST be 1 Hz tick
    input        reset,
    input        start,
    input        skip,
    input  [7:0] T_input,          // number of rounds
    output reg [7:0] workout_num,  // current round (0..T_input)
    output reg [5:0] time_remain,  // seconds (0..59)
    output reg       buzzer        // short pulse at edges
);

    parameter S0 = 3'b000, // IDLE (before start)
              S1 = 3'b001, // INIT_WORK
              S2 = 3'b010, // WORK
              S3 = 3'b011, // INIT_REST
              S4 = 3'b100, // REST
              S5 = 3'b101; // DONE

    reg [2:0] state, next_state;

    parameter WORK_TIME = 6'd45;   // 45 seconds
    parameter REST_TIME = 6'd15;   // 15 seconds

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        case (state)
            S0: next_state = start ? S1 : S0;
            S1: next_state = S2;
            S2: begin
                if (skip)
                    next_state = (workout_num + 1 < T_input) ? S1 : S5;
                else if (time_remain == 0)
                    next_state = (workout_num + 1 < T_input) ? S3 : S5;
                else
                    next_state = S2;
            end
            S3: next_state = S4;
            S4: next_state = (time_remain == 0) ? S1 : S4;
            S5: next_state = S5;
            default: next_state = S0;
        endcase
    end

    // Outputs / counters
    always @(posedge clk) begin
        if (reset) begin
            workout_num <= 0;
            time_remain <= 0;
            buzzer      <= 0;
        end else begin
            buzzer <= 0; // default
            case (state)
                S0: begin
                    workout_num <= 0;
                    time_remain <= 0;
                end
                S1: begin
                    time_remain <= WORK_TIME;
                end
                S2: begin
                    if (skip || time_remain == 0) begin
                        workout_num <= workout_num + 1;
                        buzzer      <= 1;
                    end else begin
                        time_remain <= time_remain - 1;
                    end
                end
                S3: begin
                    time_remain <= REST_TIME;
                end
                S4: begin
                    if (time_remain == 1)
                        buzzer <= 1; 
                    if (time_remain > 0)
                        time_remain <= time_remain - 1;
                end
                S5: begin
                    time_remain <= 0;
                    buzzer      <= 1;
                end
            endcase
        end
    end

endmodule


module TopModule(
    input        clk,
    input        reset,
    input        start,
    input        skip,
    input  [1:0] Cal,      // << 2-bit per spec
    input  [2:0] W,        // << 3-bit per spec
    input        gender,   // G: 0=male, 1=female(1.125)
    input  [1:0] MET,      // 00=1,01=2,10=4,11=8

    output [7:0] workout_num,
    output [5:0] time_remain,
    output       buzzer,
    output [7:0] T,

    // LCD signals (RW is hard-wired to 0 here)
    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_rw,
    output       lcd_en
);

    wire [7:0] resultCalW60;
    wire [127:0] exercise_name;
    wire [2:0] exercise_index;
    wire buzzer_signal;

    // index = workout_num % 8 (equivalent to low 3 bits)
    assign exercise_index = workout_num[2:0];

    // -------- CalW60 (only lower bits used) --------
    CalW60 part1Formula (
        .Cal(Cal),       // 2-bit
        .W(W),           // 3-bit
        .o(resultCalW60)
    );

    // -------- TimeCalculator --------
    TimeCalculator partFinalFormula (
        .cal_w60_out(resultCalW60),
        .gender(gender),
        .MET(MET),
        .T(T)
    );

    // -------- FSM controller --------
    fsm_workout fsm_ctrl (
        .clk(clk),
        .reset(reset),
        .start(start),
        .skip(skip),
        .T_input(T),
        .workout_num(workout_num),
        .time_remain(time_remain),
        .buzzer(buzzer_signal)
    );

    // -------- Exercise name decoder (16 chars) --------
    ExerciseNameDecoder decoder (
        .index(exercise_index),
        .exercise_name(exercise_name)
    );

    // -------- LCD controller (no RW port) --------
    LCD_Controller lcd_inst (
        .clk(clk),
        .reset(reset),
        .exercise_name(exercise_name),
        .time_remain(time_remain),
        .lcd_data(lcd_data),
        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en)
    );

    // RW is not used in the LCD controller: tie it low for write-only
    assign lcd_rw = 1'b0;

    // -------- Buzzer --------
    buzzer buzzer_inst (
        .clk(clk),            // or your divided 2kHz clock
        .rst(reset),
        .alarm(buzzer_signal),
        .buzzer_out(buzzer)
    );

endmodule

