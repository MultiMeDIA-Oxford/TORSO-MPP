function P = mtimes( P , x )

  if ~isa( P , 'polygon' )
    P = mtimes( x , P );
    return;
  end
  
  if ~isfloat( x ), error('x have to be float.'); end
  
  if ~isequal( size( x )  , [1 1] )
    error('x have to be scalar');
  end
  
  
  for i = 1:size(P.XY,1)
    P.XY{i,1} = bsxfun( @times , P.XY{i,1} , x );
  end
  
end
