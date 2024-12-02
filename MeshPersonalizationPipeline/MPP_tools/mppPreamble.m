function mppPreamble( fn )

if nargin < 1
  mppPreamble mpp_Read_DICOMs
  mppPreamble mpp_Subject_Data
  mppPreamble mpp_Select_Heart_Slices
  mppPreamble mpp_Read_Heart_Contours
  mppPreamble mpp_Register_Heart_Slices
  mppPreamble mpp_Automatic_Contours
  mppPreamble mpp_Manual_Contour_Heart
  mppPreamble mpp_Fix_Heart_Contours
  mppPreamble mpp_Square_Heart_Slices
  mppPreamble mpp_Adapt_SSM
  mppPreamble mpp_Align_to_Adapted
  mppPreamble mpp_Align_Heart_Contours
  mppPreamble mpp_Build_Heart_Meshes
  mppPreamble mpp_Heart_Fiducials
  mppPreamble mpp_4Chamber_Model
  mppPreamble mpp_Final_Heart_Meshes
  mppPreamble mpp_Heart_Mapping
  mppPreamble mpp_Build_Heart_Tetras
  mppPreamble mpp_On_Table_Manequin

  mppPreamble mpp_Get_AllPosition_Images
  mppPreamble mpp_Manual_Contour_Torso
  mppPreamble mpp_Fit_Vest
  mppPreamble mpp_ECG_Electrodes
  mppPreamble mpp_Final_Torso_Meshes

  mppPreamble mpp_Build_Torso_Tetras
  
  return;
end


  ffn = which( fn );
  if isempty( ffn ), error('''%s'' file doesn''t exist'); end

  PREAMBLE = readFile( which( mfilename('fullpath') ) );
  PREAMBLE = cellfun(@strtrim,PREAMBLE,'un',false);
  PREAMBLE = PREAMBLE( find( ~cellfun('isempty',strfind( PREAMBLE , '%% START mpp_preamble' )) ,1,'last'):...
                       find( ~cellfun('isempty',strfind( PREAMBLE , '%% END mpp_preamble'   )) ,1,'last') );
  for l = 2:numel( PREAMBLE )-1
    L = PREAMBLE{l};
    if isempty( L ), continue; end
    if L(1) == '%', PREAMBLE{l} = ''; continue; end
    if L(end) == ',', continue; end
    if L(end) == ';', continue; end
    L = [ L , ';' ];
    PREAMBLE{l} = L;
  end
  PREAMBLE( cellfun('isempty',PREAMBLE) ) = [];
  PREAMBLE = [ PREAMBLE(1) ; [  PREAMBLE{2:end-1} ] ; PREAMBLE(end) ];


  EPILOGUE = readFile( which( mfilename('fullpath') ) );
  EPILOGUE = cellfun(@strtrim,EPILOGUE,'un',false);
  EPILOGUE = EPILOGUE( find( ~cellfun('isempty',strfind( EPILOGUE , '%% START mpp_epilogue' )) ,1,'last'):...
                       find( ~cellfun('isempty',strfind( EPILOGUE , '%% END mpp_epilogue'   )) ,1,'last') );
  for l = 2:numel( EPILOGUE )-1
    L = EPILOGUE{l};
    if isempty( L ), continue; end
    if L(1) == '%', EPILOGUE{l} = ''; continue; end
    if L(end) == ',', continue; end
    if L(end) == ';', continue; end
    L = [ L , ',' ];
    EPILOGUE{l} = L;
  end
  EPILOGUE( cellfun('isempty',EPILOGUE) ) = [];
  EPILOGUE = [ EPILOGUE(1) ; [  EPILOGUE{2:end-1} ] ; EPILOGUE(end) ];


  fn = readFile( ffn );

  s0 = find( ~cellfun('isempty',strfind( fn , '%% START mpp_preamble' )) ,1,'last'); if isempty(s0), s0 = 0; end
  s1 = find( ~cellfun('isempty',strfind( fn , '%% END mpp_preamble'   )) ,1,'last'); if isempty(s1), s1 = 0; end
  fn = [ fn(1:s0-1) ; PREAMBLE ; fn(s1+1:end) ];


  s0 = find( ~cellfun('isempty',strfind( fn , '%% START mpp_epilogue' )) ,1,'last'); if isempty(s0), s0 = numel(fn); end
  s1 = find( ~cellfun('isempty',strfind( fn , '%% END mpp_epilogue'   )) ,1,'last'); if isempty(s1), s1 = numel(fn); end
  fn = [ fn(1:s0-1) ; EPILOGUE ];

  fid = fopen(ffn,'w');
  cellfun( @(s)fprintf(fid,'%s\n',s) , fn(1:end-1) );
  cellfun( @(s)fprintf(fid,'%s',s)   , fn(  end  ) );
  fclose( fid );


end













































function kkkk



%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR)
  fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);
  return;
end
if ~exist('SUBJECT_DIR','var')
  fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');
  return;
end
if ~ischar(SUBJECT_DIR)
  fprintf(2,'Invalid ''SUBJECT_DIR''.\n');
  return;
end
while SUBJECT_DIR(end) == filesep
  SUBJECT_DIR(end) = [];
end
try
  checkBEAT(SUBJECT_DIR);
catch
  fprintf(2,'Cannot check BEAT\n');
  return;
end
if ~isdir(SUBJECT_DIR)
  fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);
  return;
end
if isfile(Fullfile('RUNNING'))
  fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );
  clear('OUTPUT_FILES');
  return;
end

WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');
printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);
pause(1);
NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});
NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];
if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES))
else
  %   if 0,
  %     diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');
  %     fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));
  %     fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);
  %     fprintf('\n');
  %     cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);
  %     fprintf('\nMPP step ''%s'' already done. Skipping.\n',WHERE_AM_I);
  %     fprintf( '%s\n\n\n',repmat('-',1,80));
  %     diary('off');
  %   else,
  fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);
  cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);
  fprintf('\n');
  %   end;
  keepvars(NAME_OF_VARIABLES_TO_KEEP);
  try
    delete(Fullfile('RUNNING'));
  end
  return;
end
CWD__=pwd;
START__=now;
fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);
diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');
fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));
fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);
fprintf('\n');
fprintf('%s\n\n',repmat('.',1,80));
if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES))
  fprintf('\n=========================================\n');
  fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );
  for f = OUTPUT_FILES(:), f = f{1};
    fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );
    try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end
  end
  fprintf('=========================================\n\n');
end
MPP_BROKEN=true;
try
%% END mpp_preamble

%% 
%% 
%% 
%% The MPP_SCRIPT cames here!
%% 
%% 
%% 


%% START mpp_epilogue
fprintf('\n\n')
fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end
fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);
catch LastError;
  MPP_ERROR = WHERE_AM_I;
  fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;
  fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));
  fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
  fprintf(2,'%s\n',getReport(LastError));
  fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');
  try
    ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );
    fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );
    fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );
    fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );
    fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');
    fprintf(ferr,'%s\n',getReport(LastError));
    fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');
    fclose( ferr );
    fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );
  end
end
checkBEAT(SUBJECT_DIR);
fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );
fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));
fprintf('%s\n\n\n',repmat('-',1,80));
checkBEAT(SUBJECT_DIR);
diary('off');
if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508')
  executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);
end;
cd(CWD__);
keepvars(NAME_OF_VARIABLES_TO_KEEP);
w_s___ = warning('off','MATLAB:DELETE:FileNotFound');
try,delete(Fullfile('RUNNING'));end
warning(w_s___);clear('w_s___');
return;
%% END mpp_epilogue

end