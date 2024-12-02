function I = noinfs( I , varargin )

  if nargin == 1
    varargin = {1};
  end

  I = DATA_action( I , [ '@(X) noinfs(X,' uneval( varargin{:} ) ')' ] );
  
end

