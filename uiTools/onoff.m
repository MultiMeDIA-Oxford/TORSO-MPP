function V = onoff( V , varargin )
  if nargin < 1, error('at least one input expected'); end
  if nargin > 1
    V = get( V , varargin{:} );
  end


  if      ischar( V ) && strcmp( lower(V) , 'on' )
    V = true;
  elseif  ischar( V ) && strcmp( lower(V) , 'off' )
    V = false;
  elseif  ischar( V )
    error('irreconocible char!');
  elseif  numel( V ) ~= 1
    error('only one input!');
  elseif  V == true
    V = 'on';
  elseif  V == false
    V = 'off';
  else
    error('irreconocible value!');
  end

end
