module buzzer (
    input clk,        // should be ~2kHz
    input rst,
    input alarm,      // alarm signal from FSM
    output reg buzzer_out
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            buzzer_out <= 0;
        else if (alarm)
            buzzer_out <= ~buzzer_out;
        else
            buzzer_out <= 0;
    end

endmodule
