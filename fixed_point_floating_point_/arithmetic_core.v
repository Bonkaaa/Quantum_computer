// 1. Module Cộng Fixed-Point Q15.16 (Có bão hòa)
module fixed_point_add (
    input  signed [31:0] a,
    input  signed [31:0] b,
    output reg signed [31:0] out,
    output reg overflow
);
    wire signed [32:0] temp_sum;
    assign temp_sum = {a[31], a} + {b[31], b}; // Cộng mở rộng dấu

    always @(*) begin
        // Kiểm tra tràn: Nếu 2 bit cao nhất khác nhau là tràn
        if (temp_sum[32] != temp_sum[31]) begin
            overflow = 1'b1;
            // Tràn dương -> Gán Max Pos (0x7FFFFFFF)
            // Tràn âm -> Gán Max Neg (0x80000000)
            out = (temp_sum[32] == 1'b0) ? 32'h7FFFFFFF : 32'h80000000;
        end else begin
            overflow = 1'b0;
            out = temp_sum[31:0];
        end
    end
endmodule

// 2. Module Nhân Fixed-Point Q15.16 (Có bão hòa)
module fixed_point_mult (
    input  signed [31:0] a,
    input  signed [31:0] b,
    output reg signed [31:0] out,
    output reg overflow
);
    wire signed [63:0] temp_mult;
    wire signed [63:0] shifted_mult;

    assign temp_mult = a * b; // Nhân ra 64 bit
    assign shifted_mult = temp_mult >>> 16; // Dịch phải 16 bit để về Q15.16

    always @(*) begin
        // Kiểm tra phần bị cắt bỏ có khớp với bit dấu không
        // Nếu lớn hơn Max 32-bit hoặc nhỏ hơn Min 32-bit -> Tràn
        if (shifted_mult > 64'sh000000007FFFFFFF) begin
            out = 32'h7FFFFFFF;
            overflow = 1'b1;
        end else if (shifted_mult < -64'sh0000000080000000) begin
            out = 32'h80000000;
            overflow = 1'b1;
        end else begin
            out = shifted_mult[31:0];
            overflow = 1'b0;
        end
    end
endmodule