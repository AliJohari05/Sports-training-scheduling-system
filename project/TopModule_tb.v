`timescale 1ns/1ps

module TopModule_tb;

    reg clk, reset, start, skip;
    reg [1:0] MET;
    reg [7:0] Cal;
    reg [7:0] W;
    reg gender;

    wire [7:0] workout_num;
    wire [5:0] time_remain;
    wire buzzer;

    integer infile, outfile;
    integer scan_status;
    integer i;

    TopModule uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .skip(skip),
        .Cal(Cal),
        .W(W),
        .gender(gender),
        .MET(MET),
        .workout_num(workout_num),
        .time_remain(time_remain),
        .buzzer(buzzer)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        skip = 0;
        #20;
        reset = 0;

        infile = $fopen("input.txt", "r");
        outfile = $fopen("output.txt", "w");

        if (infile == 0) begin
            $display("Failed to open input.txt");
            $finish;
        end

        if (outfile == 0) begin
            $display("Failed to open output.txt");
            $finish;
        end

        for (i = 0; i < 5; i = i + 1) begin
            scan_status = $fscanf(infile, "%b %b %b %b\n", W, Cal, MET, gender);

            #10;
            start = 1;
            #10;
            start = 0;

            #600;

            $fwrite(outfile, "Test %0d: Cal=%0d W=%0d Gender=%0d MET=%0d => Workout_Num=%0d Time_Remain=%0d Buzzer=%0d \n",
                    i+1, Cal, W, gender, MET, workout_num, time_remain, buzzer);

            repeat (500) begin
                #10;
                $fwrite(outfile, "Time=%0t Workout_Num=%0d Time_Remain=%0d Buzzer=%0d\n",
                        $time, workout_num, time_remain, buzzer);
            end

            #20;
            reset = 1;
            #10;
            reset = 0;
        end

        $fclose(infile);
        $fclose(outfile);
        $display("Simulation complete. Results saved in output.txt");

        #10 $finish;
    end

endmodule
