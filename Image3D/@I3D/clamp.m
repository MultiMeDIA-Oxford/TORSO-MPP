function I = clamp( I , varargin )


  I = DATA_action( I , [ '@(X) clamp(X,' uneval( varargin{:} ) ')' ] );

  
end
