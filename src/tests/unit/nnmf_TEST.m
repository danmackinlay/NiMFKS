%Diagonal appears if V=W under large number of iterations without
%cost-break

function [Y, cost, Hmat, Hnorm] = nnmf_TEST(V, W, L, varargin)
%L: Iterations
%V: Matrix to be factorized
%W: Source matrix
parser = inputParser;
addRequired(parser, 'V')
addRequired(parser, 'W')
addRequired(parser, 'L')
addParameter(parser, 'repititionRestricted', false)
addParameter(parser, 'continuityEnhanced', false)
addParameter(parser, 'polyphonyRestricted', false)
addParameter(parser, 'convergenceCriteria', 0.005)
addParameter(parser, 'r', 3) %For repitition restricted activations
addParameter(parser, 'c', 2) %For continuity enhancing activation matrix
addParameter(parser, 'p', 3) %For polyphony restriction

parse(parser, V, W, L, varargin{:});
repititionRestricted = parser.Results.repititionRestricted;
polyphonyRestricted = parser.Results.polyphonyRestricted;
continuityEnhanced = parser.Results.continuityEnhanced;
r = parser.Results.r;
c = parser.Results.c;
p = parser.Results.p;

cost=0;

targetDim=size(V);
sourceDim=size(W);
K=sourceDim(2);
M=targetDim(2);

%Randomly initialized Matrix H: K x M
%Range: [0, 1)
H=random('unif',0, 1, K, M);
R=zeros(K, M);
P=zeros(K, M);
C=zeros(K, M);

fprintf('Convergence Criteria: %d%%\n', 100*parser.Results.convergenceCriteria)

for l=1:L-1
    
    num=W'*V;
    den=W'*W*H;
    H=H.*(num./den);
    H(isnan(H))=0;
    
%     H(k, m)=H(k, m)*num(k, m)/den(k, m);
%             if(isnan(H(k,m)))
%                 H(k,m)=0;
%             end
    
    for k=1:K
        %Updating H
        for m=1:M
            
            if(repititionRestricted)
                if(m>r && (m+r)<=M && H(k,m)==max(H(k,m-r:m+r)))
                    R(k,m)=H(k,m);
                else
                    R(k,m)=H(k,m)*(1-(l+1)/L);
                end
            end
            
            if(polyphonyRestricted)
                [~, sortedIndices] = sort(R(:, m),'descend');
                index = (length(sortedIndices) >= p) * p + ...
                            (length(sortedIndices) < p) * length(sortedIndices);
                        maximumIndices = sortedIndices(1:index);
                if(ismember(k, maximumIndices))
                    P(k,m)=R(k,m);
                else
                    P(k,m)=R(k,m)*(1-(l+1)/L);
                end
            end

            if(continuityEnhanced)
%                 %                 if(l>1 && k > c && m > c && k < K-c && m < M-c) %Original; still implemented in KLDivNNMF
%                 if(l>1 && k > c && m > c && k < K-c && m < M-c)
%                     surroundingMat = P(k-c:k+c, m-c:m+c);
%                     surroundingMat(surroundingMat < 10e-3) = 0;
% %                     diagonal = diag(flip(surroundingMat));
%                     diagonal = diag(surroundingMat);
%                     if(~all(diagonal))
%                         C(k, m) = sum(diagonal);
%                     else
%                         C(k, m) = P(k, m);
%                     end
%                 else
%                     C(k, m) = P(k, m);
%                 end
                C = conv2(P, eye(c), 'same');
            end
        end
    end  
    
    cost(l)=norm(V-W*H, 'fro'); %Frobenius norm of a matrix
    if(l > 5 && (abs(((cost(l)-cost(l-1)))/max(cost))<parser.Results.convergenceCriteria)) %TODO: Reconsider exit condition
        converged = true;
        break;
    end
    
    if(continuityEnhanced)
        num=W'*V;
        den=W'*W*C;
        H=C.*(num./den);
        H(isnan(H))=0;
    end
    
    %     Hmat{l} = H;
    %     Hnorm{l} = H./max(max(H));
end

Y=H;
% 
% if(repititionRestricted)
%     Y=R;
% end
% 
% if(polyphonyRestricted)
%     Y=P;
% end
% 
% if(continuityEnhanced)
%     Y=C;
% end

%Optional attribute for potential later use
iterations = l;
disp(strcat('Iterations:', num2str(iterations)))

Y = Y./max(max(Y)); %Normalize activations
end