function varargout = toint16( I )

  [varargout{1:nargout}] = cast( I , 'int16' );

end
