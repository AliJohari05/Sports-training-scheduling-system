`timescale 1ns/1ps

module TopModule_tb;

    reg clk, reset, start, skip;
    reg [7:0] input_vector;   // {W[2:0], Cal[1:0], MET[1:0], G}

    wire [7:0] workout_num;
    wire [5:0] time_remain;
    wire buzzer;
    wire [7:0] T;

    wire [2:0] W   = input_vector[7:5];
    wire [1:0] Cal = input_vector[4:3];
    wire [1:0] MET = input_vector[2:1];
    wire       G   = input_vector[0];

    integer infile, outfile;
    integer scan_status;
    integer i;

    integer w_dec, cal_dec, met_dec;
    reg [7*8-1:0] g_ascii;

    TopModule uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .skip(skip),
        .Cal(Cal),
        .W(W),
        .gender(G),
        .MET(MET),
        .workout_num(workout_num),
        .time_remain(time_remain),
        .buzzer(buzzer),
        .T(T)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        skip  = 0;
        #20 reset = 0;

        infile  = $fopen("input.txt",  "r");
        outfile = $fopen("output.txt", "w");

        if (infile == 0) begin
            $display("Cannot open input.txt"); $finish;
        end
        if (outfile == 0) begin
            $display("Cannot open output.txt"); $finish;
        end

        for (i = 0; i < 7; i = i + 1) begin
            scan_status = $fscanf(infile, "%b\n", input_vector);

            #10 start = 1;
            #10 start = 0;

            case (W)
                3'b000: w_dec = 50;
                3'b001: w_dec = 60;
                3'b010: w_dec = 70;
                3'b011: w_dec = 80;
                3'b100: w_dec = 90;
                3'b101: w_dec = 100;
                3'b110: w_dec = 110;
                3'b111: w_dec = 120;
                default: w_dec = 0;
            endcase

            case (Cal)
                2'b00: cal_dec = 50;
                2'b01: cal_dec = 100;
                2'b10: cal_dec = 150;
                2'b11: cal_dec = 200;
                default: cal_dec = 0;
            endcase

            case (MET)
                2'b00: met_dec = 1;
                2'b01: met_dec = 2;
                2'b10: met_dec = 4;
                2'b11: met_dec = 8;
                default: met_dec = 1;
            endcase

            if (G) g_ascii = "1.125"; else g_ascii = "1.0";

            #50; 

            $fwrite(outfile,
                "Test %0d: W=%0d, Cal=%0d, MET=%0d, G=%s => T=%0d min\n",
                i+1, w_dec, cal_dec, met_dec, g_ascii, T);

            #10 reset = 1;
            #10 reset = 0;
        end

        $fclose(infile);
        $fclose(outfile);
        $display("Simulation done. Check output.txt");
        #10 $finish;
    end

endmodule
