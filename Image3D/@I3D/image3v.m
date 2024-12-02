function varargout = image3v( I , varargin )

  [ varargout{1:nargout} ] = image3v( permute( I.data ,[1 2 3 5 4]) , 'x' , I.X , 'y', I.Y , 'z', I.Z , 'm' , I.SpatialTransform , ...
                  varargin{:} );
    
end
