function [x_out, y_out, d_out] = cordic(x_in, y_in, d_in, rotationNum, mode, bit_num, frac_num)

    K = sfi(0.60726, frac_num+1, frac_num);
    d_out = zeros(rotationNum,1);
    
    if strcmp(mode,'Rotation')
        if size(d_in) ~= rotationNum
            fprintf('Size of d_in (%d) does not match rotationNum %d.\n',size(d_in),rotationNum);
            return;
        end
        x = x_in;
        y = y_in;
        for j = 1:rotationNum
            d = d_in(j);            
            if d == 1
                x1 = x - bitsra(y,j-1);
                y1 = y + bitsra(x,j-1);
            else
                x1 = x + bitsra(y,j-1);
                y1 = y - bitsra(x,j-1);
            end
            x = x1;
            y = y1;
        end
        x = sfi(K * x, bit_num, frac_num);
        y = sfi(K * y, bit_num, frac_num);
    elseif strcmp(mode,'Vector')
        x = x_in;
        y = y_in;
        for j = 1:rotationNum
            d = xor(str2num(x.bin(1)), str2num(y.bin(1)));
            if d == 1
                x1 = x - bitsra(y,j-1);
                y1 = y + bitsra(x,j-1);
            else
                x1 = x + bitsra(y,j-1);
                y1 = y - bitsra(x,j-1);
            end
            x = x1;
            y = y1;
            d_out(j) = d;
        end
        x = sfi(K * x, bit_num, frac_num);
        y = sfi(K * y, bit_num, frac_num);
    else
        fprintf('Unknown mode "%s".\n',mode);
        return;
    end
    
    x_out = x;
    y_out = y;
end