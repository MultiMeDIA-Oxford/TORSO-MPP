function P = minus( P , x )

  if ~isa( P , 'polygon' )
    error('only allowed  minus( polygon , float )');
  end
  
  if ~isfloat( x ), error('x have to be float.'); end
  
  if ~isequal( size( x )  , [1 2] )
    error('size of x have to be 1x2');
  end
  
  
  for i = 1:size(P.XY,1)
    P.XY{i,1} = bsxfun( @minus , P.XY{i,1} , x );
  end
  
end
