function varargout = tofloat( I )

  [varargout{1:nargout}] = cast( I , 'float' );

end
