function v_ = mppOption( varargin )

  nvarargin = numel( varargin );
  O = varargin{1}; varargin(1) = [];
  
  set = false;
  if      numel(varargin) &&  strcmp( varargin{1} , '=' )
    set = true;
    varargin(1) = [];
  elseif  numel(varargin) &&  strcmp( varargin{1} , ':' )
    varargin(1) = [];
  elseif  numel(varargin) &&  strcmpi( varargin{1} , 'def:' )
    varargin(1) = [];
  elseif  numel(varargin) &&  strcmpi( varargin{1} , 'default:' )
    varargin(1) = [];
  end

  if numel(varargin)
    v = evalin( 'caller' , [ varargin{:} ] );
  else
    v = [];
  end
  
  mpp = getappdata(0,'mppOptions');
  if isempty( mpp ), mpp = struct(); end
  
  if isfield( mpp , O ) && ~set
    v = mpp.(O);
  end
  
  if set
    
    mpp.(O) = v;
    setappdata(0,'mppOptions',mpp);
    
    Ostr = O;
    Ostr = [ '"' , Ostr , '"' ];
    Ostr(end+1:30) = ' ';
    fprintf(  'mppOption  %s  ', Ostr );
    fprintf(2,'set to:  ' );
    fprintf(  '%s\n' , uneval(v) );
    
  else
    
    if nargout == 0
      assignin( 'caller', O , v );
    end
    
  end
  if nargout, v_ = v; end
  
  if nvarargin > 1
    db = dbstack();
    print = [];
    for d = 1:numel( db )
      if strncmp( db(d).file , 'mpp_' , 4 )
        print = db(d).file; print = regexprep( print , '\.m$' , '' );
        break;
      end
    end
    if ~isempty( print )
      fprintf('\n\n(in %s )%s using option:     %s%s = %s;\n\n', print , blanks( 25 - numel( print ) ) , blanks( 30 - numel( O ) ) , O , uneval( v ) );
    end
  end

end
