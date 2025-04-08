function L = meshPsuP( T , asCell )
  if nargin < 2, asCell = false; end
  
  if isstruct( T )
    nV = size( T.xyz ,1);
    T = T.tri;
  else
    nV = max( T(:) );
  end

  E = meshEdges( T );
  %E = unique( E , 'rows' );

  if asCell
    E = [ E ; E(:,[2 1]) ];
    L = accumarray( E(:,1) , E(:,2) , [ nV , 1 ] , @(x) {x} );
  else
    L = sparse( double(E(:,1)) , double(E(:,2)) , true , nV , nV );
    L = L | L.';
  end
  
end
