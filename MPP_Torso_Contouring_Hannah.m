
clear all;
run( 'C:\Users\hanith\OneDrive - Nexus365\TorsoReconstruction\Torso_Contouring_Hannah\MPP\mppSETUP.m' );
directf = 'C:\Users\hanith\OneDrive - Nexus365\TorsoReconstruction\Torso_Contouring_Hannah';
%addpath( [directf, 'MPP'] ); run( [directf, 'MPP\mppSETUP.m'] );

%% some preferences
mppOption TORSO_MODEL_DIR  = fullfile(fileparts(which('mpp_Read_DICOMs')),'TORSO');
mppOption CLEANOUT_HSs     = true;
mppOption SAVE_FIGURES     = false;
mppOption VERTICAL_FLIP_IN_MONTAGES = true;  %controls the montage appeareance

mppOption REDO_LIST        = true;  %used in mpp_Select_Heart_Slices
mppOption USE_MANNEQUIN    = true;  %used in mpp_Manual_Contour_Heart  and   mpp_Manual_Contour_Torso
mppOption UNATTENDED_TIME  = Inf;   %used in mpp_Manual_Contour_Heart  and   mpp_Manual_Contour_Torso
mppOption RV_WIDTH         = 3;     %used in mpp_Fix_Heart_Contours
mppOption RegistrationITS  = 10;    %used in mpp_Register_Heart_Slices
mppOption SquareITS        = 15;    %used in mpp_Square_Heart_Slices
mppOption EDGE_LENGTHS     = [ 1.5 , 1.0 , 0.4 ];  %used in mpp_Final_Heart_Meshes
mppOption TETRA_BUILDER    = ['tetgen'];   %used in mpp_Build_Heart_Tetras     
mppOption ExportHRs        = true;
mppOption KM_iterations    = 3;
mppOption FLIP_FIX_ANTERIOR_INFERIOR = false;  %used in mpp_Fix_Heart_Contours

%% Data specific preferences
mppOption VERSION          = ['Torso-reconstruction:1.0'];
mppOption MAKE_VIDEO       = false;
mppOption DIR              = directf;
mppOption Torso_figures    = false;
mppOption pathfull = ['C:\Users\hanith\OneDrive - Nexus365\TorsoReconstruction\Torso_Contouring_Hannah\MPP\'];

%% LIST of SUBJECTS
cd(directf); files = dir(fullfile(directf, 'data'));
files = files([files.isdir] & ~cellfun(@(x) strcmp(x,'.'),{files.name})&~cellfun(@(x) strcmp(x,'..'),{files.name}));
SUBJECT_DIRs = cell(length(files),1);
for ff = 1:length(files), SUBJECT_DIRs{ff} = fullfile(directf, 'data', files(ff).name ); end

for ff = 1:numel( SUBJECT_DIRs )
  if ~mppSubject( SUBJECT_DIRs{ff} ), continue; end
  %as default: DICOMS_DIR = fullfile( SUBJECT_DIR , 'DICOMS' );
  
  mpp_Read_DICOMs                               %output: DICOMs.mat
  mpp_Subject_Data                              %output: SubjectData.txt
  mpp_Select_Heart_Slices_Biobank               %output: HS.mat    (referring Heart Slices)  making use of "HeartSlices.list"
  mpp_Get_AllPosition_Images_Torso              %output: BS.mat
  
  mpp_Segmented_Contours_Torso                  %output: BC0.mat
  % mpp_Manual_Contour_Torso_Biobank            %output: BC.mat
  mpp_Automated_Contours_Torso
  
  mpp_Fit_Vest_Biobank
  mpp_ECG_Electrodes
  mpp_Final_Torso_Meshes_Biobank
  % mpp_Build_Torso_Tetras
  
end

for ff = 1:numel( SUBJECT_DIRs )
  if ~mppSubject( SUBJECT_DIRs{ff} ), continue; end
  mpp_Torso_Recontouring
  force mpp_Manual_Contour_Torso_Biobank              %output: BC.mat

end