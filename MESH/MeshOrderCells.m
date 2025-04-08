function M = MeshOrderCells( M , V )

  if isstruct( M )
    T = M.tri;
  else
    T = M;
  end

  if nargin < 2
    V = ( 1:max( T(:) ) ).';
  end
  
  [~,ord] = sort( reshape( V( T ) ,size(T) ) ,2);
  w = parity( ord ); ord(w,[end-1,end]) = ord(w,[end,end-1]);
  T(:) = T( sub2indv( size(T) , [ repmat( ( 1:size(T,1) ).' , [size(T,2),1] ) , ord(:) ] ) );
  
  
  if isstruct( M )
    M.tri = T;
  else
    M = T;
  end

  

end
