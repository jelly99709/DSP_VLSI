function [U, S, V] = BiSVD(H, max_sweep)

[row_num, col_num] = size(H);
H_re = real(H);
H_im = imag(H);
U = eye(row_num);
V = eye(col_num);

H_stack = [H_re; H_im];

for k = 1:1:col_num
    if(k>2)
        i1_start = k - 1;
    else
        i1_start = 1;
    end
    for i1 = i1_start:row_num
        theta_r = atan(H_stack(i1 + row_num, k) / H_stack(i1, k));
        H_stack = RowGRotate(i1, i1+row_num, theta_r, H_stack);
        U = ImagNull(i1, theta_r, U);
    end
    for i2 = row_num-1:-1:k
        theta_r = atan(H_stack(i2+1, k) / H_stack(i2, k));
        H_stack = RowGRotate(i2, i2+1, theta_r, H_stack);
        H_stack = RowGRotate(i2+row_num, i2+row_num+1, theta_r, H_stack);
        U = RealNull(i2, i2+1, theta_r, U);
    end
    
    H_concat = [H_stack(1:row_num, :), H_stack(row_num+1:2*row_num, :)];
    
    for j1 = k+1:1:col_num
        theta_c = atan(H_concat(k, j1+col_num) / H_concat(k, j1));
        H_concat = ColGRotate(j1, j1+col_num, theta_c, H_concat);
        V = ImagNull(j1, -theta_c, V);
    end
    for j2 = col_num-1:-1:k+1
        theta_c = atan(H_concat(k, j2+1) / H_concat(k, j2));
        H_concat = ColGRotate(j2, j2+1, theta_c, H_concat);
        H_concat = ColGRotate(j2+col_num, j2+col_num+1, theta_c, H_concat);
        V = RealNull(j2, j2+1, theta_c, V);
    end 
    
    H_stack = [H_concat(:, 1:col_num); H_concat(:, col_num+1:2*col_num)];
end

H_bi = H_concat(:, 1:col_num);
%{
for k = 1:1:max_sweep
    for i = 1:1:col_num-1
        theta = atan(H_bi(i, i+1) / H_bi(i,i));
        H_bi = ColGRotate(i, i+1, theta, H_bi);
        V = RealNull(i, i+1, theta, V);
    end
    for i = 1:1:row_num-1
        theta = atan(H_bi(i+1, i) / H_bi(i,i));
        H_bi = RowGRotate(i, i+1, theta, H_bi);
        U = RealNull(i, i+1, theta, U);
    end
end
%}
S = H_bi;