`timescale 1ns / 1ps
module bram_controller (
    input clk,
    input reset,
    input [7:0] pixel_in,
    input pixel_valid,
    output reg [7:0] window_0_0, window_0_1, window_0_2,
    output reg [7:0] window_1_0, window_1_1, window_1_2,
    output reg [7:0] window_2_0, window_2_1, window_2_2,
    output reg window_valid
);
    reg [7:0] line_buffer_0 [0:255];
    reg [7:0] line_buffer_1 [0:255];
    reg [7:0] x_pos;

    wire [7:0] old_row_1 = line_buffer_0[x_pos];
    wire [7:0] old_row_0 = line_buffer_1[x_pos];

    always @(posedge clk) begin
        if (reset) begin
            x_pos <= 0;
            window_valid <= 0;
            window_0_0 <= 0; window_0_1 <= 0; window_0_2 <= 0;
            window_1_0 <= 0; window_1_1 <= 0; window_1_2 <= 0;
            window_2_0 <= 0; window_2_1 <= 0; window_2_2 <= 0;
        end else begin
            window_valid <= pixel_valid;
            if (pixel_valid) begin
                window_0_0 <= window_0_1; window_0_1 <= window_0_2; window_0_2 <= old_row_0;
                window_1_0 <= window_1_1; window_1_1 <= window_1_2; window_1_2 <= old_row_1;
                window_2_0 <= window_2_1; window_2_1 <= window_2_2; window_2_2 <= pixel_in;

                line_buffer_0[x_pos] <= pixel_in;
                line_buffer_1[x_pos] <= old_row_1;
                x_pos <= x_pos + 1;
            end
        end
    end
endmodule