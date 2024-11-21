function lines_ = readFile( fname , LF , LT )
% 
% lines = readFile( fname )
%   read the whole file
% 
% numLines = readFile( fname , [] )
%   return the number of lines in fname
% 
% lines = readFile( fname , lines_to_read )
%   meanings for lines_to_read:  
%     -Inf,  1 : first line
%      Inf, -1 : last line
%       -2,-3  : second to last
% 
% lines = readFile( fname , from , to )
%   from 0, -Inf, 1 --> 1
%            Inf    --> last
%   to   0,  Inf,-1 --> last
%           -Inf    --> 1
% 
%
% example to read headers of a binary vtk
%   F = readFile( fname , '[A-Za-z0-9\. \#]{6,}' )
%   F = readFile( fname , '[A-Za-z0-9\. \#]{6,}' , '[\n\r]' )
%   F = readFile( fname , '[A-Z]{4,300}[A-Za-z0-9\. \#_]{3,300}[\n\r]' )
%
%
% readFile( fname ) is almost the same than
%   F = readFile( fname , '[^\n\r]' , '[\n\r]' )
%

  persistent LAST_FILE
  if isempty(LAST_FILE)
    LAST_FILE = struct('name',{''},'datenum',{0},'bytes',{0},'BL',{''},'EL',{''},'LINES',{[]});
  end

  chunksize = 1024 * 1024;
  extra_chunksize = 512;
  if ~ischar( fname )
    FID = fname;
    alLFids = fopen('all');
    if ~any( alLFids == FID )
      error('invalid file indentifier!!');
    end
    fname = fopen( FID );
    ORIGINAL_POS = ftell( FID );
    CLEANUP = onCleanup( @()fseek( FID , ORIGINAL_POS , 'bof' ) );
    fseek( FID , 0 , 'bof' );
  else
    FID = fopen( fname , 'r' );
    if FID < 0, error('error opening file: ''%s''',fname); end
    CLEANUP = onCleanup( @()fclose(FID) );
  end
  
  BL = '';  %default begining of a line
  EL = '';  %default ending   of a line
  if nargin > 1 && ischar( LF )
    %BL = '[^\r\n]';  %classical begining of a line
    BL = LF;
    EL = '[\r\n]';   %classical ending   of a line
    if nargin > 2 && ischar( LT )
      EL = LT;
    end
  end
  

  try,   fname = fixname( fname );  end
  fname_dir = dir( fname );
  if ~isequal( LAST_FILE.datenum , fname_dir.datenum ) ||...
     ~isequal( LAST_FILE.bytes   , fname_dir.bytes   ) ||...
     ~isequal( LAST_FILE.name    , fname_dir.name    ) ||...
     ~isequal( LAST_FILE.BL      , BL                ) ||...
     ~isequal( LAST_FILE.EL      , EL                )
    LAST_FILE.LINES   = [];
    LAST_FILE.datenum = fname_dir.datenum;
    LAST_FILE.bytes   = fname_dir.bytes;
    LAST_FILE.name    = fname_dir.name;
    LAST_FILE.BL      = BL;
    LAST_FILE.EL      = EL;
  end


%   LAST_FILE.LINES = [];
  if isempty( LAST_FILE.LINES ) && ischar( BL ) && isempty( BL ) && ischar( EL ) && isempty( EL )
    
    %default reading of a text file
    BegL = [0];
    EndL = [ ];
    cof = 0;
%     kk = 0;
    while ~feof( FID )
