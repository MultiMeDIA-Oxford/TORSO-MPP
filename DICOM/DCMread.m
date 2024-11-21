function [ DATA , X , Y , Z , R , INFO , infos ] = DCMread( D , varargin )

  CHECKsingleVolume = false;
  try,[varargin,CHECKsingleVolume] = parseargs(varargin,'CHECKonly','$FORCE$',{true,CHECKsingleVolume});end

  D = DCMvalidate( D );

  %% find the unique orientation to read
  ORI = {};
  try
    PS = getFieldNames( D , 'Patient_' );
    for p = 1:numel(PS),  P = PS{p};
      TS = getFieldNames( D.(P) , 'Study_' );
      for t = 1:numel(TS),   T = TS{t};
        RS = getFieldNames( D.(P).(T) , 'Serie_' );
        for r = 1:numel(RS),   R = RS{r};
          OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' );
          for o = 1:numel(OS),   O = OS{o};
            if ~isempty( ORI ), error('too much orientations.'); end
            ORI = { P , T , R , O };
          end
        end
      end
    end
  catch
    if CHECKsingleVolume, DATA = false; return; end
    error('too much orientations.');
  end
  
  O = D.( ORI{1} ).( ORI{2} ).( ORI{3} ).( ORI{4} );
  ZS = getFieldNames( O , 'Position_' ); ZS = ZS(:);

  %% check that all Slice Positions have the same number of images
  nImages = [];
  try
    for z = 1:numel( ZS ); Z = ZS{z};
      value = numel( getFieldNames( O.(Z) , 'IMAGE_' ) );
      if z == 1, nImages = value; end
      if ~isequal( value , nImages ), error('no structured volume'); end
    end
  catch
    if CHECKsingleVolume, DATA = false; return; end
    error('no structured volume');
  end
  if CHECKsingleVolume, DATA = true; return; end
  
  %% read the info of the items
  VERBOSE = ( numel(ZS)*nImages ) > 30;

  infos = cell( numel(ZS) , nImages );
  vprintf('reading header of slice: %4d of %4d  -  image: %4d of %4d',0,numel(ZS),0,0);
  for z = 1:numel(ZS), Z = ZS{z};
    IS = getFieldNames( O.(Z) , 'IMAGE_' );
    for i = 1:numel(IS), I = IS{i};
      vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%4d of %4d  -  image: %4d of %4d',z,numel(ZS),i,numel(IS));

      if isempty( infos{z,i} )
        try,   infos{z,i} = O.(Z).(I).info; end
      end
      
      if isempty( infos{z,i} )
        fn = [];
        if isempty( fn ), try, fn = fullfile( O.(Z).(I).zDirname , O.(Z).(I).zFilename );            end; end
        if isempty( fn ), try, fn = O.(Z).(I).zFilename;                                             end; end
        if isempty( fn ), try, fn = fullfile( O.(Z).(I).INFO.xDirname , O.(Z).(I).INFO.xFilename );  end; end
        if isempty( fn ), try, fn = O.(Z).(I).INFO.Filename;                                         end; end
        if isempty( fn ), try, fn = fullfile( O.(Z).(I).info.xDirname , O.(Z).(I).info.xFilename );  end; end
        if isempty( fn ), try, fn = O.(Z).(I).info.Filename;                                         end; end
        if isempty( fn ), error('unknow filename'); end

        try,   infos{z,i} = dicominfo( fn ); end
      end
      if isempty( infos{z,i} ), error('the file cannot be readed'); end

      try, infos{z,i} = DICOMxinfo( infos{z,i} ); end
      try, infos{z,i}.DATA = O.(Z).(I).DATA; end
    end
  end
  vprintf('\n');
  nZ = size( infos , 1 );
  nP = size( infos , 2 );

  
  %% sorting phases
  orderATT = {}; %{'xDatenum','TriggerTime','InstanceNumber'}
  try,[varargin,i,orderATT] = parseargs(varargin,'ORDERatt','orderattribute','$DEFS$',orderATT); end
  if ~isa( orderATT , 'function_handle' ) && ~iscell( orderATT ), orderATT = { orderATT }; end
  if numel( orderATT )
    for z = 1:nZ
      orderValue = [];
      for i = 1:nP
        if isa( orderATT , 'function_handle' )
          orderValue(i,:) = orderATT( infos{z,i} );
        else
          for a = 1:numel(orderATT)
            orderValue(i,a) = infos{z,i}.(orderATT{a});
          end
        end
      end
      [ignore,pOrder] = sortrows( orderValue , 1:size(orderValue,2) );
      infos(z,:) = infos(z,pOrder);
    end
  end
  
  %% remove, if it is the case, the unwanted phases
  PHASEStoRead = true( 1 , nP );
  try,[varargin,i,PHASEStoRead]= parseargs( varargin ,'phases','$DEFS$', PHASEStoRead );end
  infos = infos(:,PHASEStoRead);
  nP = size( infos , 2 );
  
  %% checking all have the same size
  VALUE = [];
  for z = 1:nZ
    for p = 1:nP
      value = [ infos{z,p}.Rows , infos{z,p}.Columns ];
      if z == 1 && p == 1, VALUE = value; end
      if ~isequal( value , VALUE ), error('different sizes'); end
    end
  end

  %% checking all have the same orientation
  VALUE = [];
  for z = 1:nZ
    for p = 1:nP
      value = infos{z,p}.ImageOrientationPatient;
      if z == 1 && p == 1, VALUE = value; end
      if max( abs( value - VALUE ) ) > 1e-5
