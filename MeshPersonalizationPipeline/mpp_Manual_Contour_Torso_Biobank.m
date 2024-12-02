%% Manual Contour Torso
OUTPUT_FILES = {'mpp/BC.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

%BC stands for HeartContours
BC = Loadv( 'BS' , 'BS' );
try, BC = contoursFrom( BC , 'BC' ,  true ); catch
try, BC = contoursFrom( BC , 'BC.tmp' , false ); catch
     BC = contoursFrom( BC , 'BC0' , true ); end; end

%%

while size(BC,2) > 3 && all(cellfun('isempty',BC(:,end))), BC(:,end) = []; end
[BC{end,end+1:3}] = deal([]);
[ BC{ cellfun('isempty',BC) } ] = deal([]);
% BC=BC(:,1:3);
% for i=1:length
%     empty(i) = isempty(BC{i,2}) +isempty(BC{i,3});
% end
% for i=length:-1:1
%     if empty(i) <2
%         last_ind = i;
%         break;
%     end
% end
% BC = BC(1:last_ind,:);
%%

pVEST = [];
if isempty( pVEST ), try, pVEST = read_VTK( Fullfile( 'TORSO.vtk' ) ); end; end
if isempty( pVEST ), try, pVEST = Loadv('fittedVEST','VEST'); end; end
if isempty( pVEST ), try, pVEST = read_VTK( Fullfile( 'mpp' , 'VEST0.vtk' ) ); end; end

pRLUNG = [];
if isempty( pRLUNG ), try, pRLUNG = read_VTK( Fullfile( 'RLUNG.vtk' ) ); end; end
if isempty( pRLUNG ), try, pRLUNG = Loadv('','RLUNG'); end; end
  
pLLUNG = [];
if isempty( pLLUNG ), try, pLLUNG = read_VTK( Fullfile( 'LLUNG.vtk' ) ); end; end
if isempty( pLLUNG ), try, pLLUNG = Loadv('','LLUNG'); end; end


MESHES = {};
try, MESHES{end+1} = pHEART;       MESHES{end}.Color = [1,0.9,0]; MESHES{end}.LineWidth = 1; end
try, MESHES{end+1} = pRLUNG;       MESHES{end}.Color = [1,0.0,0]; MESHES{end}.LineWidth = 1; end
try, MESHES{end+1} = pLLUNG;       MESHES{end}.Color = [0.0,1,0]; MESHES{end}.LineWidth = 1; end

%%

mppOption USE_MANNEQUIN   false

MANNEQUIN = [];
if USE_MANNEQUIN, try, PrepareMannequin; end; end

%%

hFig = get(0,'Children');

mppOption UNATTENDED_TIME   Inf

ManualContouring( BC , 'MANNequin' , MANNEQUIN , 'TEMPfile' , Fullfile('mpp','BC.tmp') , 'MESHES' , MESHES , 'MODE' , 'TORSO' ,'UNATTENDED',UNATTENDED_TIME);

hFig = setdiff( get(0,'Children') , hFig );
waitfor( hFig );
try, close( hFig ); end
try, BC = contoursFrom( BC , Loadv( 'BC.tmp' ) , true ); end

[ BC{ cellfun('isempty',BC) } ] = deal([]);

%%

while size(BC,2) > 3 && all(cellfun('isempty',BC(:,end))), BC(:,end) = []; end

[BC,BC_] = cleanoutHeartSlices( BC );

%% Torso cleaning
removeShorts = @(P) P( P.length > 5 );   %this will remove isolated pieces with a length smaller than 5 mm.
BC(:,2) = cellfun( @(C)double( removeShorts( polyline( C ) ) ) , BC(:,2) , 'un',0);

%%
Save( 'BC.mat' , 'BC' );
BC = BC_;

%%

hFig = Figure();
% imagesc( BC{1,1} );
hplot3d( BC(:,2) , 'r' ); axis('equal'); view(3); 
hplot3d( BC(:,3) , 'g' ); axis('tight'); 
Savefig( hFig, 'Manual Contour Torso')

%%

BS = Loadv( 'BS' , 'BS' );

switch mppBranch
case 'contouring-hannah'
  try, mkdir_( Fullfile( 'mpp' , 'torso-contours' ) ); end
  for h = 1:size(BC,1)
    fn = sprintf( '%03d.[%03d-%s](%.1f)', h, BC{h,1}.INFO.SeriesNumber, BC{h,1}.INFO.SeriesDescription, BC{h,1}.INFO.xZLevel);
    fn = Fullfile('mpp','torso-contours',[fn,'.png']);    
    S = BC{h,1}; C = transform(BC{h,2}, minv(S.SpatialTransform));
    dim = size( S.data(:,:,:,1) ); mask = zeros( dim );
    if ~isempty(C)
      [row,~] = find(isnan(C)); C(unique(row),:) = [];
      pt = round(C(:,1)/S.INFO.PixelSpacing(1)) + dim(1)*(round(C(:,2)/S.INFO.PixelSpacing(2))-1);
      mask( pt ) = 255; mask = permute(mask,[2 1]); clear row pt;
    end
    imwrite(mask,fn);
    clear S C dim mask;
  end
  
otherwise
  try, mkdir_( Fullfile( 'mpp' , 'torso-images'   ) ); end
  try, mkdir_( Fullfile( 'mpp' , 'torso-contours' ) ); end
  for h = 1:size( BC ,1)
    fn = sprintf( '%03d.[%03d-%s](%.1f)' , h , BC{h,1}.INFO.SeriesNumber , BC{h,1}.INFO.SeriesDescription , BC{h,1}.INFO.xZLevel );
    fn1 = Fullfile( 'mpp' , 'torso-images' ,   [fn ,'.png'] );
    fn2 = Fullfile( 'mpp' , 'torso-contours' , [fn ,'.png'] );
    imwrite( getPicture( BS(h,:) ) , fn1 );
    imwrite( getPicture( BC(h,:) ) , fn2 );
  end
  
end

%%
if 0

BS = Loadv( 'BS' , 'BS' );

BC = BS;  %BC stands for BodyContours
[ BC{end,end+1:3} ] = deal([]);

if true    %includes previous contouring
  BC_ = {};  
  if isempty( BC_ ), try, BC_ = Loadv( 'BC.tmp' , 'BC_' ); end; end
  if isempty( BC_ ), try, BC_ = Loadv( 'BC' , 'BC' ); end; end
  if isempty( BC_ ), try,
    CS_ = Loadv( 'CONTOURs.mat' , 'CS' );
    [~,BC_] = sort( arrayfun( @(i)BS{i,1}.INFO.SeriesNumber , 1:size(BS,1) ) );
    BC_ = BS( BC_ , 1);
    for i = 1:size(BC_,1)
      if max( distance2Plane( CS_{i,1} , BC_{i,1} ) ) < 1e-4, BC_{i,2} = CS_{i,1}; end
      if max( distance2Plane( CS_{i,2} , BC_{i,1} ) ) < 1e-4, BC_{i,3} = CS_{i,2}; end
    end
  end; end
  if ~isempty( BC_ )
    for s = 1:size(BC,1)
      c = [];
      if isempty( c ), try, c = find( strcmp( cellfun(@(i)i.INFO.MediaStorageSOPInstanceUID , BC_(:,1) ,'un',0)  , BC{s,1}.INFO.MediaStorageSOPInstanceUID ) ,1); end; end
      if isempty( c ), try, c = find( strcmp( cellfun(@(i)i.INFO.SeriesInstanceUID          , BC_(:,1) ,'un',0)  , BC{s,1}.INFO.SeriesInstanceUID          ) & ...
                                            ( cellfun(@(i)i.INFO.xZLevel                    , BC_(:,1)        ) == BC{s,1}.INFO.xZLevel                    ) ,1); end; end
      if isempty( c ), try, c = find( strcmp( cellfun(@(i)i.INFO.SeriesInstanceUID          , BC_(:,1) ,'un',0)  , BC{s,1}.INFO.SeriesInstanceUID          ) ,1); end; end
      if isempty( c ), continue; end
      BC(s,2:size(BC_,2)) = transform( BC_(c,2:end) ,  BC{s,1}.SpatialTransform / BC_{c,1}.SpatialTransform );
      BC(s,2:end) = cellfun( @double , BC(s,2:end) ,'un',0);
    end
  end
end
[ BC{ cellfun('isempty',BC) } ] = deal([]);

BC_ = BC;
for h = 1:size(BC_,1)
  BC_{h,1}.data = [];
  BC_{h,1}.INFO = struct( 'MediaStorageSOPInstanceUID' , BC_{h,1}.INFO.MediaStorageSOPInstanceUID , 'SeriesInstanceUID' , BC_{h,1}.INFO.SeriesInstanceUID ,'xZLevel', BC_{h,1}.INFO.xZLevel );
end

%%

PrepareMannequin

  
%%

[ BC{ cellfun('isempty',BC) } ] = deal(zeros(0,3));

addNaNsAtEnd = @(c)cellfun( @(x)[x;NaN(1,size(x,2))] , c , 'UniformOutput',false);


setappdata( 0 , 'drawerPosition' , FullScreenPosition() + [ 50 75 -100 -150 ] );
for h = 1:size(BC)
  for CLID = [1 2]   %Current Label ID
    MARKERS = struct([]);

    %intersetion lines
    for hh = [ 1:h-1 , h+1:size(BC,1) ]
      tM = struct('xyz', intersectionLine( BC{h,1} , BC{hh,1} ) ,...
                  'Color',[0.3,0.3,0.2],'LineStyle',':','Marker','none');
      tM.ButtonDownFcn = @(h,e)fprintf('Slice: %d\n',hh);
      MARKERS = catstruct(1,MARKERS,tM);
    end
    
    %intersetion contours
    for c = 1:2
      tM = struct('xyz',meshSlice( cell2mat( addNaNsAtEnd( BC([1:h-1,h+1:size(BC,1)], c+1) ) ) , BC{h,1} ),...
                  'Color',colorith(c),'Marker','o','LineWidth',1,'LineStyle','none','MarkerSize',2,'MarkerFaceColor','k');
      if c == CLID, tM.Marker='x'; tM.LineWidth=2; tM.MarkerSize=8; end
      tM.ButtonDownFcn = @(h,e)fprintf('on Plane: %d\n',hh);
      MARKERS = catstruct(1,MARKERS,tM);
    end
    
    %coincident planes
    Zs = arrayfun( @(hh)max( distance2Plane( BC{hh,CLID+1} ,  BC{h,1} ) ) , 1:size(BC,1) );
    Zs(h) = Inf;
    for hh = find( Zs(:).' < 1e-2 )
      tM = BC{hh,CLID+1}; if isempty( tM ), continue; end
      tM = struct('xyz',tM,'Color',[1,0.5,0],'Marker','none','LineWidth',2,'LineStyle','-');
      tM.ButtonDownFcn = @(h,e)fprintf('Plane segmented: %d\n',hh);
      MARKERS = catstruct(1,MARKERS,tM);
    end
    
    %previous HEART
    if ~isempty( pHEART ), try
    tM = struct('xyz',meshSlice( pHEART , BC{h,1} ),...
      'Color',[0,0.5,1],'Marker','none','LineWidth',2,'LineStyle','-');
    MARKERS = catstruct(1,MARKERS,tM);
    end; end
    
    %previous VEST
    if CLID == 1 && ~isempty( pVEST ), try
    tM = struct('xyz',meshSlice( pVEST , BC{h,1} ),...
      'Color',[0,0.5,1],'Marker','none','LineWidth',2,'LineStyle','-');
    MARKERS = catstruct(1,MARKERS,tM);
    end; end
    
    %previous RLUNG
    if CLID == 2 && ~isempty( pRLUNG ), try
    tM = struct('xyz',meshSlice( pRLUNG , BC{h,1} ),...
      'Color',[0,0.5,1],'Marker','none','LineWidth',2,'LineStyle','-');
    MARKERS = catstruct(1,MARKERS,tM);
    end; end
    
    %previous LLUNG
    if CLID == 2 && ~isempty( pLLUNG ), try
    tM = struct('xyz',meshSlice( pLLUNG , BC{h,1} ),...
      'Color',[0,0.5,1],'Marker','none','LineWidth',2,'LineStyle','-');
    MARKERS = catstruct(1,MARKERS,tM);
    end; end
    
    
    %%OK, now the figure and so on
    hFig = figure('Position',getappdata(0,'drawerPosition'),'Menu','none','Toolbar','none','Color','w','NumberTitle','off','Colormap',gray(256));
    set( hFig , 'DeleteFcn' , @(h,e)setappdata(0,'drawerPosition',get(h,'Position')) );
    set( hFig , 'Name',sprintf('( "%s" )   Slice: %d  of %d  ---  (%03d.%s)\n', SUBJECT_DIR , h , size(BC,1),BC{h,1}.INFO.SeriesNumber,BC{h,1}.INFO.SeriesDescription) );
    
    setappdata(0,'ContinueTheContouring',1);
    hB = uicontrol('Parent',hFig,'BackgroundColor','w','Style','checkbox','String','Continue?','Value',1,'Callback' , @(h,e)setappdata(0,'ContinueTheContouring',get(h,'value')));
    SetPosition( hB , [ -60 , -50 , 60 , 20 ] , true );
    
    hA = axes('Parent',hFig,'Position',[0 0 1 1],'Visible','off','Hittest','off');
    
    FCN = [];
    if USE_MANNEQUIN_
      SetPosition( hA , [ 0 , 0 , -200 , -0.1 ] , true );
      h3D = axes('Parent',hFig,'Position',[0 0 200 300]);
      SetPosition( h3D , [ -200 , 0 , 200 , -0.1 ] , true );
      imagesc( BC{h,1}.t1 ,'Parent',h3D,'hittest','off'); axis(h3D,'equal')
      hplot3d( meshSlice( TORSO0 , BC{h,1} ) , 'Color','m','LineWidth',2);
      set( findall( h3D ) , 'Hittest' , 'off' );
      hplotMESH( TORSO0 , 'ne','FaceColor',[255,224,189]/255,'gouraud','shiny','FaceAlpha',0.3,'Clip','off','ButtonDownFcn',@(h,e)ObjectViewRotate(h) );
      axis( h3D , objbounds(h3D) );
      view( h3D , 0 , 15 );
      try, set( h3D , 'CameraPosition' , getappdata(0,'mannequinCameraPosition') ); end
      set( h3D ,'Visible','off');
      headlight
      hL3D = line('XData',NaN,'YData',NaN,'ZData',NaN,'Color',colorith(CLID),'LineWidth',3,'Marker','.');
      setXYZ = @(xyz)set( hL3D , 'XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3) );
      getXYZ = @(L) [ vec( get(L,'XData') ) , vec( get(L,'YData') ) , vec( get(L,'ZData') ) ];
      FCN = @(clid,L)setXYZ( transform( getXYZ(L) , BC{h,1}.SpatialTransform ) );
      set( h3D , 'DeleteFcn' , @(h,e)setappdata(0,'mannequinCameraPosition',get(h,'CameraPosition')) );
    end
    
    set( hFig , 'CurrentAxes' , hA );
    points = drawContours( BC{h,1}.t1 , BC(h,2:end) ,'waitfor' ,...
      'FILTERSIZE',1,...
      'CLID', CLID ,...
      'UNATTENDED', UNATTENDED_ ,...
      'MARKERS',MARKERS,...
      'Parent', hA ,...
      'FCN',FCN ...
      ); BC{h,CLID+1} = points{CLID};
    %%
    %BC_(:,2:end) = cellfun( @single , BC(:,2:end) ,'un', 0);
    BC_(:,2:end) = BC(:,2:end);
    Save( 'BC.tmp' , 'BC_' , false );
    
    if ~getappdata(0,'ContinueTheContouring'), break; end
%%
  end
  if ~getappdata(0,'ContinueTheContouring'), break; end
end
try, rmappdata( 0 ,'ContinueTheContouring');   end
try, rmappdata( 0 ,'drawerPosition');          end
try, rmappdata( 0 ,'mannequinCameraPosition'); end

[ BC{ cellfun('isempty',BC) } ] = deal([]);
Save( 'BC' , 'BC' );

end

%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue