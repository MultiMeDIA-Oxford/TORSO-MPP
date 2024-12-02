function varargout = toint32( I )

  [varargout{1:nargout}] = cast( I , 'int32' );

end
