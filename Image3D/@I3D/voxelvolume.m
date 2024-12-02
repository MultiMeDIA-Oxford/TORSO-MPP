function [V,dx,dy,dz] = voxelvolume( I , varargin )

  dx = 1;
  dy = 1;
  dz = 1;
  
  if numel( I.X ) > 1
    dx = robustmeandiff( I.X );
  end

  if numel( I.Y ) > 1
    dy = robustmeandiff( I.Y );
  end

  if numel( I.Z ) > 1
    dz = robustmeandiff( I.Z );
  end

  V = dx*dy*dz * det( I.SpatialTransform(1:3,1:3) );

  if nargout <= 1 && numel( varargin )
    switch lower( varargin{1} )
      case 'x'      , V = dx;
      case 'y'      , V = dy;
      case 'z'      , V = dz;
      case 'min'    , V = min([dx dy dz]);
      case 'max'    , V = max([dx dy dz]);
      case 'mean'   , V = mean([dx dy dz]);
    end  
  end
  
  
  function M = robustmeandiff( X )
    D = diff( X );
    D( isnan(D) | isinf(D) | ~D ) = [];
    D = sort( D );
    N = numel( D );
    if N == 1
      M = D;
    else
      D = D( ceil( N*0.05 ):floor( N*0.95 ) );
      M = mean( D );
    end
  end
  
end
