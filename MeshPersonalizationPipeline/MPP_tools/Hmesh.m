function [ HM , EPIms , LVms , RVms , iT ] = Hmesh( HC , varargin )

  MAX_ALLOWED_PER_BUCKET = Inf;

  PLOT = false;
  try, [varargin,PLOT] = parseargs(varargin,'plot','$FORCE$',{true,PLOT}); end

  SurFCo_opts = { 'USE_BOUNDARIES' , 'noverbose' ,...
                  'SUBDIVIDE'   , { 'SafeButterfly' , 15 } ,...
                  'SMOOTH'      , { 210 , 15 } ,...  %changed this from 200 to 300
                  'DECIMATE'    , { 0.28 , 15 } };
  if PLOT, SurFCo_opts{end+1} = 'plot'; end

  DEFORMATION_ITS = 300;
  C2S = @(C,IM,it,varargin)SurFCo( C , IM , SurFCo_opts{:} ,'its' , it , varargin{:} );

  vprintf = @(varargin)0;
  vprintf = @(varargin)fprintf(varargin{:});


  %%

  T = find( all(~cellfun('isempty', HC(:,2) ),2) ,1,'last');
  [T,iT] = getPlane( HC{T,1} , '+Z' );

  HC   = transform( HC , iT );

  %%
  vprintf('Building LV mesh\n');
  LVc  = HC(:,3); LVc( all(cellfun('isempty',LVc),2) ,:) = [];
  LVp  = [];

  vprintf('Initial mesh.... ');
  LVm0 = initialHeartMesh( LVc );
  vprintf('done\n');

  vprintf('LV mesh.... ');
  LVm = C2S( LVc , LVm0 , DEFORMATION_ITS , 'eap' , LVp ); if PLOT, close(gcf); end
  vprintf('done\n');

  % plotHeartMeshAndContours( LVm , LVc )

  %%
  vprintf('Building RV mesh\n');
  RVc  = HC(:,[4 6]); RVc( all(cellfun('isempty',RVc),2) ,:) = [];
  RVp  = [];

  vprintf('Initial mesh.... ');
  RVm0 = initialHeartMesh( RVc );
  vprintf('done\n');

  vprintf('RV mesh.... ');
  RVm = C2S( RVc , RVm0 , DEFORMATION_ITS , 'eap' , RVp ); if PLOT, close(gcf); end
  vprintf('done\n');

  % plotHeartMeshAndContours( RVm , RVc )

  %%
  vprintf('Building EPI mesh\n');
  EPIc  = HC(:,[2 5]); EPIc( all(cellfun('isempty',EPIc),2) ,:) = [];
  EPIp  = [];

  vprintf('Initial mesh.... ');
  EPIm0 = initialHeartMesh( EPIc );
  vprintf('done\n');

  vprintf('EPI mesh.... ');
  EPIm = C2S( EPIc , EPIm0 , DEFORMATION_ITS , 'eap' , EPIp ); if PLOT, close(gcf); end
  vprintf('done\n');

  % plotHeartMeshAndContours( EPIm , EPIc )

  %%
  if MAX_ALLOWED_PER_BUCKET
  vprintf( 'Solving intersection RV with LV+1\n');
  LVmd = MeshDilate( LVm , 1 );
  [ RVm , RVp ] = fixMesh( RVm , LVmd , RVc , RVp , RVm0 , 'setdiff' , min(1,MAX_ALLOWED_PER_BUCKET) , PLOT , C2S , DEFORMATION_ITS );

  vprintf( 'Solving intersection LV with RV+1\n');
  RVmd = MeshDilate( RVm , 1 );
  [ LVm , LVp ] = fixMesh( LVm , RVmd , LVc , LVp , LVm0 , 'setdiff' , min(1,MAX_ALLOWED_PER_BUCKET) , PLOT , C2S , DEFORMATION_ITS );

  vprintf( 'Solving intersection RV with EPI-1\n');
  EPImd = MeshDilate( EPIm , -1 );
  [ RVm , RVp ] = fixMesh( RVm , EPImd , RVc , RVp , RVm0 , 'intersect' , min(2,MAX_ALLOWED_PER_BUCKET) , PLOT , C2S , DEFORMATION_ITS );

  vprintf( 'Solving intersection LV with EPI-1\n');
  [ LVm , LVp ] = fixMesh( LVm , EPImd , LVc , LVp , LVm0 , 'intersect' , min(2,MAX_ALLOWED_PER_BUCKET) , PLOT , C2S , DEFORMATION_ITS );

  vprintf( 'Solving intersection EPI with RV+2 and LV+2\n');
  RVmd = MeshDilate( RVm , 2 );
  LVmd = MeshDilate( LVm , 2 );
  [ EPIm , EPIp ] = fixMesh( EPIm , { RVmd , LVmd }  , EPIc , EPIp , EPIm0 , 'union' , min(3,MAX_ALLOWED_PER_BUCKET) , PLOT , C2S , DEFORMATION_ITS );
  end

  %%

  EPIm = Mesh( EPIm ,0);
  LVm  = Mesh(  LVm ,0);
  RVm  = Mesh(  RVm ,0);

  try
    SUBJECT_DIR = evalin('base','SUBJECT_DIR');
    DB = dbstack();
    inMPP = false;
    for d = 1:numel(DB)
      if strcmp( DB(d).file(1:4) , 'mpp_' )
        inMPP = true;
        break;
      end
    end
    if inMPP
      HC = cleanoutHeartSlices( HC );    
      save( [ fullfile( SUBJECT_DIR , 'mpp' , 'HEARTmesh' ) , '.temporal_surface' ] ,'EPIm','LVm','RVm','HC','T');
    end
  end

  %%

  if ~exist( 'EPIm' , 'var' )
    surFile = [ fullfile( SUBJECT_DIR , 'mpp' , 'HEARTmesh' ) , '.temporal_surface' ];
    if ~exist('EPIm','var') && isfile( surFile ),  load( surFile ,'-mat'); end
    
    surFile = [ fullfile( SUBJECT_DIR , 'mpp' , 'HEARTmesh' ) , '.sur' ];
    if ~exist('EPIm','var') && isfile( surFile ),  load( surFile ,'-mat'); end
    
    vprintf = @(varargin)0;
    iT = minv( T );
    %MESH = @(M)struct('xyz',double(M.xyz),'tri',double(M.tri));
  end
  %%

  EPIm = SolveSelfIntersections( EPIm , 'remove' );
  LVm  = SolveSelfIntersections(  LVm , 'remove' );
  RVm  = SolveSelfIntersections(  RVm , 'remove' );

  EPIm = MeshClipAndCloseAtTop( EPIm , 10 );
  EPIm = meshSeparate( EPIm , 'minz' );

  LVmd = MeshDilate( MeshSubdivide( LVm ,'safebutterfly') ,2 );
  LVmd = MeshClipAndCloseAtTop( LVmd , 9 );
  LVmd = meshSeparate( LVmd , 'minz' );

  RVmd = MeshDilate( MeshSubdivide( RVm ,'safebutterfly') ,1 );
  RVmd = MeshClipAndCloseAtTop( RVmd , 9 );
  RVmd = meshSeparate( RVmd , 'minz' );

	try,    EPIm = safe_MeshBoolean( EPIm , '+' , LVmd );
  catch,  EPIm =      MeshBoolean( EPIm , '+' , LVmd );
	end
	
	try,    EPIm = safe_MeshBoolean( EPIm , '+' , RVmd );
  catch,  EPIm =      MeshBoolean( EPIm , '+' , RVmd );
  end
  
  RVm  = MeshClipAndCloseAtTop( RVm , 8 );
  
  try,    RVm  = safe_MeshBoolean( RVm , '-' , LVmd );
  catch,  RVm  =      MeshBoolean( RVm , '-' , LVmd );
  end

  %%

  LVm  = MeshClip( LVm  , getPlane( [0 0 15;0 0 1] ) );
  LVm  = meshSeparate( LVm , 'minz' );

  RVm  = MeshClip( RVm  , getPlane( [0 0 15;0 0 1] ) );
  RVm  = meshSeparate( RVm , 'minz' );

  EPIm = MeshClip( EPIm  , getPlane( [0 0 15;0 0 1] ) );
  EPIm = meshSeparate( EPIm , 'minz' );

  %%

  if 0
   plot3d( HC(:,[2 5 7]) , 'b','LineWidth',3); hplotMESH( EPIm , 'b' ,'FaceAlpha',0.3,'ne');
  hplot3d( HC(:,[  3  ]) , 'r','LineWidth',3); hplotMESH(  LVm , 'r' ,'FaceAlpha',0.3,'ne');
  hplot3d( HC(:,[ 4 6 ]) , 'g','LineWidth',3); hplotMESH(  RVm , 'g' ,'FaceAlpha',0.3,'ne');
  headlight; axis equal
  end

  %smooth and close all meshes
  vprintf('Smoothing meshes... ');
  EPIms = Mesh( MeshSmooth( MeshSubdivide( EPIm ,'safebutterfly') , ones(150,1) ,'SetConvergence',0,'SetFeatureAngle',180,'SetFeatureEdgeSmoothing',true ) ,0);
  LVms  = Mesh( MeshSmooth( MeshSubdivide( LVm  ,'safebutterfly') , ones(150,1) ,'SetConvergence',0,'SetFeatureAngle',180,'SetFeatureEdgeSmoothing',true ) ,0);
  RVms  = Mesh( MeshSmooth( MeshSubdivide( RVm  ,'safebutterfly') , ones(150,1) ,'SetConvergence',0,'SetFeatureAngle',180,'SetFeatureEdgeSmoothing',true ) ,0);
  vprintf('done\n');

  if 0
   plot3d( HC(:,[2 5 7]) , 'b','LineWidth',3); hplotMESH( EPIms , 'b' ,'FaceAlpha',0.3,'ne');
  hplot3d( HC(:,[  3  ]) , 'r','LineWidth',3); hplotMESH(  LVms , 'r' ,'FaceAlpha',0.3,'ne');
  hplot3d( HC(:,[ 4 6 ]) , 'g','LineWidth',3); hplotMESH(  RVms , 'g' ,'FaceAlpha',0.3,'ne');
  headlight; axis equal
  end

  %%

  %Clip Plane
  Zplane = struct('xyz',[-1,-1,0;-1,-1,1;-1,1,0;-1,1,1;1,-1,0;1,-1,1;1,1,0;1,1,1],'tri',[1,2,3;4,3,2;5,7,6;8,6,7;1,5,2;6,2,5;3,4,7;8,7,4;1,3,5;7,5,3;2,6,4;8,4,6]);
  Zplane = transform( Zplane , 's', [ fro( max(EPIm.xyz,[],1) - min(EPIm.xyz,[],1) ) * [1 1] , max( EPIm.xyz(:,3) )*2 ] , 's', [200 200 40] );

  vprintf('Boolean operations... ');
  %Boolean all meshes
  HM = MeshClipAndCloseAtTop( EPIms , 1 );
  
  try,    HM = safe_MeshBoolean( HM , '-' , Zplane );
	catch,  HM =      MeshBoolean( HM , '-' , Zplane );
	end

  try,    HM = safe_MeshBoolean( HM , '-' , MeshClipAndCloseAtTop( LVms ,2) );
	catch,  HM =      MeshBoolean( HM , '-' , MeshClipAndCloseAtTop( LVms ,2) );
	end

  try,    HM = safe_MeshBoolean( HM , '-' , MeshClipAndCloseAtTop( RVms ,2) );
	catch,  HM =      MeshBoolean( HM , '-' , MeshClipAndCloseAtTop( RVms ,2) );
	end

  HM = MeshFixCellOrientation( MeshTidy( HM ,0,true) );
  HM = meshSeparate( HM , 'minz' );
  vprintf('done\n');

  HM    = transform( HM    , T );

  %%
  if nargout > 1
    EPIms = Mesh( meshSeparate( MeshClip( EPIms , getPlane( [0 0 0.5;0 0 1] ) ) ,'minz' ) ,0);
    EPIms = transform( EPIms , T );

    LVms  = Mesh( meshSeparate( MeshClip( LVms  , getPlane( [0 0 0.5;0 0 1] ) ) ,'minz' ) ,0);
    LVms  = transform( LVms  , T );

    RVms  = Mesh( meshSeparate( MeshClip( RVms  , getPlane( [0 0 0.5;0 0 1] ) ) ,'minz' ) ,0);
    RVms  = transform( RVms  , T );
    
    iZ = iT;
    %%
  end

  
  
  
  
  
  
  try
    SUBJECT_DIR = evalin('base','SUBJECT_DIR');
    DB = dbstack();
    inMPP = false;
    for d = 1:numel(DB)
      if strcmp( DB(d).file(1:4) , 'mpp_' )
        inMPP = true;
        break;
      end
    end
    if inMPP
      movefile( [ fullfile( SUBJECT_DIR , 'mpp' , 'HEARTmesh' ) , '.temporal_surface' ] ,...
                [ fullfile( SUBJECT_DIR , 'mpp' , 'HEARTmesh' ) , '.sur' ]  );
    end
  end
  
  
