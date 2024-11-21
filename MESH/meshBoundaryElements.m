function b = meshBoundaryElements( M )

  M.xyzID = ( 1:size( M.xyz ,1) ).';
  
  B = MeshBoundary( M );
  
  b = any( ismember( M.tri , B.tri ) , 2);

end
