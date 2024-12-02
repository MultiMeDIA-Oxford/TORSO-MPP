function o = order( x , varargin )
  
  sz = size(x);
  if sum( sz > 1 ) == 1
    [~,o] = sort( x , varargin{:} );
  elseif numel(sz) == 2 && sz(2) > 1
    [~,o] = sortrows( x , varargin{:} );
  else
    error('non-sortable array?');
  end



end
