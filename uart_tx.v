`timescale 1ns / 1ps
module uart_tx #(parameter CLKS_PER_BIT = 868)(
    input clk, input reset, input tx_start, input [7:0] data_in,
    output reg tx, output reg tx_busy
);
    reg [2:0] state;
    reg [9:0] clock_count;
    reg [2:0] bit_index;
    reg [7:0] tx_data;

    always @(posedge clk) begin
        if (reset) begin
            state <= 0; clock_count <= 0; bit_index <= 0; tx <= 1'b1; tx_busy <= 0; tx_data <= 0;
        end else begin
            case (state)
                0: begin
                    tx <= 1'b1; clock_count <= 0; bit_index <= 0;
                    if (tx_start) begin
                        tx_busy <= 1'b1; tx_data <= data_in; state <= 1;
                    end else tx_busy <= 1'b0;
                end
                1: begin
                    tx <= 1'b0;
                    if (clock_count < CLKS_PER_BIT-1) clock_count <= clock_count + 1;
                    else begin clock_count <= 0; state <= 2; end
                end
                2: begin
                    tx <= tx_data[bit_index];
                    if (clock_count < CLKS_PER_BIT-1) clock_count <= clock_count + 1;
                    else begin
                        clock_count <= 0;
                        if (bit_index < 7) bit_index <= bit_index + 1;
                        else begin bit_index <= 0; state <= 3; end
                    end
                end
                3: begin
                    tx <= 1'b1;
                    if (clock_count < CLKS_PER_BIT-1) clock_count <= clock_count + 1;
                    else begin clock_count <= 0; state <= 4; end
                end
                4: begin
                    tx_busy <= 1'b0; state <= 0;
                end
            endcase
        end
    end
endmodule