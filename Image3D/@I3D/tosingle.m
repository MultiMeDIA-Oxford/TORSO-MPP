function varargout = tosingle( I )

  [varargout{1:nargout}] = cast( I , 'single' );

end
