function [ HM , EPIms , LVms , RVms , iT ] = HEARTmesh( HC , varargin )

[ HM , EPIms , LVms , RVms , iT ] = Hmesh( HC , varargin );

return;


MAX_ALLOWED_PER_BUCKET = Inf;

PLOT = false;
try, [varargin,PLOT] = parseargs(varargin,'plot','$FORCE$',{true,PLOT}); end

Contours_opts = { ...
    'STIFFNESS',200,'FARTHESTP_RESAMPLING',10,...
    'SMTHDEC_ITER',20,'MAX_DEFORMATION_ITS',400,...
    'FARTERPOINTS', -3 ,...
    'TARGETREDUCTION',0.72 };
if PLOT, Contours_opts{end+1} = 'plot'; end

DEFORMATION_ITS = 300;
C2S = @(C,IM,it,varargin)Contours2Surface_ez( C , 'INITIAL_MESH', IM , Contours_opts{:} ,'MAX_DEFORMATION_ITS', it , varargin{:} );

vprintf = @(varargin)0;
vprintf = @(varargin)fprintf(varargin{:});


%%

T = find( all(~cellfun('isempty', HC(:,2) ),2) ,1,'last');
[T,iT] = getPlane( HC{T,1} , '+Z' );

HC   = transform( HC , iT );

firstSA = [];
if isempty( firstSA ), try, firstSA = find( cellfun( @(I)isfield(I.INFO,'PlaneName') && strncmp(I.INFO.PlaneName,'SAx',3) , HC(:,1) ) ,1); end; end
if isempty( firstSA ), firstSA = 4; end
firstSA = min( firstSA , size( HC ,1) );

%%

vprintf('Building LV mesh:     ');
LAs = HC(1:firstSA-1     ,[ 3 ]); LAs( all( cellfun('isempty',LAs) ,2) ,:) = [];
SAs = HC(  firstSA  :end ,[ 3 ]); SAs( all( cellfun('isempty',SAs) ,2) ,:) = [];

BASE = vertcat( SAs{find( all( ~cellfun('isempty',SAs) ,2) ,1,'last'),:} );
BASE(:,3) = BASE(:,3) - min( BASE(:,3) ) + 41;

