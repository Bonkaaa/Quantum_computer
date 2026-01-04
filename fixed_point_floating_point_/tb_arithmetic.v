`timescale 1ns/1ns

module tb_arithmetic;
    // Khai báo dây nối
    reg signed [31:0] A, B;
    wire signed [31:0] Sum, Prod;
    wire ov_add, ov_mult;

    // Kết nối module cần test
    fixed_point_add u_add (.a(A), .b(B), .out(Sum), .overflow(ov_add));
    fixed_point_mult u_mult (.a(A), .b(B), .out(Prod), .overflow(ov_mult));

    // --- CẤU HÌNH GTKWAVE (QUAN TRỌNG) ---
    initial begin
        $dumpfile("wave.vcd");      // Tên file sóng
        $dumpvars(0, tb_arithmetic); // Ghi lại tất cả tín hiệu
    end

    initial begin
        // Case 1: Phép nhân chuẩn 0.5 * 0.5 = 0.25
        // 0.5 = 32768 (0x00008000), 0.25 = 16384 (0x00004000)
        A = 32'h00008000; B = 32'h00008000;
        #10; // Chờ 10ns
        $display("Time %0t: 0.5 * 0.5 = %d (Expected 16384)", $time, Prod);

        // Case 2: Phép nhân căn 2 (Hadamard)
        // 1/sqrt(2) = 0.7071 => 46341
        // 0.7071 * 0.7071 approx 0.5
        A = 46341; B = 46341;
        #10;
        $display("Time %0t: 0.707 * 0.707 = %d (Expected approx 32768)", $time, Prod);

        // Case 3: Test Tràn số (Bão hòa)
        // Max Positive = 2147483647. Cộng thêm 10000 sẽ tràn.
        A = 32'h7FFFFFFF; B = 32'd10000;
        #10;
        $display("Time %0t: Max + 10000 = %h (Expected 7FFFFFFF - Saturation)", $time, Sum);

        // Case 4: Nhân số âm
        // -1.0 * 0.5 = -0.5
        // -1.0 = 0xFFFF0000
        A = -32'sd65536; B = 32'sd32768; 
        #10;
        
        $finish; // Kết thúc mô phỏng
    end
endmodule