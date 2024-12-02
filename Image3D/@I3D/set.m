function I = set( I , varargin )
%%usar con cuidado!!! no verfica nada!!!


  while ~isempty( varargin )
    prop  = varargin{1}; varargin(1) = [];
    value = varargin{1}; varargin(1) = [];
    
    switch lower(prop)
      case {'spatialinterpolation','interpolation'}
        I.SpatialInterpolation = value;

      otherwise
        I.(prop) = value;
    end

  end

end