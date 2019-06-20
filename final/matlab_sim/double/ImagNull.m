function Vec_new = ImagNull(idx, theta, Vec)
Vec_new = Vec;
Vec_new(:, idx) = exp(1i*theta) * Vec(:, idx);