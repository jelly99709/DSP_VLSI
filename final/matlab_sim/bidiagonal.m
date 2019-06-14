clear
clc

N = 12;
matrix = zeros(N,N);

for i = 1:100
    a = 10*(rand([1 N])-rand([1 N]))+10*j*(rand([1 N])-rand([1 N]));
    buffer = a'*a;
    matrix = matrix+buffer;
end

% for i = 1:100
%     a = 10*(rand([1 N])-rand([1 N]));
%     buffer = a'*a;
%     lamda = lamda+buffer;
% end

it = 100;
eigenvalue_convergence_buffer = zeros(1,it);
eigenvector_convergence_buffer = zeros(1,it);

[U,S,V] = svd(matrix);
[e,ind] = sort(diag(S),'descend');

% for test = 1:it
    
    lamda = matrix;
    Q = eye(N);
    P = eye(N);
    
    %% Bidiagonalization
    for time = 1:N
        %% ROW
        for i = N:-1:time
            ang = atan(imag(lamda(i,time))/real(lamda(i,time)));
            for k = time:N
                lamda(i,k) = lamda(i,k)*exp(-j*ang);
            end
            for m = 1:N
                Q(m,i) = Q(m,i)*exp(-j*ang);
            end
        end
        
        for i = (N-1):-1:time
            ang = atan(real(lamda(i+1,time))/real(lamda(i,time)));
            for k = time:N
                real_part = (real(lamda(i,k))+j*real(lamda(i+1,k)))*exp(-j*ang);
                imag_part = (imag(lamda(i,k))+j*imag(lamda(i+1,k)))*exp(-j*ang);
                lamda(i,k) = real(real_part)+j*real(imag_part);
                lamda(i+1,k) = imag(real_part)+j*imag(imag_part);
            end
            for m = 1:N
                real_part = (real(Q(m,i))+j*real(Q(m,i+1)))*exp(-j*ang);
                imag_part = (imag(Q(m,i))+j*imag(Q(m,i+1)))*exp(-j*ang);
                Q(m,i) = real(real_part)+j*real(imag_part);
                Q(m,i+1) = imag(real_part)+j*imag(imag_part);
            end
        end
        
        %%
        
        for i = N:-1:(time+1)
            ang = atan(imag(lamda(time,i))/real(lamda(time,i)));
            for k = time:N
                lamda(k,i) = lamda(k,i)*exp(-j*ang);
            end
            for m = 1:N
                P(i,m) = P(i,m)*exp(-j*ang);
            end
        end
        
        for i = (N-1):-1:(time+1)
            ang = atan(real(lamda(time,i+1))/real(lamda(time,i)));
            for k = time:N
                real_part = (real(lamda(k,i))+j*real(lamda(k,i+1)))*exp(-j*ang);
                imag_part = (imag(lamda(k,i))+j*imag(lamda(k,i+1)))*exp(-j*ang);
                lamda(k,i) = real(real_part)+j*real(imag_part);
                lamda(k,i+1) = imag(real_part)+j*imag(imag_part);
            end
            for m = 1:N
                real_part = (real(P(i,m))+j*real(P(i+1,m)))*exp(-j*ang);
                imag_part = (imag(P(i,m))+j*imag(P(i+1,m)))*exp(-j*ang);
                P(i,m) = real(real_part)+j*real(imag_part);
                P(i+1,m) = imag(real_part)+j*imag(imag_part);
            end
        end
    end
    
    lamda = real(lamda);
    
    %% Bidiagonalization to SVD
    for k = 1:100
        for i = 1:(N-1)
            for m = 1:2
                
                if m == 1
                    buffer = [lamda(i,i);lamda(i,i+1)];
                else
                    buffer = [lamda(i,i);lamda(i+1,i)];
                end
                
                %% generate J_al & J_ar
                J = eye(N);
                ang3 = atan((buffer(2,1))/(buffer(1,1)));
                p = i;
                q = i+1;
                J(p,p) = cos(ang3);
                J(p,q) = sin(ang3);
                J(q,p) = -sin(ang3);
                J(q,q) = cos(ang3);
                
                if m == 1
                    lamda = lamda*J';
                else
                    lamda = J*lamda;
                end
                
                if m == 1
                    for index1 = 1:N
                        real_combine = (real(P(i,index1))+j*real(P(i+1,index1)))*exp(-j*ang3);
                        imag_combine = (imag(P(i,index1))+j*imag(P(i+1,index1)))*exp(-j*ang3);
                        P(i,index1) = real(real_combine)+j*real(imag_combine);
                        P(i+1,index1) = imag(real_combine)+j*imag(imag_combine);;
                    end
                else
                    for index1 = 1:N
                        real_combine = (real(Q(index1,i))+j*real(Q(index1,i+1)))*exp(-j*ang3);
                        imag_combine = (imag(Q(index1,i))+j*imag(Q(index1,i+1)))*exp(-j*ang3);
                        Q(index1,i) = real(real_combine)+j*real(imag_combine);
                        Q(index1,i+1) = imag(real_combine)+j*imag(imag_combine);;
                    end
                end
                    
            end
        end
    end
    
    for index_2 = 1:N
        buffer = diag(lamda);
        if sign(buffer(index_2,:)) == 1
            Q(:,index_2) = Q(:,index_2);
        else
            Q(:,index_2) = -Q(:,index_2);
        end
    end
    
    for index_2 = 1:N       
        if sign(real(V(1,index_2)))*sign(real(Q(1,index_2))) == 1
            Q(:,index_2) = Q(:,index_2);
        else
            Q(:,index_2) = -Q(:,index_2);
        end
    end
    Q = conj(Q);
    
    lamda_column = abs(real(diag(lamda)));
    lamda_column
