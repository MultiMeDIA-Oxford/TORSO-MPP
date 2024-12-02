OUTPUT_FILES = {'TORSO.vtk'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

try
  BODY = Loadv( 'refined.mat' , 'BODY'  );
  VEST = Loadv( 'refined.mat' , 'VEST'  );
catch
  BODY = Loadv( 'fittedVEST.mat'  , 'BODY'  );
  VEST = Loadv( 'fittedVEST.mat'  , 'VEST'  );
end

fprintf('Intersections in BODY  : %d\n' , CheckSelfIntersections( BODY  ) );
fprintf('Intersections in VEST  : %d\n' , CheckSelfIntersections( VEST  ) );

%%

try
S = Mesh( BODY ); EL = 10;
[~,M] = jigsaw_surface_2_volume( S , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EL,'hfun_hmin',EL*0.9,'geom_eta1',180,'geom_eta2',180);
M = MeshFixCellOrientation( meshSeparate( MeshTidy( Mesh( M ,0) ,0,true,[1,1,1,0]) , 'largest' ) );
M = MeshFillHoles( smooth_after_jigsaw( M , S , EL/4 , 'SetFeatureEdgeSmoothing' , true , 'SetEdgeAngle' , 180 ) );
isSI = CheckSelfIntersections( M ); fprintf('Intersections in remeshed BODY : %d\n' , isSI );
if isSI, M = MeshFillHoles( SolveSelfIntersections( M ,'remove' ) ,true); fprintf('Intersections in remeshed BODY : %d (solved?)\n' , CheckSelfIntersections( M ) ); end

write_VTP( M , Fullfile('BODY.vtk') , 'binary' );
end

%%

TORSO = Remove_Head_Arms_Limbs( BODY , VEST );
fprintf('Intersections in TORSO : %d\n' , CheckSelfIntersections( TORSO ) );

S = Mesh( TORSO ); EL = 10;
[~,M] = jigsaw_surface_2_volume( S , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EL,'hfun_hmin',EL*0.9,'geom_eta1',60,'geom_eta2',60);
M = MeshFixCellOrientation( meshSeparate( MeshTidy( Mesh( M ,0) ,0,true,[1,1,1,0]) , 'largest' ) );
M = MeshFillHoles( smooth_after_jigsaw( M , S , EL/4 , 'SetFeatureEdgeSmoothing' , true , 'SetEdgeAngle' , 180 ) );
isSI = CheckSelfIntersections( M ); fprintf('Intersections in remeshed BODY : %d\n' , isSI );
if isSI, M = MeshFillHoles( SolveSelfIntersections( M ,'remove' ) ,true); fprintf('Intersections in remeshed BODY : %d (solved?)\n' , CheckSelfIntersections( M ) ); end
M = MeshTidy( M , 'SortNodes' , 'SortFaces' );

write_VTP( M  , Fullfile('TORSO.vtk') , 'binary' );
TORSOm = M;

%%
try, BC = Loadv( 'BC'  , 'BC'  ); catch
try, BC = Loadv( 'BC1' , 'BC1' ); catch
     BC = Loadv( 'BC0' , 'BC0' ); end; end
% figure, plotMESH(M); hplot3d( BC(:,2) , 'r' ); axis('equal'); view(3); axis('tight'); 

D = [];
for r = 1:size(BC,1)
  p = BC{r,2};
  if isempty(p), continue; end
  if sum(isnan(p(1,:))) == 3, p(1,:) = []; end
  pii = cell(0); dummy = 1;
  for ii = 1:size(p,1)
    if (sum(isnan(p(ii,:))) == 3) || (ii == size(p,1))
      segment = p(dummy:ii,:); dummy = ii+1;
      if size(segment,1) > 20,  pii{end+1} = segment; end
    end
  end
  p = pii;
  for ii = 1:size(p,2)
    pii = polyline(p{ii});
    pii = resample( pii , '+e',0.05 ); pii = double(pii);
    [d,cp] = distanceFrom( pii , M , true );
    w = d < 0; pii(w,:) = []; cp(w,:) = []; d(w,:) = [];
    if isempty( pii ), continue; end
    pii = Mesh( [ pii ; cp ] , bsxfun(@plus, ( 1:size(pii,1) ).' , [ 0 , size(pii,1) ] ) );
    pii.triD = d(:);
    pii.triPART = zeros( size( pii.tri ,1) ,1) + 1;
    D = MeshAppend( D , pii );
  end
end
D.celltype = 3;
write_VTK( D , Fullfile( 'mpp' , 'd2TorsoSurfaces.vtk' ) , 'binary');

%%

try

HEART = read_VTK( Fullfile( 'HEART.vtk' ) );

%make pericardium with a simulated atria
PERICARDIUM_WIDTH = 4;  %before it was 2... Jazmin, proposes 3 mm.
try, PERICARDIUM_WIDTH = PERICARDIUM_WIDTH_; end


[PERICARDIUM,~,~,~,Z] = HEARTparts( HEART );

PERICARDIUM = transform( PERICARDIUM , Z );
  
PERICARDIUM = Mesh( PERICARDIUM , 'convexhull' );
PERICARDIUM = MeshWeld( PERICARDIUM , transform( PERICARDIUM , 'mz' ) );
zmax = max( PERICARDIUM.xyz(:,3) );
q = @(z)-1/(2*zmax)*z.^2 + z;
w = PERICARDIUM.xyz( : ,3)  > 0;
PERICARDIUM.xyz( w ,3) = q( PERICARDIUM.xyz( w ,3) );
PERICARDIUM = MeshTidy( Mesh( PERICARDIUM , 'convexhull' ) ,0,true);
PERICARDIUM = MeshDilate( PERICARDIUM , PERICARDIUM_WIDTH );
PERICARDIUM = MeshTidy( Mesh( PERICARDIUM , 'convexhull' ) ,0,true);

PERICARDIUM = transform( PERICARDIUM , minv(Z) );

%%

RLUNG = Loadv( 'RLUNGmesh.mat'  , 'RLUNG' );
LLUNG = Loadv( 'LLUNGmesh.mat'  , 'LLUNG' );
RIBS  = Loadv( 'RIBSmesh.mat'   , 'RIBS'  );
  

RLUNG = Mesh( RLUNG ,0); fprintf('Intersections in RLUNG : %d\n' , CheckSelfIntersections( RLUNG ) );
LLUNG = Mesh( LLUNG ,0); fprintf('Intersections in LLUNG : %d\n' , CheckSelfIntersections( LLUNG ) );
RIBS  = Mesh( RIBS  ,0); fprintf('Intersections in RIBS  : %d\n' , CheckSelfIntersections( RIBS  ) );



%carve Left Lung
LLUNG = BooleanMeshes( LLUNG , '-' , PERICARDIUM );  %fprintf('Intersections in carved LLUNG : %d\n' , CheckSelfIntersections( LLUNG ) )
%carve Right Lung
RLUNG = BooleanMeshes( RLUNG , '-' , PERICARDIUM );  %fprintf('Intersections in carved RLUNG : %d\n' , CheckSelfIntersections( RLUNG ) )
%carve RIBS
RIBS  = BooleanMeshes( RIBS  , '-' , PERICARDIUM );  %fprintf('Intersections in carved RIBS : %d\n' , CheckSelfIntersections( RIBS ) )
%eventually, avoid ribs-lungs intersections
dilatedRIBS = DilateMesh( RIBS , 2 );
LLUNG = BooleanMeshes( LLUNG , '-' , dilatedRIBS );
RLUNG = BooleanMeshes( RLUNG , '-' , dilatedRIBS );



S = Mesh( RLUNG ); EL = 3;
[~,M] = jigsaw_surface_2_volume( S , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EL,'hfun_hmin',EL*0.9,'geom_eta1',50,'geom_eta2',50);
M = MeshFixCellOrientation( meshSeparate( MeshTidy( Mesh( M ,0) ,0,true,[1,1,1,0]) , 'largest' ) );
M = MeshFillHoles( smooth_after_jigsaw( M , S , EL/4 , 'SetFeatureEdgeSmoothing' , true , 'SetEdgeAngle' , 180 ) );
isSI = CheckSelfIntersections( M ); fprintf('Intersections in remeshed BODY : %d\n' , isSI );
if isSI, M = MeshFillHoles( SolveSelfIntersections( M ,'remove' ) ,true); fprintf('Intersections in remeshed BODY : %d (solved?)\n' , CheckSelfIntersections( M ) ); end

write_VTP( M , Fullfile(  'RLUNG.vtk' ) , 'binary' );



S = Mesh( LLUNG ); EL = 3;
[~,M] = jigsaw_surface_2_volume( S , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EL,'hfun_hmin',EL*0.9,'geom_eta1',50,'geom_eta2',50);
M = MeshFixCellOrientation( meshSeparate( MeshTidy( Mesh( M ,0) ,0,true,[1,1,1,0]) , 'largest' ) );
M = MeshFillHoles( smooth_after_jigsaw( M , S , EL/4 , 'SetFeatureEdgeSmoothing' , true , 'SetEdgeAngle' , 180 ) );
isSI = CheckSelfIntersections( M ); fprintf('Intersections in remeshed BODY : %d\n' , isSI );
if isSI, M = MeshFillHoles( SolveSelfIntersections( M ,'remove' ) ,true); fprintf('Intersections in remeshed BODY : %d (solved?)\n' , CheckSelfIntersections( M ) ); end

write_VTP( M , Fullfile(  'LLUNG.vtk' ) , 'binary' );



S = Mesh( RIBS ); EL = 2;
[~,M] = jigsaw_surface_2_volume( S , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EL,'hfun_hmin',EL*0.9,'geom_eta1',180,'geom_eta2',180);
[~,M] = jigsaw_surface_2_volume( S , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',EL,'hfun_hmin',EL*0.9,'geom_eta1',50,'geom_eta2',50);
M = MeshFixCellOrientation( meshSeparate( MeshTidy( Mesh( M ,0) ,0,true,[1,1,1,0]) , 'largest' ) );
M = MeshFillHoles( smooth_after_jigsaw( M , S , EL/4 , 'SetFeatureEdgeSmoothing' , true , 'SetEdgeAngle' , 180 ) );
isSI = CheckSelfIntersections( M ); fprintf('Intersections in remeshed BODY : %d\n' , isSI );
if isSI, M = MeshFillHoles( SolveSelfIntersections( M ,'remove' ) ,true); fprintf('Intersections in remeshed BODY : %d (solved?)\n' , CheckSelfIntersections( M ) ); end

write_VTP( M , Fullfile(  'RIBS.vtk'  ) , 'binary' );

%%  
end

%%

fprintf('Saving Electrodes positions\n');

ELECTRODES = Loadv( 'ECG_ELECTRODES.mat' , 'ELECTRODES' );
M = Mesh( TORSOm );
ELECTRODES.xyz              = [];
ELECTRODES.xyzTORSO_nodeID  = [];
for f = fieldnames( ELECTRODES ).', f=f{1};
  if strncmp( f , 'xyz' ,3), continue; end
  E = double( ELECTRODES.(f) );
  ELECTRODES = rmfield( ELECTRODES , f );
  for it=1:10
    [~,E] = vtkClosestElement( M , E );
  end
  i = vtkClosestPoint( M , E );
  ELECTRODES.xyz = [ ELECTRODES.xyz ; E ];
  ELECTRODES.xyzTORSO_nodeID_1_based = [ ELECTRODES.xyzTORSO_nodeID ; i ];
end

if 0
figure
plotMESH( TORSOm );
hplot3d( ELECTRODES.xyz , 'ok1r10' );
hplot3d( M.xyz( ELECTRODES.xyzTORSO_nodeID ,:)  , 'ok1g6' );
end

ELECTRODES = rmfield( ELECTRODES, {'xyzTORSO_nodeID','xyzTORSO_nodeID_1_based'} );
write_VTP( ELECTRODES , Fullfile( 'ECG_ELECTRODES.vtk' ) ,'ascii');

%%
% plotMESH( read_VTK( Fullfile(  'TORSO.vtk' ) ) );
% hplot3d( cell2mat(cellfun(@(f)ELECTRODES.(f),fieldnames(ELECTRODES),'un',0)) , 'ok','markerfacecolor','r' )
% end
% 
% LVstimulation = Loadv( 'LVstimulation.mat' , 'LVstimulation' );
% LVstimulation = transform( LVstimulation , 's' , 0.1 );
% 
% RVstimulation = Loadv( 'RVstimulation.mat' , 'RVstimulation' );
% RVstimulation = transform( RVstimulation , 's' , 0.1 );
% 
% LMKS = struct( 'LVstimulation' , LVstimulation , 'RVstimulation' , RVstimulation , 'Electrodes' , ELECTRODES );
% save( Fullfile(  'LMKS.mat' ) , 'LMKS' );
% 
% 
% if true
% xyz = [ LMKS.LVstimulation ;
%         LMKS.RVstimulation ;
%         cell2mat(cellfun(@(f)LMKS.Electrodes.(f),fieldnames(LMKS.Electrodes),'un',0)) ];
% write_VTP( struct('xyz',xyz),...
%            Fullfile(  'LMKS.vtk' ) , 'ascii' );


%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue