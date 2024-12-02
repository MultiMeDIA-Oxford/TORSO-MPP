function fixDiaryFile( MaxNumberOfLines )

  if nargin < 1
    MaxNumberOfLines = Inf;
  end

  df = [];
  if ischar( MaxNumberOfLines )
    df = MaxNumberOfLines;
    MaxNumberOfLines = Inf;
  end

  vprintf = @(varargin)fprintf(varargin{:});
  vprintf = @(varargin)0;

  state = get(0,'Diary');
  diary( 'off' );
  onCLEAN = onCleanup( @()diary( state ) );

  if isempty( df )
    df = get(0,'DiaryFile');
    vprintf('Fixing Diary... "%s"\n',df);
  else
    vprintf('Fixing File... "%s"\n',df);
  end
  if ~isfile( df ), return; end

  if MaxNumberOfLines <= 0
    delete( df );
  end
    

  
  fid = fopen( df , 'r' );
  d = fread( fid , Inf , '*char' );
  fclose( fid );
  
  if ~isinf( MaxNumberOfLines )
    br = find( d == 10 );
    if numel( br ) > MaxNumberOfLines
      d = d( br( end - MaxNumberOfLines + 1 ):end );
      if d(1) == 13, d(1) = []; end
    end
  end
  
  d = d.';
  
  d = regexprep( d , '<.*?>' , '');
  
  while any( d == 8 )
    vprintf( '%6d ''\\b''s remaining\n' , sum( d == 8 ) );
    d = regexprep( d , '([^\x8][^\x8][^\x8][^\x8]\x8\x8\x8\x8)' , '' );
    d = regexprep( d , '([^\x8][^\x8][^\x8][^\x8]\x8\x8\x8\x8)' , '' );
    d = regexprep( d , '([^\x8][^\x8][^\x8]\x8\x8\x8)' , '' );
    d = regexprep( d , '([^\x8][^\x8][^\x8]\x8\x8\x8)' , '' );
    d = regexprep( d , '([^\x8][^\x8]\x8\x8)' , '' );
    d = regexprep( d , '([^\x8][^\x8]\x8\x8)' , '' );
    d = regexprep( d , '([^\x8]\x8)' , '' );
    d = regexprep( d , '([^\x8]\x8)' , '' );
  end
  
  fid = fopen( df , 'w' );
  fwrite( fid , d , 'char' );
  fclose( fid );
  vprintf('OK\n');
  
end
