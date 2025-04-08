function M = MeshReOrderNodes( M , X )
% 
%  M = MeshReOrderNodes( M )   flip the order of the nodes
%  M = MeshReOrderNodes( M , X )  put first the nodes from X
%  M = MeshReOrderNodes( M , perm )  apply the permutation to the nodes
%



  Nn = size( M.xyz , 1);

  if nargin < 2

    for f = fieldnames( M ).', f = f{1};
      if ~strncmp( f , 'xyz',3), continue; end
      M.(f) = flip( M.(f) , 1 );
    end

    M.tri = ( Nn + 1 ) - M.tri;
    
  elseif isstruct( X )
    
    M = MeshReOrderNodes( M , X.xyz );

  elseif isnumeric( X ) && isvector( X )
    
    if ~isequal( sort( X(:) ).' , ( 1:numel(X) ) )
      error('a permutation was expected');
    end

    order = X;
    for f = fieldnames( M ).', f = f{1};
      if ~strncmp( f , 'xyz',3), continue; end
      M.(f) = M.(f)( order ,:);
    end
    
    M.tri = iperm( order , M.tri );

  elseif ~isvector( X )
    

    [~,b] = ismember( M.xyz , X , 'rows' );
    b( ~b ) = Inf;
    [~,order] = sort( b );
    
    for f = fieldnames( M ).', f = f{1};
      if ~strncmp( f , 'xyz',3), continue; end
      M.(f) = M.(f)( order ,:);
    end
    
    M.tri = iperm( order , M.tri );
    
  end


end