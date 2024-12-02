function p = parity(P)

  n = size( P , 2);
  F = sort(P,2);
  F = bsxfun( @eq , F , 1:n );
  if ~all( F(:) )
    error('rows of P should be a permutation.');
  end

  p = false( size(P,1) ,1);
  switch n
    case 1

    case 2
      p( P(:,1) > P(:,2) ) = true;
      
    case 3
      p( ismember( P , [1,3,2;2,1,3;3,2,1] , 'rows' ) ) = true;

    case 4
      p( ismember( P , [1,2,4,3;1,3,2,4;1,4,3,2;2,1,3,4;2,3,4,1;2,4,1,3;3,1,4,2;3,2,1,4;3,4,2,1;4,1,2,3;4,2,3,1;4,3,1,2] , 'rows' ) ) = true;

    otherwise
%       p = 0;
%       for i = 1:(size(P,2) - 1)
%         p = p + sum( bsxfun( @lt , P(:,i) , P(:, (i+1):end ) ),2);
%       end
%       p = ~~mod(p,2);
      M = speye( n , n );
      for r = 1:size(P,1)
        p(r) = det( M( P(r,:) ,:) ) < 0;
      end
  end
end
