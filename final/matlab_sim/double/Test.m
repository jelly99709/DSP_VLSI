clear;clc;
H = randn(10, 10) + 1i * randn(10, 10);
[U, S, V] = BiSVD(H, 20);
res = norm(H - U*S*V', 'fro');
res_d = norm(abs(diag(svd(H))) - abs(S), 'fro');
fprintf('Residulal norm of original matrix: %f\n', res);
fprintf('Residulal norm of diagonal matrix: %f\n', res_d);