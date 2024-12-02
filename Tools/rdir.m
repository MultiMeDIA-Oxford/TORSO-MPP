function [F,names] = rdir( Dname , varargin )
%
% F = rdir( Dname , INCLUDE_fcn , MAX_depth   , VERBOSE )
% F = rdir( Dname , MAX_depth   , INCLUDE_fcn , VERBOSE )
% F = rdir( Dname , MAX_depth   , INCLUDE_fcn , VERBOSE , EXCLUDE_fcn )
%

  %defaults
  INCLUDE_fcn   = [];
  MAX_depth     = Inf;
  VERBOSE_level = 0;
  EXCLUDE_fcn   = [];
  
  
  if numel( varargin ) > 4, error('no more than 4 parameters can be passed in'); end
  
  if numel( varargin ) == 4
    EXCLUDE_fcn = varargin{4}; varargin(4) = [];
  end
  if ischar( EXCLUDE_fcn )
    EXCLUDE_fcn = @(dname)~isempty( regexp( dname , EXCLUDE_fcn , 'ONCE' ) );
  end
  if ~isempty( EXCLUDE_fcn ) && ~isa( EXCLUDE_fcn , 'function_handle' )
    error('invalid EXCLUDEfcn');
  end

    
  if numel( varargin ) && islogical( varargin{end} )
    VERBOSE_level = varargin{end};
    varargin(end) = [];
  elseif numel( varargin ) && ischar( varargin{end} )
    switch lower( varargin{end} )
      case {'verbose','-v','-verbose'},   VERBOSE_level = true;   varargin(end) = [];
      case {'quiet','-q','-quiet'},       VERBOSE_level = false;  varargin(end) = [];
      case {'v0','-v0'},                  VERBOSE_level = 0;      varargin(end) = [];
      case {'v1','-v1'},                  VERBOSE_level = 1;      varargin(end) = [];
      case {'v2','-v2'},                  VERBOSE_level = 2;      varargin(end) = [];
      case {'v3','-v3'},                  VERBOSE_level = 3;      varargin(end) = [];
      case {'v4','-v4'},                  VERBOSE_level = 4;      varargin(end) = [];
      case {'v5','-v5'},                  VERBOSE_level = 5;      varargin(end) = [];
      case {'v6','-v6'},                  VERBOSE_level = 6;      varargin(end) = [];
      case {'v7','-v7'},                  VERBOSE_level = 7;      varargin(end) = [];
      otherwise
    end
  elseif numel( varargin ) == 3
    VERBOSE_level = varargin{3}; varargin(3) = [];
  end
  if isempty( VERBOSE_level ), VERBOSE_level = false; end
  if islogical( VERBOSE_level ), VERBOSE_level = double(VERBOSE_level) * 2; end

  %parsing varargin{1} y varargin{2}
  try, T = vararginTYPE( varargin{:} ); catch LE, throw(LE); end
  T( T == 'F' ) = 'C'; T( T == 'n' ) = '-';
  switch T
    case {'--','c-','-c'},
    case {'C-'},                      INCLUDE_fcn = varargin{1};
    case {'-C'},                      INCLUDE_fcn = varargin{2};
    case {'N-','Nc'},                                             MAX_depth = varargin{1};
    case {'cN','-N'},                                             MAX_depth = varargin{2};
    case {'NC'},                      INCLUDE_fcn = varargin{2};  MAX_depth = varargin{1};
    case {'CN'},                      INCLUDE_fcn = varargin{1};  MAX_depth = varargin{2};
    case {'cc','CC','Cc','cC','NN'},  error('syntax should be: rdir( dirname , mask , depth );');
    otherwise,                        error('non contemplanted inputs.');
  end

  F = reshape( struct('name',{},'folder',{},'date',{},'bytes',{},'isdir',{},'datenum',{},'depth',{}) ,[0,1]);
  if MAX_depth < 0, return; end

  counter_blanks = MAX_depth + 1;
  if isinf( counter_blanks ), counter_blanks = 8; end
  
  if nargin < 1, Dname = ''; end

  if isempty( INCLUDE_fcn ), INCLUDE_fcn = []; end
  if ischar( INCLUDE_fcn ) && ~isempty( strfind( INCLUDE_fcn , '**' ) )
    INCLUDE_fcn = regexprep( INCLUDE_fcn , '\*\*' , '*' );
    INCLUDE_fcn = regexptranslate( 'wildcard', INCLUDE_fcn );
    cprintf( VERBOSE_level > 5 , 'Converting mask from glob to regexp: ''%s''\n' , INCLUDE_fcn );
  end
  if ischar( INCLUDE_fcn )
    INCLUDE_fcn = @(fn)~isempty( regexp( fn , INCLUDE_fcn , 'ONCE' ) );
  end
  if ~isempty( INCLUDE_fcn ) && ~isa( INCLUDE_fcn , 'function_handle' )
    error('mask should be a string or a function handle');
  end
  
  FS = filesep;
  if ~iscell( Dname ), Dname = { Dname }; end
  counter = [ numel(Dname) ; 0 ];
  for D = Dname(:).', D = D{1};
    if isempty( D ), D = pwd; end
    try, if D(2) == ':', D(1) = upper(D(1)); end; end
    cprintf( VERBOSE_level > 0 , 'Now, going through directory: "%s"\n', D );
    while numel(D) && D(end) == FS, D(end) = []; end
    counter(end) = counter(end) + 1;
    addFiles( D , 0 );
  end
  
  if numel( Dname ) > 1
    [~,id] = unique( { F.name } ,'first' );
    F = F(id);
  end
  
  if nargout > 1
    names = { F.name }.';
  end
  
  function addFiles( D , current_depth )
    thisD = D;
    if thisD(end) == ':', thisD = [ thisD , FS ]; end
    if ~isempty( EXCLUDE_fcn ) && EXCLUDE_fcn(thisD);
      cprintf( VERBOSE_level > 1 , 'excluded: "%s"\n' , thisD );
      return;
    end
    
    nf1 = 0; nf2 = 0; DD = [];
    
    f = dir_( thisD );
    
    if numel( f )

      w = [ f.isdir ];
      DD = { f( w ).name };
      f( w ) = [];

      nf1 = numel(f);
      for i = 1:nf1
        f(i).name = [ D , FS , f(i).name ];
      end
      if ~isempty( INCLUDE_fcn )
        w = ~builtin( 'cellfun' , INCLUDE_fcn , { f.name } );
        f( w ) = [];
      end
      nf2 = numel(f);

      if nf2
        if ~isfield( f , 'folder' ), [ f.folder ] = deal( thisD );          end
        if ~isfield( f , 'depth'  ), [ f.depth  ] = deal( current_depth );  end
        f = orderfields( f , {'name','folder','date','bytes','isdir','datenum','depth'} );
        F = [ F ; f(:) ];
      end
      
    end

    switch VERBOSE_level
      case 0,
      case 1,
      case 2, cprintf( nf2 > 0 ,                      '%5d in  "%s"    [depth:%d](total:%d)\n', nf2 , thisD , current_depth , numel(F) );
      case 3, cprintf( nf2 > 0 | current_depth <= 2 , '%5d in  "%s"    [depth:%d](total:%d)\n', nf2 , thisD , current_depth , numel(F) );
      case 4, cprintf(                                '%5d in  "%s"    [depth:%d](total:%d)\n', nf2 , thisD , current_depth , numel(F) );
      case 5, cprintf(                       '%5d (of %5d) in  "%s"    [depth:%d](total:%d)\n', nf2 , nf1 , thisD , current_depth , numel(F) );
      otherwise,
        counter_str = sprintf('%d',round(( (counter(2,:)-1)./counter(1,:) )*9));
        cprintf(                      '[%s%s] %5d (of %5d) in  "%s"    [depth:%d](total:%d)\n' ,...
          counter_str,blanks( counter_blanks - numel(counter_str) ) ,...
          nf2 , nf1 , thisD , current_depth , numel(F) );
    end
    
    if current_depth >= MAX_depth
      cprintf( VERBOSE_level > 6 , 'MAX_depth (%d) reached.\n',MAX_depth);
      return;
    end
    
    counter = [ counter , [ numel(DD) ; 0 ] ];
    for i = 1:numel(DD)
      counter(end) = counter(end) + 1;
      addFiles( [ D , FS , DD{i} ] , current_depth + 1 );
    end
    counter(:,end) = [];
  end
    