end
function Mc = MeshClipAndCloseAtTop( M , z )
  M = Mesh( M ,0);

  Mc = Mesh( MeshClipAndClose( M , getPlane([0 0 z;0 0 1] ) ) ,0);
  B = MeshBoundary( Mc );

  if ~isempty( B.tri )
      
    Z = max( M.xyz(:,3) );
    for v = linspace( Z , z , 1001 )
      try
        Mc = Mesh( MeshClipAndClose( M , getPlane([0 0 v;0 0 1] ) ) ,0);
        B = MeshBoundary( Mc );
        if isempty( B.tri ), break; end
      end
    end
    
  end
    
  Mc = Mesh( Mc ,0);
end
 
function [Am,Ap] = fixMesh( Am , Bm , Ac , Ap , Am0 , operationAB , maxPerBucket , PLOT , C2S , DEFORMATION_ITS )
  Bucket_sz    = 10;
  PPLOT = PLOT;
  vprintf = @(varargin)0;
  vprintf = @(varargin)fprintf(varargin{:});
  

  if iscell( Bm )
    for bb = 2:numel( Bm )
      Bm{1} = MeshAppend( Bm{1} , Bm{bb} );
    end
    Bm = Bm{1};
  end
  Bm = MeshClip( Bm , getPlane( [0 0 10;0 0 1] ) );

  Zh = [];
  while 1
    IN = [];
    if isempty( IN ), try,   IN = IntersectingMeshes( Bm , Am ); end; end
    if isempty( IN ), break; end
    IN.tri(:,3) = [];
    IN = MeshTidy( IN  ,1e-12,true);
    if min( IN.xyz(:,3) ) > 10, break; end

    if PPLOT
      figure;
       plotMESH( MeshClip( Am , getPlane([0 0 10;0 0 1] ) ) , 'FaceColor',[1,0.6,0.6] ,'FaceAlpha',0.3,'ne','patch');
      hplotMESH(           Bm                                , 'FaceColor',[1,1,1]*0.8 ,'FaceAlpha',0.3,'ne','patch');
      hplotMESH( IN , 'EdgeColor','y','LineWidth',1,'ZLimInclude','off','patch');
      headlight;
      axis equal
    end


    fc = meshFacesConnectivity( IN );
    Zs = [];
    for f = unique( fc(:) ).'
      F = IN;
      F.tri = F.tri( fc == f ,:);
      
      F = MeshTidy( F );
      if isempty( F.xyz ), continue; end
      if min( F.xyz(:,3) ) > 10, continue; end
      if max( F.xyz(:,3) ) > 5
        newZs = [ min( F.xyz(:,3) ):1:0 , 0 , 5 ];
        p = 1;
      else
        newZs = range( F.xyz(:,3) );
        newZs = [ mean(newZs) , mean(newZs):-1:newZs(1) , mean(newZs):1:newZs(2) , newZs ];
        p = 2;
      end
      newZs = newZs(:);                   %Z value
      newZs(:,2) = f;                     %connected piece that is belongs
      newZs(1,3) = p;                     %preference level

      Zs = [ Zs ; newZs ];
    end
    Zs(:,4) = round( Zs(:,1) / Bucket_sz ) * Bucket_sz;   %bucket
    Zb = round( Zh / Bucket_sz ) * Bucket_sz;
    Zs(:,5) = arrayfun( @(b)sum( Zb == b ) , Zs(:,4) ); %number of fixings in that bucket

    Zs( Zs(:,5) >= maxPerBucket ,:) = [];

    if isempty( Zs ), break; end
    Zs = sortrows( Zs , [5,-3,1] );
    Zs = Zs(1,:);

    if PPLOT, hplotMESH( MeshRemoveFaces( IN , fc ~= Zs(1,2) ) , 'EdgeColor','m','LineWidth',2,'ZLimInclude','off','patch'); end
    Z = Zs(1); Zh = [ Zh ; Z ];

    str = sprintf( 'Fixing at Zlevel: %g  (%d of %d for bucket %g)...' , Z , Zs(5)+1 , maxPerBucket , Zs(4) );
    vprintf(str);
    if PPLOT, title(str); end

    a = meshSlice( Am  , [0 0 Z;0 0 1] );
    if PPLOT, hplot3d( a , 'r' ); end

    b = meshSlice( Bm  , [0 0 Z;0 0 1] );
    if PPLOT, hplot3d( b , 'k' ); end

    a = toPolygon( polyline( a(:,1:2) ) );
    b = toPolygon( polyline( b(:,1:2) ) );
    switch lower(operationAB)
      case 'setdiff',         r = setdiff( a , b );
      case 'union',           r = union( a , b );
      case 'intersect',       r = intersect( a , b );
      otherwise,              error('unknown mode');
    end
    r = r.XY; r(:,3) = Z;
    if PPLOT, hplot3d( r , 'b','LineWidth',2 ); end

    r = double( resample( polyline( r ) ,'e',0.1 ) );
    r( any( ~isfinite(r) ,2) ,:) = [];
    [~,~,d] = vtkClosestElement( Bm , r );
    r( d > 2 ,:) = [];
    if PPLOT, hplot3d( r , 'om' ,'MarkerFaceColor','y' ); end

    Ap = [ Ap ; r ];
    if PPLOT, hplot3d( Ap , '.r' ); drawnow; end

    Am = C2S( Ac , Am0 , DEFORMATION_ITS , 'eap' , Ap ); if PLOT, close(gcf); end
    %Am = MeshClip( Am , [0 0 15;0 0 1] , false , -1 );
    vprintf(' done.  (history of Zlevels: %s)\n', strrep( strrep( strrep( uneval(Zh) , ';' , ' , ' ) , '[' , '' ) , ']' , '' ) );
  end

end
function G = toPolygon( P )
  P = P.coordinates;
  G = polygon( P{1} );
  for p = 2:numel( P )
    G = union( G , polygon( P{p} ) );
  end
end
