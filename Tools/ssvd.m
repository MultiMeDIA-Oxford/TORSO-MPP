function [U,S,V] = ssvd( X )
% special svd
%
% Orientation preserving svd  ( svd on the SO(n) )
% 
% [U,S,V] = psvd( X )
% 
% U is a proper rotation ( det(U) == 1 )
% V is a proper rotation ( det(V) == 1 )
% S can have its minimum (in absolute value) value negative
% 



  [U,S,V] = svd(X);
  
  if det(U) < 0
    U(:,end) = - U(:,end);
    S(end)   = - S(end);
  end

  if det(V) < 0
    V(:,end) = - V(:,end);
    S(end)   = - S(end);
  end

  
  if nargout < 2
    U = diag(S);
  end
  
end