%     [e_com,ind_com] = sort(lamda_column,'descend'); % 61 add
%     lamda_column = lamda_column(ind_com,:);

%     eigenvalue_convergence_buffer(1,test) = norm(e-lamda_column);
%     eigenvector_convergence_buffer(1,test) = norm(Q-V);
% end

% figure(1)
% hold on
% plot(10*log10(eigenvalue_convergence_buffer/norm(e)),'LineWidth',2)
% xlabel('Sweep Number','FontWeight','bold','FontSize',16);
% ylabel('Error [dB]','FontWeight','bold','FontSize',16);
% 
% figure(2)
% hold on
% plot(10*log10(eigenvector_convergence_buffer/N),'LineWidth',2)
% xlabel('Sweep Number','FontWeight','bold','FontSize',16);
% ylabel('Error [dB]','FontWeight','bold','FontSize',16);



% for k = 1:100
%     for i = 1:(N-1)
%         buffer = [lamda(i,i) lamda(i,i+1);lamda(i+1,i) lamda(i+1,i+1)];
%         th_1_add_th2 = atan(buffer(1,2)/(buffer(1,1)-buffer(2,2)));
%         th_1_min_th2 = atan(-buffer(1,2)/(buffer(1,1)+buffer(2,2)));
%         th_1 = (th_1_add_th2+th_1_min_th2)/2;
%         th_2 = (th_1_add_th2-th_1_min_th2)/2;
%         Jl = [cos(th_1) sin(th_1);-sin(th_1) cos(th_1)];
%         Jr = [cos(th_2) -sin(th_2);sin(th_2) cos(th_2)];
%         buffer = Jl*buffer*Jr;
%         lamda(i,i) = buffer(1,1);
%         lamda(i,i+1) = buffer(1,2);
%         lamda(i+1,i) = buffer(2,1);
%         lamda(i+1,i+1) = buffer(2,2);
%     end
% end

% A = oringin_marix;
% [m,n]=size(A); 
% for i=1:n
%   s=norm(A(i:m,i));                     % transform A(i:m,i) to 
%                                         % (q_i,0,...,0)
%   if s==0, q(i)=0;
%   else 
%     if A(i,i)>0, q(i)=-s; else q(i)=s; end 
%     fak=sqrt(s*(s+abs(A(i,i)))); 
%     A(i,i)=A(i,i)-q(i); 
%     A(i:m,i)=A(i:m,i)/fak;
%     A(i:m,i+1:n)=A(i:m,i+1:n)-A(i:m,i)*(A(i:m,i)'*A(i:m,i+1:n));
%   end
%   if i<n,
%     s=norm(A(i,i+1:n));                 % tranformation A(i,i+1:n) to 
%                                         % (e_i,0...0)
%     if s==0, e(i)=0; 
%     else
%       if A(i,i+1)>0, e(i)=-s; else e(i)=s; end 
%       fak=sqrt(s*(s+abs(A(i,i+1)))); 
%       A(i,i+1)=A(i,i+1)-e(i);
%       A(i,i+1:n)=A(i,i+1:n)/fak; 
%       A(i+1:m,i+1:n)=A(i+1:m,i+1:n) - ...
%                     (A(i+1:m,i+1:n)*A(i,i+1:n)')*A(i,i+1:n);
%     end 
%   end 
% end                                     % insert 0 element in e (see
% e=[0 e];                                % notation of bidiagonal lamda)
% 
% B=diag(q)+diag(e(2:n),1)