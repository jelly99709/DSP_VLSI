%% Settings
clear;clc;

%Setting display format for fixed point
format loose
format long g
fiprefAtStarOfThisExample = get(fipref);
reset(fipref);

% Settings for fixed point
bit_num = 13;
frac_num = 10;

% Settings for CORDIC and Jacobi
c_bit = 14;     % Number of bit for CORDIC
f_bit = 10;
max_sweep = 20; % Number of iteration for phase II (diagonalization)

% Creat channel data
H = rand(8, 8) + 1i * rand(8, 8); % Test data
H = H*2 - (1+1i);
H = fi(H,1,bit_num,frac_num);

%% Bidiagonal SVD
[U, S, V] = BiSVD(H, max_sweep, c_bit, f_bit, bit_num, frac_num);

%%  Check the result
% Evaluate performance of the algorithm
H = H.double;
U = U.double;
S = S.double;
V = V.double;
res = norm(H - U*diag(diag(S))*V', 'fro');                 % Dist. between matrices before and after SVD
snr_res = 20 * log10(norm(H, 'fro') / res);                % Computing SNR
res_d = norm(abs(diag(svd(H))) - abs(S), 'fro');           % Dist. between diagonal matrices of MATLAB SVD and BiSVD
snr_res_d = 20 * log10(norm(diag(svd(H)), 'fro') / res_d); % Computing SNR

% Show the result
fprintf('Residulal norm of original matrix: %f\n', res);
fprintf('SNR of channel matrix: %f dB\n', snr_res);
fprintf('\n');
fprintf('Residulal norm of diagonal matrix: %f\n', res_d);
fprintf('SNR of diagonal matrix: %f dB\n', snr_res_d);