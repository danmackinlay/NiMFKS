function [cost] = KLDivCost(A , B)

% dim=size(A);
% cost=0;

cost = sum(sum(A.*log10(A./B)-A+B));

% for i=1:dim(1)
%     for j=1:dim(2)
%         cost = cost + A(i,j)*log10(A(i,j)/B(i,j))-A(i,j)+B(i,j);
%     end
% end