function M = HEARTremesh( H , iZ , EPI , LV , RV , EDGE_LENGTH , varargin )

if 0

  H   = loadv('H:\DTI003\mpp\HM.mat','HM');
  iZ  = loadv('H:\DTI003\mpp\HM.mat','iZ');
  EPI = loadv('H:\DTI003\mpp\HM.mat','EPIms');
  LV  = loadv('H:\DTI003\mpp\HM.mat','LVms');
  RV  = loadv('H:\DTI003\mpp\HM.mat','RVms');

  EDGE_LENGTH  = 0.4;

  tic
  M = HEARTremesh( H , iZ , EPI , LV , RV , EDGE_LENGTH , 'SMOOTH' , 1 , 'PLANARIZE' , 'COLLAPSE' , 'fixANGLES' );
  toc
%%
end

  SMOOTH = 0.5;
  try, [varargin,~,SMOOTH] = parseargs(varargin,'SMOOTH','$DEFS$',SMOOTH ); end

  PLANARIZE   = false;
  try, [varargin,PLANARIZE] = parseargs(varargin,'PLANARIZE','$FORCE$',{true,PLANARIZE} ); end

  COLLAPSE    = false;
  try, [varargin,COLLAPSE] = parseargs(varargin,'COLLAPSE','$FORCE$',{true,COLLAPSE} ); end

  fixANGLES   = false;
  try, [varargin,fixANGLES] = parseargs(varargin,'fixANGLES','$FORCE$',{true,fixANGLES} ); end

  %%

  vprintf = @(varargin)printf(varargin{:});
  
  Z = minv( iZ );
  H   = transform( H   , iZ );
  EPI = transform( EPI , iZ );
  LV  = transform( LV  , iZ );
  RV  = transform( RV  , iZ );

  %%

  H = Mesh( H ,0);

  vprintf('Remeshing ...');
  [~,M] = jigsaw_surface_2_volume( H , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EDGE_LENGTH,'hfun_hmin',EDGE_LENGTH*0.9);
  vprintf(' done.\n');


  %%

  vprintf('Splitting into EPI, LV, RV and LID ...');
  M = MeshTidy( Mesh( M ,0) , 0 );

  %M = rmfield( vtkPolyDataNormals( M , 'SetSplitting' , true , 'SetFeatureAngle' , 1 , 'SetConsistency' , true ,'SetComputePointNormals',false,'SetComputeCellNormals',true) , 'triNormals' );
  M = MeshSplit( M , -1 );
  M.triPART = meshFacesConnectivity( Mesh(M,0) );
  %M = MeshGenerateIDs( M );
  fc = meshFacesCenter( M );
  d = zeros( size(fc) );
  d(:,1) = distanceFrom( fc , EPI );
  d(:,2) = distanceFrom( fc , LV  );
  d(:,3) = distanceFrom( fc , RV  );
  [~,M.triCL] = min( d , [] , 2 );

  for p = unique( M.triPART(:) ).'
    w = M.triPART == p;
    d = M.triCL( w );
    if alleq( d )
      M.triPART( w ) = -d(1);
    else
      M.triPART( w ) = 0;
    end
  end
  M.triPART = abs( M.triPART );
  M.triPART( M.triPART == 0 ) = 4;
  M = rmfield( M , {'triCL'} );
  M = MeshTidy( M , 0 , true );
  vprintf(' done.\n');

  if SMOOTH > 0
    vprintf('Smoothing at %g ...', SMOOTH );
    %M = smooth_after_jigsaw( M , H , SMOOTH ,'SetFeatureEdgeSmoothing',true,'SetEdgeAngle',60);
    M = smooth_after_jigsaw( M , H , SMOOTH ,'SetFeatureEdgeSmoothing',true,'SetEdgeAngle',60,'SetFeatureAngle',60);
    vprintf(' done.\n');
  end
  if PLANARIZE
    vprintf('Planarize ...');
    M.xyz( M.tri( M.triPART == 4 ,:) ,3) = 0;
    vprintf(' done.\n');
  end

  M = MeshTidy( M , -1 , true );

  %%
  if COLLAPSE
    vprintf('Collapse small edges ...');
    
    FEAT = MeshTidy( MeshBoundary( MeshRemoveFaces( MeshGenerateIDs( M ) , M.triPART ~= 4 ) ) );
    FEAT = FEAT.xyzID;
    
    % M.xyz = [ M.xyz , meshF2V( M , M.triPART , @min )*1e8 ];

    M = MeshCollapseEdges( M , EDGE_LENGTH/2 , FEAT );

    % M.xyz = M.xyz(:,1:3);

    vprintf(' done.\n');
  end

  %%
  if fixANGLES
    vprintf('Reducing angles ...');
    
    vprintf('(not implemented yet)');
    
    vprintf(' done.\n');
  end
  %%

  vprintf('Final sorting ...');
  
  P = sparse( (1:size(M.tri,1)).'*[1 1 1] , M.tri , 5 - M.triPART*[1 1 1] , size(M.tri,1) , size(M.xyz,1) );
  P = full( 5 - max( P , [] , 1 ).' );

  [~,order] = sortrows( [ P  , M.xyz(:,3) , atan2( M.xyz(:,2) , M.xyz(:,1) ) ] , [1 2 3] );
  M.xyz     = M.xyz( order , : );
  P         = P( order );
  M.tri     = iperm( order , M.tri );
  M.tri     = sort( M.tri , 2 );
  M = MeshFixCellOrientation( M );

  [~,order] = sortrows( [ M.triPART , M.tri ] );
  M.tri = M.tri( order , : );
  M.triPART = M.triPART( order , : );
  
%   M = rmfield( M , 'triPART' );


  ApexBase = M.xyz( argmin( M.xyz(:,3) ) , : );
  ApexBase = [ ApexBase ; ApexBase(1:2) , max( M.xyz(:,3) ) ];

  M        = transform( M , Z );
  ApexBase = transform( ApexBase , Z );
  %plotMESH( M );hplot3d( ApexBase ,'ok','markerfacecolor','r','markersize',10);

  M.TITLE = sprintf('ApexBase=%s; EPInodes=%d; LVnodes=%d; RVnodes=%d; ZEROnodes=%d;' ,...
    uneval( ApexBase ) , sum( P == 1 ) , sum( P == 2 ) , sum( P == 3 ) , sum( P == 4 ) );

  
%   %from mm 2 cm
%   M.xyz    = M.xyz / 10;
%   ApexBase = ApexBase / 10;

  vprintf(' done.\n');
  
end