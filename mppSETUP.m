%% SETTING UP MPP (Mesh Personalization Pipeline)
try
  is_M_P_P_dir_ = @(d) isdir(d) && isdir( fullfile( d , 'MeshPersonalizationPipeline' ) );
  mpp_F_O_L_D_E_R_ = '';
  if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = fileparts(which('mppSETUP.m')); end
  if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = fileparts(fileparts(which('mppSETUP.m'))); end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = fileparts(fileparts(mfilename('fullpath')));                   end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = fileparts(mfilename('fullpath'));                              end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = pwd;                                                           end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = fileparts(pwd);                                                end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = 'E:\Dropbox\shared\';                                          end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = 'C:\Dropbox\Vigente\shared\';                                  end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = 'Z:\Dropbox\shared\';                                          end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = 'E:\Dropbox\Vigente\shared\';                                  end
%   if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), mpp_F_O_L_D_E_R_ = 'C:\Users\peter\Dropbox\shared\'; end
  if ~is_M_P_P_dir_( mpp_F_O_L_D_E_R_ ), error('can''t find mpp_F_O_L_D_E_R_'); end
  clearvars('is_M_P_P_dir_');
  mpp_F_O_L_D_E_R_ = fullfile( mpp_F_O_L_D_E_R_ , 'MeshPersonalizationPipeline' );
  fprintf('\n');
  fprintf('mpp FOLDER is :   "%s"\n' , mpp_F_O_L_D_E_R_ );

  set(0,'DefaultFigureCreateFcn','factory');
  fprintf('',cellfun(@(p)isempty(strfind(p,'Dropbox'))||find(rmpath(p),1),strsplit(path,';','CollapseDelimiters',true)));
  fprintf('',cellfun(@(p)isempty(strfind(p,mpp_F_O_L_D_E_R_))||find(rmpath(p),1),strsplit(path,';','CollapseDelimiters',true)));
  addpath(                      mpp_F_O_L_D_E_R_ );
  addpath( fullfile(            mpp_F_O_L_D_E_R_ ,   'MPP_tools\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'thirdParty\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'thirdParty\export_fig' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'thirdParty\Factorize' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'IO\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'LieAlgebra\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MESH\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MESHES\' ) ); try,enableVTK;end
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MESHES\jigsaw\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MESHES\tetgen\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MESHES\carve\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MESHES\gmsh\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'Tools\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'Tools\parseargs' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'uiTools\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'DICOM\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'Image3D\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'polygons\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'POLYLINE\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'CardiacAnalysisTools\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'OPTIM\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MatrixCalculus\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'uiTools\OrbitPanZoom\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'euclidean_distance_A2B\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'drawContours\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'MESHES\gmsh\' ) );
  addpath( fullfile( fileparts( mpp_F_O_L_D_E_R_ ) , 'SSM\' ) );
  clearvars('mpp_F_O_L_D_E_R_');
  
  
  %% checks
  fprintf( 'Matlab version    ... ' );
  fprintf( 2 , '%s ' , version );
  fprintf('\b\n');

  
  fprintf( 'MPP steps in path ... ' );
  if ~isempty( which( 'mpp_Read_DICOMsJC' ) )
    fprintf( 2 , 'OK ');
  else
    fprintf( 2 , 'ERROR ');
  end
  fprintf('\b\n');
    

  fprintf( 'MPP tools in path ... ' );
  if ~isempty( which( 'mppOption' ) )
    fprintf( 2 , 'OK ');
  else
    fprintf( 2 , 'ERROR ');
  end
  fprintf('\b\n');

  
  fprintf( 'MESH in path      ... ' );
  if ~isempty( which( 'Mesh' ) )
    fprintf( 2 , 'OK ');
  else
    fprintf( 2 , 'ERROR ');
  end
  fprintf('\b\n');
  
  
  fprintf( 'VTK enabled?      ... ' );
  try
    [~] = evalc( 'vtkPolyDataReader()' );
    fprintf( 2 , 'OK ');
  catch
    fprintf( 2 , 'ERROR ');
  end
  fprintf('\b\n');
  
  
  fprintf( 'JIGSAW enabled?   ... ' );
  try
    [jigsaw_executed_status,~] = system( [ '"' , jigsaw_remesh , '"' , ' jig.jig' ] );
    delete( fullfile( pwd , 'jig.log' ) );
    if jigsaw_executed_status ~= 2, error('error executing jigsaw'); end
    clearvars('jigsaw_executed_status');
    fprintf( 2 , 'OK ');
  catch
    fprintf( 2 , 'ERROR ');
  end
  fprintf('\b\n');

  
  fprintf( 'TETGEN enabled?   ... ' );
  try
    [~] = tetgen( icosahedronMesh );
    fprintf( 2 , 'OK ');
  catch
    fprintf( 2 , 'ERROR ');
  end
  fprintf('\b\n');
  
  
  fprintf( 'GUI tools working ... ' );
  if ~[100,1]*sscanf(version,'%d.%d') <= 8.3
    fprintf( 2 , 'SHOULD WORK! ');
  else
    fprintf( 2 , 'DUBIOUSLY ');
  end
  fprintf('\b\n');
  
  
  %%
  fprintf('');disp('  __  __       ___                ___');disp(' |  \/  |     | _ \              | _ \');disp(' | |\/| |     |  _/              |  _/');disp(' |_|  |_|esh  |_|ersonalization  |_|ipeline');
  fprintf('\n                                has been set!!\n----------------------------------------------\n\n');

  
if 0  
mppOption VERSION          = ['jenny:1.0'];
mppOption TORSO_MODEL_DIR  = fullfile(fileparts(which('mpp_Read_DICOMs')),'TORSO');
mppOption CLEANOUT_HSs     = true;
mppOption SAVE_FIGURES     = false;
mppOption REDO_LIST        = false;
mppOption MAKE_VIDEO       = true;
mppOption USE_MANNEQUIN    = true;
mppOption UNATTENDED_TIME  = 100;
mppOption RV_WIDTH         = 4;
mppOption RegistrationITS  = 10;
mppOption SquareITS        = 15;
mppOption EDGE_LENGTHS     = [ 1.5 , 1.0 , 0.4 ];
mppOption TETRA_BUILDER    = ['tetgen'];
mppOption ExportHRs        = true;
mppOption KM_iterations    = 1;
end
  
  
  OPTS = getappdata( 0 , 'mppOptions' );
  try
  if ~isempty( OPTS )
    fprintf('\n');
    fprintf('There are some previous mppOptions already set:\n');

    for f = fieldnames( OPTS ).', f = f{1};
      n = f; n(end+1:20) = ' ';
      v = uneval( OPTS.(f) );
      if ischar( OPTS.(f) )
        v = [ '[ ' , v , ' ]' ];
      end
      fprintf(2,'mppOption  %s = %s;\n' , n , v );
    end; clearvars('n','f','v');
    fprintf('\nReseting the mppOptions to defaults (that is, removing them!).\n\n');
    rmappdata( 0 , 'mppOptions' );
  end
  end
  clearvars('OPTS');
  
catch LE
  clearvars('is_M_P_P_dir_');
  clearvars('mpp_F_O_L_D_E_R_');
  error('error SETTING UP MPP (Mesh Personalization Pipeline).');
end

