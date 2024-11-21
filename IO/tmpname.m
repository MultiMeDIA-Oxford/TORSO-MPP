function [ name , CLEANER ] = tmpname( name , varargin )
%
% name = tmpname( pattern , 'mkdir' , 'mkfile' );
%
%   pattern temp_??????  -->  temp_00001, temp_00002,...
%   pattern d*\f_?       -->  d0\f_0, dd\f_0, dc\f_1,...
%
%

  if ~isempty( which( 'isfile' ) )
    ISF = @(fn,varargin)isfile(fn,varargin{:});
  else
    ISF = @(fn,varargin)exist(fn,'file');
  end

  if nargin < 1 || isempty( name )
    name = 'temp_??????';
    try, name = getoption('tmpname','default_name',name); end
  end

  if ~any( name == '?' ) && ~any( name == '*' )
    error('invalid temporal pattern. At least a ''?'' or a ''*'' was expected.');
  end
  
  MKD = false; MKF = false;
  for v = 1:numel(varargin)
    if ~ischar( varargin{v} ), continue; end
    if strcmpi( varargin{v} , 'mkdir' )
      MKD = true;
    end
    if strcmpi( varargin{v} , 'mkfile' )
      MKD = true; MKF = true;
    end
  end
  
  
  isRel = true;
  sys = computer;
  switch upper(sys)
    case {'PCWIN','PCWIN64'}
      if ~isempty( regexp( name , '^[a-zA-Z]\:(?:\\|/|$)' ) ) ||...
         ~isempty( regexp( name , '^\\\\\' ) )
        isRel = false;
      end
    case {'SOL2','HPUX','GLNX86','GLNXA64','MAC'}
      if ~isempty( regexp( varargin{1} , '^(?:\\|/|\~)' ) )
        isRel = false;
      end
  end
  
  if isRel
    tdir = [];
    try
      tdir = getoption('tmpname','dir');
      if ~iscell( tdir ), tdir = {tdir}; end
      while ~isempty(tdir)
          try
        if isdir( tdir{1} )
          tdir = tdir{1};
          break;
        end
          end
        tdir(1) = [];
      end
    end
    if isempty( tdir )
      tdir = tempdir;
    end
    name = fullfile( tdir , name );
  end
  
  name = builtin( 'strrep' , name , '?' , char(161) );
  name = builtin( 'strrep' , name , '*' , char(162) );
  try, name = fixname( name ); end
  name = builtin( 'strrep' , name , char(161) , '?' );
  name = builtin( 'strrep' , name , char(162) , '*' );
  
  
  [q_starts,q_ends] = regexp( name , '\?+' , 'start' , 'end' );
  [a_starts,a_ends] = regexp( name , '\*+' , 'start' , 'end' );
  siz = [ q_ends - q_starts + 1 , a_ends - a_starts + 1 ];
  
  starts = [ q_starts , -a_starts ];
  ends   = [ q_ends   , -a_ends   ];
  [~,ord] = sort( abs(starts) );
  starts = starts( ord );
  ends   = ends( ord );
  siz    = siz( ord );
  
  q = zeros(1,numel(starts));
  while ~isinf( q(1) )
    for d = 1:numel(q)
      if starts(d) > 0
        T = sprintf('%0*d',siz(d),q(d));
      else
        T = [];
        while numel( T ) < siz(d)
          T = [ T , builtin( 'strrep' , uuid , '-' , '' ) ];
        end
        T = T(1:siz(d));
      end
      name( abs( starts(d) ):abs( ends(d) ) ) = T;
    end
    
    if name(end) == filesep
      if ~isdir( name ), break; end
    else
      try
        if ~ISF( name , 'fast' ), break; end
      catch
        if ~ISF( name ), break; end
      end
    end
    
    for d = numel(siz):-1:1
      q(d) = q(d) + 1;
      if q(d) == 10^siz(d)
        if d == 1
          error('pattern is too simply and too much existing files');
        end
        q(d) = 0;
      else
        break;
      end
    end
  end
  
  DIR_made  = '';
  if MKD
    dirname = fileparts(name);
    %% it have to be fixed in order to remove all created dir
    %% CLEANER of tmpdir( 'A/B/C/D/?.txt' ,'mkfile') should remove A, not only D
    if ~isdir( dirname )
      status = mkdir( dirname );
      if ~status
        error('imposible to make the directory.');
      end
      DIR_made = dirname;
    end
  end
  
  FILE_made = '';
  if MKF
    status = fopen( name ,'w');
    if status < 0
      error('imposible to make the file.');
    end
    fclose( status );
    FILE_made = name;
  end
  
  
  if nargout > 1
    CLEANER = eval( [ 'onCleanup( @() tmpCLEANER( ''delete_file'' , ''' , FILE_made , ''' , ''delete_directory'' , ''' , DIR_made , ''' ) )' ] );
  end
  
  function tmpCLEANER( ff , f , dd , d )
    if ~isempty(f)
      if ISF(f),
        try, delete(f); end
      end
    end
    if ~isempty(d)
      if isdir( d )
        try
          D = rdir( d );
          for f = 1:numel(D)
            try, delete( D(f).name ); end
          end
        end
        try, rmdir( d , 's' ); end
      end
    end
  end
    
end
