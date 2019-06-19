function H_rotate = RowGRotate(idx1, idx2, theta, H)

H_rotate = H;
H_rotate(idx1,:) = cos(theta)*H(idx1,:) + sin(theta)*H(idx2,:);
H_rotate(idx2,:) = -sin(theta)*H(idx1,:) + cos(theta)*H(idx2,:);
