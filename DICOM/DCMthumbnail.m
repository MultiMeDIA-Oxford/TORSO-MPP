function D = DCMthumbnail( D , maxsz , FIELD , REDO , VERBOSE )
%
% D = DCMthumbnail( D , 'default' );
% 

  if nargin < 5, VERBOSE = true; end
  if nargin < 4, REDO = false; end
  if nargin < 3, FIELD = ''; end
  if nargin < 2 || isempty( maxsz ), maxsz = Inf; end
  if ischar( maxsz ) && ( strcmpi( maxsz , 'default' ) || strcmpi( maxsz , 'def' ) )
    maxsz = @(s)[ [1,1] * max( 512 , ( s(4)==1 )*1e4 ) , 3 , 25*max( 1 , ( s(1)*s(2) <= 2^16 ) * 10 ) ];
  end
  if isnumeric( maxsz )
    if numel( maxsz ) < 2
      maxsz = [ maxsz , maxsz ];
    end
    maxsz( end+1:4 ) = Inf;
    maxsz(3) = Inf;
    maxsz = maxsz(:).';
  elseif isa( maxsz , 'function_handle' )
  else
    error('invalid specification of maxsz.');
  end
  if VERBOSE
    vprintf = @(level,varargin)level>=2&&fprintf(varargin{:});
  else
    vprintf = @(varargin)0;
  end
  
  D = DCMvalidate( D );
  
  PS = {};  TS = {};  RS = {};  OS = {};  ZS = {};  IS = {};
  if ~isempty( FIELD )
    FIELD = regexp( FIELD , '(?<f>Patient_[^\.]*)\.?(?<F>.*)' ,'names','once');
    PS = FIELD.f; FIELD = FIELD.F;
  end
  if ~isempty( FIELD )
    FIELD = regexp( FIELD , '(?<f>Study_[^\.]*)\.?(?<F>.*)' ,'names','once');
    TS = FIELD.f; FIELD = FIELD.F;
  end
  if ~isempty( FIELD )
    FIELD = regexp( FIELD , '(?<f>Serie_[^\.]*)\.?(?<F>.*)' ,'names','once');
    RS = FIELD.f; FIELD = FIELD.F;
  end
  if ~isempty( FIELD )
    FIELD = regexp( FIELD , '(?<f>Orientation_[^\.]*)\.?(?<F>.*)' ,'names','once');
    OS = FIELD.f; FIELD = FIELD.F;
  end
  if ~isempty( FIELD )
    FIELD = regexp( FIELD , '(?<f>Position_[^\.]*)\.?(?<F>.*)' ,'names','once');
    ZS = FIELD.f; FIELD = FIELD.F;
  end
  if ~isempty( FIELD )
    FIELD = regexp( FIELD , '(?<f>IMAGE_[^\.]*)\.?(?<F>.*)' ,'names','once');
    IS = FIELD.f; FIELD = FIELD.F;
  end
  
  

  if iscell(PS),  PS= getFieldNames( D , 'Patient_' ); else, PS = {PS}; end
  for p = 1:numel(PS),  P = PS{p};
    if iscell(TS),  TS = getFieldNames( D.(P) , 'Study_' ); else, TS = {TS}; end
    for t = 1:numel(TS),   T = TS{t};
      if iscell(RS),  RS = getFieldNames( D.(P).(T) , 'Serie_' ); else, RS = {RS}; end
      for r = 1:numel(RS),   R = RS{r};
        if iscell(OS),  OS = getFieldNames( D.(P).(T).(R) , 'Orientation_' ); else, OS = {OS}; end
        for o = 1:numel(OS),   O = OS{o};
          if iscell(ZS),  ZS = getFieldNames( D.(P).(T).(R).(O) , 'Position_' ); else, ZS = {ZS}; end
          for z = 1:numel(ZS),   Z = ZS{z};
            if iscell(IS),  IS = getFieldNames( D.(P).(T).(R).(O).(Z) , 'IMAGE_' ); else, IS = {IS}; end
            for i = 1:numel(IS),   I = IS{i};
              
              if ~REDO && isfield( D.(P).(T).(R).(O).(Z).(I) , 'zThumbnail' ) && ~isempty( D.(P).(T).(R).(O).(Z).(I).zThumbnail ), continue; end
              try, D.(P).(T).(R).(O).(Z).(I) = rmfield( D.(P).(T).(R).(O).(Z).(I) , 'zThumbnail' ); end
              vprintf(1,'"reading" image  %s.%s.%s.%s.%s.%s  ' , P , T , R , O , Z , I );
              try
                im = [];
                if isempty(im), try, im = D.(P).(T).(R).(O).(Z).(I).DATA; vprintf(1,' from DATA  '); end; end
                if isempty(im), try, im = dicomread( fullfile( D.(P).(T).(R).(O).(Z).(I).zDirname , D.(P).(T).(R).(O).(Z).(I).zFilename ) ); vprintf(1,' from FILE  ');  end; end
                if isempty(im)
                  vprintf(1,' empty DATA\n' );
                  try, D.(P).(T).(R).(O).(Z).(I) = rmfield( D.(P).(T).(R).(O).(Z).(I) , 'zThumbnail' ); end
                  continue;
                end

                im = makeThumbnail( im , Inf(1,4) , true );
                D.(P).(T).(R).(O).(Z).(I).zThumbnail = im;
                vprintf(1,'...done    ( size= %d x %d x %d %d )\n', size(im,1), size(im,2), size(im,3), size(im,4) );
              catch, vprintf(1e3,2,'some error in making image thumbnail.\n'); end
              
            end
            
            if ~REDO && isfield( D.(P).(T).(R).(O).(Z) , 'zThumbnail' ) && ~isempty( D.(P).(T).(R).(O).(Z).zThumbnail ), continue; end
            try, D.(P).(T).(R).(O).(Z) = rmfield( D.(P).(T).(R).(O).(Z) , 'zThumbnail' ); end
            if numel( IS ) <= 1, continue; end
            
            vprintf(2, 'collecting IMAGES within POSITION  %s.%s.%s.%s.%s  ' , P , T , R , O , Z );
            try
              D.(P).(T).(R).(O).(Z).zThumbnail = makeThumbnail( collectIMAGES( D.(P).(T).(R).(O).(Z) , IS ) , maxsz );
              vprintf(2,'...done\n');
            catch, vprintf(1e3,2,'some error in collecting images.\n'); end
            
          end
          
          if ~REDO && isfield( D.(P).(T).(R).(O) , 'zThumbnail' ) && ~isempty( D.(P).(T).(R).(O).zThumbnail ), continue; end
          try, D.(P).(T).(R).(O) = rmfield( D.(P).(T).(R).(O) , 'zThumbnail' ); end
          if numel( ZS ) <= 1, continue; end

          vprintf(3,'collecting POSITIONS in ORIENTATION  %s.%s.%s.%s  ' , P , T , R , O );
          try
            D.(P).(T).(R).(O).zThumbnail = makeThumbnail( collectPOSITIONS( D.(P).(T).(R).(O) , ZS ) , maxsz );
            vprintf(3,'...done\n');
          catch, vprintf(1e3,2,'some error in collecting positions.\n'); end
          
        end
        
        if ~REDO && isfield( D.(P).(T).(R) , 'zThumbnail' ) && ~isempty( D.(P).(T).(R).zThumbnail ), continue; end
        try, D.(P).(T).(R) = rmfield( D.(P).(T).(R) , 'zThumbnail' ); end
        if numel( OS ) <= 1, continue; end

        vprintf(4,'collect ORIENTATIONS in SERIE  %s.%s.%s  ' , P , T , R );
        try
          D.(P).(T).(R).zThumbnail = collectORIENTATIONS( D.(P).(T).(R) , OS );
          vprintf(4,'...done\n');
        catch, vprintf(1e3,2,'some error in collecting orientations.\n'); end
        
      end
    end
  end
  
