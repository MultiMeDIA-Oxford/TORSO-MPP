function [I,sname] = DCMload( S , varargin )

  if isempty( which('I3D') )
    error('no I3D toolbox in the path');
  end

  if ischar( S ) || ( isstruct( S ) && isfield( S , 'name' ) )
    S = DICOMgather( S ,'quiet');
  end
  if ~isa( S , 'struct' ), error('invalid input'); end

  S = DCMvalidate( S );

  if ~DCMread(S,'CHECKonly')
    [varargin,i,MASK]= parseargs(varargin,'mask','$DEFS$',[]);
    [ oDescriptions , oFields ] = DCMorientations( S , 'mask', MASK );
    if     numel(oDescriptions)==0
      error('invalid input');
    elseif numel(oDescriptions)==1
      oFields= oFields(1,:);
    else
      index= listdlg( 'ListString' , oDescriptions ,...
        'SelectionMode','single','ListSize',[800 600],'Name','Select Volume' ,...
        'PromptString','Choose a Volume or a I3D data:', 'uh',18,'fus',2,'ffs',4  );
      oFields= oFields(index,:);
    end
    S= getfield( S , oFields{:} );
  end
  
  
  CoordSystem = 'XYZ';  %by default use the scanner XYZ coordinate system.
                        %It equals RAS if patient is in HeadFirst-prone position.
                        %see, http://www.slicer.org/slicerWiki/index.php/Coordinate_systems
  [varargin,CoordSystem] = parseargs( varargin,'xyz','SCANNERxyz','$FORCE$',{'XYZ',CoordSystem} );
  [varargin,CoordSystem] = parseargs( varargin,'ras'             ,'$FORCE$',{'RAS',CoordSystem} ); %RAS is the one used by slicer.
  
  [DATA,X,Y,Z,R,INFO,infos] = DCMread( S , varargin{:} );
  
  DATA = permute( DATA , [2 1 3 4] );  %%asi funciona bien para las imagenes de ADNI !!, comparado con el SNAP
                                       %%preserva izq-der, si leo la imagen
                                       %%con DICOM2DIR, me da la misma
                                       %%orientacion izq-der, pero I,J,K
                                       %%representan distintas cosas 
  I= I3D( DATA );  
  

  if isfield( INFO , 'PatientPosition' )
    PatientPosition = upper( INFO.PatientPosition );
  else
    PatientPosition = 'HFS';  %by default, HeadFirst-supine is assumed
  end
  switch CoordSystem
    case 'XYZ'
      %R=R;
      
    case 'RAS'
      switch upper( PatientPosition )
        case 'HFP'    %Head First-Prone
          %R = [ R(1,:) ; R(2,:) ; R(3,:) ; R(4,:) ];
        case 'HFS'    %Head First-Supine
          R = [ -R(1,:) ; -R(2,:) ; R(3,:) ; R(4,:) ];
        case 'HFDR'   %Head First-Decubitus Right
          R = [ R(2,:) ; -R(1,:) ; R(3,:) ; R(4,:) ];
        case 'HFDL'   %Head First-Decubitus Left
          R = [ -R(2,:) ; R(1,:) ; R(3,:) ; R(4,:) ];
        case 'FFDR'   %Feet First-Decubitus Right
          R = [ R(2,:) ; R(1,:) ; -R(3,:) ; R(4,:) ];
        case 'FFDL'   %Feet First-Decubitus Left
          R = [ -R(2,:) ; -R(1,:) ; -R(3,:) ; R(4,:) ];
        case 'FFP'    %Feet First-Prone
          R = [ -R(1,:) ; R(2,:) ; -R(3,:) ; R(4,:) ];
        case 'FFS'    %Feet First-Supine  
          R = [ R(1,:) ; -R(2,:) ; -R(3,:) ; R(4,:) ];
      end
  end
                  
  
  
  I.X = X;
  I.Y = Y;
  I.Z = Z;
  I.SpatialTransform = R;
  I.INFO = struct('DICOM_INFO', INFO , 'SLICES_INFO' , { infos } );
  
  if size( I , 4 ) > 1
    T = I.T;
    try
      for t = 1:size(infos,2)
        imageTimes = NaN( size(infos,1) , 1 );
        for z = 1:size(infos,1)
          imageTimes(z) = DICOMdatenum( infos{z,t} );
        end
        T(t) = mean( imageTimes );
      end
    end
    T = T - min(T);
    if ~any( isnan(T) ), I.T = T; end
  end
  

  try,   sname = INFO.SeriesDescription;
  catch, sname = '';
  end

end
