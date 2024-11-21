function M0 = MeshDilate( M0 , o , Nits )
  
  if nargin < 3, Nits = 20; end

  M = MeshFixCellOrientation( Mesh(M0,0) );
  if o < 0, M.tri = M.tri( : , [ 1:end-2 , end , end-1 ] ); end
  
  MM = M;

  C = M.xyz; Xp = C;
  N = meshNormals( M ,'area');
  
  Os = linspace(0,o,Nits+1);

  FP = meshGeodesicFarthestPointSampling( M , 200 , false );
  for o = Os(2:end)
    %o
    X = C + N * o;
    [~,~,d] = vtkClosestElement( MM , X );

    w = d < o*0.999 | d > o/0.999;
    w = d < o*0.9;

    X( w ,:) = Xp( w ,:); Xp = X;
    X = FarthestPointSampling( X , FP , 0 , numel(FP)*2 );
    
    if 0
      [~,Y] = vtkClosestElement( M , X );
      M.xyz = InterpolatingSplines( Y , X , M.xyz , 'r' );
    else
      M = MeshPull( M , X , 50 , [] , Inf , true );
    end
    
  end

  M0.xyz = M.xyz;
   
  return;
  %%
  
  
  
  
  
  
  Cf = meshFacesCenter( M );
  Nf = meshNormals( M );
  Xf = Cf + Nf * o;
  [~,~,Df] = vtkClosestElement( Xf );
  wf = Df < o*0.99 | Df > o/0.99;
  %plotMESH( M ); hplot3d( Cf(wf,:) , Xf(wf,:) , '.-r2' );

  for i = find( wf(:).' )
    C = Cf(i,:); N = Nf(i,:);
    tt = linspace( 1e-6 , 10*o , 5001 );
    [~,~,dd] = vtkClosestElement( bsxfun( @plus , C , tt(:)*N ) );
    
    w = find( diff( dd ) < 0 ,1) + 1; tt(w:end) = []; dd(w:end) = [];
    w = dd >= o;                      tt( w )   = []; dd( w )   = [];
    if dd(end) > o
      t = tt( find( dd > o ,1)-1 );
    else
      t = tt( end )*0.99;
    end
    Xf( i ,:) = C + N * t;
  end


  

  vtkClosestElement([],[]);
  
  
  
  
  x=0;for it=1:200,x=x+(1-x)*0.025;end,x
  M = MeshKneading( M , [ Xf ; Xv ] , 500 , 0.01 ,'plot','sampling',{-500,1} );
  M0.xyz = M.xyz;
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Cv = M.xyz;
  Nv = meshNormals( M ,'area' );
  Xv = Cv + Nv * o;
  [~,~,Dv] = vtkClosestElement( Xv );
  wv = Dv < o*0.99 | Dv > o/0.99;
  %plotMESH( M ); hplot3d( Cv(wv,:) , Xv(wv,:) , '.-r2' );
  
  
  C = [ double( M.xyz )           ;  ];
  N = [ meshNormals( M , 'area' ) ;                ];
  
  
  

  N = vtkPolyDataNormals( M , 'SetFeatureAngle',180,'SetSplitting',false,'SetConsistency',true,'SetAutoOrientNormals',true,'SetComputePointNormals',true,'SetComputeCellNormals',false,'SetNonManifoldTraversal',true);
  N.xyzNormals = bsxfun( @rdivide , N.xyzNormals , sqrt( sum( N.xyzNormals.^2 , 2 ) ) );
  M.xyz = M.xyz + N.xyzNormals*o ;
  
end