end
function names = getFieldNames( S , str )
  names = fieldnames(S);
  names = names( strncmp( names , str , numel(str) ) );
end
function X = makeThumbnail( X , nsz , gnormalize )
  if nargin < 3, gnormalize = false; end
  if isempty( X )
    X = [];
    return;
  end

  X = double( X );
  sz = size( X ); sz(end+1:4) = 1;

  if gnormalize
    if sz(3) == 3
    elseif sz(3) == 1
      X = X - prctile( X(:) , 2  );
      X = X / prctile( X(:) , 98 );
      X = clamp( X , 0 , 1 );
    else
      fprintf(2,'Why is size( X ,3) equal to %d ?\n', sz(3));
    end
  end

  if isa( nsz , 'function_handle' )
    nsz = nsz( sz );
  end
  nsz(end+1:numel(sz)) = Inf;
  nsz = nsz(:).';
  
  if any( sz(1:2) > nsz(1:2) )
    nsz(1:2) = round( sz(1:2) ./ max( [ sz(1:2)./nsz(1:2) , 1 ] ) );

    X = reshape( X , [ sz(1) , sz(2) , prod( sz(3:end) ) ] );
    X = DCTresize( double( X ) , [ nsz(1:2) , prod( sz(3:end) ) ] );
    X = reshape( X , [ nsz(1:2) , sz(3:end) ] );
    X = clamp( X , 0 , 1 );
  end
  
  if sz(4) > nsz(4)
    X = X(:,:,:,  unique( round( linspace( 1 , sz(4) , nsz(4) ) ) ) ,:,:,:);
  end
  
