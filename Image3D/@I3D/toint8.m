function varargout = toint8( I )

  [varargout{1:nargout}] = cast( I , 'int8' );

end
