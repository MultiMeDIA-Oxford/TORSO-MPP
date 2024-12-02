function varargout = himag3( varargin )

  ish = ishold( gca );
  hold(gca,'on');
  
  [ varargout{1:nargout} ] = imag3( varargin{:} );
  
  if ~ish, hold(gca,'off'); end

end
