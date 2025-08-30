// TopModule_FPGA.v
// Packed input P[7:0] = { G, MET[1:0], Cal[1:0], W[2:0] }
// Separate clocks for accurate timing: clk_sys (LCD), clk_1hz (FSM), clk_2khz (buzzer)

module TopModule_FPGA (
    input        clk_sys,   // system clock for LCD controller (e.g., 50MHz)
    input        clk_1hz,   // 1 Hz clock for the workout FSM (seconds)
    input        clk_2khz,  // ~2 kHz clock for buzzer tone
    input        reset,
    input        start,
    input        skip,
    input  [7:0] P,         // {G, MET[1:0], Cal[1:0], W[2:0]}

    // Minimal hardware outputs
    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_en,
    output       buzzer
);

    // Unpack fields from P
    wire        gender = P[7];      // 1 = female (x1.125), 0 = male (x1.0)
    wire [1:0]  MET    = P[6:5];    // 00:1, 01:1/2, 10:1/4, 11:1/8 (per your TimeCalculator)
    wire [1:0]  Cal    = P[4:3];    // abstract 2-bit calorie selector
    wire [2:0]  W      = P[2:0];    // abstract 3-bit weight selector

    // Internal signals
    wire [7:0] resultCalW60;
    wire [7:0] T_internal;
    wire [7:0] workout_num_internal;
    wire [5:0] time_remain_internal;
    wire       buzzer_signal;
    wire [2:0] exercise_index = workout_num_internal[2:0]; // mod 8
    wire [127:0] exercise_name;

    // (1) Cal*60/W from your minimized logic
    CalW60 part1Formula (
        .Cal(Cal),
        .W(W),
        .o(resultCalW60)
    );

    // (2) Apply gender and MET scaling
    TimeCalculator partFinalFormula (
        .cal_w60_out(resultCalW60),
        .gender(gender),
        .MET(MET),
        .T(T_internal)
    );

    // (3) Workout FSM runs at 1 Hz so time_remain is in real seconds
    fsm_workout fsm_ctrl (
        .clk(clk_1hz),
        .reset(reset),
        .start(start),
        .skip(skip),
        .T_input(T_internal),
        .workout_num(workout_num_internal),
        .time_remain(time_remain_internal),
        .buzzer(buzzer_signal)
    );

    // (4) Exercise name (fixed 16 ASCII)
    ExerciseNameDecoder decoder (
        .index(exercise_index),
        .exercise_name(exercise_name)
    );

    // (5) LCD controller uses the fast system clock (clk_sys)
    LCD_Controller lcd_inst (
        .clk(clk_sys),
        .reset(reset),
        .exercise_name(exercise_name),
        .time_remain(time_remain_internal),
        .lcd_data(lcd_data),
        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en)
    );

    // (6) Buzzer toggles on alarm at ~2kHz
    buzzer buzzer_inst (
        .clk(clk_2khz),
        .rst(reset),
        .alarm(buzzer_signal),
        .buzzer_out(buzzer)
    );

endmodule
