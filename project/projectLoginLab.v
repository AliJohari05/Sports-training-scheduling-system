module CalW60 (
    input [1:0] Cal,     // c1, c0
    input [2:0] W,       // w2, w1, w0
    output wire [7:0] o  // o[0] to o[7]
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
                  (c0 & w1 & & ~c1 & ~w0) | (c1 & ~c0 & ~w1 & ~w2) | 
                  (c1 & ~w0 & ~w1) | (c0 & c1 & w2 & !w0) | 
                  (c0 & c1 & w0 & w1);

    assign o[3] = (~w2 & ~c1 & `w0 & ~c0) | (~w2 & ~w1 & ~w0 & ~c1) |
                  (w2 & w1 & ~c1 & ~c0) | (w2 & w0 & ~w1 & ~c1) | 
                  (w2 & w0 & ~c0) |
                   (w0 & w1 & ~w2 & c0 & ~c1) | (c0 & c1 & ~w0 & w1) | 
                   (c0 & c1 & w0 & ~w1);

    assign o[4] = (w2 & w1 & ~c1) | (w2 & w0 & ~c1) |
     (w2 & w0 & ~w1) | (~w2 & ~w1 & ~c0) |
    (~w2 & ~w0 & ~c1 & ~c0) | (~w2 & w1 & c1 & w0)
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
    input [7:0] cal_w60_out, // output : CalW60 (Cal * 60 / W)
    input gender,            // 0 = male (G=1), 1 = female (G=1.125)
    input [1:0] MET,         // MET = 1, 2, 4, 8
    output [7:0] T       // Final workout time (in minutes)
);
    reg [7:0] Gender_output; 
    reg [7:0] Met_output;
    always @(*) begin
        case(gender)
            1'b0 : Gender_output = cal_w60_out;
            1'b1 : Gender_output = cal_w60_out + (cal_w60_out >> 3) // *(9/8) = 1.125
            default : Gender_output = cal_w60_out;
        endcase
    end 

    always @(*)begin
        case(MET):
            2'b00 : Met_output = Gender_output;
            2'b01 : Met_output = (Gender_output >> 1); // / 2
            2'b10 : Met_output = (Gender_output >> 2); // / 4
            2'b11 : Met_output = (Gender_output >> 3); // / 8
            default:Met_output = Gender_output;
        endcase
    end

    assign T = Met_output;

endmodule

module fsm_workout (
    input clk,              
    input reset,            
    input start,             
    input skip,              
    input [7:0] T_input,     // Total number of workouts from TimeCalculator
    output reg [7:0] workout_num, // Current workout index
    output reg [5:0] time_remain, // Countdown time (0-59 seconds)
    output reg buzzer             // Buzzer signal
);

    parameter S0 = 3'b000, // Initial state before starting the exercise
              S1 = 3'b001, // INIT_WORK
              S2 = 3'b010, // WORK
              S3 = 3'b011, // INIT_REST
              S4 = 3'b100, // REST
              S5 = 3'b101; // DONE(Completion of exercises)

    reg [2:0] state, next_state;

  
    parameter WORK_TIME = 6'd45;
    parameter REST_TIME = 6'd15;

    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

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

 always @(posedge clk) begin
        if (reset) begin
            workout_num <= 0;
            time_remain <= 0;
            buzzer <= 0;
        end else begin
            buzzer <= 0;
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
                        buzzer <= 1;
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
                    buzzer <= 1;
                end
            endcase
        end
    end

endmodule

module TopModule(
    input clk,
    input reset,
    input start,
    input skip,
    input [1:0] Cal,    
    input [2:0] W,      
    input gender,        
    input [1:0] MET,     

    output [7:0] workout_num,
    output [5:0] time_remain,
    output buzzer
);

    wire [7:0] resultCalW60;
    wire [7:0] total_time;

    CalW60 part1Formula (
        .Cal(Cal),
        .W(W),
        .o(resultCalW60)
    );

    TimeCalculator partFinalFormula (
        .cal_w60_out(resultCalW60),
        .gender(gender),
        .MET(MET),
        .T(total_time)
    );

    fsm_workout fsm_ctrl (
        .clk(clk),
        .reset(reset),
        .start(start),
        .skip(skip),
        .T_input(total_time),
        .workout_num(workout_num),
        .time_remain(time_remain),
        .buzzer(buzzer)
    );

endmodule
