function [U, S, V] = BiSVD(H, max_sweep, c_bit, f_bit, bit_num, frac_num)

[row_num, col_num] = size(H);
H_re = real(H);
H_im = imag(H);
U = fi(eye(row_num),1,bit_num,frac_num); % Left Singular Vector
V = fi(eye(col_num),1,bit_num,frac_num); % Right Singular Vector

H_stack = [H_re; H_im];

%% Phase I Bidiagonalization
for k = 1:1:col_num
    
    % Column Nullification via Row Operations
    % Nullify the imaginary part of the column
    % ====================================================================
    % Warning! Paper makes mistake here! The loop should start from k-1
    % when k is greater than 2. The reason is that the (k-2,k) entry has 
    % already been nullified in the loops before, which may result in
    % getting wrong value during CORDIC.
    % ====================================================================
    if(k>2)
        i1_start = k - 1;
    else
        i1_start = 1;
    end
    for i1 = i1_start:row_num
        % cos_theta, sin_theta: 10bit fraction & 1bit sign
        [cos_theta_r, sin_theta_r] = AtanCORDIC(H_stack(i1 + row_num, k) , H_stack(i1, k), c_bit, 4, c_bit);
        H_stack = RowGRotate(i1, i1+row_num, cos_theta_r, sin_theta_r, H_stack, 4, f_bit);
        U = ImagNull(i1, cos_theta_r, sin_theta_r, U, 4, f_bit);
    end
    
    % Column Nullification via Row Operations
    % Nullify elements of the column except diagonal and upper diagonal ones
    for i2 = row_num-1:-1:k
        [cos_theta_r, sin_theta_r] = AtanCORDIC(H_stack(i2+1, k), H_stack(i2, k), c_bit, 4, c_bit);
        H_stack = RowGRotate(i2, i2+1, cos_theta_r, sin_theta_r, H_stack, 4, f_bit);
        H_stack = RowGRotate(i2+row_num, i2+row_num+1, cos_theta_r, sin_theta_r, H_stack, 4, f_bit);
        U = RealNull(i2, i2+1, cos_theta_r, sin_theta_r, U, 4, f_bit);
    end
    
    H_concat = [H_stack(1:row_num, :), H_stack(row_num+1:2*row_num, :)];
    
    % Row Nullification via Column Operations
    % Nullify the imaginary part of the row
    for j1 = k+1:1:col_num
        [cos_theta_c, sin_theta_c] = AtanCORDIC(H_concat(k, j1+col_num), H_concat(k, j1), c_bit , 4, c_bit);
        H_concat = ColGRotate(j1, j1+col_num, cos_theta_c, sin_theta_c, H_concat, 4, f_bit);
        V = ImagNull(j1, cos_theta_c, -sin_theta_c, V, 4, f_bit); % Be careful of the sign signal of sine value
    end
    
    % Row Nullification via Column Operations
    % Nullify elements of the row except diagonal and upper diagonal ones
    for j2 = col_num-1:-1:k+1
        [cos_theta_c, sin_theta_c] = AtanCORDIC(H_concat(k, j2+1), H_concat(k, j2), c_bit, 4, c_bit);
        H_concat = ColGRotate(j2, j2+1, cos_theta_c, sin_theta_c, H_concat, 4, f_bit);
        H_concat = ColGRotate(j2+col_num, j2+col_num+1, cos_theta_c, sin_theta_c, H_concat, 4, f_bit);
        V = RealNull(j2, j2+1, cos_theta_c, sin_theta_c, V, 4, f_bit);
    end 
    
    H_stack = [H_concat(:, 1:col_num); H_concat(:, col_num+1:2*col_num)];
end

H_bi = H_concat(:, 1:col_num);

%% Phase II Off-Diagonalization Nullification
for k = 1:1:max_sweep
    % Nullify the upper diagonal elements
    for i = 1:1:col_num-1
        [cos_theta, sin_theta] = AtanCORDIC(H_bi(i, i+1), H_bi(i,i), c_bit, 4, c_bit);
        H_bi = ColGRotate(i, i+1, cos_theta, sin_theta, H_bi, 4, f_bit);
        V = RealNull(i, i+1, cos_theta, sin_theta, V, 4, f_bit);
    end
    % Nullify the lower diagonal elements
    for i = 1:1:row_num-1
        [cos_theta, sin_theta] = AtanCORDIC(H_bi(i+1, i), H_bi(i,i), c_bit, 4, c_bit);
        H_bi = RowGRotate(i, i+1, cos_theta, sin_theta, H_bi, 4, f_bit);
        U = RealNull(i, i+1, cos_theta, sin_theta, U, 4, f_bit);
    end
end

S = H_bi;