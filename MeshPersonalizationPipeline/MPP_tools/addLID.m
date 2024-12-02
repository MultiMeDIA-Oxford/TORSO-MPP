function [L,M] = addLID( M )

  M = MeshGenerateIDs( M );

  L = MeshTidy( MeshBoundary( M ) ,-1);
  [Z,iZ] = getPlane( L.xyz ,'+z');
  L = transform( L , iZ ); L.xyz = L.xyz * eye(3,2);

  D = delaunayTriangulation( L.xyz , L.tri );
  D = L.xyzID( D.ConnectivityList( isInterior( D ) ,:) );
  L = MeshTidy( MeshGenerateIDs( struct('xyz',M.xyz,'tri',D) ) ,-1);

  % x = bluerandOnMesh( B , 200000 );
  % x = FarthestPointSampling( [ B.xyz ; x ] , unique( B.tri ) , median( meshEdges( M , M ) ) , Inf , true );

  % x = bluerandOnMesh( B , -median( meshEdges( M , M ) ) );
  % x = [ B.xyz ; x ];

  % x = randOnMesh( B , 3*round( sum( meshQuality( B , 'area' ) )/(pi* median( meshEdges( M , M ) )^2) ) );
  % x = [ B.xyz ; x ];

  x = bluerandOnMesh( L , round( pi * sum( meshQuality( L , 'area' ) )/( pi* median( meshEdges( M , M ) )^2) ) );
  x = [ L.xyz ; x ];

  x = transform( x , iZ );

  D = delaunayTriangulation( x(:,1:2) , MeshBoundary( L.tri ) );
  D = D.ConnectivityList( isInterior( D ) ,:);
  L.xyzID( end+1:size(x,1) ) = 0;

  L = struct('xyz',transform(x,Z),'tri',D,'xyzID',L.xyzID);
  L.xyz( ~~L.xyzID ,:) = M.xyz( L.xyzID( ~~L.xyzID ,:) ,:);
  L = MakeMesh( L );
  L = MeshRelax( L );

  if nargout > 1
    M = MakeMesh( M );
    L = MakeMesh( L );
    M = MeshAppend( M , L );
    M = MeshTidy( M , 0 );
  end

end