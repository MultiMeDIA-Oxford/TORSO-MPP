%% Fit Vest
OUTPUT_FILES = {'mpp/fittedVEST.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

mppOption Torso_figures     false
mppOption TORSO_MODEL_DIR

Mb_ = loadv( fullfile( TORSO_MODEL_DIR , 'BODY_MODEL' ) , 'Mb_' );
Mv_ = loadv( fullfile( TORSO_MODEL_DIR , 'VEST_MODEL' ) , 'Mv_' );
if Torso_figures && ~exist( Fullfile( 'mpp', 'torso-figures' ), 'dir'), mkdir( Fullfile( 'mpp', 'torso-figures' ) ); end

try
  %% The heart for the mean shape
  HEART0 = read_VTK( fullfile( TORSO_MODEL_DIR , 'HEART.vtk' ) );
  % and the center of the Heart0
  centerH0 = mean( HEART0.xyz , 1 );
  
  centerH = [];
  if isempty( centerH ), try, centerH = Loadv( 'HEARTmesh' , 'HEART' );      centerH = mean( centerH.xyz , 1 ); end; end
  if isempty( centerH ), try, centerH = read_VTK( Fullfile( 'HEART.vtk' ) ); centerH = mean( centerH.xyz , 1 ); end; end
  if isempty( centerH ), try, [~,centerH] = MeshVolume( struct('xyz', ecgI.nodes ,'tri', ecgI.mesh ) ); end; end
  if isempty( centerH ), try
      HS_ = [];
      if isempty( HS_ ), try, HS_ = Loadv('HS','HS'); end; end
      if isempty( HS_ ), try, HS_ = Loadv('HC','HC'); HS_ = HS_(:,1); end; end
      
      A = []; B = [];
      for r = 1:size(HS_,1) %unique( round( linspace(1,size(IS,1),10) ))
        for s = 1:r-1
          IL = intersectionLine( HS_{r,1} , HS_{s,1} );
          if isempty( IL ), continue; end
          
          a = IL(1,:).'; b = IL(2,:).';
          b = a+(b-a)/fro(b-a);
          
          A = [ A ; ( eye(3) - (b-a)*(b-a)' )   ];
          B = [ B ; ( eye(3) - (b-a)*(b-a)' )*a ];
          clear IL a b;
        end
      end
      % This is the point closest to all the intersection lines between the slices
      centerH = (A.'*A) \ ( A.'*B );
      clear HS_ A B;
    end; end
  
  if isempty( centerH ), error('toCatch'); end
  % The translation for placing the body model in "subject's coordinates"
  R = maketransform( 't' , -centerH0 , 't' , centerH  );
  
  clear HEART0 centerH0 centerH;
catch
  error('Impossible to compute initial R');
  R = [];
end

try, BC = Loadv( 'BC'  , 'BC'  ); catch
try, BC = Loadv( 'BC1' , 'BC1' ); catch
     BC = Loadv( 'BC0' , 'BC0' ); end; end

%% The torso contours

if Torso_figures
  figure( 'units', 'normalized', 'outerposition', [0 0 1 1])
  plotMESH( transform(Mb_(0), R), 'ne', 'FaceAlpha', 0.1, 'dull'); headlight
  hplot3d( BC(:,2), 'b', 'LineWidth', 1.5);
  
  savefig( gcf , Fullfile( 'mpp', 'torso-figures', 'Torso_contours.fig' ) );
  % fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_contours.png' ) );
  % view(0,0);    fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_contours_cor.png' ) );
  % view(-90,0);  fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_contours_sag.png' ) );
  % view(-90,90); fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_contours_ax.png'  ) );
  close(gcf);
  
  % showSlices( BC(:,1:2) ); axis equal
  % fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_all_slices_3D.png' ) ); close(gcf);
  % hFig = figure('units','normalized','outerposition',[0 0 1 1]); MontageHeartSlices( BC , hFig );
  % fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_all_slices_Montage.png' ) ); close(gcf);
  clear fr; pause(0.5);
end

%%
%P = cell2mat( BC(:,2) ); P( any( ~isfinite(P) ,2) ,:) = [];

P = BC(:,2); P( cellfun('isempty',P) ) = []; P = polyline( P{:} );
for p = 1:P.np, P(p) = resample( P(p) , 'e+' , 1 ); end
P = cell2mat( P.coordinates.' );
try, P = FarthestPointSampling( P , 1 , 5 , Inf , [] , false ); catch
try, P = FarthestPointSampling( P , 1 , 5 , Inf , false ); catch
     P = FarthestPointSampling( P , 1 , 5 ); end; end

q = [];

if Torso_figures
  figure('units','normalized','outerposition',[0 0 1 1])
  plotMESH( transform( Mv_(0) , R ),'ne','FaceAlpha',0.5,'gouraud','dull'); headlight
  [~,cp] = ClosestElement( transform( Mv_(q) , R ) , P );   %projections on the mesh
  hplot3d( P ,'o1rr3'); hplot3d( cp ,'o1kk2'); hplot3d( P , cp , '-' );
  savefig( gcf , Fullfile( 'mpp', 'torso-figures', 'Torso_closest_element.fig' ) );
  % [F_cor,F_sag,F_ax] = deal(cell(0,1));
  % view(0,0);    F_cor{1} = getframe(gcf); imwrite(F_cor{1}.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_closest_element_cor.png' ) );
  % view(-90,0);  F_sag{1} = getframe(gcf); imwrite(F_sag{1}.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_closest_element_sag.png' ) );
  % view(-90,90); F_ax{1}  = getframe(gcf); imwrite(F_ax{1}.cdata,  Fullfile( 'mpp', 'torso-figures', 'Torso_closest_element_ax.png'  ) );
  close(gcf); clear cp; pause(0.5);
end

% Find the best "q" and "R" such that transform( Mv_(q) ,R) is closest to
% the points P with q up to 40 parameters
while numel( q ) < 40
  if ~rem( numel(q)+1 , 5 ), R = {R}; end
  [q,R] = fitSSM( Mv_  , @(rt){'rx',rt(1),'t',rt(2:4)} , P , 2^2   , [q;0] , R , 'RANGE' , 5 );
  
  % if Torso_figures
  %   figure('units','normalized','outerposition',[0 0 1 1])
  %   plotMESH( transform( Mv_(q) , R ) , 'ne' , 'FaceAlpha' , 0.5 , 'gouraud' , 'dull' ); headlight
  %   [~,cp] = ClosestElement( transform( Mv_(q) , R ) , P );
  %   hplot3d( P ,'o1rr3'); hplot3d( cp ,'o1kk2'); hplot3d( P , cp , '-' );
  %   view(0,0);    F_cor{end+1} = getframe(gcf);
  %   view(-90,0);  F_sag{end+1} = getframe(gcf);
  %   view(-90,90); F_ax{end+1}  = getframe(gcf); close(gcf); clear cp; pause(0.5);
  % end
end

% if Torso_figures
%   v = VideoWriter( Fullfile( 'mpp', 'torso-figures', 'torso_optimize_cor' ), 'Uncompressed AVI' );
%   v.FrameRate = 1; open(v); for it = 1:length(F_cor), writeVideo(v,F_cor{it}); end; close(v);
%   v = VideoWriter( Fullfile( 'mpp', 'torso-figures', 'torso_optimize_sag' ), 'Uncompressed AVI' );
%   v.FrameRate = 1; open(v); for it = 1:length(F_sag), writeVideo(v,F_sag{it}); end; close(v);
%   v = VideoWriter( Fullfile( 'mpp', 'torso-figures', 'torso_optimize_ax'  ), 'Uncompressed AVI' );
%   v.FrameRate = 1; open(v); for it = 1:length(F_ax),  writeVideo(v,F_ax{it});  end; close(v);
%   clear F_cor F_sag F_ax v;
% end

BODY = transform( Mb_(q) , R );
VEST = transform( Mv_(q) , R );

if Torso_figures
  figure('units','normalized','outerposition',[0 0 1 1])
  plotMESH( BODY , 'ne' , 'FaceAlpha' , 0.5 , 'gouraud' , 'dull' );
  hplotMESH( VEST , 'r'  , 'ne' , 'FaceAlpha' , 0.5 , 'gouraud' , 'dull' ); headlight
  [~,cp] = ClosestElement( VEST , P );
  hplot3d( P ,'o1rr3'); hplot3d( cp ,'o1kk2'); hplot3d( P , cp , '-' );
  savefig( gcf , Fullfile( 'mpp', 'torso-figures', 'Body_opt.fig' ) );
  % view(0,0);    fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Body_opt_cor.png' ) );
  % view(-90,0);  fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Body_opt_sag.png' ) );
  % view(-90,90); fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Body_opt_ax.png'  ) );
  close(gcf);
  
  figure('units','normalized','outerposition',[0 0 1 1])
  plotMESH( VEST , 'r'  , 'ne' , 'FaceAlpha' , 0.5 , 'gouraud' , 'dull' ); headlight
  hplot3d( P ,'o1rr3'); hplot3d( cp ,'o1kk2'); hplot3d( P , cp , '-' );
  savefig( gcf , Fullfile( 'mpp', 'torso-figures', 'Torso_opt.fig' ) );
  % view(0,0);    fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_opt_cor.png' ) );
  % view(-90,0);  fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_opt_sag.png' ) );
  % view(-90,90); fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Torso_opt_ax.png'  ) );
  close(gcf); clear cp; pause(0.5);
end

%% Final refinement
% Perform a series of smooth deformations to push the body mesh closer to the torso points
BODYr = BODY; VESTr = VEST; Pr = P;
for it = 1:20
  [~,cp] = ClosestElement( BODYr , Pr ); dist = fro(cp-Pr,2); mean(dist)
  thres = max(min(prctile(dist,95), 25), 15); Pr = Pr(dist < thres,:); cp = cp(dist < thres,:);
  
  VESTr.xyz = InterpolatingSplines( cp , cp + ( Pr - cp )*0.1 , VESTr.xyz , 'r','lambda',size(Pr,1)*1e3);
  BODYr.xyz = InterpolatingSplines( cp , cp + ( Pr - cp )*0.1 , BODYr.xyz , 'r','lambda',size(Pr,1)*1e3);
  clear cp dist thres;
end

if Torso_figures
  figure('units','normalized','outerposition',[0 0 1 1])
  plotMESH(  BODYr , 'ne', 'FaceAlpha' ,0.5 , 'gouraud' , 'dull' );
  hplotMESH( VESTr , 'r'  , 'ne' , 'FaceAlpha' , 0.5 , 'gouraud' , 'dull' ); headlight
  [~,cp] = ClosestElement( BODYr , P );
  hplot3d( P ,'o1rr3'); hplot3d( cp ,'o1kk2'); hplot3d( P , cp , '-' );
  savefig( gcf , Fullfile( 'mpp', 'torso-figures', 'Body_final.fig' ) );
  % view(0,0);    fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Body_final_cor.png' ) );
  % view(-90,0);  fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Body_final_sag.png' ) );
  % view(-90,90); fr = getframe(gcf); imwrite(fr.cdata, Fullfile( 'mpp', 'torso-figures', 'Body_final_ax.png'  ) );
  close(gcf); clear cp; pause(0.5);
end

BODY = BODYr; VEST = VESTr;
clear BODYr VESTr Pr it;

%% fix the BODY surface
ring = [87;948;996;999;1005;1007;1008;1016;1023;1024;1040;1041;1044;1045;1179;3197;3199;3203;3204;3205;3206;4165;4213;4218;4220;4222;4224;4225;4240;4249;4253;4255;4256;4258;4262;6321;6327;6329;6331;6336;6337];

[Z,iZ] = getPlane( BODY.xyz( ring , : ) );
%w = transform( FacesCenter(BODY) , iZ ) *[0;0;1] > 0;
w = meshFacesCenter(BODY) * iZ(3,1:3).' + iZ(3,4) > 0;

B = BODY; U = BODY;
B.tri( w,:) = []; U.tri( ~w,:) = [];
C = MeshTidy( U , -1 );
C.tri = convhulln( C.xyz );
C.tri( meshNormals( MeshFixCellOrientation( C ) )*[0;0;1] < 0 , : ) = [];
C = MeshTidy( C );

[~,~,d] = vtkClosestElement( C , meshFacesCenter( U ) );
U.tri( d > 1 , : ) = [];

BODY = vtkFillHolesFilter( MeshTidy( MeshAppend( B , U ) ,0,true) );
BODY = MeshFixCellOrientation( MeshTidy( BODY ,0,true) );
%BODY = MeshFillHoles( SolveSelfIntersections( BODY , 'remove' ) );

clear ring Z iZ w B U C d;

%%
[vID,cp,d] = vtkClosestPoint( BODY , VEST.xyz ); range( d )
BODY = SolveSelfIntersections( BODY , 'smooth' );
VEST.xyz = BODY.xyz( vID , : );
clear vID cp d;

%%
Save( 'fittedVEST.mat' , 'q' , 'R' , 'VEST' , 'BODY' , 'P' );

%%

write_VTP( VEST , Fullfile( 'mpp' , 'VEST0.vtk' ) ,'ascii');
write_VTP( BODY , Fullfile( 'mpp' , 'BODY0.vtk' ) ,'ascii');

% hFig = Figure(); plotMESH( transform( Mv_(q) , R ) );
% hplotMESH( transform( Mb_(q) , R ) ,'FaceColor','none');
% hplot3d( P ,'.r'); axis(objbounds);
% Savefig( hFig , 'Fit Vest' );

clear q R P VEST BODY Mv_ Mb_ BC Torso_figures;

%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue