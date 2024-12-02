OUTPUT_FILES = {'mpp/BC1.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

BC0 = Loadv( 'BS' , 'BS' );
BC0 = contoursFrom( BC0 , 'BC0' , true );

try, mkdir_( Fullfile( 'mpp' , 'torso-contours-full' ) ); end
for h = 1:size(BC0,1)
  fn = sprintf( '%03d.[%03d-%s](%.1f)', h, BC0{h,1}.INFO.SeriesNumber, BC0{h,1}.INFO.SeriesDescription, BC0{h,1}.INFO.xZLevel);
  fn = Fullfile('mpp','torso-contours-full',[fn,'.png']);    
  S = BC0{h,1}; C = transform(BC0{h,2}, minv(S.SpatialTransform));
  dim = size( S.data(:,:,:,1) ); mask = zeros( dim );
  if ~isempty(C)
    [row,~] = find(isnan(C)); C(unique(row),:) = [];
    pt = round(C(:,1)/S.INFO.PixelSpacing(1)) + dim(1)*(round(C(:,2)/S.INFO.PixelSpacing(2))-1);
    mask( pt ) = 255; mask = permute(mask,[2 1]); clear row pt;
  end
  imwrite(mask,fn); clear S C dim mask;
end

%
mppOption pathfull
setenv('PATH', ['C:\python-venv\torso-2D-seg\Scripts', pathsep, getenv('PATH')]);
system(['"C:\python-venv\torso-2D-seg\Scripts\python" "', pathfull, 'PreTrained\torso_contouring.py"', ' --dir_img ', Fullfile('mpp', 'torso-images'),...
  ' --model_path ', fullfile(pathfull, 'PreTrained', 'torso_cnt_N65_35_cycle_2.pt')]);

%%

BC1 = Loadv( 'BS' , 'BS' );
for ss = 1:size(BC1,1)
  fn = sprintf( '%03d.[%03d-%s](%.1f).png' , ss, BC1{ss,1}.INFO.SeriesNumber, BC1{ss,1}.INFO.SeriesDescription, BC1{ss,1}.INFO.xZLevel);
  fn = Fullfile('mpp', 'torso-contouring', fn );
  seg = imread( fn ); seg = permute(seg,[2 1]);
  
  S = BC1{ss,1}; S = S(:,:,:,1);
  seg = imresize(seg,size(S.data),'nearest'); seg( seg < 128 ) = 0; seg( seg >= 128 ) = 255;
  t = S.SpatialTransform(1:3,4); R = S.SpatialTransform(1:3,1:3);
  
  CC = bwlabel(seg == 255); cnt = [];
  for comp = 1:max(unique(CC))
    [row, col] = find(CC == comp);
    if length(row) > 5
      pt = [S.INFO.PixelSpacing(1)*row S.INFO.PixelSpacing(2)*col zeros(length(row),1)];
      pt = (bsxfun(@plus, R*pt', t))';
      
      [min_D, min_idx] = min(pdist2(pt, BC0{ss,2}),[],2);
      u_idx = unique(min_idx); rem = zeros(size(pt,1),1);
      for kk = 1:length(u_idx)
        dummy = find(min_idx == u_idx(kk));
        if min(min_D(dummy)) > 4, rem(dummy) = 1;
        elseif min(min_D(dummy)) <= 1.5 && length(dummy) > 1, rem(dummy(min_D(dummy) > 1.5)) = 1;
        end; clear dummy;
      end
      pt(find(rem),:) = []; clear min_D min_idx u_idx rem kk;
      
      if size(pt,1) > 0
      [min_D, min_idx] = min(pdist2(pt, BC0{ss,2}),[],2);
      min_idx(find(min_D > (prctile(min_D,95)+0.1))) = [];
      dummy = BC0{ss,2}(sort(unique(min_idx)),:);
      
      dist = zeros(size(dummy,1),1);
      for kk = 1:(size(dummy,1)-1), dist(kk) = pdist2(dummy(kk,:),dummy(kk+1,:)); end
      kk = size(dummy,1); dist(kk) = pdist2(dummy(kk,:),dummy(1,:));
      
      thres = find(dist > 8 & dist > 10*(quantile(dist,0.75)-median(dist)));
      if length(thres) > 0
        
        segmnt = cell(length(thres),1); segmnt{1} = dummy(1:thres(1),:);
        if length(thres) > 1, for ii = 2:length(thres), segmnt{2} = dummy((thres(ii-1)+1):thres(ii),:); end; end
        ii = length(thres);
        if thres(end) < size(dummy,1)
          if dist(end) > 8 && dist(end) > 10*(quantile(dist,0.75)-median(dist))
            segmnt{end+1} = dummy((thres(ii)+1):end,:);
          else
            segmnt{1} = [dummy((thres(ii)+1):end,:); segmnt{1}];
          end
        end
        segmnt = segmnt( cellfun(@(x) size(x,1), segmnt) > 5 ,:);
        segmnt = cellfun(@(x) [ Moving_average(x, 5); [NaN NaN NaN] ], segmnt,'UniformOutput', false);
        cnt = [ cnt ; cell2mat(segmnt) ];
        clear segmnt ii;
        
      else
        if size(dummy,1) > 5, cnt = [ cnt ; Moving_average(dummy, 5); [NaN NaN NaN] ]; end
      end
      
      clear min_D min_idx dummy dist thres kk;
      end
      clear pt;
    end
    clear row col;
  end
  
  BC1{ss,2} = cnt; clear CC cnt comp t R S seg fn;
end

%% Torso cleaning
removeShorts = @(P) P( P.length > 7.5 );   %this will remove isolated pieces with a length smaller than 7.5mm
BC1(:,2) = cellfun( @(C) double( removeShorts( polyline( C ) ) ) , BC1(:,2) , 'un',0);

%%

[BC1,BC1_] = cleanoutHeartSlices( BC1 );
Save( 'BC1' , 'BC1' );
BC1 = BC1_;

hFig = Figure(); hplot3d( BC1(:,2) , 'r' ); axis('equal'); view(3); axis('tight');
savefig( hFig, Fullfile('mpp','Automatic_Contours_Torso.fig') ); close(hFig);

%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue