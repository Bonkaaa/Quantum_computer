`timescale 1ns/1ps

module tb_quantum_system;
    // ==================== TEST SIGNALS ====================
    reg clk;
    reg reset;
    
    reg [2:0] cmd_gate;
    reg cmd_execute;
    
    wire [1:0] status;
    wire [31:0] display_alpha;
    wire [31:0] display_beta;
    wire gate_busy;
    
    // ==================== REAL VALUES CONVERSION ====================
    real alpha_real, beta_real;
    real prob0_real, prob1_real;
    
    // Fixed-point to real: Q16.16 → real
    function real fp_to_real;
        input [31:0] fp_val;
        begin
            fp_to_real = $itor(fp_val) / 65536.0;
        end
    endfunction
    
    always @(*) begin
        alpha_real = fp_to_real(display_alpha);
        beta_real  = fp_to_real(display_beta);
        
        // Probability = α², β²
        prob0_real = alpha_real * alpha_real;
        prob1_real = beta_real * beta_real;
    end
    
    // ==================== STATE DISPLAY ====================
    function [39:0] get_state_name;
        input [31:0] alpha, beta;
        real a, b;
        begin
            a = fp_to_real(alpha);
            b = fp_to_real(beta);
            
            if (a > 0.99 && b < 0.01) get_state_name = "|0⟩          ";
            else if (a < 0.01 && b > 0.99) get_state_name = "|1⟩          ";
            else if (a > 0.707 && a < 0.708 && b > 0.707 && b < 0.708) 
                get_state_name = "|+⟩ = H|0⟩   ";
            else if (a > 0.707 && a < 0.708 && b < -0.707 && b > -0.708)
                get_state_name = "|-⟩ = H|1⟩   ";
            else 
                get_state_name = "Superposition";
        end
    endfunction
    
    // ==================== DUT INSTANCE ====================
    quantum_controller dut (
        .clk(clk),
        .reset(reset),
        .cmd_gate(cmd_gate),
        .cmd_execute(cmd_execute),
        .status(status),
        .display_alpha(display_alpha),
        .display_beta(display_beta),
        .gate_busy(gate_busy)
    );
    
    // ==================== CLOCK GENERATION ====================
    // 100MHz clock (10ns period)
    always #5 clk = ~clk;
    
    // ==================== TASK: APPLY GATE ====================
    task apply_gate;
        input [2:0] gate_code;
        input [79:0] gate_name;
        begin
            // Wait if controller is busy
            while (gate_busy) #10;
            
            // Set command
            cmd_gate = gate_code;
            #10;
            
            // Pulse execute
            cmd_execute = 1;
            #10;
            cmd_execute = 0;
            
            $display("  [APPLY] %s at time %t", gate_name, $time);
            
            // Wait for completion (1µs + margin)
            #1100;
            
            // Display result
            $display("    -> α = %8.6f, β = %8.6f", alpha_real, beta_real);
            $display("    -> |ψ⟩ = %s", get_state_name(display_alpha, display_beta));
            $display("    -> P(|0⟩) = %6.2f%%, P(|1⟩) = %6.2f%%", 
                     prob0_real*100, prob1_real*100);
        end
    endtask
    
    // ==================== MAIN TEST SEQUENCE ====================
    initial begin
        // Initialize waveform dump
        $dumpfile("quantum_system.vcd");
        $dumpvars(0, tb_quantum_system);
        
        // Initialize signals
        clk = 0;
        reset = 1;
        cmd_gate = 3'b000;
        cmd_execute = 0;
        
        // System reset
        #100 reset = 0;
        
        $display("\n==========================================");
        $display("   QUANTUM CONTROLLER SIMULATION");
        $display("==========================================\n");
        
        $display("Initial state after reset:");
        $display("  α = %8.6f, β = %8.6f", alpha_real, beta_real);
        $display("  |ψ⟩ = %s", get_state_name(display_alpha, display_beta));
        $display("");
        
        // ========== TEST 1: BASIC GATES ==========
        $display("=== TEST 1: BASIC GATE SEQUENCE ===");
        
        // H gate: |0⟩ → |+⟩
        apply_gate(3'b001, "Hadamard (H)");
        
        // X gate: |+⟩ → |+⟩ (unchanged!)
        apply_gate(3'b010, "Pauli-X (X)");
        
        // H gate: |+⟩ → |0⟩ (H² = I)
        apply_gate(3'b001, "Hadamard (H)");
        
        // X gate: |0⟩ → |1⟩
        apply_gate(3'b010, "Pauli-X (X)");
        
        // H gate: |1⟩ → |-⟩
        apply_gate(3'b001, "Hadamard (H)");
        
        // ========== TEST 2: Z GATE ==========
        $display("\n=== TEST 2: Z GATE EFFECT ===");
        
        // Back to |+⟩ first
        apply_gate(3'b001, "Hadamard (H)");  // |-⟩ → |1⟩
        apply_gate(3'b001, "Hadamard (H)");  // |1⟩ → |-⟩
        apply_gate(3'b001, "Hadamard (H)");  // |-⟩ → |1⟩
        apply_gate(3'b010, "Pauli-X (X)");   // |1⟩ → |0⟩
        apply_gate(3'b001, "Hadamard (H)");  // |0⟩ → |+⟩
        
        // Z on |+⟩: |+⟩ → |-⟩
        apply_gate(3'b011, "Pauli-Z (Z)");
        
        // ========== TEST 3: Y GATE ==========
        $display("\n=== TEST 3: Y GATE ===");
        
        // Reset to |0⟩
        reset = 1;
        #100 reset = 0;
        
        // Y gate: |0⟩ → -|1⟩ ≈ |1⟩ (global phase ignored)
        apply_gate(3'b100, "Pauli-Y (Y)");
        
        // ========== TEST 4: GATE CHAINING ==========
        $display("\n=== TEST 4: GATE CHAINING ===");
        
        reset = 1;
        #100 reset = 0;
        
        // HZH = X (Test identity)
        $display("Testing HZH = X:");
        apply_gate(3'b001, "H");  // |0⟩ → |+⟩
        apply_gate(3'b011, "Z");  // |+⟩ → |-⟩
        apply_gate(3'b001, "H");  // |-⟩ → |1⟩
        // Should end up in |1⟩, same as X|0⟩
        
        $display("\n=== SIMULATION COMPLETE ===");
        $display("Total simulation time: %t ns", $time);
        $finish;
    end
    
    // ==================== MONITOR ====================
    // Optional: monitor state changes
    initial begin
        #10; // Wait a bit
        $monitor("Time %t: Status=%b, α=%8.6f, β=%8.6f", 
                 $time, status, alpha_real, beta_real);
    end
    
endmodule