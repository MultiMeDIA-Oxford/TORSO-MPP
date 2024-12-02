function varargout = touint8( I )

  [varargout{1:nargout}] = cast( I , 'uint8' );

end
