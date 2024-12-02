function M = initialHeartMesh( C )

  for r = 1:size(C,1)
    tC = [];
    for c = 1:size(C,2)
      tC = join( tC , polyline( C{r,c} ) );
    end
    C{r,1} = double( tC );
  end
  C(:,2:end) = [];

  baseID = find( ~cellfun('isempty',C) ,1,'last' );
  [rZ,nZ] = getPlane( C{ baseID } ,'+z');

  C = transform( C , nZ );
  
  %apexID = find( ~cellfun('isempty',C(4:end)) ,1,'first' ) + 3;
  apex = cell2mat( C );
  apex = apex( argmin( apex(:,3) ) ,:);
  
  M = ruledSurfaceMesh( C , [] , apex , -40 );
  if CheckSelfIntersections( M )
%     bb = meshBB( M );
%     bb = bsxfun( @plus , bsxfun( @minus , bb , mean(bb,1) ) * 1.1 , mean(bb,1) );
%     x = linspace( bb(1,1) , bb(2,1) , 45 );
%     y = linspace( bb(1,2) , bb(2,2) , 45 );
%     z = linspace( bb(1,3) , bb(2,3) , 45 );
%              
%     G = meshIsInterior( M , ndmat(x,y,z) );
%     G = reshape( double(G) , [ numel(x) , numel(y) , numel(z) ] );
%     G = imfilter( G , gaussianKernel(-10:10,-10:10,-10:10,'s',1) ,'same' );
%     
%     G = I3D( G , 'x',x,'y',y,'z',z);
%     G = Mesh( isosurface( G , 0.5 ) );
%     G = MeshClip( G , getPlane([0,0,35;0,0,1]) );
%     G = MeshSmooth( G , [10 10 10 10 10] );
% 
%     M = G;
% %     plotMESH( G ); hplot3d( C , 'r3' )

    
    B = MeshTidy( MeshBoundary( M ) );
    G = Mesh( M , 'convexhull');
    [~,~,nP,rP] = miniballNormalize( G.xyz );
    
    G = transform( G , nP );
    M = transform( M , nP );
    
    G = MeshFixCellOrientation( jigsaw_remesh( G , 0.1 ) );
    G = MeshPull( G , M.xyz , 250 ,[], 2 );
    
    G = transform( G , rP );
    
    
    M = MeshClip( G , maketransform('tz',-3,getPlane(B,'+z')) );
    M = meshSeparate( M , 'minz' );
    M = Mesh( M , 0);
    
  else
    M = MeshSubdivide( {M,2} , 'loop' );
%     M = MeshSubdivide( M , 'loop' );
%     M = MeshSubdivide( M , 'loop' );
  end

  [~,~,nP,rP] = miniballNormalize( C );
  
  C = transform( C , nP );
  M = transform( M , nP );


  C = [ C ; mesh2contours( MeshBoundary( M ) ) ];
  for r = 1:size( C )
    try, C{r} = double(resample( polyline( C{r} ) , '+e' , 0.01 ) ); end
  end
  
  %attractors = FarthestPointSampling( cell2mat( C ) , 1 , 0.05 );
  R = MeshKneading( M , cell2mat( C ) , 100 , 0.25 , geospace(1e-3,1e-0,100) ,true,'SAMPLING',{0.05,false});

  EL = 0.1;
  while 1
    M = jigsaw_remesh( R , EL ); EL = EL * 0.95;
    M = MeshFixCellOrientation( M );
    M = MeshTidy( M ,0,'REMoveall');
    M = MeshTidy( meshSeparate( MeshSplit( M ,'nonmanifold' ) ,'largest' ) ,0,true );
    if EL > 1.075
      try
        M = MeshSubdivide( M , 'butterfly' );
      catch
        continue;
      end
    end
    break;
  end

  M = transform( M , rP , rZ );

end
