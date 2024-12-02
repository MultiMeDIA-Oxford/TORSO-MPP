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
  M = MeshSubdivide( {M,2} , 'loop' );

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
