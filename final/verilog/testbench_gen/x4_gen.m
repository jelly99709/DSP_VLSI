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

% pattern generation
H = rand(4, 4) + 1i .* rand(4, 4);
H = H*2 - (1+1i);
% To fixed point
H_r = sfi(real(H),bit_num,frac_num);
H_i = sfi(imag(H),bit_num,frac_num);
% gold pattern
T_r = real(H);
T_i = imag(H);

%% Input pattern export
fileR = fopen(strcat('../dat/4x4/patternR_', testCode, '.dat'),'w');
fileI = fopen(strcat('../dat/4x4/patternI_', testCode, '.dat'),'w');
for i = 1:4
    for j = 1:4
        R = H_r(i,j);
        I = H_i(i,j);
        fprintf(fileR, R.bin);
        fprintf(fileR, '\n');
        fprintf(fileI, I.bin);
        fprintf(fileI, '\n');
    end
end
fclose(fileR);
fclose(fileI);

%% Bidiagonalization

% Phase 1
[H_r(1,1), H_i(1,1), d_pe1_c1] = cordic(H_r(1,1), H_i(1,1), d_0,      rotationNum, 'Vector',   bit_num, frac_num); % PE1_C1
[H_r(2,1), H_i(2,1), d_pe1_c2] = cordic(H_r(2,1), H_i(2,1), d_0,      rotationNum, 'Vector',   bit_num, frac_num); % PE1_C2
[H_r(1,2), H_i(1,2), ~]        = cordic(H_r(1,2), H_i(1,2), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_r(2,2), H_i(2,2), ~]        = cordic(H_r(2,2), H_i(2,2), d_pe1_c2, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(1,1), T_i(1,1), theta1] = vector(T_r(1,1), T_i(1,1)); % PE1_C1
[T_r(2,1), T_i(2,1), theta2] = vector(T_r(2,1), T_i(2,1)); % PE1_C2
[T_r(1,2), T_i(1,2)]         = rotate(T_r(1,2), T_i(1,2), theta1); % PE2_C1
[T_r(2,2), T_i(2,2)]         = rotate(T_r(2,2), T_i(2,2), theta2); % PE2_C2

% Phase 2
[H_r(1,3), H_i(1,3), ~] = cordic(H_r(1,3), H_i(1,3), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C1
[H_r(1,4), H_i(1,4), ~] = cordic(H_r(1,4), H_i(1,4), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C2
[H_r(2,3), H_i(2,3), ~] = cordic(H_r(2,3), H_i(2,3), d_pe1_c2, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_r(2,4), H_i(2,4), ~] = cordic(H_r(2,4), H_i(2,4), d_pe1_c2, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(1,3), T_i(1,3)] = rotate(T_r(1,3), T_i(1,3), theta1); % PE1_C1
[T_r(1,4), T_i(1,4)] = rotate(T_r(1,4), T_i(1,4), theta1); % PE1_C2
[T_r(2,3), T_i(2,3)] = rotate(T_r(2,3), T_i(2,3), theta2); % PE2_C1
[T_r(2,4), T_i(2,4)] = rotate(T_r(2,4), T_i(2,4), theta2); % PE2_C2

% Phase 3
[H_r(3,1), H_i(3,1), d_pe1_c1] = cordic(H_r(3,1), H_i(3,1), d_0,      rotationNum, 'Vector',   bit_num, frac_num); % PE1_C1
[H_r(4,1), H_i(4,1), d_pe1_c2] = cordic(H_r(4,1), H_i(4,1), d_0,      rotationNum, 'Vector',   bit_num, frac_num); % PE1_C2
[H_r(3,2), H_i(3,2), ~]        = cordic(H_r(3,2), H_i(3,2), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_r(4,2), H_i(4,2), ~]        = cordic(H_r(4,2), H_i(4,2), d_pe1_c2, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(3,1), T_i(3,1), theta1] = vector(T_r(3,1), T_i(3,1)); % PE1_C1
[T_r(4,1), T_i(4,1), theta2] = vector(T_r(4,1), T_i(4,1)); % PE1_C2
[T_r(3,2), T_i(3,2)]         = rotate(T_r(3,2), T_i(3,2), theta1); % PE2_C1
[T_r(4,2), T_i(4,2)]         = rotate(T_r(4,2), T_i(4,2), theta2); % PE2_C2

% Phase 4
[H_r(3,3), H_i(3,3), ~] = cordic(H_r(3,3), H_i(3,3), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C1
[H_r(3,4), H_i(3,4), ~] = cordic(H_r(3,4), H_i(3,4), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C2
[H_r(4,3), H_i(4,3), ~] = cordic(H_r(4,3), H_i(4,3), d_pe1_c2, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_r(4,4), H_i(4,4), ~] = cordic(H_r(4,4), H_i(4,4), d_pe1_c2, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(3,3), T_i(3,3)] = rotate(T_r(3,3), T_i(3,3), theta1); % PE1_C1
[T_r(3,4), T_i(3,4)] = rotate(T_r(3,4), T_i(3,4), theta1); % PE1_C2
[T_r(4,3), T_i(4,3)] = rotate(T_r(4,3), T_i(4,3), theta2); % PE2_C1
[T_r(4,4), T_i(4,4)] = rotate(T_r(4,4), T_i(4,4), theta2); % PE2_C2

% Phase 5
[H_r(1,1), H_r(2,1), d_pe1_c1] = cordic(H_r(1,1), H_r(2,1), d_0,      rotationNum, 'Vector',   bit_num, frac_num); % PE1_C1
[H_i(1,1), H_i(2,1), ~]        = cordic(H_i(1,1), H_i(2,1), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C2
[H_r(1,2), H_r(2,2), ~]        = cordic(H_r(1,2), H_r(2,2), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_i(1,2), H_i(2,2), ~]        = cordic(H_i(1,2), H_i(2,2), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(1,1), T_r(2,1), theta1] = vector(T_r(1,1), T_r(2,1)); % PE1_C1
[T_i(1,1), T_i(2,1)]         = rotate(T_i(1,1), T_i(2,1), theta1); % PE1_C2
[T_r(1,2), T_r(2,2)]         = rotate(T_r(1,2), T_r(2,2), theta1); % PE2_C1
[T_i(1,2), T_i(2,2)]         = rotate(T_i(1,2), T_i(2,2), theta1); % PE2_C2

% Phase 6
[H_r(1,3), H_r(2,3), ~] = cordic(H_r(1,3), H_r(2,3), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C1
[H_i(1,3), H_i(2,3), ~] = cordic(H_i(1,3), H_i(2,3), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C2
[H_r(1,4), H_r(2,4), ~] = cordic(H_r(1,4), H_r(2,4), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_i(1,4), H_i(2,4), ~] = cordic(H_i(1,4), H_i(2,4), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(1,3), T_r(2,3)] = rotate(T_r(1,3), T_r(2,3), theta1); % PE1_C1
[T_i(1,3), T_i(2,3)] = rotate(T_i(1,3), T_i(2,3), theta1); % PE1_C2
[T_r(1,4), T_r(2,4)] = rotate(T_r(1,4), T_r(2,4), theta1); % PE2_C1
[T_i(1,4), T_i(2,4)] = rotate(T_i(1,4), T_i(2,4), theta1); % PE2_C2

% Phase 7
[H_r(4,1), H_r(3,1), d_pe1_c1] = cordic(H_r(4,1), H_r(3,1), d_0,      rotationNum, 'Vector',   bit_num, frac_num); % PE1_C1
[H_i(4,1), H_i(3,1), ~]        = cordic(H_i(4,1), H_i(3,1), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C2
[H_r(4,2), H_r(3,2), ~]        = cordic(H_r(4,2), H_r(3,2), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_i(4,2), H_i(3,2), ~]        = cordic(H_i(4,2), H_i(3,2), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(4,1), T_r(3,1), theta1] = vector(T_r(4,1), T_r(3,1)); % PE1_C1
[T_i(4,1), T_i(3,1)]         = rotate(T_i(4,1), T_i(3,1), theta1); % PE1_C2
[T_r(4,2), T_r(3,2)]         = rotate(T_r(4,2), T_r(3,2), theta1); % PE2_C1
[T_i(4,2), T_i(3,2)]         = rotate(T_i(4,2), T_i(3,2), theta1); % PE2_C2

% Phase 8
[H_r(4,3), H_r(3,3), ~] = cordic(H_r(4,3), H_r(3,3), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C1
[H_i(4,3), H_i(3,3), ~] = cordic(H_i(4,3), H_i(3,3), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE1_C2
[H_r(4,4), H_r(3,4), ~] = cordic(H_r(4,4), H_r(3,4), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C1
[H_i(4,4), H_i(3,4), ~] = cordic(H_i(4,4), H_i(3,4), d_pe1_c1, rotationNum, 'Rotation', bit_num, frac_num); % PE2_C2
[T_r(4,3), T_r(3,3)] = rotate(T_r(4,3), T_r(3,3), theta1); % PE1_C1
[T_i(4,3), T_i(3,3)] = rotate(T_i(4,3), T_i(3,3), theta1); % PE1_C2
[T_r(4,4), T_r(3,4)] = rotate(T_r(4,4), T_r(3,4), theta1); % PE2_C1
[T_i(4,4), T_i(3,4)] = rotate(T_i(4,4), T_i(3,4), theta1); % PE2_C2

%% Check
H_out = H_r.double + 1i.*H_i.double;
T_out = T_r + 1i.*T_i;
snr = SNR(H_out, T_out);
fprintf('SNR = %f\n', snr);

%% Golden pattern export
goldR = fopen(strcat('../dat/4x4/goldenR_', testCode, '.dat'),'w');
goldI = fopen(strcat('../dat/4x4/goldenI_', testCode, '.dat'),'w');
for i = 1:4
    for j = 1:4
        R = H_r(i,j);
        I = H_i(i,j);
        fprintf(goldR, R.bin);
        fprintf(goldR, '\n');
        fprintf(goldI, I.bin);
        fprintf(goldI, '\n');
    end
end
fclose(goldR);
fclose(goldI);

%% Subfunction definition
function [x_out, y_out, angle] = vector(x,y)
    x_out = sqrt(x^2+y^2) * sign(x);
    y_out = 0;
    angle = -atan(y/x);
end

function [x_out, y_out] = rotate(x,y,theta)
    A = [cos(theta), -sin(theta); sin(theta), cos(theta)]*[x; y];
    x_out = A(1,1);
    y_out = A(2,1);
end

function s = SNR(test, gold)
    s = 10*log10(sum(test.^2)/sum((test-gold).^2));
end

function angle = d2angle(d)
    angle = 0;
    d(d==0) = -1;
    for i = 1:size(d)
        angle = angle + d(i)*atan(2^(-i+1));
    end
end