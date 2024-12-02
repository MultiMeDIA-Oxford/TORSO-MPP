function [varargout] = mkdir_( dn , varargin )

  if isdir( dn )
    
    varargout = cell(1,nargout);
    
  else
    
    [varargout{1:nargout}] = mkdir( dn , varargin{:} );
    
  end

end
