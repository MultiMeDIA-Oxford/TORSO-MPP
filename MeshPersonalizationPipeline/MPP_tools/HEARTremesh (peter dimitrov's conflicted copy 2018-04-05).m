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

  H = MakeMesh( H );

  vprintf('Remeshing ...');
  [~,M] = jigsaw_surface_2_volume( H , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EDGE_LENGTH,'hfun_hmin',EDGE_LENGTH*0.9);
  vprintf(' done.\n');


  %%

  vprintf('Splitting into EPI, LV, RV and LID ...');
  M = MeshTidy( MakeMesh( M ) , 0 );

  M = rmfield( vtkPolyDataNormals( M , 'SetSplitting' , true , 'SetFeatureAngle' , 1 , 'SetConsistency' , true ,'SetComputePointNormals',false,'SetComputeCellNormals',true) , 'triNormals' );
  M.triPART = meshFacesConnectivity( M );
  M = MeshGenerateIDs( M );
  fc = meshFacesCenter( M );
  d = zeros( size(fc) );
  [~,~,d(:,1)] = vtkClosestElement( EPI , fc );
  [~,~,d(:,2)] = vtkClosestElement( LV  , fc );
  [~,~,d(:,3)] = vtkClosestElement( RV  , fc );
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
  M = rmfield( M , {'xyzID','triID','triCL'} );
  M = MeshTidy( M , 0 );
  vprintf(' done.\n');

  if SMOOTH > 0
    vprintf('Smoothing at %g ...', SMOOTH );
    M = smooth_after_jigsaw( M , H , SMOOTH , 'SetFeatureEdgeSmoothing' , true , 'SetEdgeAngle' , 60 );
    vprintf(' done.\n');
  end
  if PLANARIZE
    vprintf('Planarize ...');
    M.xyz( M.tri( M.triPART == 0 ,:) ,3) = 0;
    vprintf(' done.\n');
  end

  M = MeshRemoveFaces( M , M.tri(:,1) == M.tri(:,2) | M.tri(:,2) == M.tri(:,3) | M.tri(:,1) == M.tri(:,3) );
  M.triPART( M.triPART == 0 ) = 4;

  %%
  if COLLAPSE
    vprintf('Collapse small edges ...');
    P = sparse( (1:size(M.tri,1)).'*[1 1 1] , M.tri , 5 - M.triPART*[1 1 1] , size(M.tri,1) , size(M.xyz,1) );
    P = full( 5 - max( P , [] , 1 ).' );

    FEAT = MeshTidy( MeshBoundary( MeshRemoveFaces( MeshGenerateIDs( M ) , M.triPART ~= 4 ) ) ,-1);
    FEAT = FEAT.xyzID;

    [ED,EL] = meshEdges( M );
    w = EL == 0;                                        ED(w,:) = []; EL(w,:) = [];
    w = P( ED(:,1) ) ~= P( ED(:,2) );                   ED(w,:) = []; EL(w,:) = [];
    %w = any( ismember( ED , FEAT ) , 2 );               ED(w,:) = []; EL(w,:) = [];
    w = sum( ismember( ED , FEAT ) , 2 ) == 1;          ED(w,:) = []; EL(w,:) = [];

    it = 0;
    while 1, it = it+1;
      if ~rem(it,100), w = ~isfinite( EL ); EL(w,:)=[]; ED(w,:)=[]; end
      [mel,eid] = min( EL ); 
      if ~rem(it,100), fprintf('minimum edgeLength: %g\n',mel); end
      if mel > EDGE_LENGTH/2, break; end
      E = ED( eid ,:);

      M.tri( M.tri == E(2) ) = E(1);
      M.xyz( E(1) ,:) = mean( M.xyz( E ,:) , 1);

      ED( ED == E(2) ) = E(1);
      w = any( ED == E(1) ,2);
      EL( w ) = sqrt( sum( ( M.xyz( ED(w,1) ,:) - M.xyz( ED(w,2) ,:) ).^2 ,2) );
      EL( EL == 0 ) = Inf;
    end

    M = MeshRemoveFaces( M , M.tri(:,1) == M.tri(:,2) | M.tri(:,2) == M.tri(:,3) | M.tri(:,1) == M.tri(:,3) );
    M = MeshTidy( M , 0 );

    [~,ts] = unique( sort( M.tri ,2) ,'rows' );
    M = MeshRemoveFaces( M , { ts } );
    M = MeshTidy( M , -1 );
    
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
  M = MeshFixFacesOrientation( M );

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