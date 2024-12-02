OUTPUT_FILES = {'mpp/BC0.mat'};

%% START mpp_preamble
if exist('MPP_ERROR','var')&&~isempty(MPP_ERROR);fprintf(2,'MPP_ERROR is "%s"    <a href="matlab:clear(''MPP_ERROR'')">CLEAR IT</a>\n',MPP_ERROR);return;end;if ~exist('SUBJECT_DIR','var');fprintf(2,'There is no specified ''SUBJECT_DIR''.\n');return;end;if ~ischar(SUBJECT_DIR);fprintf(2,'Invalid ''SUBJECT_DIR''.\n');return;end;while SUBJECT_DIR(end) == filesep;SUBJECT_DIR(end) = [];end;try;checkBEAT(SUBJECT_DIR);catch;fprintf(2,'Cannot check BEAT\n');return;end;if ~isdir(SUBJECT_DIR);fprintf(2,'Directory ''SUBJECT_DIR'' does not exist. ("%s")\n',SUBJECT_DIR);return;end;if isfile(Fullfile('RUNNING'));fprintf(2,'MPP already RUNNING for this SUBJECT (''%s'').   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SUBJECT_DIR , Fullfile('RUNNING') );clear('OUTPUT_FILES');return;end;WHERE_AM_I=strrep(strrep(mfilename(),'mpp_',''),'_',' ');printf(+Fullfile('RUNNING'),'in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);pause(1);NAME_OF_VARIABLES_TO_KEEP=setdiff(who,{'ans','WHERE_AM_I','NAME_OF_VARIABLES_TO_KEEP','OUTPUT_FILES'});NAME_OF_VARIABLES_TO_KEEP=[NAME_OF_VARIABLES_TO_KEEP(:);'MPP_ERROR';'MPP_BROKEN'];if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) || ( exist('MPP_FORCE','var') &&  MPP_FORCE ) || ~all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));else;fprintf('\nSkipping MPP step ''%s'' for "%s" since\n',WHERE_AM_I,SUBJECT_DIR);cellfun(@(f)fprintf('file ''%s'' exists\n',Fullfile(f)),OUTPUT_FILES);fprintf('\n');keepvars(NAME_OF_VARIABLES_TO_KEEP);try;delete(Fullfile('RUNNING'));end;return;end;CWD__=pwd;START__=now;fprintf('\n\nRUNNING : %s\n',WHERE_AM_I);diary(Fullfile('MeshPersonalizationPipeline.log'));diary('on');fprintf('*** MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('*',1,65-numel(SUBJECT_DIR)));fprintf('in: %s%s  | %s   at   %s@%s:%d (%s)\n',WHERE_AM_I,blanks(30-numel(WHERE_AM_I)),datestr(START__,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);fprintf('\n');fprintf('%s\n\n',repmat('.',1,80));if ( exist('MPP_BROKEN','var') && MPP_BROKEN ) && all(cellfun(@(f)isfile(Fullfile(f)),OUTPUT_FILES));fprintf('\n=========================================\n');fprintf('BROKEN !!   The pipeline was previously BROKEN, then forcing this step (%s).\n' , WHERE_AM_I );for f = OUTPUT_FILES(:), f = f{1};fprintf('Backuping previous file: "%s"\n' , Fullfile(f) );try, movefile( Fullfile(f) , [ Fullfile(f) , '.bak' ] ); end;end;fprintf('=========================================\n\n');end;MPP_BROKEN=true;try;
%% END mpp_preamble

BS = Loadv( 'BS' , 'BS' );
try, mkdir_( Fullfile( 'mpp' , 'torso-images' ) ); end
for h = 1:size(BS,1)
  fn = sprintf('%03d.[%03d-%s](%.1f)', h, BS{h,1}.INFO.SeriesNumber, BS{h,1}.INFO.SeriesDescription, BS{h,1}.INFO.xZLevel);
  fn = Fullfile('mpp', 'torso-images', [fn,'.png']);
  %while isfile( fn ) && etime( getv( dir(fn) , '.date' ) ) < 10, fn = [ fn(1:end-4) , '_' , '.png' ]; end
  imwrite(getPicture(BS(h,:)), fn); clear fn;
end

%%
mppOption pathfull
setenv('PATH', ['C:\python-venv\torso-2D-seg\Scripts', pathsep, getenv('PATH')]);
system(['"C:\python-venv\torso-2D-seg\Scripts\python" "', pathfull, 'PreTrained\torso_segmentor.py"', ' --dir_img ', Fullfile('mpp', 'torso-images'),...
  ' --model_path ', fullfile(pathfull, 'PreTrained', 'N15_cycle_4.pt')]);

%%
BC0 = BS;

if isfile( Fullfile('mpp','BC0.tmp') )
  
  BC0 = Loadv( 'BC0.tmp' , 'BC0' );
  delete( Fullfile('mpp','BC0.tmp') );
  
else
  for ss = 1:size(BC0,1)
    fn = sprintf( '%03d.[%03d-%s](%.1f).png' , ss, BC0{ss,1}.INFO.SeriesNumber, BC0{ss,1}.INFO.SeriesDescription, BC0{ss,1}.INFO.xZLevel);
    fn = Fullfile('mpp', 'torso-segment', fn );
    seg = imread( fn ); seg = permute(seg,[2 1]);
    
    S = BC0{ss,1}; S = S(:,:,:,1);
    seg = imresize(seg,size(S.data),'nearest'); seg( seg < 128 ) = 0; seg( seg >= 128 ) = 255;
    seg(1,:) = 0; seg(end,:) = 0;
    seg(:,1) = 0; seg(:,end) = 0;
    
    S.data = seg; BC0{ss,2} = contour( S==255 , [1,1]*0.5); close(gcf);
    if size(BC0{ss,2},1) > 0
      cntrs = BC0{ss,2}; dummy = {};
      for jj = size(cntrs,1):-1:1
        if all(isnan(cntrs(jj,:))), dummy{end+1,1} = cntrs(jj+1:end,:); cntrs(jj:end,:) = []; end
      end
      test = zeros(size(dummy,1),1);
      for jj = 1:size(dummy,1)
        if size(dummy{jj},1) > 15 && max(cellfun(@(x) size(x,1), dummy))/size(dummy{jj},1) < 10
          dummy{jj}(end+1,:) = [NaN, NaN, NaN]; mask = ~~S.inpoly(dummy{jj}); test(jj) = sum(mask(:)); clear mask;
        else test(jj) = 0;
        end
      end
      [~,indx] = max(test); BC0{ss,2} = dummy{indx,1}; clear cntrs dummy test indx jj;
    else
      BC0{ss,2} = [];
    end
    
    if size(BC0{ss,2},1) > 0
      test = ones(size(S.data)); test(1,:) = 0; test(end,:) = 0; test(:,1) = 0; test(:,end) = 0;
      S.data = test; bdry = contour( S==1 , [1,1]*0.5 ); close(gcf); bdry(1,:) = [];
      
      for jj = (size(BC0{ss,2},1)-1):-1:1
        if min(pdist2(BC0{ss,2}(jj,:),bdry)) <= 4.0
          if (jj == 1) || ( (jj > 1) && all(isnan( BC0{ss,2}(jj-1,:) )) ) || all(isnan( BC0{ss,2}(jj+1,:) )), BC0{ss,2}(jj,:) = []; else BC0{ss,2}(jj,:) = [NaN, NaN, NaN]; end
        end
      end
      clear test bdry jj;
    end
    
    clear fn seg S;
  end
  clear ss;
end
clear BS;

%%
[BC0,BC0_] = cleanoutHeartSlices( BC0 );
Save( 'BC0' , 'BC0' );
BC0 = BC0_;

hFig = Figure(); hplot3d( BC0(:,2) , 'r' ); axis('equal'); view(3); axis('tight');
savefig( hFig, Fullfile('mpp','Segmented_Contours_Torso.fig') ); close(hFig);

%% START mpp_epilogue
fprintf('\n\n'),fprintf('*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end,fprintf('*** DONE : ''%s''  | %s   at   %s@%s:%d (%s)\n\n',WHERE_AM_I , datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'),getUSER,getHOSTNAME,feature('getpid'),computer);catch LastError;MPP_ERROR = WHERE_AM_I;fprintf(2,'*** ellapsed time:  ');try,etime(START__);catch,fprintf('unknown?\n');end;fprintf(2,'\n\nERROR EXECUTING: %s     for ''%s''  at   %s\n\n',WHERE_AM_I,SUBJECT_DIR,datestr(now,'dd/mm/yy (HH:MM:SS.FFF)'));fprintf(2,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(2,'%s\n',getReport(LastError));fprintf(2,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n');try,ferr = fopen( Fullfile('MeshPersonalizationPipeline.err') , 'a' );fprintf(ferr,'ERROR EXECUTING: %s     for ''%s''\n', WHERE_AM_I , SUBJECT_DIR );fprintf(ferr,'at:   %s\n', datestr(now,'dd/mm/yy (HH:MM:SS.FFF)') );fprintf(ferr,'in: %s@%s:%d (%s)\n', getUSER,getHOSTNAME,feature('getpid'),computer );fprintf(ferr,'\n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n');fprintf(ferr,'%s\n',getReport(LastError));fprintf(ferr,'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n\n');fclose( ferr );fixDiaryFile( Fullfile('MeshPersonalizationPipeline.err') );end,end,checkBEAT(SUBJECT_DIR);fixDiaryFile( iff(mppBranch('hcm'),Inf,10000) );fprintf('+++ MPP for ''%s'' %s\n',SUBJECT_DIR,repmat('+',1,65-numel(SUBJECT_DIR)));fprintf('%s\n\n\n',repmat('-',1,80));checkBEAT(SUBJECT_DIR);diary('off');if isequal(strfind(SUBJECT_DIR,'H:\'),1) && isequal(getUSER,'engs1508'),executeInBEAT(['chmod ug+rw -R /data/CardiacPersonalizationStudy/',strrep(SUBJECT_DIR,'H:\',''),'/.']);end;cd(CWD__);keepvars(NAME_OF_VARIABLES_TO_KEEP);w_s___ = warning('off','MATLAB:DELETE:FileNotFound');try,delete(Fullfile('RUNNING'));end,warning(w_s___);clear('w_s___');return;
%% END mpp_epilogue