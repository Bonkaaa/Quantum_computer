`timescale 1ns/1ps

module quantum_controller(
    // SYSTEM SIGNALS
    input wire         clk,           // System clock (e.g., 100MHz)
    input wire         reset,
    
    // COMMAND INPUTS
    input wire [2:0]   cmd_gate,      // Gate command from user
    input wire         cmd_execute,   // Execute pulse (1 cycle)
    
    // STATUS OUTPUTS  
    output reg [1:0]   status,        // 00: idle, 01: busy, 10: done
    output reg [31:0]  display_alpha, // For monitoring
    output reg [31:0]  display_beta,
    
    // GATE TIMING CONTROL
    output wire        gate_busy      // High when gate is executing
);
    
    // ==================== FSM STATES ====================
    parameter ST_IDLE    = 2'b00;
    parameter ST_EXECUTE = 2'b01;
    parameter ST_UPDATE  = 2'b10;
    
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // ==================== TIMING CONTROL ====================
    // Gate execution time: 1µs = 1000ns
    parameter GATE_DELAY = 32'd1000;  // 1000 cycles @ 1ns
    
    reg [31:0] timer_counter;
    reg        timer_done;
    
    // ==================== INTERNAL SIGNALS ====================
    reg [31:0]  alpha_to_gate;
    reg [31:0]  beta_to_gate;
    wire [31:0] alpha_from_gate;
    wire [31:0] beta_from_gate;
    
    reg         reg_update_en;
    reg [2:0]   current_gate;
    
    // ==================== MODULE INSTANCES ====================
    
    // Gate execution unit
    quantum_gate gate_unit (
        .alpha_in(alpha_to_gate),
        .beta_in(beta_to_gate),
        .gate_type(current_gate),
        .alpha_out(alpha_from_gate),
        .beta_out(beta_from_gate)
    );
    
    // State register
    quantum_state state_reg (
        .clk(clk),
        .reset(reset),
        .update_en(reg_update_en),
        .alpha_in(alpha_from_gate),
        .beta_in(beta_from_gate),
        .alpha_out(alpha_to_gate),
        .beta_out(beta_to_gate),
        .prob_0(),  // Optional
        .prob_1()
    );
    
    // ==================== FSM: STATE REGISTER ====================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= ST_IDLE;
            timer_counter <= 0;
            timer_done    <= 0;
        end
        else begin
            current_state <= next_state;
            
            // Timer logic
            if (current_state == ST_EXECUTE) begin
                if (timer_counter < GATE_DELAY) begin
                    timer_counter <= timer_counter + 1;
                    timer_done <= 0;
                end
                else begin
                    timer_done <= 1;
                end
            end
            else begin
                timer_counter <= 0;
                timer_done <= 0;
            end
        end
    end
    
    // ==================== FSM: NEXT STATE LOGIC ====================
    always @(*) begin
        // Default values
        next_state = current_state;
        reg_update_en = 0;
        status = ST_IDLE;
        
        case (current_state)
            ST_IDLE: begin
                status = ST_IDLE;
                if (cmd_execute && (cmd_gate != 3'b000)) begin
                    next_state = ST_EXECUTE;
                    current_gate = cmd_gate;
                end
            end
            
            ST_EXECUTE: begin
                status = ST_EXECUTE;
                if (timer_done) begin
                    next_state = ST_UPDATE;
                end
            end
            
            ST_UPDATE: begin
                status = ST_EXECUTE;  // Still busy
                reg_update_en = 1;
                next_state = ST_IDLE;
            end
            
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end
    
    // ==================== OUTPUT ASSIGNMENTS ====================
    always @(posedge clk) begin
        display_alpha <= alpha_to_gate;
        display_beta  <= beta_to_gate;
    end
    
    assign gate_busy = (current_state != ST_IDLE);
    
endmodule