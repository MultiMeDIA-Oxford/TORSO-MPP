function V_ = loadv( fn , vn )

  if isstruct( fn )
    fn = fn.name;
  end

  [~,~,e] = fileparts( fn );
  if isempty(e), fn = [ fn , '.mat' ]; end

  if nargin < 2

    V = whos('-file',fn);
    
    if ~nargout
      arrayfun(@(v)disp(v.name),V);
    end

  elseif isempty( vn )
    
    V = whos('-file',fn);
    if numel( V ) > 1
      error('more than a single variable stored in file');
    end
    
    vn = V(1).name;
    fprintf('Loading variable ''%s'' from "%s"\n',vn,fn);
    V = load( fn , '-mat' , vn );
    V = V.(vn);
    
  elseif ischar( vn )

    V = load( fn , '-mat' , vn );
    V = V.(vn);
  
  else
    
    error('unknown ''vn'' (variable name)');
    
  end

  if nargout
    V_ = V;
  elseif nargin > 1 
    isVarInCaller = evalin('caller', sprintf('exist( ''%s'' )',vn) );
    if      isVarInCaller == 1
      warning('A variable called ''%s'' already exists.\nProper assignment is required.',vn);
    elseif  isVarInCaller
      warning('Something called ''%s'' already exists.\nProper assignment is required.',vn);
    else
      assignin('caller',vn,V);
    end
  end
  
end
