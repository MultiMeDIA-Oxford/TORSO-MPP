function L = meshLaplaceBeltrami( M )

% Contribution
%  Author : Mei-Heng Yueh   Created: 2016/09/06
% 


  W   = zeros( size( M.tri ,1) ,3);

  M.xyz(:,end+1:3) = 0;

  % Compute the cotangent weight
  Vki = M.xyz( M.tri(:,1) ,:) - M.xyz( M.tri(:,3) ,:);
  Vkj = M.xyz( M.tri(:,2) ,:) - M.xyz( M.tri(:,3) ,:);
  Vij = M.xyz( M.tri(:,2) ,:) - M.xyz( M.tri(:,1) ,:);

  % Compute W = [Wij, Wjk, Wki] = [ cot(theta_k), cot(theta_i), cot(theta_j)]
  W(:,1) =   dot( Vki , Vkj , 2) ./ fro( cross2(Vki, Vkj) ,2);
  W(:,2) = - dot( Vij , Vki , 2) ./ fro( cross2(Vij, Vki) ,2);
  W(:,3) =   dot( Vkj , Vij , 2) ./ fro( cross2(Vkj, Vij) ,2);
  W = W/2;

  % K is the weighted adjacency matrix
  K = sparse( double( M.tri ) , double( M.tri(:,[2, 3, 1]) ) , W , size( M.xyz ,1) , size( M.xyz ,1) );
  K = K + K.';

  % L is the discrete Laplaci-Beltrami operator
  L = diag( sum(K, 2) ) - K;

end