end



function T = vararginTYPE( varargin )
  T = '';
  for v = varargin(:).'
    switch class(  v{1} )
      case {'char'}
        T = [ T , 'c' ];
      case {'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
        T = [ T , 'n' ];
      case {'logical'}
        T = [ T , 'l' ];
      case {'function_handle'}
        T = [ T , 'f' ];
      otherwise
        T = [ T , 'u' ];
    end
    if ~isempty(  v{1} )
      T(end) = T(end) + 'A' - 'a';
    end
  end
  T(end+1:2) = '-';

  if any( T == 'u' ), error('unknown type in varargin.'); end
  if any( T == 'U' ), error('unknown type in varargin.'); end
  if any( T == 'f' ), error('empty function_handle in varargin.'); end
  if any( T == 'l' ), error('logical in varargin.'); end
  if any( T == 'L' ), error('logical in varargin.'); end

  if T(end) == 'n', T(end) = '-'; end
end
function cprintf( varargin )
  if islogical( varargin{1} )
    if ~varargin{1}, return; end
    varargin(1) = [];
  end

  persistent isHot
  if isempty( isHot ), isHot = matlab.internal.display.isHot(); end
  if ~isHot
    fprintf( varargin{:} );
    return;
  end
  
  s = sprintf( varargin{:} );
%   s = strrep( s , '"' ,'<strong>"</strong>');
%   fs = [ 0 , find( s == filesep | s == '"' ) ];
  fs = [ 0 , find( s == filesep ) ];
  for f = 1:numel(fs)-1
    fprintf(  '%s', s( fs(f)+1:fs(f+1)-1 ) );
    if isHot
      fprintf(2,'<strong>%s </strong>' , s(fs(f+1)) ); fprintf('\b');
    else
      fprintf(2,'%s ' , s(fs(f+1)) ); fprintf('\b');
    end
  end
  fprintf( '%s' , s( fs(end)+1:end ) );

end
function F = dir_( D )
  try
    J = java.io.File( D ); %java file object
    J = J.listFiles; %java.io.File objects
    
    m = numel(D)+1;
    
    F = struct([]);
    for f = numel( J ):-1:1
      n = char( J(f) );
      F(f).name = n( m:end );
      while F(f).name(1) == '\' || F(f).name(1) == '/', F(f).name(1) = []; end
%       F(f).name = strrep( n , D , '' );
      F(f).date = '';
      F(f).bytes = 0;
      F(f).isdir = J(f).isDirectory;
      F(f).datenum = 0;
    end
    F = F(:);

    return;
  end
  
  try
    F = dir( D );

    F( strcmp( {F.name} , '.'  ) ) = [];
    F( strcmp( {F.name} , '..' ) ) = [];

    return;
  end

%{

fname = fullfile(pwd, 'demomtime.txt');
f = System.IO.File.Create(fname);
f.Close
System.IO.File.SetLastWriteTime(fname, System.DateTime(2079, 7, 27)); %set modification time to 27 July 2079
s = dir;

%}

  JS = java.io.File(D).listFiles();
  if numel(JS)
    F = struct('name',[],'date',[],'bytes',[],'isdir',[],'datenum',[],'folder',[]);
    for f = numel(JS):-1:1, J = JS(f);
      F(f,1).name   = char( J.getName );
      %F(f,1).date   = char( System.IO.File.GetCreationTime( char(J) ).ToString );
      F(f,1).bytes  = J.length;
      F(f,1).isdir  = J.isDirectory;
      F(f,1).folder = D;
    end
    [~,ord]=sort( { F.name } );
    F = F(ord);
  else
    F = struct('name','.','date',[],'bytes',0,'isdir',true,'datenum',[]);
  end
  
end