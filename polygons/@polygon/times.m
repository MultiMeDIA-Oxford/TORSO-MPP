function P = times( P , x )

  if ~isa( P , 'polygon' )
    P = times( x , P );
    return;
  end
  
  if ~isfloat( x ), error('x have to be float.'); end
  
  if ~isequal( size( x )  , [1 2] ) && ~isequal( size( x )  , [1 1] )
    error('size of x have to be 1x2 or scalar');
  end
  
  
  for i = 1:size(P.XY,1)
    P.XY{i,1} = bsxfun( @times , P.XY{i,1} , x );
  end
  
end
