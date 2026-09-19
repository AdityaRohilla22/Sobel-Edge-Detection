`timescale 1ns / 1ps
module uart_rx #(parameter CLKS_PER_BIT = 868)(
    input clk, input reset, input rx,
    output reg [7:0] data_out, output reg data_valid
);
    reg [2:0] state;
    reg [9:0] clock_count;
    reg [2:0] bit_index;
    reg [7:0] rx_data;

    always @(posedge clk) begin
        if (reset) begin
            state <= 0; clock_count <= 0; bit_index <= 0;
            data_valid <= 0; data_out <= 0; rx_data <= 0;
        end else begin
            case (state)
                0: begin
                    data_valid <= 0; clock_count <= 0; bit_index <= 0;
                    if (rx == 1'b0) state <= 1;
                end
                1: begin
                    if (clock_count == (CLKS_PER_BIT-1)/2) begin
                        if (rx == 1'b0) begin
                            clock_count <= 0; state <= 2;
                        end else state <= 0;
                    end else clock_count <= clock_count + 1;
                end
                2: begin
                    if (clock_count < CLKS_PER_BIT-1) clock_count <= clock_count + 1;
                    else begin
                        clock_count <= 0; rx_data[bit_index] <= rx;
                        if (bit_index < 7) bit_index <= bit_index + 1;
                        else begin bit_index <= 0; state <= 3; end
                    end
                end
                3: begin
                    if (clock_count < CLKS_PER_BIT-1) clock_count <= clock_count + 1;
                    else begin
                        data_valid <= 1'b1; data_out <= rx_data; clock_count <= 0; state <= 4;
                    end
                end
                4: begin
                    data_valid <= 0; state <= 0;
                end
            endcase
        end
    end
endmodule