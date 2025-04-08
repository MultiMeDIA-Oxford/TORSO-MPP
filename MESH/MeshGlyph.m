function M = MeshGlyph( M , x , varargin )

  N = size(x,1);
  nV = size( M.xyz ,1);
  
  for f = fieldnames(M)',f=f{1};
    if ~strncmp( f ,'xyz' ,3) && ~strncmp( f ,'tri' ,3) && ~( strcmp( f ,'celltype') && numel( M.celltype ) > 1 )
      continue;
    end
    sz = size( M.(f) );
    M.(f) = repmat( M.(f) , [1,1,1,1,1,1,1,1,1,N] );
    if strcmp( f , 'tri' )
      M.tri = bsxfun( @plus , M.tri , reshape( ( 0:(N-1) )*nV , [1,1,1,1,1,1,1,1,1,N] ) );
    end
    if strcmp( f , 'xyz' )
      M.xyz = bsxfun( @plus , M.xyz , reshape( x.' , [1,3,1,1,1,1,1,1,1,N] ) );

      for v = 1:numel(varargin)
        
        
      end
    end
    
    M.(f) = permute( M.(f) , [1,10,2,3,4,5,6,7,8,9] );
    sz(1) = sz(1) * N;
    M.(f) = reshape( M.(f) , sz );
  end


end
