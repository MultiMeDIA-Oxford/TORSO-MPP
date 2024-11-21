function M = MeshAddField( M , Fname , val )

  if ischar( val )
    if size( val ,1) > 1, error('a string was expected'); end
    val = { val };
  end

  
  nF = 0; try, nF = size( M.tri ,1); end
  nV = 0; try, nV = size( M.xyz ,1); end
  n  = size( val , 1 );
  
  parent = '';
  if     strncmp( Fname , 'xyz' , 3 )
    parent = 'xyz'; Fname = Fname(4:end);
  elseif strncmp( Fname , 'tri' , 3 )
    parent = 'tri'; Fname = Fname(4:end);
  elseif n == nF  &&  n ~= nV
    parent = 'tri';
  elseif n ~= nF  &&  n == nV
    parent = 'xyz';
  elseif n == nF  &&  n == nV
    error('cannot determine if it is a field for VERTICES or for FACES.');
  elseif n ~= nF  &&  n ~= nV
    error('It cannot be a field for VERTICES or for FACES.');
  end
  
  if strcmp( parent , 'xyz' )
    if n == 1
      val = repmat( val , [ nV , 1 ] );
    end
    if size( val ,1) ~= nV
      error('It cannot be a field for VERTICES.');
    end
  end
  if strcmp( parent , 'tri' )
    if n == 1
      val = repmat( val , [ nF , 1 ] );
    end
    if size( val ,1) ~= nF
      error('It cannot be a field for FACES.');
    end
  end
    
  M.([ parent , Fname ]) = val;

end
