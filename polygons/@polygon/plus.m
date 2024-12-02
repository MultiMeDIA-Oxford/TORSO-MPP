function P = plus( P , x )

  if ~isa( P , 'polygon' )
    P = plus( x , P );
    return;
  end
  
  if ~isfloat( x ), error('x have to be float.'); end
  
  if ~isequal( size( x )  , [1 2] ) && ~isequal( size( x )  , size(cell2mat(P.XY(:,1))) )
    error('size of x have to be 1x2 or Nx2');
  end
  
  if isequal( size( x )  , [1 2] )
  
  for i = 1:size(P.XY,1)
    P.XY{i,1} = bsxfun( @plus , P.XY{i,1} , x );
  end
  
  else
    ini=0;  
    for i = 1:size(P.XY,1)
    P.XY{i,1} = P.XY{i,1} + x(ini+1:ini+size(P.XY{i,1},1),:);
    ini=ini+size(P.XY{i,1},1);
    end  
  end;
  
end
