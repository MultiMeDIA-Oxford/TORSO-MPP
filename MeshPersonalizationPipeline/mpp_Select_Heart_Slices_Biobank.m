%Select Heart Slices
OUTPUT_FILES = {'mpp/HS.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble


if isfile( Fullfile('mpp','HS.tmp') )

  HS = Loadv( 'HS.tmp' , 'HS' );
  
  Save( 'HS.mat' , 'HS' );
  
  delete( Fullfile('mpp','HS.tmp') );
  
else

try
  
  mppOption REDO_LIST   false;
  if REDO_LIST  &&  exist( 'MPP_FORCE', 'var')   &&  MPP_FORCE
    error('jump skip to catch');
  end
  
  HS = Loadv( 'HS' , 'HS' );
  
catch

% if ~exist( 'HEART_SLICES_list','var' )
  HEART_SLICES_list = Fullfile('HeartSlices.list');
% end


DICOMs = Loadv( 'DICOMs' , 'DICOMs' );

%%

mppOption REDO_LIST   false;

if REDO_LIST   ||  ~isfile( HEART_SLICES_list )  %to prepare the list
  D = DICOMs;
  D = D.( getv( fieldnames(D) , { find( strncmp( fieldnames(D) , 'Patient_' , 8 ) ,1) } ) );
  D = D.( getv( fieldnames(D) , { find( strncmp( fieldnames(D) , 'Study_' , 6   ) ,1) } ) );
  
  for f = fieldnames( D ).', f = f{1};
    if ~strncmp( f , 'Serie_N',7 ), continue; end
    O = fieldnames( D.(f) );         O( ~strncmp( O , 'Orientation_', 12 ) ) = [];
    if numel( O ) ~= 1, D = rmfield( D , f ); continue; end
    P = fieldnames( D.(f).(O{1}) );  P( ~strncmp( P , 'Position_', 9 ) ) = [];
    P( strcmp( P , 'Position_unknow' ) ) = [];
    %if numel( P ) ~= 1, D = rmfield( D , f ); continue; end
    if numel( P ) >= 40, D = rmfield( D , f ); continue; end
  end
  
  SS = fieldnames( D ); SS( ~strncmp(SS,'Serie_N',7) ) = [];
  SS = cellfun(@(ss)sscanf( ss , 'Serie_N%d') , SS );
  
  fid = fopen( HEART_SLICES_list , 'w');
  fprintf(fid,'%%PlaneName   SeriesNumber   EndDiastole    %%Comments\n\n');
  plane = {'LAX_4Ch','LAX_2Ch','LAX_3Ch','SAX_b'};
  for h = SS(:).'
    condn = find( ~cellfun( @isempty, cellfun(@(x) strfind(D.(sprintf('Serie_N%03d',h)).zSeriesDescription,x), plane, 'UniformOutput', false ) ) );
    if ~isempty(condn)
        switch condn
            case 1, PlaneName = 'HLA';  Comment = '';
            case 2, PlaneName = 'VLA';  Comment = '';
            case 3, PlaneName = 'LVOT'; Comment = '';
            case 4, PlaneName = 'SAX';  Comment = sprintf( ' at z=%.1f' , D.(sprintf('Serie_N%03d',h)).Orientation_01.Position_001.IMAGE_001.info.xZLevel );
        end
        fprintf(fid,'"%s"%s%02d             1            %%%s\n',PlaneName,blanks(13-numel(PlaneName)),h,Comment);
    end
  end
  fclose(fid);
end

%%

SS = DICOMs;

SS = SS.( getv( fieldnames(SS) , { find( strncmp( fieldnames(SS) , 'Patient_' , 8 ) ,1) } ) );
SS = SS.( getv( fieldnames(SS) , { find( strncmp( fieldnames(SS) , 'Study_' , 6   ) ,1) } ) );

%%

fprintf('Reading LIST  ("%s") ...', HEART_SLICES_list );

fid = 0;
try
  fid = fopen( HEART_SLICES_list , 'r' );
  LIST = textscan( fid , '%s %s %d' , 'CommentStyle' , {'%'} , 'MultipleDelimsAsOne' , true );
  fclose( fid ); fid = 0;
catch
  if fid, fclose(fid); end
  error('HEART_SLICES_list file improper or not provided.');
end

[~,id] = unique( LIST{2} , 'first' );
id = setdiff( 1:numel(LIST{2}) , id );
for h = id(:).'
  warning('SeriesNumber of element %d of the HEART_SLICES_list is repeated, keeping only its first appearance',h );
end

LIST{1}(id) = [];
LIST{2}(id) = [];
LIST{3}(id) = [];

fprintf(' OK\n');

%%

HS = {};
for h = 1:size(LIST{1},1)
  I = [];
  try
    SN = LIST{2}(h);
    if iscell( SN ), SN = SN{1}; end
    if ischar( SN )
      SN_ = str2double( SN );
      if ~isnan( SN_ ), SN = SN_; end
    end
    
    if ~ischar( SN )
      renameSN = [];
      fprintf('Loading SeriesNumber %3d    (%2d of %d)\n', SN , h , size(LIST{1},1) );
      SN = SS.(sprintf('Serie_N%03d',SN));
      
    else
      renameSN = SN;
      fprintf('Loading  "%s"    (%2d of %d)\n', SN , h , size(LIST{1},1) );
      
      s = SN( 1:find( SN == '.' ,1)-1 ); SN( 1:numel(s)+1 ) = []; s = str2double( s );
      o = SN( 1:find( SN == '.' ,1)-1 ); SN( 1:numel(o)+1 ) = []; o = str2double( o );
      p = str2double( SN );
      
      SN = SS.(sprintf('Serie_N%03d',s)).(sprintf('Orientation_%02d',o)).(sprintf('Position_%03d',p));
    end
    
    I = DCMload( SN );
    if size(I,3) ~= 1
      error('it is not a single slice');
    end

    ED = LIST{3}(h);
    I.data = I.data(:,:,:,[ ED:end , 1:ED-1 ] );
    dummy = I.INFO.SLICES_INFO([ ED:end , 1:ED-1 ]);
    I.INFO = mergestruct( I.INFO.SLICES_INFO{ED} , I.INFO.DICOM_INFO );
    I.INFO.SLICES_INFO = dummy;
    I.INFO.xPhase = [ ED , size( I , 4 ) ];

    PlaneName = LIST{1}{h};
    PlaneName = regexprep( PlaneName , '^"?([^"]*)"?$' , '$1' );
    I.INFO.PlaneName = PlaneName;
    
    if ~isempty( renameSN )
      I.INFO.SeriesNumber = renameSN;
    end
    
    HS{end+1,1} = I;
  catch LE
    warning('error with the element %d of the HEART_SLICES_list.',h);
    fprintf('------------------------------\n');
    disperror( LE );
    fprintf('------------------------------\n\n');
  end
end

%%

SAid = strncmpi( cellfun( @(I)I.INFO.PlaneName , HS ,'un',0) , 'SAX' , 3 );
SA   = HS(  SAid ,:); if isempty( SA ), SA = {[]}; end
HS   = HS( ~SAid ,:);

HLAid = strncmpi( cellfun( @(I)I.INFO.PlaneName , HS ,'un',0) , 'HLA' , 3 );
HLA   = HS(  HLAid ,:); if isempty( HLA ), HLA = {[]}; end
HS    = HS( ~HLAid ,:);

VLAid = strncmpi( cellfun( @(I)I.INFO.PlaneName , HS ,'un',0) , 'VLA' , 3 );
VLA   = HS(  VLAid ,:); if isempty( VLA ), VLA = {[]}; end
HS    = HS( ~VLAid ,:);

LVOTid = strncmpi( cellfun( @(I)I.INFO.PlaneName , HS ,'un',0) , 'LVOT' , 4 );
LVOT   = HS(  LVOTid ,:); if isempty( LVOT ), LVOT = {[]}; end
HS     = HS( ~LVOTid ,:);

[~,ord] = sort( cellfun( @(I)I.INFO.xZLevel , SA ) , 'descend' ); SA = SA(ord);
% ulevel = unique(cellfun( @(I)I.INFO.xZLevel , SA ),'stable');
ZLevel = round( cellfun( @(I) I.INFO.xZLevel , SA )*1e4 )/1e4;
ulevel = unique( ZLevel, 'stable' ); ordN = zeros(length(ulevel),1);
for ii = 1:length(ulevel)
  dummy = ZLevel == ulevel(ii);
  if sum(dummy) > 1
    idum = find(dummy); tdum = cell2mat(cellfun( @(I)I.INFO.AcquisitionTime , SA(idum), 'UniformOutput', false ));
    [~,idx] = max(str2num(tdum)); ordN(ii) = idum(idx);
  else
    ordN(ii) = find(dummy);
  end
end
SA = SA(ordN);
[~,ord] = sort( cellfun( @(I)I.INFO.xZLevel , SA ) , 'ascend' ); SA = SA(ord); clear ord;

if any( HLAid), [~,ord] = sort( str2num(cell2mat(cellfun( @(I)I.INFO.AcquisitionTime ,  HLA, 'UniformOutput', false ))) , 'descend' );  HLA =  HLA(ord); clear ord; end
if any( VLAid), [~,ord] = sort( str2num(cell2mat(cellfun( @(I)I.INFO.AcquisitionTime ,  VLA, 'UniformOutput', false ))) , 'descend' );  VLA =  VLA(ord); clear ord; end
if any(LVOTid), [~,ord] = sort( str2num(cell2mat(cellfun( @(I)I.INFO.AcquisitionTime , LVOT, 'UniformOutput', false ))) , 'descend' ); LVOT = LVOT(ord); clear ord; end

HS = [ HLA(1) ; VLA(1) ; LVOT(1) ];
if length(HLA)  > 1, HS = [ HS;  HLA(2:end)]; end
if length(VLA)  > 1, HS = [ HS;  VLA(2:end)]; end
if length(LVOT) > 1, HS = [ HS; LVOT(2:end)]; end
HS = [ HS ; SA ];

%%

Save( 'HS.mat' , 'HS' );

end

end
%%

MontageHeartSlices( HS ); Figure(gcf);
Export_fig( gcf , Fullfile( 'Montage_slices.png' ) ,'-png','-a1');
% ExportMontage( gcf , Fullfile( 'mpp','HR','Montage_slices.png' ) );
while getv( dir(  Fullfile( 'Montage_slices.png' ) ) ,'.bytes' ) < 1, end; pause(1);
copyfile(         Fullfile( 'Montage_slices.png' ) , Fullfile( 'mpp' , 'Montage_slices.png' ) );
Savefig( [] , 'Montage_slices' );

mppOption MAKE_VIDEO true
if MAKE_VIDEO
  fprintf('Making Video ... ' );
  try, MontageVideo_AB( HS , Fullfile('mpp','montage_video') ); end
  fprintf('done.\n' );
end

%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue