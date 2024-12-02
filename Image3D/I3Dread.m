function [ I , fname ] = I3Dread( fname , format , varargin )
%   
% [ I , fname ] = I3Dread( fname , format , 
%                     'VariableName' , name
%                     'Orientation'  , {'Patient_01' 'Study_02' 'Serie_01' 'Orientation_03' }
%                                       or [1 2 1 3]
%                     'onlyphases', [1 2 3]
%                                      
% Format could be:
%     'VTK'  'NII'  'MAT' 'MHD' 'MHG'
%


[varargin,i,vname] = parseargs( varargin , 'VariableName','Var', '$DEFS$',0);
[varargin,i,orien] = parseargs( varargin , 'Orient','ORIENtation', '$DEFS$',0);


  switch lower(format)
    case {'vevo'}
      fn = strrep( fname , '.3d.bmode' , '' );
      [I,hdr] = read_VEVO( read_rawVEVO( [fn,'.3d.bmode'] ) , [fn,'.xml'] );
      
      I = I3D( I );
      I.X = hdr.parameter_B_Mode_Width     * linspace( -1 , 1 , numel(I.X) )/2;
      I.Y = hdr.parameter_B_Mode_Depth     * linspace( -1 , 1 , numel(I.Y) )/2;
      I.Z = hdr.parameter_3D_Scan_Distance * linspace( -1 , 1 , numel(I.Z) )/2;
      I = rot90( I , 'k' );
      
    case {'mgh'}
      if isempty( which('load_mgh') )
        if isunix
            addpath( fullfile( fileparts( which('FS_prefix.m') ) , 'freesurfer/'  ) );
%           if strncmp(getHOSTNAME, 'her',3)
%             addpath( '~/extra/database/mia/soft/freesurfer/matlab/' );
%           else
%             addpath( '/usr/local/freesurfer_5.1/matlab/' );
%           end
        else
          try
            addpath( 'z:\soft\freesurfer\matlab\' );
          catch, try
            addpath( 'x:\soft\freesurfer\matlab\' );
          catch, try
            addpath( 'w:\soft\freesurfer\matlab\' );
          catch,
            error('no encuentro read_mgh del freesurfer.');
          end; end; end;
        end

      end
      
      [I,M] = load_mgh( fname );
      I= I3D( I );
      I.INFO.MGH_MATRIX = M;

      
      
%%      
      
      [T,d] = qr( M(1:3,1:3) );

      if max(abs(vec( diag( diag(d) ) - d ))) > 1e-6
        warning('the rotation matrix is not of the form rot*diag!!!');
      end
      d = diag(d);

      if det(T) < 0
        T = T*diag([1 1 -1]);
        d = [ d(1) d(2) -d(3) ];
      end

      caso = '000'; caso( d<0 ) = '-'; caso( d>0 ) = '+';
      switch caso
        case '+++',
        case '---', T = T*diag([-1 -1  1]);  d = [ -d(1) -d(2)  d(3) ];
        case '+--', T = T*diag([ 1 -1 -1]);  d = [  d(1) -d(2) -d(3) ];
        case '-+-', T = T*diag([-1  1 -1]);  d = [ -d(1)  d(2) -d(3) ];
        case '--+', T = T*diag([-1 -1  1]);  d = [ -d(1) -d(2)  d(3) ];
      end

      for dd = 1:3
        if d(dd) < 0
          I.data = flipdim( I.data , dd );
          d(dd) = abs(d(dd));
          I.('W'+dd) = flipdim( -I.('W'+dd) , 2 );
        end
      end

      I.X = I.X * d(1) ;
      I.Y = I.Y * d(2) ;
      I.Z = I.Z * d(3) ;
      M(1:3,1:3) = T;
      I.SpatialTransform = M;

      
      %%      
      
      if det(M) < 0, I = flipdim( I , 3 ); end

    
    case {'nii','img','hdr'}

      nii_version = [];
      [varargin,nii_version] = parseargs( varargin , 'OLD_NII' , '$FORCE$',{0,nii_version} );
      
      if isempty( nii_version )
        nii_version = getappdata(0,'NII_version');
        if isempty( nii_version )
          nii_version = 1;
        end
      end
      
      if nii_version == 0

        warning('I3Dread:NII_version0','Using NII version = 0 !!!');
        
        if isempty( which('load_nii') ), addpath( [ fileparts( which('loadI3D') )  filesep 'NIFTI' ] ); end

        I = load_nii( fname , [] , [] , [] , [] , [] , 0.6 , [] );
        H = rmfield( I , 'img' );

        pixdim = I.hdr.dime.pixdim;
        I = I3D( I.img );
        I.X = I.X * pixdim(2) ;
        I.Y = I.Y * pixdim(3) ;
        I.Z = I.Z * pixdim(4) ;
        I.T = I.T * pixdim(5) ;        
        
      else
        
        [p,f,e] = fileparts( fname );
        if strcmp( e ,'.img' )
          fname = fullfile( p , [ f , '.hdr' ] );
        end

        [I,H] = read_NII( fname );

        pixdim = double( H.pixdim );

        I = I3D( I );
        I.T = I.T * pixdim(5);

        if strcmp( H.hdr_format , 'nii' )
          
          I.T = I.T + H.toffset;
          
          [S,Q] = compute_R( H );

          is1nan = @(x) numel(x)==1 && isnan(x);

          
          if ~is1nan(Q)

            I.X = I.X * pixdim(2) ;
            I.Y = I.Y * pixdim(3) ;
            if H.qfac == 1
              I.Z = I.Z * pixdim(4) ;
            else
              
              I.data = flipdim( I.data , 3 );
              I.Z = flipdim( -I.Z , 2 );
              I.Z = I.Z * pixdim(4) ;
            
            end
            I.SpatialTransform = Q;
            
          elseif ~is1nan(S)

            [T,d] = qr( S(1:3,1:3) );

            if max(abs(vec( diag( diag(d) ) - d ))) > 1e-6
              warning('the rotation matrix is not of the form rot*diag!!!');
            end
            d = diag(d);

            if det(T) < 0
              T = T*diag([1 1 -1]);
              d = [ d(1) d(2) -d(3) ];
            end

            caso = '000';
            caso( d<0 ) = '-';
            caso( d>0 ) = '+';
            switch caso
              case '+++'

              case '---'
                T = T*diag([-1 -1  1]);  d = [ -d(1) -d(2)  d(3) ];
                %cualquiera de estas funcionaria
%                 T = T*diag([-1  1 -1]);  d = [ -d(1)  d(2) -d(3) ];
%                 T = T*diag([ 1 -1 -1]);  d = [  d(1) -d(2) -d(3) ];
              case '+--'
                T = T*diag([ 1 -1 -1]);
                d = [  d(1) -d(2) -d(3) ];
              case '-+-'
                T = T*diag([-1  1 -1]);
                d = [ -d(1)  d(2) -d(3) ];
              case '--+'
                T = T*diag([-1 -1  1]);
                d = [ -d(1) -d(2)  d(3) ];
            end

            for dd = 1:3
              if d(dd) < 0
                I.data = flipdim( I.data , dd );
                d(dd) = abs(d(dd));
                I.('W'+dd) = flipdim( -I.('W'+dd) , 2 );
              end
            end

            I.X = I.X * d(1) ;
            I.Y = I.Y * d(2) ;
            I.Z = I.Z * d(3) ;
            
            if true
            I.X = I.X * pixdim(2) ;
            I.Y = I.Y * pixdim(3) ;
            I.Z = I.Z * pixdim(4) ;
            end
            
            
            S(1:3,1:3) = T;
            I.SpatialTransform = S;
            
            % if ~is1nan(Q)
            %   %comparar diferencias entre el quat y la matriz
            %   if max(vec(abs(Q-S))) > 5e-4
            %     fprintf('hay differencias entre Q y S???\n')
            %     disp( [ Q  Q(:,1)*NaN  S Q(:,1)*NaN Q-S] );
            %     warning('puede haber diferencias entre S y Q');
            %   end
            % end

          elseif is1nan(S) && is1nan(Q)

            I.X = I.X * pixdim(2) ;
            I.Y = I.Y * pixdim(3) ;
            I.Z = I.Z * pixdim(4) ;

          end

        elseif strcmp( H.hdr_format , 'img' )
          
          I.X = I.X * pixdim(2);
          I.Y = I.Y * pixdim(3);
          I.Z = I.Z * pixdim(4);

          switch H.orient
            case 0
              I.SpatialTransform = [1 0 0 0;0 1 0 0;0 0 1 0;0 0 0 1];
              I.data = flipdim( I.data , 1 );
              I.X    = flipdim( -I.X , 2 );
            case {1, 32}
              I.SpatialTransform = [-1 0 0 0;0 0 1 0;0 1 0 0;0 0 0 1];
            case 2
              I.SpatialTransform = [0 0 1 0;1 0 0 0;0 1 0 0;0 0 0 1];
              I.data = flipdim( I.data , 3 );
              I.Z    = flipdim( -I.Z , 2 );
            case 3
              I.SpatialTransform = [-1 0 0 0;0 0 1 0;0 1 0 0;0 0 0 1];
            case 4
              I.SpatialTransform = [-1 0 0 0;0 0 1 0;0 1 0 0;0 0 0 1];
            case 5
              I.SpatialTransform = [-1 0 0 0;0 0 1 0;0 1 0 0;0 0 0 1];
            otherwise
              error('con esta orientacion no he abierto nunca!! revisar y chequear con slicer!!');
          end
          
          
        end
        
      end
      
      I.INFO.hdr = H;
      
    case {'mitk'}
      H = read_MITK( fname );
      
      if ~strcmpi( H.DataType , 'image' )
        error('ROOT object of MITK file ''%s'' is not an image.',fname);
      end
      
      [ tDIR , tDIR_cleaner ] = tmpname( 'mikt_data_????/' ,'mkdir');
      
      ChildrenIMAGES = struct([]);
      H = getAllImagesChildrenFromMITK( H );
      
      I = ChildrenIMAGES(1).DATA; ChildrenIMAGES(1).DATA = [];
      I.INFO.Name = ChildrenIMAGES(1).name;
      I.INFO.hdr  = H;
      I.INFO = rmfield( I.INFO , 'filename' );
      
      for f = 2:numel(ChildrenIMAGES)
        field_name = ChildrenIMAGES(f).name;
        try,   struct( field_name , 1 );
        catch
          warning( 'Invalid FieldName ''%s'' ... using ''unknown_field''.', field_name );
          field_name = 'unknown_field';
        end
        while isfield( I.FIELDS , field_name )
          field_name = [ field_name , '_' ];
        end
        F = ChildrenIMAGES(f).DATA; ChildrenIMAGES(f).DATA = [];
        F.INFO = [];
        if isequal( I.X , F.X ) &&...
           isequal( I.Y , F.Y ) &&...
           isequal( I.Z , F.Z ) &&...
           isequal( I.T , F.T ) &&...
           isequal( I.SpatialTransform , F.SpatialTransform )
          I.FIELDS.(field_name) = F.data;
        else
          I.FIELDS.(field_name) = F;
        end
      end
      
    case {'gipl'}
      [I,H] = read_GIPL( fname );
      
      %I = permute( I , [2 1 3:ndims(I)] );
      I = I3D( I );
      I.INFO.hdr = H;
      
      if numel( H.PixelDimensions ) >= 1 , I.X = I.X * H.PixelDimensions(1); end
      if numel( H.PixelDimensions ) >= 2 , I.Y = I.Y * H.PixelDimensions(2); end
      if numel( H.PixelDimensions ) >= 3 , I.Z = I.Z * H.PixelDimensions(3); end

      if numel( H.Origin ) >= 1 , I.X = I.X + H.Origin(1); end
      if numel( H.Origin ) >= 2 , I.Y = I.Y + H.Origin(2); end
      if numel( H.Origin ) >= 3 , I.Z = I.Z + H.Origin(3); end
      
      if H.VoxelMax > H.VoxelMin
        I.ImageTransform = double( [ H.VoxelMin , 0 ; H.VoxelMax , 1 ] );
      end
      
      if ~isempty( H.Patient )
        I.INFO.PatientInformation = strtrim( H.Patient );
      end
      
      if any( H.Matrix )
        I.SpatialTransform = reshape( double( H.Matrix(1:16) ) , [4,4] );
      end
      
    case {'nrrd'}
      [I,H] = read_NRRD( fname );
      
      I = I3D( I );
      
      if numel( H.Spacings ) > 1 , I.X = I.X * H.Spacings(1); end
      if numel( H.Spacings ) > 2 , I.Y = I.Y * H.Spacings(2); end
      if numel( H.Spacings ) > 3 , I.Z = I.Z * H.Spacings(3); end
      
      I.SpatialTransform = [ H.SpaceDirections , H.SpaceOrigin ; 0 0 0 1 ];
      I.INFO.hdr = H;

      if isfield( H , 'Space' )
        switch lower( H.Space )
          case {'3dr','3drt'}
            I.SpatialTransform = bsxfun( @times , I.SpatialTransform , [-1;-1;1;1] );
          case {'xyz','xyzt'}
            I.SpatialTransform = bsxfun( @times , I.SpatialTransform , [-1;-1;1;1] );
          case {'ras','rast'}

          case {'las','last'}
            I.SpatialTransform = bsxfun( @times , I.SpatialTransform , [1;-1;1;1] );

          case {'lps','lpst'}
            I.SpatialTransform = bsxfun( @times , I.SpatialTransform , [-1;-1;1;1] );

          case {'3dl','3dlt'}
            I.SpatialTransform = bsxfun( @times , I.SpatialTransform , [-1;-1;-1;1] );

        end
      end      

    case {'vtk','vti'}
      [I,h]= read_VTI( fname );
      I= I3D( I );
      
      switch upper(h.DataType)
        case 'STRUCTURED_POINTS'
          I.X = I.X * h.Spacing(1) + h.Origin(1);
          I.Y = I.Y * h.Spacing(2) + h.Origin(2);
          I.Z = I.Z * h.Spacing(3) + h.Origin(3);
        case 'RECTILINEAR_GRID'
          I.X = double(h.X(:)).';
          I.Y = double(h.Y(:)).';
          I.Z = double(h.Z(:)).';
      end
      I.INFO = h;
      
    case {'mhd','mha'}
      [I,h] = read_MHD( fname );
      if isempty(I)
        try, I = zeros( [ h.DimSize , 1 , 1 , 0 ] ); end
      end
%       try
%       if h.ElementNumberOfChannels > 1
%           sz = size(I);
%           I = permute( reshape( I , [ h.ElementNumberOfChannels , sz(1:end-1) ] ) , [2 3 4 5 1] );
%       end
%       end        
        
      sz = h.DimSize;
      sz(end+1:4) = 1;
      try, sz(end+1) = h.ElementNumberOfChannels; end
      I = reshape( I , sz );


      I= I3D( I );
      try, I.X= I.X * h.ElementSpacing(1); end
      try, I.Y= I.Y * h.ElementSpacing(2); end
      try, I.Z= I.Z * h.ElementSpacing(3); end
      try, I.SpatialTransform = h.TransformMatrix; end
      I.INFO = h;
      
    case 'mat'
      if ~vname
        vname= whos('-file',fname);
        if numel(vname)>1
          error('You have to specified the variable name.');
        end
        vname= vname.name;
      end

      I = load( fname , '-mat' , vname );
      I= I.(vname);

      if isnumeric( I )
        I= I3D( I );
        I = I.set( 'POINTER' , ...
              { ''                                                ;...
                { ['@(X) load(''' fixname(fname) ''',''' vname ''')' ] }  ;...
                { ['@(X) X.' vname ] }                           ...
              } );
      elseif isa( I , 'I3D' )
        I = I.set( 'POINTER' , ...
              { ''                                                ;...
                { ['@(X) load(''' fixname(fname) ''',''' vname ''')'] }  ;...
                { ['@(X) X.' vname ] }                          ;...
                { '@(X) X.data' }                                        ...
              } );
      end
      

      [dirname,n,ext]= fileparts( fname );
      fname= [ fname ':' vname ];

      
      if isstruct( I );
        oldPWD= pwd;
        cd(dirname);
%         try
          [I,sname] = loadDICOMvolume( I , varargin{:} );
%         catch
%           cd(oldPWD);
%           error;
%         end
        cd(oldPWD);
        fname= [ fname '::' sname ];
      end

    otherwise
      error('Unknow data format.');
  end

  I.INFO.filename = fname;
  
%   try 
%     if ~numel( I.LABELS_INFO )
%       I= addlabel(I);
%     end
%   end




  function [S,Q] = compute_R( h )

    S = NaN;
    Q = NaN;

    if        h.sform_code > 0
      
      S = eye(4);

      S(1,:) = h.srow_x;
      S(2,:) = h.srow_y;
      S(3,:) = h.srow_z;

      S = double( S );

    end
    
    
    if h.qform_code > 0
      
      Q = eye(4);
    
      Q(1:3,1:3) = quat2mat( double( [ h.quatern_b , h.quatern_c ,  h.quatern_d ] ));

      Q(1,4) = h.qoffset_x;
      Q(2,4) = h.qoffset_y;
      Q(3,4) = h.qoffset_z;

      Q = double( Q );
      
    end
    
  end

  function H = getAllImagesChildrenFromMITK( H )

    if strcmpi( H.DataType , 'image' )
      tFILE = tmpname( [ tDIR , 'temp????_' , H.DataFile ]  ,'mkfile');
      FID = fopen( tFILE , 'w' );
      fwrite( FID , H.DATA , 'uint8' );
      fclose( FID );
      H.DATA = [];

      ChildrenIMAGES( end+1 ).DATA = loadI3D( tFILE ); delete( tFILE );
      ChildrenIMAGES( end   ).name = H.Properties.name;
    end
    
    for c = 1:numel(H.children)
      H.children(c) = getAllImagesChildrenFromMITK( H.children(c) );
    end
  end
      


end
