function D = DICOMgatherJC( files , varargin )
% TODO:
% - default options via .ini
% - group should preserve the full dicominfo
% - group should group also the path
% - allow add new data to an existing DCM
% - allow to load a DICOMDIR file
% - report conflicts to a file


  VERBOSE = true;
  try,[varargin,VERBOSE  ] = parseargs(varargin,'quiet' ,'$FORCE$',{false,true} );end

  preSORT = true; 
  try,[varargin,preSORT  ] = parseargs(varargin,'nosort' ,'$FORCE$',{false,preSORT} );end
  
  INFOFCN = @(fn)DICOMxinfo(fn); i = 0;
  try,[varargin,i,INFOFCN] = parseargs(varargin,'infofcn','$DEFS$',INFOFCN );end
  if i, UserProvidedINFOfcn = true;
  else, UserProvidedINFOfcn = false;
  end
  

  if nargin < 1 || isempty( files )
    files = pwd;
  end
  if ischar( files )
    if isdir( files )
      DEPTH = Inf;
      try,[varargin,i,DEPTH  ] = parseargs(varargin,'depth'  ,'$DEFS$', DEPTH );end

      vprintf('Reading directory ''%s''...',files);
      files = rdir(files,[],DEPTH);
      vprintf(' ...Done\n');
    else
      files = struct('name',files);
    end
  end
  if iscell( files )
    files = struct( 'name' , files );
  end

  if ~isfield( files , 'name' ) && isfield( files , 'Filename' )
    files = struct('name',{files.Filename});
  end
  
  [~,ids] = unique( { files.name } , 'first' );
  ids = setdiff( 1:numel(files) , ids );
  if numel(ids)
    vprintf('%d repeated files, removing them.\n',numel(ids));
    files(ids) = [];
  end
  
  
  try
    vprintf('Inspecting files...  ');
    nF = numel( files );
    vprintf('%6d of %6d',0,nF);
    DICfiles = false( nF , 1 );
    for ff = 1:nF
      try, DICfiles(ff) = ~strncmp( filename( files(ff).name ) , '.#.' , 3 ) && isdicom( files(ff).name ); end
      if ~mod(ff,100)
        vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%6d of %6d',ff,nF);
      end
    end
    vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b ...Done\n');
    vprintf('#Original files: %d   -   #DICOM files: %d',numel(files),sum(DICfiles));
    files = files( DICfiles );
    
    DICfiles = strcmp( cellfun( @(f)filename(f) , {files.name} ,'un',0) , 'DICOMDIR' );
    vprintf('   -   #DICOMDIR files: %d\n',sum(DICfiles));
    files = files( ~DICfiles );
  end
  
  findDUPS = false;
  try,[varargin,findDUPS] = parseargs(varargin,'checkDUPLICATES' ,'$FORCE$',{true,findDUPS} );end
  if findDUPS
    vprintf('Checking Duplicates...  ');
    
    nF = numel( files );
    vprintf('%6d of %6d',0,nF);
    for f = 1:nF
      if files(f).bytes < 0, continue; end
      vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%6d of %6d',f,nF);
      w = find( [ files.bytes ] == files(f).bytes );
      w( w <= f ) = [];
      for ff = w(:).'
        if areDuplicates( files(f).name , files(ff).name )
          files(ff).bytes = -1;
        end
      end
    end
    vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b ...Done   ');
    w = [ files.bytes ] < 0;
    if any(w)
      vprintf('%d files duplicates found.\n', sum(w) );
      files( w ) = [];
    else
      vprintf('No duplicated files.\n');
    end
  end


  KEYS_creators = varargin;  %%TODO 
  
  nF = numel( files );
  INFOS = cell( nF , 1 );
  if preSORT && nF > 1
    orderATT = {'SeriesNumber','SliceLocation','xZLevel','InstanceNumber','xDatenum','TriggerTime',@(item)date2num(item.ContentTime),@(item)string2number( filename(item.Filename,0) ,-1) };
    try,[varargin,i,orderATT] = parseargs(varargin,'ORDERatt','orderattribute','$DEFS$',orderATT);end
    if ~isa( orderATT , 'function_handle' ) && ~iscell( orderATT ), orderATT = { orderATT }; end
  
