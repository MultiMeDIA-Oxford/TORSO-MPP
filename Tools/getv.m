function x = getv( x , varargin )

  if numel( varargin ) == 1 && iscell( varargin{1} )
    
    x = x{ varargin{1}{1} };

  elseif isstruct( x ) && strcmp( varargin{1} , '.' )
    
    x = x.(varargin{2});
    
  elseif isstruct( x ) && ~strcmp( varargin{1} , '.' ) && strncmp( varargin{1} , '.' , 1 )

    f = varargin{1};
    
    while 1
      try, if f(1) == '.', f(1) = []; end; end
      if isempty( f ), break; end
      e = find( f == '.' ,1) - 1;
      if isempty( e ), e = numel(f); end
      ff = f(1:e); f(1:e) = [];
      x = x.(ff);
    end
    
  else

    x = x( varargin{:} );

  end

end
