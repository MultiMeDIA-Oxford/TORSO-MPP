function C = read_CVI42WSX( xml , varargin )
% Function to read the data of the XML file exported from CMR42, and to get
% the contours drawn in a short axis stack.
%
% By Pablo Lamata. Oxford, 07/02/2014
% rewritten by EZ, KCL 04/2015


%{
dicoms_directory = 'c:\test\DICOMS';

DICOM_INFOS = read_CVI42WSX( [] , dicoms_directory , 'verbose' );   % it explores the dicom_directory and built a                                                                     % kind
                                                                    % kind of lookup table relating each
                                                                    % dicom file with it MediaStorageSOPInstanceUID
                                                                    
C = read_CVI42WSX( 'contours_file.cvi42wsx' , DICOM_INFOS , 'verbose' ); % read the contours stored in contours_file.cvi42wsx

%equivalently it can be called by 
%C = read_CVI42WSX( 'contours_file.cvi42wsx' , dicoms_directory , 'verbose' );
%C = read_CVI42WSX( 'contours_file.cvi42wsx' , dicoms_directory );  %quiet way

%after reading you get an array of structures with these fields
% C = 
% 53x1 struct array with fields:
%     ImageSize
%     Points
%     NPoints
%     PixelSize
%     SubpixelResolution
%     Type
%     IsManuallyDrawn
%     Label
%     Description
%     parentUID
%     parentDICOMfound
%     parentFilename
%     parentPatientID
%     parentStudyInstanceUID
%     parentStudyDescription
%     parentSeriesInstanceUID
%     parentSeriesDescription
%     parentImageOrientation
%     NumberOfTimeInstant
%     TimeInstant
%     RotationMatrix
%     NumberOfSlices
%     Zid
%     Points3D
%     ImageSlice
%     ImageHeader

%you can play with it. Some examples at the following!
% plot all contours in the world-coordinate system
plot3d = @(x,varargin)plot3(x(:,1),x(:,2),x(:,3),varargin{:});
figure;
for c = 1:numel(C)
  try, hold on; plot3d( C(c).Points3D , 'color',rand(1,3) ); hold off; end
end
axis('equal'); view(3);

%or plot them in the "stack"-coordinates
plot3d = @(x,varargin)plot3(x(:,1),x(:,2),x(:,3),varargin{:});
figure;
for c = 1:numel(C)
  try, hold on; plot3d( C(c).Points3D * inv( C(c).RotationMatrix )' , 'color',rand(1,3) ); hold off; end
end
axis('equal'); view(3);

% ImageSize
cat(1, C.ImageSize )

% NPoints  (number of points of each contour)
[ C.NPoints ]

% PixelSize
cat(1, C.PixelSize )

% SubpixelResolution
[ C.SubpixelResolution ]

% Type
{ C.Type }

% IsManuallyDrawn
[ C.IsManuallyDrawn ]

% Label
{ C.Label }

% Description
{ C.Description }'
unique( { C.Description }' )

% Filename (of the dicoms)
unique(cellfun(@char,{ C.parentFilename }','un',0))

% dicom parent PatienID, StudyDescription, SeriesDescription
unique(cellfun(@char,{ C.parentPatientID }','un',0))
unique(cellfun(@char,{ C.parentStudyDescription }','un',0))
unique(cellfun(@char,{ C.parentSeriesDescription }','un',0))

% Time
[ C.NumberOfTimeInstant ]  % for example around 25 for a cine serie
[ C.TimeInstant ]          % which is the phase of this contour within those 25 frames

% NumberOfSlices (how many slices belong to the DICOMserie and form the stack)
[ C.NumberOfSlices ] 

% Zid  (position within the stack)
[ C.Zid ]

% ImageSlice  (try it...) the image is not stored in C
% this is only a "pointer" to read the image
C(1).ImageSlice
% which can be executed
feval( C(1).ImageSlice )
%or by
C(1).ImageSlice()


%the contours corresponding to the "t0" can be gather with
C( [ C.TimeInstant ] == 1 )

%and the ones belonging to a unique slice
C( [ C.TimeInstant ] == 1 & [ C.Zid ] == 5 )

%}


  HUGE = false;
  [varargin,HUGE] = parseargs(varargin,'huge','$FORCE$',{true,HUGE});

  
  SAFE = true;
  [varargin,SAFE] = parseargs(varargin,'safe','$FORCE$',{true,SAFE});
  [varargin,SAFE] = parseargs(varargin,'unsafe','$FORCE$',{false,SAFE});
  if HUGE, SAFE = false; end
  if SAFE
    try
      fs = dir( xml );
      fs = fs.bytes;
    catch
      fs = 0;
    end
    if fs/1024/1024 > 20
      fprintf( 'File too large! to avoid problems... switching to huge!!\n' );
      try, C = read_CVI42WSX( xml , varargin{:} ,'huge');
      catch LE
        rethrow( LE );
      end
      return;
    end
    
    try
      DINFO = read_CVI42WSX( [] , varargin{:} , 'unsafe' );
      varargin = { DINFO , varargin{:} };
    end
    try
      C = read_CVI42WSX( xml , varargin{:} ,'unsafe');
    catch LE
      fprintf( 'switching to huge!!\n' );
      try, C = read_CVI42WSX( xml , varargin{:} ,'huge');
      catch LE
        rethrow( LE );
      end
    end
    return;
  end
  
  if HUGE
    
    [reducedCVI42,CLEANER] = tmpname( 'huge_CVI42WSX__****.cvi42wsx' , 'mkfile' );
    C = struct([]);

    fprintf( 'reading HUGE file: %s ...' , xml );
    XMLtext = readFile( xml );
    fprintf( '\n... done\n');
    
    ImageStates = find( ~cellfun( 'isempty' , regexp( XMLtext , 'ImageStates' , 'once' ) ) );
    ImageStates = ImageStates(1:2);
    
    PRE = XMLtext( 1:ImageStates(1)       );
    POS = XMLtext(   ImageStates(2)-1:end );
    XMLtext( [ 1:ImageStates(1) , ImageStates(2)-1:end ] ) = [];
    
    while ~isempty( XMLtext )
%       key = regexp( XMLtext{1} , '.*:key="([^"]*)".*' , 'tokens' );
%       if isempty( key ), XMLtext(1) = []; end
%       key = key{1}{1};
%       key = builtin( 'strrep' , key , '.' , '\.' );
%       end_key = find( ~cellfun( 'isempty' , regexp( XMLtext , key , 'once' ) ) );
%       if isempty( end_key ), XMLtext(1) = []; end
%       end_key = end_key(end);
      
      
      key = regexp( XMLtext(1:min(end,100000)) , '.*:key="([\d\.]*)".*' , 'tokens' );
      key( cellfun('isempty',key) ) = [];
      if isempty( key ), XMLtext(1) = []; end
      key = key{max(1,end-1)}{1};
      key = builtin( 'strrep' , key , '.' , '\.' );
      end_key = find( ~cellfun( 'isempty' , regexp( XMLtext , key , 'once' ) ) );
      if isempty( end_key ), XMLtext(1) = []; end
      end_key = end_key(end);
      
      
      
      K = XMLtext( 1:end_key );
      XMLtext( 1:end_key ) = [];
      fprintf( '%10d  lines remaining   (%d contours up to now)\n', numel( XMLtext ) , numel(C) );
      
      if ~any( ~cellfun( 'isempty' , regexp( K , 'ImageSize' , 'once' ) ) )
        continue;
      end
      
      try
        fid = fopen( reducedCVI42 , 'w' );
        for l = 1:numel(PRE), fprintf( fid , PRE{l} ); fprintf( fid , '\n' ); end
        for l = 1:numel( K ), fprintf( fid ,   K{l} ); fprintf( fid , '\n' ); end
        for l = 1:numel(POS), fprintf( fid , POS{l} ); fprintf( fid , '\n' ); end
        fclose( fid );
        
        thisC = read_CVI42WSX( reducedCVI42 , varargin{:} , 'unsafe' );
        if ~isempty( thisC )
        	C = catstruct( 1 , C , thisC );
        end
      end
      
    end

    return;
  end
  

  %%unsafe/original version!
  
  [varargin,VERBOSE] = parseargs(varargin,'verbose','$FORCE$',{true,false});

  DINFO = [];
  if numel(varargin)
    DINFO = varargin{1};
    varargin(1) = [];
  end

  
  C = [];
  if ~isempty( xml )
    try
      XML = xmlread(xml);
    catch
      error('error reading xml file. May be the JavaHeapSpace is too low. Check the error by executing:  XML = xmlread( ''%s'' )', xml );
    end
  end

  if     isempty( DINFO ) && isempty( xml )
    error('no xml specified and invalid DICOM infos');
  elseif isempty( DINFO ) 
    DINFO = struct( 'MediaStorageSOPInstanceUID' , {} );
  elseif isa( DINFO , 'char' )
    try, DINFO = fixname( DINFO ); end
    vprintf('reading directories ...');
    DINFO = rdir( DINFO );
    vprintf(' ... done\n');
    DINFO = DINFO_from_files( DINFO );
  elseif isstruct( DINFO ) && isequal( fieldnames(dir('..*')) , fieldnames( DINFO ) )
    DINFO = DINFO_from_files( DINFO );
  elseif isa( DINFO , 'struct' ) && isfield( DINFO , 'name' ) && isfield( DINFO , 'bytes' ) && isfield( DINFO , 'MediaStorageSOPInstanceUID' )
  elseif isa( DINFO , 'struct' ) && any( strncmp( fieldnames( DINFO ) , 'Patient_' , 8 ) )
    DINFO = DINFO_from_DCM( DINFO );
  end
  
  if isempty( xml )
    C = DINFO;
    return;
  end
  
  DICOMS_UIDs = { DINFO.MediaStorageSOPInstanceUID };
  DICOMS_UIDs = DICOMS_UIDs(:);
  
  
  ITEMS = XML.getElementsByTagName('Hash:item');
  LL = ITEMS.getLength;
  vprintf('%6d of %6d',0,LL);
  for i = 1:LL
    vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%6d of %6d',i,LL);
    IT = ITEMS.item(i-1);
    if  IT.getNodeType == 1    && ...
        IT.hasChildNodes       && ...
        strcmpi( char(IT.getAttributeNode('Hash:key').getTextContent) , 'contours' )

      ITc = IT.getChildNodes; % create array of children nodes
      for c = 1:ITc.getLength        % read in each child
        ITT = ITc.item(c-1);
        if ~ITT.hasChildNodes, continue; end

        CC = struct();
        CC.cvi42wsxFile = xml;
        ITTc = ITT.getChildNodes;
        for c = 1:ITTc.getLength, try
          N = ITTc.item(c-1);
          ATRname = strtrim(char( N.getAttributeNode('Hash:key').getTextContent ));
          switch ATRname
            case 'ImageSize'
              CC.( ATRname ) = [ str2double(char( N.getElementsByTagName('Size:width' ).item(0).getTextContent )) ,...
                                 str2double(char( N.getElementsByTagName('Size:height').item(0).getTextContent )) ];
            case 'IsManuallyDrawn'
              switch lower(char( N.getTextContent ))
                case 'false', CC.( ATRname ) = false;
                case 'true',  CC.( ATRname ) = true;
                otherwise, error('unknown');
              end
            case 'PixelSize'
              CC.PixelSize = [ str2double(char( N.getElementsByTagName('Size:width' ).item(0).getTextContent )) ,...
                               str2double(char( N.getElementsByTagName('Size:height').item(0).getTextContent )) ];
            case 'Points'
              CC.Points  = getPoints( N );
              CC.NPoints = size( CC.Points ,1);
            case 'PointsBeforeRotation'
              %CC.( ATRname ) = getPointsBeforeRotation( N );
            case 'RotationAngle'
              %CC.( ATRname ) = getRotationAngle( N );
            case 'SubpixelResolution'
              CC.( ATRname ) = str2double(char( N.getTextContent ));
            case 'Type'
              CC.( ATRname ) = char( N.getTextContent );
            otherwise
              CC.( ATRname ) = char( N.getTextContent );
          end
        end; end
      
        if isempty( fieldnames(CC) ), continue; end
        
        try, CC.Description = strtrim(char( ITT.getAttributeNode('Hash:key').getTextContent ) ); end
        try, CC.parentUID   = strtrim(char(  IT.getParentNode.getAttributeNode('Hash:key').getTextContent )); end

             vprintf('      CONTOUR item found\n');
        try, vprintf('                      contour_description     : %s\n', CC.Description      ); end
        try, vprintf('                      contour_points          : %d\n', size( CC.Points ,1) ); end
        

        CC.parentDICOMfound = false;
        if ~isempty( DINFO ) && isa( DINFO , 'struct' ) && isfield( CC , 'parentUID' )

          id = find( strcmp( DICOMS_UIDs , CC.parentUID ) );
          if     isempty( id ), vprintf(2,'                      no parent DICOM found\n' );
          elseif numel(id) > 1, vprintf(2,'                      too much DICOM parents found\n' );
          else,                 vprintf(  '                      parent DICOM image found.\n' );

            CC.parentDICOMfound = true;
            info = DINFO(id);
            if isfield( info , 'Filename' ) && ~isfield( info , 'name' )
              info.name = info.Filename;
            end
            
            try, CC.parentFilename          = info.name;      end
            try, vprintf('                          DICOM_Filename          : %s\n', CC.parentFilename          ); end

            try
              if isfield( info , 'INFO' ) && ~isempty( info.INFO )
                info = mergestruct( info , info.INFO );
              else
                info = mergestruct( info , dicominfo( info.name ) );
              end
            end
              
            try, CC.parentPatientID         = info.PatientID;         end
            try, vprintf('                          DICOM_PatientID         : %s\n', CC.parentPatientID         ); end

            try, CC.parentStudyInstanceUID  = info.StudyInstanceUID;  end
            try, CC.parentStudyDescription  = info.StudyDescription;  end
            try, vprintf('                          DICOM_StudyDescription  : %s\n', CC.parentStudyDescription  ); end

            try, CC.parentSeriesInstanceUID = info.SeriesInstanceUID; end
            try, CC.parentSeriesDescription = info.SeriesDescription; end
            try, vprintf('                          DICOM_SeriesDescription : %s\n', CC.parentSeriesDescription ); end
            try, CC.parentSeriesNumber      = info.SeriesNumber; end
            try, vprintf('                          DICOM_SeriesNumber      : %s\n', CC.SeriesNumber            ); end

            try, CC.parentImageOrientation = info.ImageOrientationPatient; end
            try, vprintf('                          DICOM_ImageOrientationPatient : ( %g , %g , %g , %g , %g , %g )\n', CC.parentImageOrientation(:) ); end

            %time id
            try
              thisDINFO = DINFO;

              w =  strcmp( { DINFO.SeriesInstanceUID } , CC.parentSeriesInstanceUID ) ;
              thisDINFO = thisDINFO( w );
              
              w =  sum( bsxfun( @minus , [ thisDINFO.ImageOrientationPatient ].' , CC.parentImageOrientation.' ).^2 , 2 )  < 1e-8 ;
              thisDINFO = thisDINFO( w );
              
              w =  sum( bsxfun( @minus , [ thisDINFO.ImagePositionPatient ].' , info.ImagePositionPatient.' ).^2 , 2 )  < 1e-8 ;
              thisDINFO = thisDINFO( w );
              
              w = cat( 2 , cat(1,thisDINFO.TriggerTime) , cat(1,thisDINFO.AcquisitionTime) );
              
              [~,w] = sortrows( w , 1:2 );
              thisDINFO = thisDINFO( w );
              
              CC.NumberOfTimeInstant = size( w , 1 );
              CC.TimeInstant = find( strcmp( { thisDINFO.MediaStorageSOPInstanceUID } , info.MediaStorageSOPInstanceUID ) , 1 );
              
              vprintf('                          contour in Time         : %d of %d\n', CC.TimeInstant , CC.NumberOfTimeInstant );
            catch, vprintf(2,'                          error in Time\n'); end
            
            
            R = NaN;
            try
              %rotation matrix
              R = reshape( info.ImageOrientationPatient , 3 , 2 );
              R(:,3)= cross( R(:,1), R(:,2) );
              for cc = 1:3, for it = 1:5, R(:,cc) = R(:,cc)/sqrt( R(:,cc).' * R(:,cc) ); end; end
              CC.RotationMatrix = R;
              vprintf('                          Rotation matrix computed\n' );
            catch, vprintf(2,'                          error in Computing Rotation Matrix\n'); end

            XYZs = [];
            %get the Z id
            try, if numel(R) == 1 && isnan(R), error('no matrix'); end
              thisDINFO = DINFO;

              w =  strcmp( { DINFO.SeriesInstanceUID } , CC.parentSeriesInstanceUID ) ;
              thisDINFO = thisDINFO( w );
              
              w =  sum( bsxfun( @minus , [ thisDINFO.ImageOrientationPatient ].' , CC.parentImageOrientation.' ).^2 , 2 )  < 1e-8 ;
              thisDINFO = thisDINFO( w );
              
              XYZs = unique( [ thisDINFO.ImagePositionPatient ].' , 'rows' );
              XYZs = XYZs / (R.');
              [~,zOrder] = sort( XYZs(:,3) , 'ascend' );
              XYZs = XYZs( zOrder , : );
              
              xyz = info.ImagePositionPatient(:).' / ( R.' );
 
              CC.NumberOfSlices = size( XYZs , 1 );
              [~,CC.Zid] = min( sum( bsxfun( @minus , XYZs , xyz ).^2 , 2 ) );
              vprintf('                          contour in zth-slice    : %d of %d\n', CC.Zid , CC.NumberOfSlices );
            catch, vprintf(2,'                          error in Zid\n'); end
            
            %compute 3D coordinates of the points
            try, if numel(R) == 1 && isnan(R), error('no matrix'); end
              Points3D = CC.Points(:,[1 2]);
              try,   Points3D = Points3D/CC.SubpixelResolution;  end
              try,   Points3D = Points3D * diag( CC.PixelSize ); end
              Points3D(:,3) = 0;
            
              xyz = info.ImagePositionPatient(:).' / ( R.' );
              R = [ R , R * xyz(:) ; 0 0 0 1 ];

              Points3D = bsxfun( @plus , Points3D * R(1:3,1:3).' , R(1:3,4).' );
              CC.Points3D = Points3D;
              vprintf('                          3D points computed\n' );
            catch, vprintf(2,'                          error computing 3D Coordinates\n'); end
              
            %slice image (as an I3D)
            try
              error('1');
              already = []; try, already = find( strcmp( { C.parentUID } , CC.parentUID ) ); end
              if isempty( already )
                CC.ImageSlice = DCMload( struct('name',info.Filename) , 'quiet' );
              else
                CC.ImageSlice = C(already(1)).ImageSlice;
              end
              vprintf('                          Slice stored\n' );
            catch
              try,   CC.ImageSlice = makeFH(['@()struct(''data'',dicomread(''' , info.name , '''),''hdr'',dicominfo(''' , info.name , '''))']);
              catch, vprintf(2,'                          error reading SliceImage\n');
              end
            end
            
            try
              CC.ImageHeader.SeriesOrigin    = XYZs(1,:) * R(1:3,1:3).';
              CC.ImageHeader.origin          = info.ImagePositionPatient(:).';
              CC.ImageHeader.TransformMatrix = R(1:3,1:3);
              CC.ImageHeader.spacing         = [ CC.PixelSize , mean( diff( XYZs(:,3) ) ) ];
              CC.ImageHeader.dim             = [ CC.ImageSize , CC.NumberOfSlices , CC.NumberOfTimeInstant ];
            end
            
          end
          
        elseif isempty( DINFO )
          vprintf(2,'                    consider to use DICOM INFO\n');
        else
          vprintf(2,'            error reading from DINFO\n');
        end
        
        C = catstruct( 1 , C , CC );
        vprintf('%6d of %6d',i,LL);
      end
      
    else
      if VERBOSE && 0
        fprintf('  skipped, key: %s', char(IT.getAttributeNode('Hash:key').getTextContent) );
        fprintf('\n');
        fprintf('%6d of %6d',i,LL);
      end
    end
  end
  vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
  
%   try
%   [~,ids] = sortrows( [ {C.Type}.' , {C.Description}.' , {C.NPoints}.' ] );
%   C = C(ids);
%   end
  
  
  function xy = getPoints( N )
    nP = str2double(char( N.getAttributeNode('List:count').getTextContent ));
    xy = NaN(nP,2);
    for p = 1:nP
      L = N.getElementsByTagName('List:item').item(p-1);
      xy(p,1) = str2double(char( L.getElementsByTagName('Point:x').item(0).getTextContent ));
      xy(p,2) = str2double(char( L.getElementsByTagName('Point:y').item(0).getTextContent ));
    end
  end
  function names = getFieldNames( S , str )
    names = fieldnames( S );
    names = names( strncmp( names , str , numel(str) ) );
  end
  function vprintf(varargin)
    if VERBOSE, fprintf(varargin{:}); end
  end





  function DINFO = DINFO_from_files( DINFO )
    persistent matlabV
    if isempty( matlabV ), matlabV = sscanf(version,'%d.%d.%d.%d.%d',5); matlabV=[100,1,1e-2,1e-9,1e-13]*[ matlabV(1:min(5,end)) ; zeros(5-numel(matlabV),1) ]; matlabV = round(matlabV); end

      try, DINFO( [ DINFO.isdir ] ) = []; end
      if isfield( DINFO , 'isdir' ),     DINFO = rmfield( DINFO , 'isdir'   ); end
      if isfield( DINFO , 'date' ),      DINFO = rmfield( DINFO , 'date'    ); end
      if isfield( DINFO , 'datenum' ),   DINFO = rmfield( DINFO , 'datenum' ); end

%       DINFO = DINFO( cellfun( @(f)isdicom(f) , {DINFO.name} ) );
%       DINFO = DINFO( ~strcmp( cellfun( @(f)filename(f) , {DINFO.name} ,'un',0) , 'DICOMDIR' ) );
      [~,~,endian] = computer; dictionary = dicomdict('get_current');
      vprintf('exploring DICOMS %6d of %6d',0,numel(DINFO));
      cwd = cd(cd()); CLEANUP = onCleanup( @()cd(cwd) );
      cd( fullfile( fileparts(which('dicominfo')) , 'private' ) );
      for ff = 1:numel(DINFO)
        vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%6d of %6d',ff,numel(DINFO));
        if ~isdicom( DINFO(ff).name ), DINFO(ff).bytes = -1; continue; end
        try,
          switch matlabV
            case 803,  info = dicomparse( DINFO(ff).name , DINFO(ff).bytes , endian , false , dictionary );
            otherwise, info = dicomparse( DINFO(ff).name , DINFO(ff).bytes , endian , false , dictionary , true );
          end
          GROUP = [ info.Group   ];
          ELEME = [ info.Element ];

         %i = find( GROUP == hex2dec('2') & ELEME == hex2dec('3') ,1);
          i = find( GROUP ==          2   & ELEME ==          3   ,1);
          DINFO(ff).MediaStorageSOPInstanceUID = char( info(i).Data( ~~info(i).Data ) );

         %i = find( GROUP == hex2dec('10') & ELEME == hex2dec('20') ,1); (0010,0020)
          i = find( GROUP ==          16   & ELEME ==         32   ,1);
          DINFO(ff).PatientID = char( info(i).Data( ~~info(i).Data ) );  
          
         %i = find( GROUP == hex2dec('20') & ELEME == hex2dec('E') ,1);
          i = find( GROUP ==          32   & ELEME ==         14   ,1);
          DINFO(ff).SeriesInstanceUID = char( info(i).Data( ~~info(i).Data ) );

         %i = find( GROUP == hex2dec('20') & ELEME == hex2dec('37') ,1);
          i = find( GROUP ==          32   & ELEME ==          55   ,1);
          DINFO(ff).ImageOrientationPatient = sscanf( char( info(i).Data ) , '%f\\');

         %i = find( GROUP == hex2dec('20') & ELEME == hex2dec('32') ,1);
          i = find( GROUP ==          32   & ELEME ==          50   ,1);
          DINFO(ff).ImagePositionPatient = sscanf( char( info(i).Data ) , '%f\\');

          DINFO(ff).TriggerTime = 0;
          try
         %i = find( GROUP == hex2dec('18') & ELEME == hex2dec('1060') ,1);
          i = find( GROUP ==          24   & ELEME ==          4192   ,1);
          DINFO(ff).TriggerTime = sscanf( char( info(i).Data ) , '%f\\');
          end

         %i = find( GROUP == hex2dec('8') & ELEME == hex2dec('32') ,1);
          i = find( GROUP ==          8   & ELEME ==          50   ,1);
          DINFO(ff).AcquisitionTime = char( info(i).Data( ~~info(i).Data ) );

          DINFO(ff).AcquisitionTime = datenum( [ 1900 , 01 , 01 ,...
                        str2double( DINFO(ff).AcquisitionTime(1:2)   ) ,...
                        str2double( DINFO(ff).AcquisitionTime(3:4)   ) ,...
                        str2double( DINFO(ff).AcquisitionTime(5:end) ) ] );

          DINFO(ff).INFO = [];
        catch
          DINFO(ff).bytes = -1;
        end
      end
      cd(cwd);
      vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b... ...Done\n');

      
      DINFO( [ DINFO.bytes ] < 0 ) = [];
      if isfield( DINFO , 'bytes' ),     DINFO = rmfield( DINFO , 'bytes'   ); end

  end
  function fn = filename( f )
    [ p , fn , e ] = fileparts( f );
    fn = [ fn , e ];
  end
  function DINFO = DINFO_from_DCM( D )

    DINFO = struct();
    d = 1;
    INFO_0 = struct(); try, INFO_0 = D.INFO; end
    PS= getFieldNames( D , 'Patient_' );
    for p = 1:numel(PS),  P = PS{p}; INFO_P = INFO_0; try, INFO_P = mergestruct( INFO_P , D.(P).INFO ); end
      TS = getFieldNames( D.(P) , 'Study_' );
      for t = 1:numel(TS),   T = TS{t}; INFO_T = INFO_P; try, INFO_T = mergestruct( INFO_T , D.(P).(T).INFO ); end
        RS = getFieldNames( D.(P).(T) , 'Serie_' );
        for r = 1:numel(RS),   R = RS{r}; INFO_R = INFO_T; try, INFO_R = mergestruct( INFO_R , D.(P).(T).(R).INFO ); end
          OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' );
          for o = 1:numel(OS),   O = OS{o}; INFO_O = INFO_R; try, INFO_O = mergestruct( INFO_O , D.(P).(T).(R).(O).INFO ); end
            ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' );
            for z = 1:numel(ZS),   Z = ZS{z}; INFO_Z = INFO_O; try, INFO_Z = mergestruct( INFO_Z , D.(P).(T).(R).(O).(Z).INFO ); end
              IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' );
              for i = 1:numel(IS),   I = IS{i}; INFO_I = INFO_Z; try, INFO = mergestruct( INFO_I , D.(P).(T).(R).(O).(Z).(I).INFO ); end; try, INFO = mergestruct( D.(P).(T).(R).(O).(Z).(I).info , INFO ); end
                try
                  DINFO( d ).name                         = INFO.Filename;
                  DINFO( d ).MediaStorageSOPInstanceUID   = INFO.MediaStorageSOPInstanceUID;
                  DINFO( d ).PatientID                    = INFO.PatientID;
                  DINFO( d ).SeriesInstanceUID            = INFO.SeriesInstanceUID;
                  DINFO( d ).ImageOrientationPatient      = INFO.ImageOrientationPatient;
                  DINFO( d ).ImagePositionPatient         = INFO.ImagePositionPatient;
                  DINFO( d ).TriggerTime                  = INFO.TriggerTime;
                  DINFO( d ).AcquisitionTime              = INFO.AcquisitionTime;
                  DINFO( d ).INFO                         = INFO;

                  d = d+1;
                end
              end
            end
          end
        end
      end
    end
    
  end

end
function f = makeFH( s )
  f = eval(s);
end
