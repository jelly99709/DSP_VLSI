function Vec_new = RealNull(idx1, idx2, theta, Vec)
Vec_new = Vec;
Vec_new(:,idx1) = cos(theta) * Vec(:,idx1) + sin(theta) * Vec(:,idx2);
Vec_new(:,idx2) = -sin(theta) * Vec(:,idx1) + cos(theta) * Vec(:,idx2);