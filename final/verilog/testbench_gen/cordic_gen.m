clear all
close all

%Setting display format for fixed point
format loose
format long g
fiprefAtStarOfThisExample = get(fipref);
reset(fipref);

fileX = fopen('../dat/cordic/patternX.dat','w');
fileY = fopen('../dat/cordic/patternY.dat','w');
fileD = fopen('../dat/cordic/patternD.dat','w');

fileLength = 128;
rotationNum = 14;

bit_num = 18;
frac_num = 14;

rng(1);
dataX = sfi(rand(fileLength,1) * 4, bit_num, frac_num);
dataY = sfi(rand(fileLength,1) * 4, bit_num, frac_num);
dataD = fi(round(rand(fileLength*rotationNum,1)), 0, 1);

%dataX = rand(fileLength,1) * 4;
%dataY = rand(fileLength,1) * 4;
%dataD = round(rand(fileLength*rotationNum,1));

for i = 1:fileLength
    x = dataX(i);
    fprintf(fileX,x.bin);
    fprintf(fileX,'\n');
    y = dataY(i);
    fprintf(fileY,y.bin);
    fprintf(fileY,'\n');
end

for i = 1:fileLength*rotationNum
    d = dataD(i);
    fprintf(fileD,d.bin);
    fprintf(fileD,'\n');
end

testX = zeros(fileLength);
testY = zeros(fileLength);
ansX = zeros(fileLength);
ansY = zeros(fileLength);

K = sfi(0.60726, frac_num+1, frac_num);

Rotation = 0;
Vector = 1;
mode = Rotation;
%mode = Vector;

if mode == Rotation
    goldX = fopen('../dat/cordic/goldenX_rot.dat','w');
    goldY = fopen('../dat/cordic/goldenY_rot.dat','w');
    for i = 1:fileLength
        x = dataX(i);
        y = dataY(i);
        theta = 0;
        for j = 1:rotationNum
            d = dataD((i-1)*rotationNum+j);            
            if d == 1
                x1 = x - bitsra(y,j-1);
                y1 = y + bitsra(x,j-1);
                dX = x1.hex;
                dY = y1.hex;
                theta = theta + atan(2^(-j+1));
            else
                x1 = x + bitsra(y,j-1);
                y1 = y - bitsra(x,j-1);
                dX = x1.hex;
                dY = y1.hex;
                theta = theta - atan(2^(-j+1));
            end
            x = x1;
            y = y1;
        end
        x = sfi(K * x, bit_num, frac_num);
        y = sfi(K * y, bit_num, frac_num);
        fprintf(goldX,x.bin);
        fprintf(goldX,'\n');
        fprintf(goldY,y.bin);
        fprintf(goldY,'\n');
        %testX(i) = x;
        %testY(i) = y;
        %ansX(i) = dataX(i).*cos(theta)-dataY(i).*sin(theta);
        %ansY(i) = dataY(i).*cos(theta)+dataX(i).*sin(theta);
    end
else
    goldX = fopen('../dat/cordic/goldenX_vec.dat','w');
    goldY = fopen('../dat/cordic/goldenY_vec.dat','w');
    goldD = fopen('../dat/cordic/goldenD_vec.dat','w');
    for i = 1:fileLength
        x = dataX(i);
        y = dataY(i);
        for j = 1:rotationNum
            %d = -sign(x*y);
            d = xor(str2num(x.bin(1)), str2num(y.bin(1)));
            if d == 1
                x1 = x - bitsra(y,j-1);
                y1 = y + bitsra(x,j-1);
                d = 1;
            else
                x1 = x + bitsra(y,j-1);
                y1 = y - bitsra(x,j-1);
                d = 0;
            end
            x = x1;
            y = y1;
            fprintf(goldD,num2str(d));
            fprintf(goldD,'\n');
        end
        x = sfi(K * x, bit_num, frac_num);
        y = sfi(K * y, bit_num, frac_num);
        fprintf(goldX,x.bin);
        fprintf(goldX,'\n');
        fprintf(goldY,y.bin);
        fprintf(goldY,'\n');
        %testX(i) = x;
        %testY(i) = y;
        %ansX(i) = sqrt(dataX(i).^2 + dataY(i).^2);
    end
end

%SNR_X = 10*log10(sum(testX.^2)/sum((testX-ansX).^2));
%SNR_Y = 10*log10(sum(testY.^2)/sum((testY-ansY).^2));
%disp(SNR_X);
%disp(SNR_Y);

