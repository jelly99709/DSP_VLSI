function Vec_new = RealNull(idx1, idx2, cos_theta, sin_theta, Vec, int_num, frac_num)
Vec_new = Vec;
Vec_new(:,idx1) = fi(cos_theta * Vec(:,idx1) + sin_theta * Vec(:,idx2), 1, frac_num+int_num, frac_num);
Vec_new(:,idx2) = fi(-sin_theta * Vec(:,idx1) + cos_theta * Vec(:,idx2), 1, frac_num+int_num, frac_num);