function b = meshBoundaryNodes( M )

  M.xyzID = ( 1:size( M.xyz ,1) ).';
  
  B = MeshBoundary( M );
  
  b = false( size(M.xyz,1) ,1);
  b( B.xyzID( B.tri(:) ) ) = true;

end
