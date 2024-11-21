function M = MeshCrinkle( M , V , insideOut )
% remove the positive!

  if nargin < 3, insideOut = false; end

  if isnumeric( M )
    M = struct( 'xyz' , M , 'tri' , [ ( 1:size(M,1)-1 ).' , ( 2:size(M,1) ).'  ] ,'celltype',3 );
  end
  M.xyz(:,end+1:3) = 0;

  
  if isa( V , 'function_handle' )
    try, V = feval( V , M ); catch
    try, V = feval( V , M.xyz ); catch
      error('invalid function to evaluate on mesh');
    end; end
  elseif ischar( V )
    try, V = M.(['xyz',V]); catch
    try, V = M.(V); catch
      error('invalid attribute name.');
    end; end
  elseif isnumeric( V ) && isequal( size( V ) , [4 4] )
    V = distance2Plane( M.xyz , V , true );
  end
  if numel( V ) ~= size( M.xyz ,1)
    error('invalid scalar for crinling');
  end
  
  if isequal( insideOut , 2), insideOut = 'both'; end
  if ~ischar( insideOut ), insideOut = ~~insideOut; end
  if numel( insideOut ) && islogical( insideOut ) && insideOut
    V = V( M.tri );
    w = all( V < 0 ,2);
  elseif numel( insideOut ) && islogical( insideOut ) && ~insideOut
    V = V( M.tri );
    w = all( V > 0 ,2);
  elseif ischar( insideOut ) && ( strcmp( insideOut , 'both' ) || strcmp( insideOut , 'b' ) )
    V = V( M.tri );
    w = all( V < 0 ,2) | all( V > 0 ,2);
  else
    error( 'invalid option' );
  end
  
  M = MeshRemoveFaces( M , w );
  
end