%     if numel( orderATT )
      IsValidImage = true( nF , 1 );
      vprintf('Pre sorting files: %6d of %6d items',0,nF);

      if isa( orderATT , 'function_handle' ), orderValue = NaN( nF , 1 );
      else,                                   orderValue = NaN( nF , numel(orderATT) );
      end
      for ff = 1:nF
        vprintf( '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%6d of %6d items', ff, nF );
        item = getINFO( ff );
        if ~isstruct( item )
          vprintf('  ');
          vprintf(2,'Invalid DICOM File?: ''%s''.\n', files(ff).name );
          vprintf('Pre sorting files: %6d of %6d items',ff,nF);
          IsValidImage(ff) = false;
          continue;
        end

        if isa( orderATT , 'function_handle' )
          try,   orderValue(ff,:) = orderATT(item);
          catch
            try, orderValue(ff,:) = orderATT( files(ff).name ); end
          end
        else
          for a = 1:numel(orderATT)
            orderValue(ff,a) = NaN;
            if ischar( orderATT{a} )
              try
                if ischar( item.(orderATT{a}) )
                  try
                    orderValue(ff,a) = date2num( item.(orderATT{a}) );
                  end
                end
              end
              try, orderValue(ff,a) = item.(orderATT{a}); end
            elseif isa( orderATT{a} , 'function_handle' )
              try
                orderValue(ff,a) = feval( orderATT{a} , item );
              end
            end
          end
        end
        %if any( isnan( orderValue(ff,:) ) )
        %  vprintf('\n');
        %  vwarning('Invalid orderATTRIBUTE: %s.\nin file: ''%s''', uneval( orderValue(ff,:) ) , files(ff).name );
        %  vprintf('Pre sorting files: %6d of %6d items',ff,nF);
        %end
      end
      orderValue = orderValue( IsValidImage , : );
      files      = files( IsValidImage );
      INFOS      = INFOS( IsValidImage );
      nF         = numel( files );

      vprintf('   -   #Invalid files: %d ', sum( ~IsValidImage ) );

      [ignore,order] = sortrows( orderValue , 1:size(orderValue,2) );
      files = files(order);
      INFOS = INFOS(order);

      vprintf(' ...Done\n');
    
%     end
  end
  
  
  defPATIENT     = @(item)item.PatientID;                         try,[varargin,~,defPATIENT     ] = parseargs( varargin,'defpatient'     ,'$DEFS$', defPATIENT     ); end
  defSTUDY       = @(item)'';                                     try,[varargin,~,defSTUDY       ] = parseargs( varargin,'defstudy'       ,'$DEFS$', defSTUDY       ); end
  defSERIE       = @(item)sprintf( 'N%03d' , item.SeriesNumber ); try,[varargin,~,defSERIE       ] = parseargs( varargin,'defserie'       ,'$DEFS$', defSERIE       ); end
  defORIENTATION = @(item)'';                                     try,[varargin,~,defORIENTATION ] = parseargs( varargin,'deforientation' ,'$DEFS$', defORIENTATION ); end
  defPOSITION    = @(item)'';                                     try,[varargin,~,defPOSITION    ] = parseargs( varargin,'defposition'    ,'$DEFS$', defPOSITION    ); end
  defIMAGE       = @(item)'';                                     try,[varargin,~,defIMAGE       ] = parseargs( varargin,'defimage'       ,'$DEFS$', defIMAGE       ); end
  
  
  if numel( varargin ) &&  isstruct( varargin{1} )
    D = varargin{1}; varargin(1) = [];
  else
    D = struct();
  end
  vprintf('%6d of %6d items',0,nF);
  for ff = 1:nF
  try
    vprintf( '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%6d of %6d items', ff, nF );
%     vprintf( '\n%6d of %6d items', ff, nF );
    item = getINFO( ff );
    if ~isstruct(item), error('no image'); end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% PATIENT
    key = item.zPATIENTkey;
    try,   P = getID( D , key , 'Patient_' , defPATIENT(item) );
    catch, P = getID( D , key , 'Patient_' );
    end
    w = { '.' , P };
    
    try, safe_assign_in_D( w , 'zPatientID'  , item.PatientID );  end
    try, safe_assign_in_D( w , 'zFamilyName' , item.PatientName.FamilyName );  end
    try, safe_assign_in_D( w , 'zPatientSex' , item.PatientSex );  end
    try, safe_assign_in_D( w , 'zPatientAge' , item.PatientAge );  end
    D.(P).zzKEY = key;
    %% --------------------------------------------------------------------

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% STUDY
    key = item.zSTUDYkey;
