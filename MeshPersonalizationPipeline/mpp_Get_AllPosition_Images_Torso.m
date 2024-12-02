%% Get AllPosition Images
OUTPUT_FILES = {'mpp/BS.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

DICOMs = Loadv( 'DICOMs.mat' ,'DICOMs' );

Pat1 = fieldnames( DICOMs );
Pat1 = Pat1{1};
DICOMs = DCMselect( DICOMs , @(i,f)isequal( f{1} , Pat1 ) && prod( i.xSize ) && isempty( regexpi( i.SeriesDescription , 'molli' ) ) && isempty( regexpi( i.SeriesDescription , 'tagging' ) )  );

IMs = DCMgetimages( DICOMs , 'withDATA' );

PositionList  = cat(1,IMs.LOCATIONS);
PositionList(:,6) = [];
[~,ids] = unique( arrayfun( @(r)[ PositionList{r,:} ] , ( 1:size(PositionList,1) ).' , 'Un',0 ) , 'first' );
w = sort( ids );

BS = cell(0,1);  %BS stands for BodySlices
for i = w(:).'
  try
  DIC = IMs(i);

  I = DIC.DATA;
  H = DIC.INFO;
%   H = kpfields( H , {'MediaStorageSOPInstanceUID','SeriesInstanceUID','SeriesDescription','PatientName','PatientID''PatientBirthDate','PatientSex','PatientAge','PatientSize','PatientWeight','SequenceName','PatientPosition','SeriesNumber','ImagePositionPatient','ImageOrientationPatient','SliceLocation','PixelSpacing','xDirname','xFilename','xPatientName','xDatenum','xSize','xSpatialTransform'} );

  BS{end+1,1} = I3D( { I , H } );
  end
end

for i = 1:size(BS,1)
  BS{i,1}.INFO.PlaneName = '?';
  try
    vn = slicePlaneName( BS{i,1} );
    if any( strcmpi( vn , {'ax','cor','sag'} ) )
      BS{i,1}.INFO.PlaneName = vn;
    end
  end
end

try
HS = [];
if isempty(HS), try, HS = Loadv( 'HS'  , 'HS'  ); end; end
if isempty(HS), try, HS = Loadv( 'HC'  , 'HC'  ); end; end
if isempty(HS), try, HS = Loadv( 'HC0' , 'HC0' ); end; end
if isempty(HS), try, HS = Loadv( 'HCm' , 'HCm' ); end; end
HS( cellfun('isempty',HS(:,1)) ,:) = [];

w = ismember( arrayfun( @(i)BS{i,1}.INFO.SeriesInstanceUID , 1:size(BS,1) , 'un',0) ,...
              arrayfun( @(i)HS{i,1}.INFO.SeriesInstanceUID , 1:size(HS,1) , 'un',0) );
BS(w,:) = [];
BS = [ BS ; HS(:,1) ];
end

%reordering them!
w = ~cellfun( 'isempty' , regexpi( arrayfun( @(i)BS{i,1}.INFO.SeriesDescription , 1:size(BS,1) , 'un',0) , 'pilo' ) );
BS = [ BS( w ,:) ; BS( ~w ,:) ];

w = ~cellfun( 'isempty' , regexpi( arrayfun( @(i)BS{i,1}.INFO.SeriesDescription , 1:size(BS,1) , 'un',0) , 'cine' ) );
BS = [ BS( w ,:) ; BS( ~w ,:) ];

w = sum( ~cell2mat( arrayfun( @(i)BS{i,1}.INFO.ImageOrientationPatient.' , 1:size(BS,1) , 'un',0)' ) ,2) > 2;
BS = [ BS( w ,:) ; BS( ~w ,:) ];

try
% HS = [];
% if isempty(HS), try, HS = Loadv( 'HC' , 'HC' ); end; end
% if isempty(HS), try, HS = Loadv( 'HS' , 'HS' ); end; end
% HS( cellfun('isempty',HS(:,1)) ,:) = [];
w = ismember( arrayfun( @(i)BS{i,1}.INFO.SeriesInstanceUID , 1:size(BS,1) , 'un',0) ,...
              arrayfun( @(i)HS{i,1}.INFO.SeriesInstanceUID , 1:size(HS,1) , 'un',0) );

BS = [ BS( w ,:) ; BS( ~w ,:) ];
end

w = ~cellfun( 'isempty' , regexpi( arrayfun( @(i)BS{i,1}.INFO.SeriesDescription , 1:size(BS,1) , 'un',0) , 'loc' ) );
BS = [ BS( w ,:) ; BS( ~w ,:) ];



%%

Bidx = 1:size( BS , 1 );
try
  AXs = cellfun( @(I)strcmp(I.INFO.PlaneName,'AX') , BS(:,1) );
  AXs = bwlabeln( AXs );
  SNs = cellfun( @(I)I.INFO.SeriesNumber , BS(:,1) );
  SNs( ~AXs ) = 0;
  AXs = AXs + SNs*max(SNs);
  
  for a = unique( AXs ).'
    if ~a, continue; end
    w = AXs == a;
    if sum( w ) == 1, continue; end
     Zs = cellfun( @(I)I.INFO.xZLevel , BS(w,1) );
    [Zs,ord] = sort( Zs , 'descend' );
    w = find(w);
    Bidx(w) = Bidx(w(ord));
  end
end
BS = BS(Bidx,:);


%%

fileID =fopen(strcat(SUBJECT_DIR,'\TORSO_try.list'),'w');
for i = 1:numel(BS)
    
   fprintf(fileID,'%3d -  ' , i );
   fprintf(fileID,'%03d.' , BS{i}.INFO.SeriesNumber );
   fprintf(fileID,'%s  ' , BS{i}.INFO.SeriesDescription );
   fprintf(fileID,'%s  ' , BS{i}.INFO.PlaneName );
   fprintf(fileID,'(%g)' , BS{i}.INFO.xZLevel );
   fprintf(fileID,'\n');
end
fclose(fileID);

%% perform some pruning of the whole list of images
accepted_torso_images = []; check = {'InlineVF','Thorax'};
fileID =fopen(strcat(SUBJECT_DIR,'\TORSO_filtered.list'),'w');
for i = 1:numel(BS)
  condn = find( ~cellfun( @isempty, cellfun(@(x) strfind(BS{i}.INFO.SeriesDescription,x), check, 'UniformOutput', false )));
  if isempty(condn)
    same = 0;
    if i>1 && BS{i}.INFO.SeriesNumber == BS{i-1}.INFO.SeriesNumber
      if abs(BS{i}.INFO.xZLevel - BS{i-1}.INFO.xZLevel) < 5,  same = 1; end
    end
    try, distance = BS{i}.INFO.xZLevel - BS{i-1}.INFO.xZLevel; catch, distance = 0; end
    if same == 0 || abs(distance) > 40 || ~isempty(strfind(BS{i}.INFO.SeriesDescription,'Loca'))
       fprintf(fileID,'%3d -  ' , i );
       fprintf(fileID,'%03d.' , BS{i}.INFO.SeriesNumber );
       fprintf(fileID,'%s  ' , BS{i}.INFO.SeriesDescription );
       fprintf(fileID,'%s  ' , BS{i}.INFO.PlaneName );
       fprintf(fileID,'(%g)' , BS{i}.INFO.xZLevel );
       fprintf(fileID,'\n');
       accepted_torso_images = [accepted_torso_images,i];
    end
  end
end
fclose(fileID);

%%
BS = BS( accepted_torso_images ,:);
Save( 'BS.mat' , 'BS' );

%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue