function varargout = hist( I , varargin )

  [varargout{1:nargout}] = hist( double(I.data(:)) , varargin{:} );

end