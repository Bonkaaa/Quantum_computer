`timescale 1ns/1ps

module quantum_gate(
    // INPUTS
    input wire [31:0] alpha_in,     // Hệ số |0⟩ hiện tại
    input wire [31:0] beta_in,      // Hệ số |1⟩ hiện tại  
    input wire [2:0]  gate_type,    // Loại cổng (000: idle, 001: H, 010: X, 011: Z)
    
    // OUTPUTS
    output reg [31:0] alpha_out,    // α sau cổng
    output reg [31:0] beta_out      // β sau cổng
);
    
    // ==================== HẰNG SỐ ====================
    // Fixed-point format: Q16.16 (16 bit nguyên, 16 bit phân)
    parameter FIXED_ONE   = 32'h0001_0000;  // 1.0
    parameter FIXED_ZERO  = 32'h0000_0000;  // 0.0
    parameter INV_SQRT2   = 32'h0000_B504;  // 1/√2 ≈ 0.70710678
    
    // ==================== MÃ CỔNG ====================
    parameter GATE_IDLE   = 3'b000;
    parameter GATE_H      = 3'b001;  // Hadamard
    parameter GATE_X      = 3'b010;  // Pauli-X
    parameter GATE_Z      = 3'b011;  // Pauli-Z
    parameter GATE_Y      = 3'b100;  // Pauli-Y (mở rộng)
    
    // ==================== HÀM SỐ PHỤ ====================
    // Fixed-point multiplication: a * b (Q16.16 * Q16.16 → Q16.16)
    function [31:0] fp_mul;
        input [31:0] a, b;
        reg [63:0] temp;
        begin
            temp = a * b;          // 64-bit result
            fp_mul = temp[47:16];  // Take middle 32 bits
        end
    endfunction
    
    // ==================== LOGIC CHÍNH ====================
    always @(*) begin
        case (gate_type)
            // Hadamard Gate: H = 1/√2 * [[1, 1], [1, -1]]
            GATE_H: begin
                // α' = (α + β)/√2
                // β' = (α - β)/√2
                alpha_out = fp_mul((alpha_in + beta_in), INV_SQRT2);
                beta_out  = fp_mul((alpha_in - beta_in), INV_SQRT2);
            end
            
            // Pauli-X Gate: X = [[0, 1], [1, 0]]  
            GATE_X: begin
                // α' = β
                // β' = α
                alpha_out = beta_in;
                beta_out  = alpha_in;
            end
            
            // Pauli-Z Gate: Z = [[1, 0], [0, -1]]
            GATE_Z: begin
                // α' = α
                // β' = -β
                alpha_out = alpha_in;
                beta_out  = -beta_in;
            end
            
            // Pauli-Y Gate: Y = [[0, -i], [i, 0]] 
            // Với số thực: coi như [[0, -1], [1, 0]]
            GATE_Y: begin
                // α' = -β
                // β' = α
                alpha_out = -beta_in;
                beta_out  = alpha_in;
            end
            
            // Default: Identity (không làm gì)
            default: begin
                alpha_out = alpha_in;
                beta_out  = beta_in;
            end
        endcase
    end
    
endmodule