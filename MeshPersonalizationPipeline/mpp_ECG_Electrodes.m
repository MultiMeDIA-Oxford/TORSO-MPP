OUTPUT_FILES = {'mpp/ECG_ELECTRODES.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

mppOption TORSO_MODEL_DIR

LMKS = loadv( fullfile( TORSO_MODEL_DIR , 'LMKS' ) , 'LMKS' );
ELECTRODES = LMKS.Electrodes;

Mv_ = loadv( fullfile( TORSO_MODEL_DIR , 'VEST_MODEL' ) , 'Mv_' );

VEST0 = Mv_(0);
try
  VEST1 = Loadv( 'refined.mat' , 'VEST'  );
catch
  VEST1 = Loadv( 'fittedVEST.mat'  , 'VEST'  );
end

for f = fieldnames( ELECTRODES ).'
  [e,cp,d,c] = vtkClosestElement( VEST0 , ELECTRODES.(f{1}) );
  
  ELECTRODES.(f{1}) = c*VEST1.xyz( VEST0.tri(e,:) , : );
end


if 0
plotMESH( VEST1 );
hplot3d( cell2mat(cellfun(@(f)ELECTRODES.(f),fieldnames(ELECTRODES),'un',0)) , 'ok','markerfacecolor','r' )
end


Save( 'ECG_ELECTRODES.mat'  , 'ELECTRODES'  );

%%


hFig = Figure();
plotMESH( VEST1 );
hplot3d( cell2mat(cellfun(@(f)ELECTRODES.(f),fieldnames(ELECTRODES),'un',0)) , 'ok','markerfacecolor','r' )
Savefig


%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue