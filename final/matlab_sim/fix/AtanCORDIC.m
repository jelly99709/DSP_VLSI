function [cos_theta, sin_theta] = AtanCORDIC(y, x, bit_num, int_num, frac_num)
% ========================================================================
% Compute the sine cosine value without getting the value of the angle
% ========================================================================

x = fi(x,1,frac_num+int_num,frac_num);
y = fi(y,1,frac_num+int_num,frac_num);

K = fi(0.60726,1,frac_num+1,frac_num); % Constant
cos_theta = fi(1,1,frac_num+2,frac_num);
sin_theta = fi(0,1,frac_num+2,frac_num);

for i = 1:bit_num
    if xor(str2num(x.bin(1)), str2num(y.bin(1))) == 0 % Just need to consider the sign of x and y (x*y > 0)
        d = -1;
    else
        d = 1;
    end
    %{
    %real number
    x_new = x - y * d * 2^(-i+1);
    y_new = y + x * d * 2^(-i+1);
    cos_theta_new = cos_theta + sin_theta * d * 2^(-i+1);
    sin_theta_new = sin_theta - cos_theta * d * 2^(-i+1);
    %}
    %fixed point
    if d == 1
        x_new = x - bitsra(y,i-1);
        y_new = y + bitsra(x,i-1);
        cos_theta_new = cos_theta + bitsra(sin_theta,i-1);
        sin_theta_new = sin_theta - bitsra(cos_theta,i-1);
    else
        x_new = x + bitsra(y,i-1);
        y_new = y - bitsra(x,i-1);
        cos_theta_new = cos_theta - bitsra(sin_theta,i-1);
        sin_theta_new = sin_theta + bitsra(cos_theta,i-1);
    end
        
    x = x_new;
    y = y_new;
    cos_theta = cos_theta_new;
    sin_theta = sin_theta_new;
end

cos_theta = fi(K * cos_theta,1,frac_num+2,frac_num);
sin_theta = fi(K * sin_theta,1,frac_num+2,frac_num);