% %       if ~isequal( value , VALUE ), 
        error('different orientations');
      end
    end
  end
  
  %% checking all have the same pixel Spacings
  VALUE = [];
  for z = 1:nZ
    for p = 1:nP
      value = infos{z,p}.PixelSpacing;
      if z == 1 && p == 1, VALUE = value; end
      if ~isequal( value , VALUE ), error('different pixel sizes'); end
    end
  end
  
  %% checking that, within a Position, all have the same coordinates
  for z = 1:nZ
    VALUE = [];
    for p = 1:nP
      value = infos{z,p}.ImagePositionPatient;
      if p == 1, VALUE = value; end
      if ~isequal( value , VALUE ), error('different position coordinates'); end
    end
  end

  %% Positions
  POS = NaN( nZ , 3 );
  for z = 1:nZ
    POS(z,:) = infos{z,1}.ImagePositionPatient(:).';
  end

  %% rotation matrix
  R = infos{1,1}.ImageOrientationPatient;
  R = reshape( R , 3 , 2 );
  
  R(:,3)= cross( R(:,1), R(:,2) );
  for c=1:3, for it = 1:5, R(:,c) = R(:,c)/sqrt( R(:,c).' * R(:,c) ); end; end
  
  %% sorting the slices
  xyz = POS / ( R.' ); %it should be the same that ( POS * R )
  if var( xyz(:,1) ) > 1e-8 ||...
     var( xyz(:,2) ) > 1e-8
    warning('slices can be disaligned.');
  end
  
  
  [~,zOrder] = sort( xyz(:,3) , 'ascend' );
  xyz   = xyz(zOrder,:);
  infos = infos(zOrder,:);

  %% rotation matrix and coordinates
  origin = xyz(1,:) * R.';
  R = [ R , origin(:) ; 0 0 0 1 ];

  X = ( 0:( double(infos{1,1}.Columns) - 1 ) ) * double( infos{1,1}.PixelSpacing(1) );
  Y = ( 0:( double(infos{1,1}.Rows   ) - 1 ) ) * double( infos{1,1}.PixelSpacing(2) );
  Z = ( xyz(:,3) - xyz(1,3) ).';
  

  %% Filling the DATA volume
  vprintf('slice: %4d of %4d  -  phase: %4d of %4d',0,nZ,0,nP);
  for z = nZ:-1:1
    for p = nP:-1:1
      vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%4d of %4d  -  phase: %4d of %4d',z,nZ,p,nP);

      if isfield( infos{z,p} , 'DATA' ) && ~isempty( infos{z,p}.DATA )
        slice = infos{z,p}.DATA;
      else
        fn = [];
        if isempty( fn ), try, fn = infos{z,p}.Filename; end; end
        if isempty( fn ), error('error in slice Filename'); end

        slice = [];
        if isempty(slice), try,  slice =     dicomread( fn ); end; end
        if isempty(slice), try,  slice = safedicomread( fn ); end; end
        if isempty(slice), error('error reading slice'); end
      end

      if size( slice ,3) == numel(z) && ...
         size( slice ,4) == numel(p) 
        
        DATA(:,:,z,p) = slice;
      
      elseif size( slice ,4) > 1
        
        DATA = squeeze( slice );
        Z = ( 0:size(DATA)-1 ) * infos{z,p}.SpacingBetweenSlices;
        
      end
    end
  end
  vprintf('\n');
  

  
  if nargout < 2 || nargout > 5
    %% find the common attributes
    INFO = infos{1};
    for i = 2:numel(infos)
      INFO = remove_unequals( INFO , infos{i} );
    end
    % and remove them from innfos
    F = fieldnames( INFO );
    for i = 1:numel(infos), infos{i} = rmfield( infos{i} , F ); end
  end
  if nargout < 2
    DATA = struct('DATA' , DATA ,...
                     'X' , X    ,...
                     'Y' , Y    ,...
                     'Z' , Z    ,...
                     'R' , R    ,...
            'commonINFO' , INFO ,...
            'slicesINFO' , {infos} );
  end
  

  %%
  function names = getFieldNames( S , str )
    names = fieldnames( S );
    names = names( strncmp( names , str , numel(str) ) );
  end
  function A = remove_unequals( A , B )
    if isempty(A)
      A = B;
      F = fieldnames(A); F = F( strncmp(F,'z',1) );
      A = rmfield( A , F );
    else
      F = fieldnames(A);
      for f = 1:numel(F)
        if  isfield( B , F{f} ) &&...
            isequal( A.(F{f}) , B.(F{f}) )
          F{f} = '';
        end
      end
      F( cellfun('isempty',F) ) = [];
      A = rmfield( A , F );
    end
  end
  function vprintf( varargin )
    if VERBOSE, fprintf( varargin{:} ); end
  end

end
