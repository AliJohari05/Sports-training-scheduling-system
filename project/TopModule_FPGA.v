module TopModule_FPGA (
    input        clk,      // board clock (e.g., 50MHz)
    input        reset,
    input        start,
    input        skip,
    input  [7:0] P,        // packed: {G, MET[1:0], Cal[1:0], W[2:0]}

    // expose these to wrapper
    output [7:0] lcd_data,
    output       lcd_rs,
    output       lcd_en,
    output       buzzer,
    output [7:0] T          // for 7-seg/debug
);

    // unpack
    wire        gender = P[7];
    wire [1:0]  MET    = P[6:5];
    wire [1:0]  Cal    = P[4:3];
    wire [2:0]  W      = P[2:0];

    // internal wires
    wire [7:0] resultCalW60;
    wire [7:0] T_internal;
    wire [7:0] workout_num_internal;
    wire [5:0] time_remain_internal;
    wire       buzzer_signal;

    // exercise name (16 chars)
    wire [2:0]   exercise_index = workout_num_internal[2:0];
    wire [127:0] exercise_name;

    // Cal*60/W LUT
    CalW60 part1Formula (
        .Cal(Cal),
        .W(W),
        .o(resultCalW60)
    );

    // Gender & MET
    TimeCalculator partFinalFormula (
        .cal_w60_out(resultCalW60),
        .gender(gender),
        .MET(MET),
        .T(T_internal)
    );

    // FSM
    fsm_workout fsm_ctrl (
        .clk(clk),
        .reset(reset),
        .start(start),
        .skip(skip),
        .T_input(T_internal),
        .workout_num(workout_num_internal),
        .time_remain(time_remain_internal),
        .buzzer(buzzer_signal)
    );

    // exercise name
    ExerciseNameDecoder decoder (
        .index(exercise_index),
        .exercise_name(exercise_name)
    );

    // single LCD controller (ONLY here)
    LCD_Controller lcd_inst (
        .clk(clk),
        .reset(reset),
        .exercise_name(exercise_name),
        .time_remain(time_remain_internal),
        .lcd_data(lcd_data),
        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en)
    );

    // buzzer
    buzzer buzzer_inst (
        .clk(clk),
        .rst(reset),
        .alarm(buzzer_signal),
        .buzzer_out(buzzer)
    );

    // expose T
    assign T = T_internal;

endmodule
