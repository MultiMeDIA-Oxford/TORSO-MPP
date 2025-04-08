function M = MeshRemoveNodes( M , w )

  if isa( w , 'function_handle' )
    try
      w = feval( w , M );
    catch
      try
        w = feval( w , M.xyz );
      catch
        error('invalid function to be evaluated on Mesh or on nodes coordinates.');
      end
    end
  end


  NN = size( M.xyz , 1 );
  
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
      error('Indices must be smaller than the number of nodes.');
    end
    
  else
    
    error('incorrect argument');
    
  end
  
  w = setdiff( 1:NN , w );
  
  M = renameStructField( M , 'uv' , 'xyz___UV___' );
  
  Fs = fieldnames( M );
  
  for f = 1:numel( Fs )
    if ~strncmp( Fs{f} , 'xyz' , 3 ), continue; end
    M.(Fs{f}) = M.(Fs{f})( w ,:,:,:,:,: );
  end
  
  map = zeros( NN , 1 );
  map( w ) = 1:numel(w);
  
  w = all( ismember( M.tri , w ) , 2 );
  for f = 1:numel( Fs )
    if ~strncmp( Fs{f} , 'tri' , 3 ), continue; end
    M.(Fs{f}) = M.(Fs{f})( w ,:,:,:,:,: );
  end
    
  try
    M.tri = feval( class( M.tri ) , reshape( map( M.tri ) ,size(M.tri) ) );
  catch
    M.tri = reshape( map( M.tri ) ,size(M.tri) );
  end  

  M = renameStructField( M , 'xyz___UV___' , 'uv' );
  
end



