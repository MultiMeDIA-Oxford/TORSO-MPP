function R = meshRings( M )
  
  if isstruct( M )
    nP = size( M.xyz ,1);
    M = M.tri;
  else
    nP = max( M(:) );
  end
  
  if size( M ,2) ~= 3
    error('only triangles are allowed');
  end
  
%   M = uint32( M );
  
  nT = size( M ,1);
  Tids = ( 1:nT ).';
  
  T = accumarray( M(:) , repmat( Tids ,[ size( M ,2) , 1 ])  , [ nP , 1 ] , @(x){M(x,:)} );
  
  B = false( nP , 1);
  B( MeshBoundary(M) ) = true;
  
  R = cell( nP , 1 );
  
  id = 1:20;
  id = reshape( id , 2 , numel(id)/2 );
  id = id([2 1],:);
  
  RR = NaN( 1 , 1000 );
  for r = 1:numel(R)
    TT = T{r}; if isempty( TT ), continue; end
    TT( TT == r ) = 0;
    
    TT = sort( TT , 2 );
    TT = TT(:,2:3);
    TT = TT.';

    N = 0;
    while ~isempty( TT )
      l = TT( find( B(TT) ,1) );
      if isempty( l ), l = TT(1); end
      N = N+1; RR(N) = l;
      while 1
        e = find( TT == l ,1);
        if isempty( e ), break; end
        try,    i = id(e);
        catch,  i = e - realpow( -1 , e );
        end
        l = TT( i );
        N = N+1; RR(N) = l;
        
        TT( [ e , i ] ) = 0;
      end
      
      if any( TT(:) ), N = N+1; RR(N) = NaN;
      else, break;
      end
      TT( : , ~TT(1,:) ) = [];
    end
    R{r} = RR(1:N).';
  end
  
end
