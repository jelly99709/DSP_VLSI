%% Settings
clear all
close all

% Setting display format for fixed point
format loose
format long g
fiprefAtStarOfThisExample = get(fipref);
reset(fipref);

%  parameter settings
rotationNum = 14;
bit_num = 18;
frac_num = 14;
d_0 = zeros(rotationNum,1);
testCode = 'a';
row_num = 4;
col_num = 4;

% pattern generation
H = rand(4, 4) + 1i .* rand(4, 4);
H = H*2 - (1+1i);
% To fixed point
H_r = sfi(real(H),bit_num,frac_num);
H_i = sfi(imag(H),bit_num,frac_num);
% gold pattern
T_r = real(H);
T_i = imag(H);

%% Bidiagonalization
H_stack = [H_r; H_i];
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
        [~, ~, theta] = cordic(H_stack(i1, k) , H_stack(i1 + row_num, k), d_0, rotationNum, 'Vector', bit_num, frac_num);
        for r = 1:col_num
            [H_stack(i1,r), H_stack(i1+row_num,r), ~] = cordic(H_stack(i1, r) , H_stack(i1 + row_num, r), theta, rotationNum, 'Rotation', bit_num, frac_num);
        end
        %U = ImagNull(i1, cos_theta_r, sin_theta_r, U, 4, f_bit);
    end
    
    % Column Nullification via Row Operations
    % Nullify elements of the column except diagonal and upper diagonal ones
    for i2 = row_num-1:-1:k
        [~, ~, theta] = cordic(H_stack(i2, k), H_stack(i2+1, k), d_0, rotationNum, 'Vector', bit_num, frac_num);
        for r = 1:col_num
            [H_stack(i2,r), H_stack(i2+1,r), ~] = cordic(H_stack(i2,r), H_stack(i2+1,r), theta, rotationNum, 'Rotation', bit_num, frac_num);
            [H_stack(i2+row_num,r), H_stack(i2+row_num+1,r), ~] = cordic(H_stack(i2+row_num,r), H_stack(i2+row_num+1,r), theta, rotationNum, 'Rotation', bit_num, frac_num);
        end
        %U = RealNull(i2, i2+1, cos_theta_r, sin_theta_r, U, 4, f_bit);
    end
    
    H_concat = [H_stack(1:row_num, :), H_stack(row_num+1:2*row_num, :)];
    
    % Row Nullification via Column Operations
    % Nullify the imaginary part of the row
    for j1 = k+1:1:col_num
        [~, ~, theta] = cordic(H_concat(k, j1) , H_concat(k, j1+col_num), d_0, rotationNum, 'Vector', bit_num, frac_num);
        for r = 1:row_num
            [H_concat(r,j1), H_concat(r,j1+col_num), ~] = cordic(H_concat(r,j1) , H_concat(r,j1+col_num), theta, rotationNum, 'Rotation', bit_num, frac_num);
        end
        %V = ImagNull(j1, cos_theta_c, -sin_theta_c, V, 4, f_bit); % Be careful of the sign signal of sine value
    end
    
    % Row Nullification via Column Operations
    % Nullify elements of the row except diagonal and upper diagonal ones
    for j2 = col_num-1:-1:k+1
        [~, ~, theta] = cordic(H_concat(k, j2) , H_concat(k, j2+1), d_0, rotationNum, 'Vector', bit_num, frac_num);
        for r = 1:row_num
            [H_concat(r,j2), H_concat(r,j2+1), ~] = cordic(H_concat(r,j2) , H_concat(r,j2+1), theta, rotationNum, 'Rotation', bit_num, frac_num);
            [H_concat(r,j2+col_num), H_concat(r,j2+col_num+1), ~] = cordic(H_concat(r,j2+col_num) , H_concat(r,j2+col_num+1), theta, rotationNum, 'Rotation', bit_num, frac_num);
        end
        %V = RealNull(j2, j2+1, cos_theta_c, sin_theta_c, V, 4, f_bit);
    end 
    
    H_stack = [H_concat(:, 1:col_num); H_concat(:, col_num+1:2*col_num)];
end

H_bi = H_concat(:, 1:col_num) + 1i .* H_concat(:, col_num+1:end);

%% Test
addpath('../../matlab_sim/double/');
[~, T_bi, ~] = BiSVD(H, 20);

snr = SNR(H_bi.double,T_bi);
fprintf('SNR = %f\n',snr);

%% Generated pattern
fileR = fopen('../dat/bidiag/patternR.dat','w');
fileI = fopen('../dat/bidiag/patternI.dat','w');
goldR = fopen('../dat/bidiag/goldenR.dat','w');
goldI = fopen('../dat/bidiag/goldenI.dat','w');

for x = 1:4
    for y = 1:4
        val = H_r(x,y);
        fprintf(fileR, val.bin);
        fprintf(fileR,'\n');
        val = H_i(x,y);
        fprintf(fileI, val.bin);
        fprintf(fileI,'\n');
        val = real(H_bi(x,y));
        fprintf(goldR, val.bin);
        fprintf(goldR,'\n');
        val = imag(H_bi(x,y));
        fprintf(goldI, val.bin);
        fprintf(goldI,'\n');
    end
end

%% Subfunction definition
function s = SNR(test, gold)
    s = 10*log10(sum(test.^2)/sum((test-gold).^2));
end