%       kk = kk+1; disp(kk)
      B = fread( FID , chunksize , '*char' ).';

      B10 = B == char(10);
      BegL = [ BegL , cof + find( B10 ) ];

      B13 = B == char(13);
      EndL = [ EndL , cof + find( B10 | B13 ) ];

      cof = cof + numel(B);
    end
    EndL = [ EndL , cof+1 ];
    LAST_FILE.LINES = sortLINES( BegL , EndL );

  elseif isempty( LAST_FILE.LINES )

    %personalized reading with BL (begining of the file) and EL (ending of
    %the file) which are reg.expressions.
    BegL = [ ];
    EndL = [ ];
    cof  = 0;
    while 1
      cof = ftell( FID );
      B = fread( FID , chunksize+extra_chunksize, '*char' ).';

      begs = regexp( B , BL , 'start' ) - 1;
      if numel(begs) && cof ~= 0 && begs(1) == 0, begs = begs(2:end); end
      
      ends = regexp( B , EL , 'end' );
      ends = [ ends , begs ];
      
      BegL = [ BegL , cof + begs ];
      EndL = [ EndL , cof + ends ];

      if feof( FID ), cof = ftell(FID); break; end
      fseek( FID , -extra_chunksize , 'cof' );
    end
    EndL = [ EndL , cof+1 ];
    
    LAST_FILE.LINES = sortLINES( unique(BegL) , unique(EndL) );

  end

  
  numLines = size( LAST_FILE.LINES , 1 ) - 1;
  
  if nargin == 1 || ischar( LF )

    Lno = 1:numLines;

  elseif nargin == 2 && ~ischar(LF) && isempty( LF )
    
    lines_ = numLines;
    return;

  elseif nargin == 2 && ~ischar(LF)
    
    Lno = LF;

  elseif nargin == 3 && ~ischar(LF)
    
    if numel( LF ) > 1 || numel( LT ) > 1
      error('from and to are expected as scalars.');
    end

    if LF == 0,               LF = 1;                 end
    if isinf( LF ) && LF > 0, LF = numLines;          end
    if isinf( LF ) && LF < 0, LF = 1;                 end
    if LF < 0,                LF = numLines + LF + 1; end

    if LT == 0,               LT = numLines;          end
    if isinf( LT ) && LT > 0, LT = numLines;          end
    if isinf( LT ) && LT < 0, LT = 1;                 end
    if LT < 0,                LT = numLines + LT + 1; end
    
    Lno = LF:LT;
    
  end

  Lno( isinf(Lno) & Lno > 0 ) = numLines;
  Lno( isinf(Lno) & Lno < 0 ) = 1;
  Lno( Lno < 0 ) = numLines + Lno( Lno < 0 ) + 1;
  if any( Lno > numLines | Lno < 1 )
    error('Lno invalid, only %d lines in file',numLines );
  end
  
  
  %uneval( Lno )
  lines = cell( numel(Lno) , 1 );
  cof   = ftell( FID );
  %for L = 1:numel( Lno )
  for L = 1:numel( Lno )
    if cof ~= LAST_FILE.LINES(Lno(L),1)
      fseek( FID , LAST_FILE.LINES(Lno(L),1) , 'bof' );
      cof = LAST_FILE.LINES(Lno(L),1);
    end

    thisLENGTH = LAST_FILE.LINES(Lno(L)+1,1) - LAST_FILE.LINES(Lno(L),1);
    thisLINE = fread( FID , thisLENGTH , '*char' ).';
    cof = cof + thisLENGTH;
    
%     try
      thisLINE( (LAST_FILE.LINES(Lno(L),2)-LAST_FILE.LINES(Lno(L),1)):end ) = [];
%     catch
%       thisLINE = thisLINE( 1:find( ismembc( thisLINE , char([10 13])) ,1) );
%     end

    if isempty( thisLINE ), lines{L} = '';
    else, lines{L} = thisLINE;
    end
  end
  
  if nargout == 0
    
    fprintf('**************************************************************************\n');
    fprintf('readFile( "%s" )  (in the specified lines)\n',fname);
    fprintf('..........................................................................\n');
    cellfun(@disp,lines);
    fprintf('--------------------------------------------------------------------------\n');

  else
    lines_ = lines;
  end
  
  
  function LINES = sortLINES( B , E )
    numLines = numel( B );
    
    LINES = B(:); LINES(:,2) = 0;
    e = 1;
    for l = 1:numLines
      while E(e) <= B(l), e = e+1; end
      LINES(l,2) = E(e);
    end
    LINES(l+1,:) = LINES(l,2);
    

%     LINES = zeros( numLines + 1 ,2); %e = 1;
%     for l = 1:numLines
%       ll = B(l);
%       %e  = e - 1 + find( E(e:end) > ll ,1);
%       e  = find( E > ll ,1);
%       LINES(l,:) = [ ll , E( e ) ];
%     end
%     LINES(l+1,:) = LINES(l,2);
    

%     clc; round( reshape( unique( [ B(:) ; E(:) ] ) ,2,[]).' )
    
%     LINES = reshape( sort( [ B(:) ; E(:) ] ) , 2,[] ).';
%     LINES(end+1,:) = LINES(end,2);
    
%     B = B(:); B(:,2) = 0;
%     E = E(:); E(:,2) = 1;
%     
%     LINES = kk= sortrows( [ B ; E ] ,1);
%     [~,ll] = unique( LINES(:,1) , 'first' );
%     LINES = LINES(ll,:);
%     LINES = [ LINES( LINES(:,2) == 0,1) , LINES( LINES(:,2) == 1,1) ];
    
  end
end
