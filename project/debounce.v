module debounce (
    input clk,         // 1kHz or faster clock (مثل 1MHz)
    input rst,
    input noisy,       
    output reg clean   // Cleaned output
);

    reg [2:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            shift_reg <= 3'b000;
        else
            shift_reg <= {shift_reg[1:0], noisy};
    end

    always @(*) begin
        if (shift_reg == 3'b111)
            clean = 1'b1;
        else if (shift_reg == 3'b000)
            clean = 1'b0;
    end

endmodule
