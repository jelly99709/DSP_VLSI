function H_rotate = RowGRotate(idx1, idx2, cos_theta, sin_theta, H, int_num, frac_num)

H_rotate = H;
H_rotate(idx1,:) = fi(cos_theta * H(idx1,:) + sin_theta * H(idx2,:), 1, frac_num+int_num, frac_num);
H_rotate(idx2,:) = fi(-sin_theta * H(idx1,:) + cos_theta * H(idx2,:), 1, frac_num+int_num, frac_num);

