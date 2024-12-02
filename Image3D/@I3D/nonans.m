function I = nonans( I , varargin )

  if nargin == 1
    varargin = {0};
  end

  I = DATA_action( I , [ '@(X) nonans(X,' uneval( varargin{:} ) ')' ] );
  
end

