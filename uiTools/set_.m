function o = set_( varargin )
  o = false;
  try
    set( varargin{:} );
    o = true;
  end
  drawnow

end
