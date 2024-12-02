%Read DICOMs
OUTPUT_FILES = {'mpp/DICOMs.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

switch mppBranch

case 'hcm'

  V = loadv( Fullfile( HEART_CONTOURS_FILE ) , 'C' ); V = V(:);
  V( ~[ V.parentDICOMfound ] ) = [];

  ALL_DICOMS = loadv( 'H:\RINA_HCM_MRIs\ALL_DICOMS' , 'DICOMS' );
  for d = 1:numel( ALL_DICOMS )
    if isempty( ALL_DICOMS(d).Filename ), continue; end
    ALL_DICOMS(d).Filename = strrep( ALL_DICOMS(d).Filename , 'E:\HCMdata_MRIs\' , 'H:\RINA_HCM_MRIs\' );
  end

  pID = unique( { V.parentPatientID } );
  if numel( pID ) ~= 1, error('more than 1 PatientID'); end
  pID = pID{1};
  if ~isempty( pID )
    w = strcmp( { ALL_DICOMS.PatientID }        , pID );
    ALL_DICOMS = ALL_DICOMS( w );
  end

  sID = unique( { V.parentStudyInstanceUID } );
  if numel( sID ) ~= 1, error('more than 1 StudyInstanceUID'); end
  sID = sID{1};
  if ~isempty( sID )
    w = strcmp( { ALL_DICOMS.StudyInstanceUID } , sID );
    ALL_DICOMS = ALL_DICOMS( w );
  end

  if numel( unique( {ALL_DICOMS.PatientID} ) ) ~= 1
    error('not a single PatientID');
  end
  if numel( unique( {ALL_DICOMS.StudyInstanceUID} ) ) ~= 1
    error('not a single StudyInstanceUID');
  end

  ALL_DICOMS = struct('name',{ ALL_DICOMS.Filename } );

  %%

otherwise

  if ~exist('DICOMS_DIR','var')
    DICOMS_DIR = Fullfile( 'DICOMS' );
    fprintf('setting DICOMS_DIR to: %s\n', DICOMS_DIR );
  else
    fprintf('existing DICOMS_DIR : %s\n', DICOMS_DIR );
  end
  
  if ~isdir( DICOMS_DIR )
    error('DICOMS_DIR "%s"  does not exist.',DICOMS_DIR);
  end
  
  fprintf('gathering DICOMS from ''%s''...\n', DICOMS_DIR );
  ALL_DICOMS = DICOMS_DIR;

%%    
end

%gather DICOMs 
fprintf('gathering DICOMS ...\n' );
switch mppBranch
case 'atria'
    DICOMs = DICOMgather_Atria( ALL_DICOMS );
otherwise
    DICOMs = DICOMgatherJC( ALL_DICOMS );
end
fprintf('Done\n\n');

%loading DICOMs DATA
fprintf('loading DATA ...\n' );
DICOMs = DCMthumbnail( DICOMs );
fprintf('Done\n\n');

s = warning('error', 'MATLAB:save:sizeTooBigForMATFile');
warning('error', 'MATLAB:save:sizeTooBigForMATFile');
try
  Save( 'DICOMs' , 'DICOMs' );
catch
  if ~isdir( fullfile( SUBJECT_DIR , 'mpp' ) ), mkdir( fullfile( SUBJECT_DIR , 'mpp' ) ); end
  save( fullfile( SUBJECT_DIR , 'mpp' , 'DICOMs.mat' ) , 'DICOMs' , '-v7.3' );
end
warning(s);

if 0
DCMexplorer( DICOMs , 'nav' );
ecgI_surface = struct('xyz',[],'tri',[]);
try
  ecgI = load(ECGi_result_file); ecgI = ecgI.(getv(fieldnames(ecgI),{1}));

  ecgI_surface = MeshAppend( ecgI_surface , Mesh( ecgI.nodes                     , ecgI.mesh                     ) );
  ecgI_surface = MeshAppend( ecgI_surface , Mesh( ecgI.anatomy.mesh.septum.nodes , ecgI.anatomy.mesh.septum.mesh ) );
  %ecgI_surface = MeshAppend( ecgI_surface , Mesh( ecgI.anatomy.mesh.atria.nodes  , ecgI.anatomy.mesh.atria.mesh  ) );
  %ecgI_surface = MeshAppend( ecgI_surface , Mesh( ecgI.anatomy.mesh.lvot.nodes   , ecgI.anatomy.mesh.lvot.mesh   ) );
  %ecgI_surface = MeshAppend( ecgI_surface , Mesh( ecgI.anatomy.mesh.rvot.nodes   , ecgI.anatomy.mesh.rvot.mesh   ) );
end  
  DCMexplorer( DICOMs , 'FCN',@(i)DCMexplorer_slicemesh(i,ecgI_surface) );
end

%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue