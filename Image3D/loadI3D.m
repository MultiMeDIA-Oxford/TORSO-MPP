function [ I , fname ] = loadI3D( fname , varargin )
  if nargin < 1 || strcmp( fname , '' ) 
    fname= pwd;
  end
  
  if ~ischar( fname )
    error('invalid fname, fname have to be a char!!');
  end
  ofname = fname;
  fname = fixname( fname );
  try, fname = scp( fname ); end
  
%   if ~isfile( fname )
%     [fname,dirname]= uigetfile( ...
%           { '*.mat;*.vtk;*.vti;*.img;*.hdr;*.nii;*.mhd;*.gz;*.mgh;*.mgz;*.nrrd;*.nhdr' 'All image files'    ;
%             '*.mat;*.mati3d'                      'Matlab Files'                  ;
%             '*.vtk;*.vti'                         'VTK Files (STRUCTURED_POINTS)' ;
%             '*.gipl'                              'Guys Image Processing Lab'     ;
%             '*.mhd'                               'Meta Files MHD+RAW'            ;
%             '*.mgh;*.mgz'                         'FreeSurfer Files'              ;
%             '*.img;*.hdr;*.nii'                   'ANALYZE Files'                 ;
%             '*.nrrd;*.nhdr'                       'NRRD Files'                    ;
%             '*.mitk'                              'MITK Files'                    ;
%             '*.gz'                                'gz Files'                      ;
%             '*.*'                                 'All Files'                     } ...
%           ,'Select Image' , fname ...
%       );
% %       'MultiSelect', 'on' );
%     if isequal(fname,0) || isequal(dirname,0)
%       return;
%     end
%     fname= fixname( dirname , fname );
%   end

  
  if ~isfile( fname )
    I= [];
    return;
  end

  [ dirname , fn , ext ]= fileparts( fname );
  switch lower(ext)
    case {'.gz'}
      [ tDIR , tDIR_cleaner ] = tmpname( 'loadI3D_gz????\' , 'mkdir' );
      unziped_fn = gunzip( fname , tDIR );
      if numel( unziped_fn ) > 1
        error('After Decompress the file --> multiple files'); 
      end

      try
        I = loadI3D( unziped_fn{1} , varargin{:} );
        I.INFO.filename = ofname;
      catch LE
        safe_fclose( unziped_fn{1} );
        rethrow(LE);
      end

    case {'.mgz'}
      [ tDIR , tDIR_cleaner ] = tmpname( 'loadI3D_mgz????\' , 'mkdir' );
      unziped_fn = gunzip( fname , tDIR );
      if numel( unziped_fn ) > 1
        error('After Decompress the file --> multiple files'); 
      end

      try
        I = I3Dread( unziped_fn{1} , 'mgh' );
        I.INFO.filename = ofname;
      catch LE
        safe_fclose( unziped_fn{1} );
        rethrow(LE);
      end

    case {'.bmode'}
      I= I3Dread( fname , 'vevo' );
    case {'.mgh'}
      I= I3Dread( fname , 'mgh' );
    case {'.mhd','.mha'}
      I= I3Dread( fname , 'mhd' );
    case {'.hdr','.img','.nii'}
      I= I3Dread( fname , 'NII' , varargin{:} );
    case {'.gipl'}
      I= I3Dread( fname , 'GIPL' );
    case {'.mitk'}
      I= I3Dread( fname , 'MITK' );
    case {'.nrrd','.nhdr'}
      I= I3Dread( fname , 'NRRD' );
    case {'.vti','.vtk'}
      I= I3Dread( fname , 'VTK' );
    case {'.mat','.mati3d'}
      vars = whos('-file',fname);
      if numel( vars ) > 1
        names= {};
        for i=1:numel( vars )
          names{end+1}= sprintf( '%s   ( %s - %d )', vars(i).name , vars(i).class , vars(i).size );
        end

        index= listdlg( 'ListString' , names ,...
          'SelectionMode','single','ListSize',[300 200],'Name','Select Variable' ,...
          'PromptString','Choose a Volume or a I3D data:', 'uh',18,'fus',2,'ffs',4  );
        vars= vars(index);
      end

      [I,fname] = I3Dread( fname , 'MAT', 'VariableName', vars.name , varargin{:} );

    otherwise
      disp('Unknow (extension) data format.');
  end
  
  if isempty( I.POINTER )
    I = I.set('POINTER', { ofname } ); 
  end
  I.INFO.filename = ofname;  

%   try 
%     if ~numel( I.LABELS_INFO )
%       I= addlabel(I);
%     end
%   end

end
