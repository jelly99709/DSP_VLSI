function Vec_new = ImagNull(idx, cos_theta, sin_theta, Vec, int_num, frac_num)
Vec_new = Vec;
Vec_new(:, idx) = fi((cos_theta + 1i * sin_theta) * Vec(:, idx), 1, frac_num+int_num, frac_num);