LVm0 = Mesh( [ vertcat( SAs{:} ) ; vertcat( LAs{:} ) ; BASE ] ,'convhull');
LVm0 = MeshClip( Mesh(LVm0) , getPlane( [0 0 40;0 0 1] ) );
LVm0 = jigsaw_remesh( LVm0 , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',15,'hfun_hmin',15*0.9,'geom_eta1',180,'geom_eta2',180);
LVm0 = MeshTidy( LVm0 ,0,true);

LVc = [ LAs ; SAs ];
LVp = double( resample( polyline( BASE ) ,'e',3 ) ); LVp(:,3) = 50;
vprintf('Initial mesh.... ');
LVm0 = C2S( LVc , LVm0 , 100 , 'eap' , LVp ); if PLOT, close(gcf); end
LVm0 = MeshFixCellOrientation( LVm0 );
vprintf('   -   ');

vprintf('LV mesh.... ');
LVm = C2S( LVc , LVm0 , DEFORMATION_ITS , 'eap' , LVp ); if PLOT, close(gcf); end
vprintf('done\n');
  
% plotHeartMeshAndContours( LVm , LVc )

%%

vprintf('Building RV mesh:     ');
LAs = HC(1:firstSA-1     ,[4 6]); LAs( all( cellfun('isempty',LAs) ,2) ,:) = [];
SAs = HC(  firstSA  :end ,[4 6]); SAs( all( cellfun('isempty',SAs) ,2) ,:) = [];

BASE = vertcat( SAs{find( all( ~cellfun('isempty',SAs) ,2) ,1,'last'),:} );
BASE(:,3) = BASE(:,3) - min( BASE(:,3) ) + 41;

RVm0 = Mesh( [ vertcat( SAs{:} ) ; vertcat( LAs{:} ) ; BASE ] ,'convhull');
RVm0 = MeshClip( Mesh(RVm0) , getPlane( [0 0 40;0 0 1] ) );
RVm0 = jigsaw_remesh( RVm0 , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',15,'hfun_hmin',15*0.9,'geom_eta1',180,'geom_eta2',180);
RVm0 = MeshTidy( RVm0 ,0,true);

RVc = [ LAs ; SAs ];
RVp = double( resample( polyline( BASE ) ,'e',3 ) ); RVp(:,3) = 50;
vprintf('Initial mesh.... ');
RVm0 = C2S( RVc , RVm0 , 100 , 'eap' , RVp ); if PLOT, close(gcf); end
RVm0 = MeshFixCellOrientation( RVm0 );
% RVm0 = vtkQuadricDecimation( RVm0 , 'SetTargetReduction' , 0.75 );
vprintf('   -   ');

vprintf('RV mesh.... ');
RVm = C2S( RVc , RVm0 , DEFORMATION_ITS , 'eap' , RVp ); if PLOT, close(gcf); end
vprintf('done\n');
  
% plotHeartMeshAndContours( RVm , RVc )

%%

vprintf('Building EPI mesh:     ');
LAs = HC(1:firstSA-1     ,[2 5]); LAs( all( cellfun('isempty',LAs) ,2) ,:) = [];
SAs = HC(  firstSA  :end ,[2 5]); SAs( all( cellfun('isempty',SAs) ,2) ,:) = [];

BASE = vertcat( SAs{find( all( ~cellfun('isempty',SAs) ,2) ,1,'last'),:} );
BASE(:,3) = BASE(:,3) - min( BASE(:,3) ) + 41;


SAs( [ false ; any( cellfun('isempty',SAs(2:end-1,:)) ,2) ; false ] ,:) = [];

EPIm0 = Mesh( [ vertcat( SAs{:} ) ; vertcat( LAs{:} ) ; BASE ] ,'convhull');
EPIm0 = MeshClip( Mesh(EPIm0) , getPlane( [0 0 40;0 0 1] ) );
EPIm0 = jigsaw_remesh( EPIm0 , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',15,'hfun_hmin',15*0.9,'geom_eta1',180,'geom_eta2',180);
EPIm0 = MeshTidy( EPIm0 ,0,true);

EPIc = [ LAs ; SAs ];
EPIp = double( resample( polyline( BASE ) ,'e',3 ) ); EPIp(:,3) = 50;
vprintf('Initial mesh.... ');
EPIm0 = C2S( EPIc , EPIm0 , 100 , 'eap' , EPIp ); if PLOT, close(gcf); end
EPIm0 = MeshFixCellOrientation( EPIm0 );
% EPIm0 = vtkQuadricDecimation( EPIm0 , 'SetTargetReduction' , 0.75 );
vprintf('   -   ');

vprintf('EPI mesh.... ');
EPIm = C2S( EPIc , EPIm0 , DEFORMATION_ITS , 'eap' , EPIp ); if PLOT, close(gcf); end
vprintf('done\n');
  
% plotHeartMeshAndContours( EPIm , EPIc )

%%
if 1
vprintf( 'Solving intersection RV with LV+1\n');
[ RVm , RVp ] = fixMesh( RVm , MeshDilate( LVm , 1 ) , RVc , RVp , RVm0 , 'setdiff' , min(1,MAX_ALLOWED_PER_BUCKET) );

vprintf( 'Solving intersection LV with RV+1\n');
[ LVm , LVp ] = fixMesh( LVm , MeshDilate( RVm , 1 ) , LVc , LVp , LVm0 , 'setdiff' , min(1,MAX_ALLOWED_PER_BUCKET) );

vprintf( 'Solving intersection RV with EPI-1\n');
[ RVm , RVp ] = fixMesh( RVm , MeshDilate( EPIm , -1 ) , RVc , RVp , RVm0 , 'intersect' , min(2,MAX_ALLOWED_PER_BUCKET) );

vprintf( 'Solving intersection LV with EPI-1\n');
[ LVm , LVp ] = fixMesh( LVm , MeshDilate( EPIm , -1 ) , LVc , LVp , LVm0 , 'intersect' , min(2,MAX_ALLOWED_PER_BUCKET) );

vprintf( 'Solving intersection EPI with RV+2 and LV+2\n');
[ EPIm , EPIp ] = fixMesh( EPIm , { MeshDilate( RVm , 2 ) , MeshDilate( LVm , 2 ) }  , EPIc , EPIp , EPIm0 , 'union' , min(3,MAX_ALLOWED_PER_BUCKET) );
end

%%
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
    save( [ fullfile( SUBJECT_DIR , 'mpp' , 'HEARTmesh' ) , '.tmp' ] ,'EPIm','LVm','RVm','HC','T');
  end
end

%%

if ~exist( 'EPIm' , 'var' )
  load( [ fullfile( SUBJECT_DIR , 'mpp' , 'HEARTmesh' ) , '.tmp' ] ,'-mat');
  vprintf = @(varargin)0;
  iT = minv( T );
end

EPIm = meshSeparate( EPIm , 'minz' );
EPIm = SolveSelfIntersections( EPIm , 'remove' );
try
  EPIm = MeshClipAndClose( EPIm , getPlane([0 0 20;0 0 1]) );
catch
  EPIm = MeshClipAndClose( EPIm , getPlane([0 0 19;0 0 1]) );
end

LVmd = LVm;
LVmd = MeshDilate( LVmd ,2 );
LVmd = MeshClipAndClose( LVmd , getPlane([0 0 21;0 0 1]) );
LVmd = meshSeparate( LVmd , 'minz' );

RVmd = RVm;
RVmd = MeshDilate( RVmd ,2 );
RVmd = MeshClipAndClose( RVmd , getPlane([0 0 21;0 0 1]) );
RVmd = meshSeparate( RVmd , 'minz' );

EPIm = MeshBoolean( EPIm , '+' , LVmd );
EPIm = MeshBoolean( EPIm , '+' , RVmd );

RVm  = MeshClipAndClose( RVm , getPlane([0 0 20;0 0 1]) );
RVm  = MeshBoolean( RVm , '-' , LVmd );

%%

LVm  = MeshClip( LVm  , getPlane( [0 0 15;0 0 1] ) );
LVm  = meshSeparate( LVm , 'minz' );

RVm  = MeshClip( RVm  , getPlane( [0 0 15;0 0 1] ) );
RVm  = meshSeparate( RVm , 'minz' );

EPIm = MeshClip( EPIm  , getPlane( [0 0 10;0 0 1] ) );
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
EPIms = MeshSmooth( MeshSubdivide( EPIm ,'butterfly') , ones(150,1) ,'SetConvergence',0,'SetFeatureAngle',180,'SetFeatureEdgeSmoothing',true );
LVms  = MeshSmooth( MeshSubdivide( LVm  ,'butterfly') , ones(150,1) ,'SetConvergence',0,'SetFeatureAngle',180,'SetFeatureEdgeSmoothing',true );
RVms  = MeshSmooth( MeshSubdivide( RVm  ,'butterfly') , ones(150,1) ,'SetConvergence',0,'SetFeatureAngle',180,'SetFeatureEdgeSmoothing',true );
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
HM = Mesh(EPIms,0);
HM = MeshFillHoles( HM ,Inf);
HM = MeshBoolean( HM , '-' , Zplane );

HM = MeshBoolean( HM , '-' , MeshFillHoles( LVms ,Inf) );
HM = MeshBoolean( HM , '-' , MeshFillHoles( RVms ,Inf) );
HM = MeshFixCellOrientation( MeshTidy( HM ,0,true) );
vprintf('done\n');


HM    = transform( HM    , T );

%%
if nargout > 1
  EPIms = MeshClip( EPIms , getPlane( [0 0 0.5;0 0 1] ) );
  EPIms = transform( EPIms , T );
  
  LVms  = MeshClip( LVms  , getPlane( [0 0 0.5;0 0 1] ) );
  LVms  = transform( LVms  , T );

  RVms  = MeshClip( RVms  , getPlane( [0 0 0.5;0 0 1] ) );
  RVms  = transform( RVms  , T );
end


  function [Am,Ap] = fixMesh( Am , Bm , Ac , Ap , Am0 , operationAB , maxPerBucket )
    if nargin < 7, maxPerBucket = 3; end
    Bucket_sz    = 10;
    PPLOT = PLOT;

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
      IN = MeshTidy( IN  ,0,true);
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
      
      r = double( resample( polyline( r ) ,'e',3 ) );
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
  

end
function G = toPolygon( P )
  P = P.coordinates;
  G = polygon( P{1} );
  for p = 2:numel( P )
    G = union( G , polygon( P{p} ) );
  end
end
