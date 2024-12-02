function varargout = exp( V , varargin )

  warning('I3D:exp','use expm instead of exp. exp will change soon as exp(I.data).')
  
  [ varargout{1:nargout} ] = expm( V , varargin{:} );
end