%     try,   T = getID( D.(P) , key , 'Study_' , defSTUDY(item) );
%     catch, T = getID( D.(P) , key , 'Study_' );
%     end
    T = 'Study_u01';
    w = [ w , '.' , T ];

    desc = '';
    try,desc = [ '_DIR_' , item.xDirname ];end; try, desc = item.StudyDescription; end
    try, safe_assign_in_D( w , 'zStudyInstanceUID' , item.StudyInstanceUID );  end
    try, safe_assign_in_D( w , 'zStudyDescription' , desc );  end
    try, safe_assign_in_D( w , 'zStudyDate'        , ToDay(item.StudyDate) );  end
    try, safe_assign_in_D( w , 'zStudyTime'        , ToTime(item.StudyTime) );  end
    D.(P).(T).zzKEY = key;
    %% --------------------------------------------------------------------
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% SERIE
    key = item.zSERIEkey;
    try,   R = getID_serie( D.(P).(T) , key , 'Serie_' , defSERIE(item) );
    catch, R = getID_serie( D.(P).(T) , key , 'Serie_' );
    end
    w = [ w , '.' , R ];

    desc = '';
    try,desc = [ '_DIR_' , item.xDirname ];end; try, desc = item.SeriesDescription; end
    try, safe_assign_in_D( w , 'zSeriesInstanceUID' , item.SeriesInstanceUID );  end
    try, safe_assign_in_D( w , 'zSeriesDescription' , desc );  end
    try, safe_assign_in_D( w , 'zSeriesNumber'      , item.SeriesNumber );  end
    try, safe_assign_in_D( w , 'zModality'          , item.Modality );  end
    try, safe_assign_in_D( w , 'zInstitution'       , item.Institution );  end
    try, safe_assign_in_D( w , 'zSeriesDate'        , ToDay(item.SeriesDate) );  end
    try, safe_assign_in_D( w , 'zSeriesTime'        , ToTime(item.SeriesTime) );  end
    D.(P).(T).(R).zzKEY = key;
    %% --------------------------------------------------------------------


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ORIENTATION
    key = item.zORIENTATIONkey; 
    try,   O = getID( D.(P).(T).(R) , key , 'Orientation_' , defORIENTATION(item) );
    catch, O = getID( D.(P).(T).(R) , key , 'Orientation_' );
    end
    w = [ w , '.' , O ];
    
    try, safe_assign_in_D( w , 'zOrientation' , reshape( item.ImageOrientationPatient , 3 , 2 ).' );  end
    try, safe_assign_in_D( w , 'zSize' , [ item.Rows , item.Columns ] , 0 );  end
    D.(P).(T).(R).(O).zzKEY = key;
    %% ---------------------------------------------------------------------


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ZS-POSITION
    key = item.zPOSITIONkey; 
    try,   Z = getID( D.(P).(T).(R).(O) , key , 'Position_' , defPOSITION(item) );
    catch, Z = getID( D.(P).(T).(R).(O) , key , 'Position_' );
    end
    w = [ w , '.' , Z ];

    try, safe_assign_in_D( w , 'zZLevel' , item.xZLevel , 1 );  end
    try, safe_assign_in_D( w , 'zatt' , att );  end
    D.(P).(T).(R).(O).(Z).zzKEY = key;
    %% --------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% IMAGE
    key = item.zIMAGEkey; 
    try,   I = getID( D.(P).(T).(R).(O).(Z) , key , 'IMAGE_' , defIMAGE(item) );
    catch, I = getID( D.(P).(T).(R).(O).(Z) , key , 'IMAGE_' );
    end
    if isfield( D.(P).(T).(R).(O).(Z) , I )
      %The image already exits, skip it
      vprintf( '  ' );
      if 0 & areDuplicates( D.(P).(T).(R).(O).(Z).(I).info.Filename , item.Filename )
        vwarning( 'skipping ''%s'' since it is duplicate of ''%s''\n' , item.Filename , D.(P).(T).(R).(O).(Z).(I).info.Filename );
      else
        vwarning( 'skipping ''%s''.  try with DICOMcompare( ''%s'' , ''%s'' )\n' , item.Filename , D.(P).(T).(R).(O).(Z).(I).info.Filename , item.Filename );
      end
      vprintf( '%6d of %6d items', ff, nF );
      continue;
    end
    
    w = [ w , '.' , I ];

    try, safe_assign_in_D( w , 'zFileName' , files(ff).name );  end
         [fnp,fnf,fne] = fileparts( files(ff).name );
         safe_assign_in_D( w , 'zDirname'  , fnp );
         safe_assign_in_D( w , 'zFilename' , [fnf,fne] );
    try, safe_assign_in_D( w , 'zSize' , item.xSize );  end
    D.(P).(T).(R).(O).(Z).(I).zMediaStorageSOPInstanceUID = item.MediaStorageSOPInstanceUID;
    D.(P).(T).(R).(O).(Z).(I).info = item;
    %     D.(P).(T).(R).(O).(Z).(I).INFO = D.(P).(T).(R).(O).(Z).(I).info;
    %     try, D.(P).(T).(R).(O).(Z).(I).zSize                = [ item.Rows item.Columns ];       end
    %     try, D.(P).(T).(R).(O).(Z).(I).zTriggerTime         = item.TriggerTime;                 end
    %     try, D.(P).(T).(R).(O).(Z).(I).zInstanceNumber      = item.InstanceNumber;              end
    %     try, D.(P).(T).(R).(O).(Z).(I).zImageComments       = item.ImageComments;               end
    %     try, D.(P).(T).(R).(O).(Z).(I).zPixelsSpacing       = item.PixelSpacing';               end
    %     try, D.(P).(T).(R).(O).(Z).(I).zSliceThickness      = item.SliceThickness;              end
    %     try, D.(P).(T).(R).(O).(Z).(I).zImageType           = item.ImageType;                   end
    %     try, D.(P).(T).(R).(O).(Z).(I).zINFO                = item;                             end
    D.(P).(T).(R).(O).(Z).(I).zzKEY = key;
    %% ---------------------------------------------------------------------
    
  catch    
    vprintf('  ');
    vprintf(2,'some error in File: ''%s''.\n', files(ff).name );
    vprintf('%6d of %6d items', ff, nF );
  end
  end

  %fix the size of Orientations
  PS = getFieldNames( D , 'Patient_' );
  for p = 1:numel(PS),  P= PS{p};
    TS = getFieldNames( D.(P) , 'Study_' );
    for t = 1:numel(TS),   T= TS{t};
      RS = getFieldNames( D.(P).(T) , 'Serie_' );
      for r = 1:numel(RS),   R= RS{r};
        OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' );
        for o = 1:numel(OS),   O= OS{o};
          ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' );
          
          nImages = NaN( numel(ZS) , 1 );
          for z = 1:numel(ZS),    Z= ZS{z};
            IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' );

            %%
            ImageTimes = NaN( 1 , numel(IS) );
            for i = 1:numel(IS),    I = IS{i};
              try
                ImageTimes(i) = D.(P).(T).(R).(O).(Z).(I).info.xDatenum;
              end
            end
            if alleq( ImageTimes )
              ImageTimes = NaN( 1 , numel(IS) );
              for i = 1:numel(IS),    I = IS{i};
                try
                  ImageTimes(i) = date2num( D.(P).(T).(R).(O).(Z).(I).info.ContentTime );
                end
              end
            end
            
            if numel( ImageTimes ) > 1
              ImageTimes = ImageTimes - min( ImageTimes );
              ImageTimes = round(ImageTimes*3600*24*1000)/1000;
            end
            
            D.(P).(T).(R).(O).(Z).zImageTimes = ImageTimes;

            
            %%
            try
            ImageTimes = NaN( 1 , numel(IS) );
            for i = 1:numel(IS),    I = IS{i};
              try
                ImageTimes(i) = D.(P).(T).(R).(O).(Z).(I).info.TriggerTime;
              end
            end
            
            if numel( ImageTimes ) > 1
              ImageTimes = ImageTimes - min( ImageTimes );
            end
            
            D.(P).(T).(R).(O).(Z).zTriggerTimes = ImageTimes;
            end
            
            nImages(z) = numel( IS );
          end

          if all( nImages == nImages(1) )
            try, D.(P).(T).(R).(O).zSize = [ D.(P).(T).(R).(O).zSize , numel(ZS) , nImages(1) ]; end
          end
        end
      end
    end
  end
%   %at end add zNumberOf... attribute
%   P = getFieldNames( D , 'Patient_' );
%   D.zNumberOfPatients = numel(P);
%   for p = 1:numel(P), p = P{p};
%     T = getFieldNames( D.(p) , 'Study_' );
%     D.(p).zNumberOfStudies = numel(T);
%     for t = 1:numel(T), t = T{t};
%       R = getFieldNames( D.(p).(t) , 'Serie_' );
%       D.(p).(t).zNumberOfSeries = numel(R);
%       for r = 1:numel(R), r = R{r};
%         O = getFieldNames( D.(p).(t).(r) , 'Orientation_' );
%         D.(p).(t).(r).zNumberOfOrientations = numel(O);
%         for o = 1:numel(O), o = O{o};
%           Z = getFieldNames( D.(p).(t).(r).(o) , 'Position_' );
%           D.(p).(t).(r).(o).zNumberOfPositions = numel(Z);
%           for z = 1:numel(Z), z = Z{z};
%             I = getFieldNames( D.(p).(t).(r).(o).(z) , 'IMAGE_' );
%             D.(p).(t).(r).(o).(z).zNumberOfImages = numel(I);
%           end
%         end
%       end
%     end
%   end
  vprintf(' ...Done\n');
  
  %try,[varargin,GROUP] = parseargs(varargin,'group','$FORCE$',{true,false});end
  GROUP = true;
  try,[varargin,GROUP] = parseargs(varargin,'nogroup','$FORCE$',{false,GROUP});end
  if GROUP
    vprintf('Grouping...');
    try
      D = DCMgroup(D);
      vprintf(' ...Done\n');
    catch
      fprintf('Some error in the grouping step. try: D = DCMgroup(D)\n');
    end
  end
  
  function p = getID( S , key , str , def )
    if ischar( key )
    switch key
      case 'UNKNOW_PATIENT',      p = 'Patient_unknow';       return;
      case 'UNKNOW_STUDY',        p = 'Study_unknow';         return;
      case 'UNKNOW_SERIE',        p = 'Serie_unknow';         return;
      case 'UNKNOW_ORIENTATION',  p = 'Orientation_unknow';   return;
      case 'UNKNOW_POSITION',     p = 'Position_unknow';      return;
      case 'UNKNOW_IMAGE',        p = 'IMAGE_unknow';         return;
    end
    end
    
    FN = getFieldNames( S , str );
    for p = 1:numel(FN)
      try
      p = FN{p};
      switch str
        case {'Position_'},    if isequal( S.(p).zzKEY , key ) || max( abs( S.(p).zzKEY(:) - key(:) ) ) < 1e-9, return; end
        case {'Orientation_'}, if isequal( S.(p).zzKEY , key ) || max( abs( S.(p).zzKEY(:) - key(:) ) ) < 1e-5, return; end
        otherwise,             if isequal( S.(p).zzKEY , key ), return; end
      end
      end
    end
    if nargin < 4 || isempty( def ) %|| ( isnumeric(def) && ~def ) || ( islogical(def) && ~def )
      switch str
        case {'Position_'}, def = sprintf( '%s%03d' , str , numel(FN)+1 );
        case {'IMAGE_'},    def = sprintf( '%s%03d' , str , numel(FN)+1 );
        otherwise,          def = sprintf( '%s%02d' , str , numel(FN)+1 );
      end
    else
      if ~strncmp( def , str , numel(str) )
        def = [ str , def ];
      end
      def = regexprep( def , '^([^A-Za-z]*)' , '' );
      def = regexprep( def , '([^A-Za-z0-9_]*)' , '_' );
      def = def(1:min(60,end));
    end
    newL = 'A';
    while isfield( S , def )
      if numel( def ) > 60
        def = [ def(1:end-1) , '_' , newL ]; newL = char( new+1 );
      else
        def = [ def , '_' ];
      end
    end
    p = def;
  end

  function item = getINFO( ff )
    item = INFOS{ff};
    if isstruct( item ), return; end
    item = NaN;
    try
      item = INFOFCN( files(ff).name );
      if UserProvidedINFOfcn
        try, item = DICOMxinfo( item ); end
      end
      
% % % % % % % % % % % %   %some information to improved the gahtering by using KEYS     %%TODO at begining, outside getINFO
% % % % % % % % % % % %   %personalized keys (provided by varargin)
% % % % % % % % % % % %   for K = {'PATIENT','STUDY','SERIE','ORIENTATION','POSITION','IMAGE'}, K = K{1};
% % % % % % % % % % % %     if isfield( item , [ 'z' , K , 'key' ] ), continue; end
% % % % % % % % % % % %     [i,i,KEY] = parseargs( KEYS_creators , [K,'key'],[K,'Skey'],'$DEFS$',[]);
% % % % % % % % % % % %     if      isempty(KEY), continue;
% % % % % % % % % % % %     elseif  ischar( KEY ),              try, item.([ 'z' , K , 'key' ]) = item.(KEY); end
% % % % % % % % % % % %     elseif  isa(KEY,'function_handle'), try, item.([ 'z' , K , 'key' ]) = KEY( item ); end
% % % % % % % % % % % %     end
% % % % % % % % % % % %   end

  %if KEYS haven't been provided, try to use the default KEYS
  if ~isfield( item , 'zPATIENTkey')
    item.zPATIENTkey = [];
    try, item.zPATIENTkey = item.PatientID; end
    if isempty( item.zPATIENTkey ), item.zPATIENTkey = 'UNKNOW_PATIENT'; end
  end
  if ~isfield( item , 'zSTUDYkey')
    item.zSTUDYkey = [];
    try, item.zSTUDYkey = item.StudyInstanceUID; end
    if isempty( item.zSTUDYkey ), item.zSTUDYkey = 'UNKNOW_STUDY'; end
  end
  if ~isfield( item , 'zSERIEkey')
    item.zSERIEkey = [];
    try, item.zSERIEkey = item.SeriesInstanceUID; end
    if isempty( item.zSERIEkey ), item.zSERIEkey = 'UNKNOW_SERIE'; end
  end
  if ~isfield( item , 'zORIENTATIONkey')
    try
      item.zORIENTATIONkey = [];
      try, item.zORIENTATIONkey = item.ImageOrientationPatient(:); end
      try, item.zORIENTATIONkey = [ item.zORIENTATIONkey ; double(item.Rows(:)) ; double(item.Columns(:)) ]; end
      if isempty( item.zORIENTATIONkey ), item.zORIENTATIONkey = 'UNKNOW_ORIENTATION'; end
    end
  end
  if ~isfield( item , 'zPOSITIONkey')
    item.zPOSITIONkey = [];
    try, item.zPOSITIONkey = item.ImagePositionPatient; end
    if isempty(item.zPOSITIONkey), item.zPOSITIONkey = 'UNKNOW_POSITION'; end
  end
  if ~isfield( item , 'zIMAGEkey')
    item.zIMAGEkey = [];
    try, item.zIMAGEkey = item.MediaStorageSOPInstanceUID; end
    if isempty( item.zIMAGEkey ), item.zIMAGEkey = 'UNKNOW_IMAGE'; end
  end
  
    end
    try, INFOS{ff} = item; end
  end

  function safe_assign_in_D( w , key , value , warm )  %%TODO add CONFLICTS
    %warm cases: 1 - check if it exists and warm, do not overlap
    %            0 - if it exists return doing nothing
    
    if nargin < 4, warm = 1; end
    w = substruct( w{:} , '.' , key );
    try
      prev_value = subsref( D , w );
    catch
      D = subsasgn( D , w , value );
      return;
    end
    if warm == 1 && ~isequal( prev_value , value )   %%TODO conflicts
      D = subsasgn( D , [ w(1:end-1) , substruct('.','CONFLICT') ] , ...
        struct('in',w(end).subs,'prev_value',prev_value,'new_value',value ) );
      vprintf('\n');
      vprintf( '************** C O N F L I C T !!! **************\n' );
      vwarning( 'Existing attribute with a different value.\nin file: ''%s''', files(ff).name );
      try
      vprintf(' attribute stored in: %s\n',sprintf('.%s',w.subs) );
      vprintf('value already stored: %s\n',uneval( prev_value ) );
      vprintf('    this image value: %s\n',uneval( value ) );
      end
      vprintf( '-------------------------------------------------\n\n' );
      vprintf( '%6d of %6d items', ff, nF );
    end
  end

  function vprintf( varargin )
    if VERBOSE, fprintf( varargin{:} ); end
  end
  function vwarning( varargin )
%     disp('in vwarning');
    if VERBOSE
%       old_state = warning('query','backtrace'); warning('off','backtrace');
%       warning( varargin{:} );
%       warning( old_state );
      fprintf( 2 , 'WARNING! ' );
      fprintf( varargin{:} );
    end    
  end
end

function t = date2num( str )
  if      ~isempty( regexp( str , '^[\d]{2}-[\D]{3}-([\d]{2}|[\d]{4})\s+[\d]{2}\:[\d]{2}\:[\d]{2}$' ) )
    t = datenum( str );
  elseif  ~isempty( regexp( str , '^[\d]{8}^' ) )
    t = datenum( [str2double(str(1:4)),str2double(str(5:6)),str2double(str(7:8))] );
  elseif  ~isempty( regexp( str , '^[\d]{6}\.\d{2,}$' ) )
    t = datenum([1900,01,01,str2double(str(1:2)),str2double(str(3:4)),str2double(str(5:end))]);
  else
    error('no valid date nor time');
  end
end
function hms = ToTime( hms )
  hms = datestr(datenum([1900,01,01,str2double(hms(1:2)),str2double(hms(3:4)),str2double(hms(5:end))]), 'HH:MM:SS.FFF');
end
function day = ToDay( day )
  day = datestr(datenum([str2double(day(1:4)),str2double(day(5:6)),str2double(day(7:8))]), 'mmm.dd,yyyy');
end
function names = getFieldNames( S , str )
  names = fieldnames( S );
  names = names( strncmp( names , str , numel(str) ) );
end
function is = safe_isdicom( f )
  is = false;
  try, is = isdicom( f ); 
  catch
    keyboard;
  end
end

function p = getID_serie( S , key , str , def )
if ischar( key )
  switch key
    case 'UNKNOW_PATIENT',      p = 'Patient_unknow';       return;
    case 'UNKNOW_STUDY',        p = 'Study_unknow';         return;
    case 'UNKNOW_SERIE',        p = 'Serie_unknow';         return;
    case 'UNKNOW_ORIENTATION',  p = 'Orientation_unknow';   return;
    case 'UNKNOW_POSITION',     p = 'Position_unknow';      return;
    case 'UNKNOW_IMAGE',        p = 'IMAGE_unknow';         return;
  end
end

FN = getFieldNames( S , str );
for p = 1:numel(FN)
  try
    p = FN{p};
    switch str
      case {'Position_'},    if isequal( S.(p).zzKEY , key ) || max( abs( S.(p).zzKEY(:) - key(:) ) ) < 1e-9, return; end
      case {'Orientation_'}, if isequal( S.(p).zzKEY , key ) || max( abs( S.(p).zzKEY(:) - key(:) ) ) < 1e-5, return; end
      otherwise,             if isequal( S.(p).zzKEY , key ), return; end
    end
  end
end
if nargin < 4 || isempty( def ) %|| ( isnumeric(def) && ~def ) || ( islogical(def) && ~def )
  switch str
    case {'Position_'}, def = sprintf( '%s%03d' , str , numel(FN)+1 );
    case {'IMAGE_'},    def = sprintf( '%s%03d' , str , numel(FN)+1 );
    otherwise,          def = sprintf( '%s%02d' , str , numel(FN)+1 );
  end
else
  if ~strncmp(def, str, numel(str)),  def = [str, def]; end
  def = regexprep( def , '^([^A-Za-z]*)' , '' );
  def = regexprep( def , '([^A-Za-z0-9_]*)' , '_' );
  def = def(1:min(60,end));
end
p = def;
end