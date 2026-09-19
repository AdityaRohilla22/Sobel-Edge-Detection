`timescale 1ns / 1ps
module sobel_operator (
    input clk,
    input reset,
    input [7:0] window_0_0, window_0_1, window_0_2,
    input [7:0] window_1_0, window_1_1, window_1_2,
    input [7:0] window_2_0, window_2_1, window_2_2,
    input window_valid,
    output reg [7:0] edge_value,
    output reg edge_valid
);
    reg signed [10:0] gx_pos, gx_neg;
    reg signed [10:0] gy_pos, gy_neg;
    reg valid_stage1;
    reg signed [11:0] gx, gy;
    reg valid_stage2;
    reg [11:0] abs_gx, abs_gy;
    reg valid_stage3;

    always @(posedge clk) begin
        if (reset) begin
            valid_stage1 <= 0; valid_stage2 <= 0; valid_stage3 <= 0;
            edge_valid   <= 0; edge_value   <= 0;
        end else begin
            gx_pos <= {3'b0, window_0_0} + {2'b0, window_1_0, 1'b0} + {3'b0, window_2_0};
            gx_neg <= {3'b0, window_0_2} + {2'b0, window_1_2, 1'b0} + {3'b0, window_2_2};
            gy_pos <= {3'b0, window_0_0} + {2'b0, window_0_1, 1'b0} + {3'b0, window_0_2};
            gy_neg <= {3'b0, window_2_0} + {2'b0, window_2_1, 1'b0} + {3'b0, window_2_2};
            valid_stage1 <= window_valid;

            gx <= gx_pos - gx_neg;
            gy <= gy_pos - gy_neg;
            valid_stage2 <= valid_stage1;

            abs_gx <= (gx[11]) ? -gx : gx;
            abs_gy <= (gy[11]) ? -gy : gy;
            valid_stage3 <= valid_stage2;

            if ((abs_gx + abs_gy) > 255)
                edge_value <= 255;
            else
                edge_value <= abs_gx + abs_gy;
                
            edge_valid <= valid_stage3;
        end
    end
endmodule