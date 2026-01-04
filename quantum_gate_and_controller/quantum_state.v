`timescale 1ns/1ps

module quantum_state(
    // INPUTS
    input wire         clk,         // Clock hệ thống
    input wire         reset,       // Reset tích cực mức cao
    input wire         update_en,   // Tín hiệu cho phép cập nhật
    input wire [31:0]  alpha_in,    // α mới từ cổng
    input wire [31:0]  beta_in,     // β mới từ cổng
    
    // OUTPUTS
    output reg [31:0]  alpha_out,   // α hiện tại
    output reg [31:0]  beta_out,    // β hiện tại
    
    // MONITOR OUTPUTS (tùy chọn)
    output wire [31:0] prob_0,      // Xác suất |0⟩ = α²
    output wire [31:0] prob_1       // Xác suất |1⟩ = β²
);
    
    // ==================== HẰNG SỐ ====================
    parameter FIXED_ONE  = 32'h0001_0000;  // 1.0
    parameter FIXED_ZERO = 32'h0000_0000;  // 0.0
    
    // ==================== HÀM SỐ PHỤ ====================
    // Bình phương fixed-point: a² (Q16.16 → Q16.16)
    function [31:0] fp_square;
        input [31:0] a;
        reg [63:0] temp;
        begin
            temp = a * a;
            fp_square = temp[47:16];  // Q16.16
        end
    endfunction
    
    // ==================== LOGIC CHÍNH ====================
    // Cập nhật trạng thái theo clock
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset về trạng thái |0⟩ = 1|0⟩ + 0|1⟩
            alpha_out <= FIXED_ONE;
            beta_out  <= FIXED_ZERO;
        end
        else if (update_en) begin
            // Cập nhật trạng thái mới
            alpha_out <= alpha_in;
            beta_out  <= beta_in;
        end
        // Không else: giữ nguyên khi không update
    end
    
    // ==================== TÍNH XÁC SUẤT ====================
    // Tính liên tục (combinational logic)
    assign prob_0 = fp_square(alpha_out);
    assign prob_1 = fp_square(beta_out);
    
    // ==================== KIỂM TRA NORMALIZATION ====================
    // (Optional) Cảnh báo nếu |α|² + |β|² ≠ 1
    wire [31:0] total_prob;
    assign total_prob = prob_0 + prob_1;
    
    // Có thể thêm $display warning ở testbench
    
endmodule