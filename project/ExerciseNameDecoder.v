// ExerciseNameDecoder.v
// Returns 16 ASCII chars (128 bits)

module ExerciseNameDecoder (
    input  [2:0]   index,
    output reg [127:0] exercise_name
);
    always @(*) begin
        case (index)
            3'd0: exercise_name = "Jumping Jacks  ";
            3'd1: exercise_name = "Push Ups       ";
            3'd2: exercise_name = "Squats         ";
            3'd3: exercise_name = "Lunges         ";
            3'd4: exercise_name = "Plank          ";
            3'd5: exercise_name = "Mountain Climb ";
            3'd6: exercise_name = "Burpees        ";
            3'd7: exercise_name = "High Knees     ";
            default: exercise_name = "Unknown        ";
        endcase
    end
endmodule