end
function T = collectIMAGES( D , IS )
  T = [];
  for j = 1:numel(IS)
    tT = [];
    try, tT = D.(IS{j}).zThumbnail; end
    if isempty( tT ), continue; end
    tT = tT(:,:,:, round( (size(tT,4)+1)/2 ) );
    if isempty( T )
      T = tT;
    else
      if      size( tT , 3 ) == 1 && size( T , 3 ) == 3
        tT = repmat( tT , [1 1 3 1 1]);
      elseif  size( tT , 3 ) == 3 && size( T , 3 ) == 1
        T = repmat( T , [1 1 3 1 1]);
      end
      T = cat( 4 , T , tT );
    end
  end
end
function T = collectPOSITIONS( D , ZS )
  nZS = numel( ZS );

  switch nZS
    case 1, msz = [1,1]; error('why here??');
    case 2, msz = [1,2];
    case 3, msz = [1,3];
    case 4, msz = [2,2];
    otherwise
      msz = [2,3];
      for i=1:4, if prod( msz ) < nZS, msz( rem(i,2)+1 ) = msz( rem(i,2)+1 )+1; end; end
  end

  T = {};
  for Z = ZS( unique( round( linspace( 1 , nZS , prod(msz) ) ) ) ).', Z = Z{1};
    tT = [];
    if isempty(tT), try, tT = D.(Z).zThumbnail; end; end
    if isempty(tT), try, tT = D.(Z).IMAGE_001.zThumbnail; end; end
    if isempty( tT )
      keyboard;
    end
    T{end+1} = tT;
  end

  
  n = cellfun( @(x)size(x,1) , T ); m = max( n );
  for z = find( n ~= m )
    T{z}( end+1:m ,:,:,:,: ) = 0.2;
  end
  
  n = cellfun( @(x)size(x,2) , T ); m = max( n );
  for z = find( n ~= m )
    T{z}(:, end+1:m ,:,:,:,:) = 0.2;
  end
  
  n = cellfun( @(x)size(x,3) , T ); m = max( n );
  for z = find( n ~= m )
    T{z} = repmat( T{z} , [ 1 , 1 , ceil( m / size(T{z},3) ) , 1 , 1 ] );
    T{z} = T{z}(:,:,1:m,:,:);
  end
  
  n = cellfun( @(x)size(x,4) , T ); m = max( n );
  for z = find( n ~= m )
    error('niy');
    T{z} = repmat( T{z} , [ 1 , 1 , ceil( m / size(T{z},3) ) , 1 , 1 ] );
    T{z} = T{z}(:,:,1:m,:,:);
  end

  X = [];
  for z = numel( T )+1:prod(msz)
    if isempty( X )
      X = tril( ones( size( T{1} ,1) , size( T{1} ,2) ) );
      X = 2*X + fliplr(X);
      X = X/6 + 0.4;
      X = repmat( X , [ 1 , 1 , size( T{1} ,3) , size( T{1} ,4) , 1 , 1 ] );
    end
    T{z} = X;
  end
  
  T = reshape( T , [ msz(2) , msz(1) ] ).';
  T = cell2mat( T );
  
end

function T = collectORIENTATIONS( D , OS )
  T = []; C = [0 0];
  for j = 1:numel(OS)
    tT = [];
    if isempty( tT )
      try, tT = D.(OS{j}).zThumbnail; end;
    end
    if isempty( tT )
      Z = sort( getFieldNames( D.(OS{j}) , 'Position_' ) ); Z = Z{1};
      try, tT = D.(OS{j}).(Z).zThumbnail; end
    end
    if isempty( tT )
      I = sort( getFieldNames( D.(OS{j}).(Z) , 'IMAGE_' ) ); I = I{1};
      try, tT = D.(OS{j}).(Z).(I).zThumbnail; end
    end
    if isempty( tT )
      fprintf(2,'no image?\n');
    end

    tT = tT(:,:,:,round( (size(tT,4)+1)/2 ) );
    if size( tT , 3 ) ~= 3
      tT = repmat( tT , [1 1 3 1] );
    end
    col = hsv2rgb( [rand(1) 1 1] );
    tT( [1:2,end-1:end] , : , 1 ) = col(1); tT( :, [1:2,end-1:end] , 1 ) = col(1);
    tT( [1:2,end-1:end] , : , 2 ) = col(2); tT( :, [1:2,end-1:end] , 2 ) = col(2);
    tT( [1:2,end-1:end] , : , 3 ) = col(3); tT( :, [1:2,end-1:end] , 3 ) = col(3);

    m = size( tT , 1 ); n = size( tT , 2 );
    M = size( T  , 1 ); N = size( T  , 2 ); 

    T = resize( T , max( M , C(1)+m ) , max( N , C(2)+n ) , 3 , {NaN} );
    T( C(1) + (1:m) , C(2) + (1:n) , : ) = tT;

    C = C + floor( [m n]*0.58 );
  end
  T( isnan(T) ) = 1;
end



