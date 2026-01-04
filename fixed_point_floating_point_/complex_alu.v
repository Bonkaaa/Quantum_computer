module complex_mult (
    input  signed [31:0] ar, ai, // Số phức A (Thực, Ảo)
    input  signed [31:0] br, bi, // Số phức B (Thực, Ảo)
    output signed [31:0] cr, ci  // Kết quả C (Thực, Ảo)
);
    // Công thức: (ar + ai*i)*(br + bi*i) = (ar*br - ai*bi) + (ar*bi + ai*br)*i
    
    wire signed [31:0] p1, p2, p3, p4;
    wire ov1, ov2, ov3, ov4;

    // 4 Phép nhân thực
    fixed_point_mult m1 (ar, br, p1, ov1); // ar * br
    fixed_point_mult m2 (ai, bi, p2, ov2); // ai * bi
    fixed_point_mult m3 (ar, bi, p3, ov3); // ar * bi
    fixed_point_mult m4 (ai, br, p4, ov4); // ai * br

    // 1 Trừ, 1 Cộng
    // Lưu ý: Phép trừ có thể dùng bộ cộng với số đảo dấu, ở đây viết tắt logic
    // Để đơn giản cho demo, ta dùng bộ cộng cho phần ảo:
    wire ov_imag;
    fixed_point_add add_imag (p3, p4, ci, ov_imag); // Imag = p3 + p4

    // Phần thực dùng bộ cộng: Real = p1 + (-p2)
    wire signed [31:0] neg_p2;
    assign neg_p2 = -p2; 
    wire ov_real;
    fixed_point_add add_real (p1, neg_p2, cr, ov_real); // Real = p1 - p2

endmodule