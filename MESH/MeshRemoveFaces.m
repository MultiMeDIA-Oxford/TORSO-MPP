function M = MeshRemoveFaces( M , w )
% - if specified, tidy up the mesh

  if isa( w , 'function_handle' )
    w = feval( w , M );
  end
  
  NN = size( M.tri , 1 );
  if islogical( w )
    
    if ~isvector( w ) || numel( w ) ~= NN
      error('Incorrect logical indexing');
    end
    if ~any( w ), return; end
    w = find(w);
  
  elseif iscell( w ) && isnumeric( w{1} )
    
    w = setdiff( 1:NN , w{1} );
    
  elseif iscell( w ) && islogical( w{1} )
    
    w = setdiff( 1:NN , find( w{1} ) );
    
  elseif isnumeric( w )
  
    if isempty( w ), return; end
    if any( w < 0 ) || any( mod( w , 1 ) )
      error('Indices must either be real positive integers.');
    end

    if max( w ) > NN
      error('Indices must be smaller than the number of faces.');
    end
    
  else
    
    error('incorrect argument');
    
  end
  
  w = setdiff( 1:NN , w );
  
  Fs = fieldnames( M );
  
  for f = fieldnames( M ).', f=f{1};
    if ~strncmp( f , 'tri' , 3 ), continue; end
    sz = size( M.(f) ); sz(1) = numel(w);
    M.(f) = reshape( M.(f)( w ,:,:,:,:,:,:) , sz );
  end
  if isfield( M , 'celltype' ) && ~isscalar( M.celltype )
    M.celltype = M.celltype( w ,:);
  end
  
  %M = MeshTidy( M );
  
end
