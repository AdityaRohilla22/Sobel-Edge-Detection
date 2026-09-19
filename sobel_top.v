`timescale 1ns / 1ps
module sobel_top (
    input clk,
    input reset,
    input RsRx,           
    output RsTx,          
    output [7:0] led      
);

    wire [7:0] pixel_data;
    wire pixel_valid;
    wire [7:0] edge_value;
    wire edge_valid;
    wire tx_busy;

    wire [7:0] window_0_0, window_0_1, window_0_2;
    wire [7:0] window_1_0, window_1_1, window_1_2;
    wire [7:0] window_2_0, window_2_1, window_2_2;
    wire window_valid;

    uart_rx receiver (
        .clk(clk), .reset(reset), .rx(RsRx),
        .data_out(pixel_data), .data_valid(pixel_valid)
    );

    bram_controller bram_ctrl (
        .clk(clk), .reset(reset),
        .pixel_in(pixel_data), .pixel_valid(pixel_valid),
        .window_0_0(window_0_0), .window_0_1(window_0_1), .window_0_2(window_0_2),
        .window_1_0(window_1_0), .window_1_1(window_1_1), .window_1_2(window_1_2),
        .window_2_0(window_2_0), .window_2_1(window_2_1), .window_2_2(window_2_2),
        .window_valid(window_valid)
    );

    sobel_operator sobel (
        .clk(clk), .reset(reset),
        .window_0_0(window_0_0), .window_0_1(window_0_1), .window_0_2(window_0_2),
        .window_1_0(window_1_0), .window_1_1(window_1_1), .window_1_2(window_1_2),
        .window_2_0(window_2_0), .window_2_1(window_2_1), .window_2_2(window_2_2),
        .window_valid(window_valid),
        .edge_value(edge_value), .edge_valid(edge_valid)
    );

    reg [7:0] tx_buffer;
    reg send_pending;

    always @(posedge clk) begin
        if (reset) begin
            send_pending <= 0;
        end else begin
            if (edge_valid) begin
                tx_buffer <= edge_value;
                send_pending <= 1;
            end 
            else if (send_pending && !tx_busy) begin
                send_pending <= 0;
            end
        end
    end

    uart_tx transmitter (
        .clk(clk), .reset(reset),
        .tx_start(send_pending && !tx_busy),
        .data_in(tx_buffer),
        .tx(RsTx), .tx_busy(tx_busy)
    );

    assign led = pixel_data;
endmodule