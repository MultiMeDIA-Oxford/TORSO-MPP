function [E,C,A] = meshCellsContact( M )

  C = ( 1:size( M.tri ,1) ).';
  switch meshCelltype( M )
    case 3
    case 5
      E = [ M.tri(:,[1,2]) ;...
            M.tri(:,[2,3]) ;...
            M.tri(:,[1,3]) ];
      C = repmat( C , 3,1);
          
  end
  
  E = sort( E ,2);
  [E,~,c] = unique( E , 'rows' );
  
  if nargout > 1
    C = accumarray( c , C , [], @(x){x(:).'} );
  end
  
  if nargout > 2
  
    A = NaN( size(E,1) ,1);

    n = cellfun('prodofsize',C);
    A( n > 2 ) = Inf;

    w = n == 2;

    PC = cell2mat( C(w) );

    N = meshNormals( M );
    A(w) = 2*asind( fro( N( PC(:,1) ,:) - N( PC(:,2) ,:) ,2)/2 );
    
  end
  
end