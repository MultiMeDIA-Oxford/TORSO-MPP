function L = meshEsuP( T , asCell )
  if nargin < 2, asCell = false; end

  if isstruct( T )
    nV = size( T.xyz ,1);
    T = T.tri;
  else
    nV = double( max( T(:) ) );
  end
  
  nT = size( T ,1);
  Tids = ( 1:nT ).';
  Tids = repmat( Tids ,[ size( T ,2) , 1 ]);
  
  if asCell
    L = accumarray( T(:) , Tids  , [ nV , 1 ] , @(x) {x} );
  else
    L = sparse( Tids , double(T(:)) , true , nT , nV );
  end

end
