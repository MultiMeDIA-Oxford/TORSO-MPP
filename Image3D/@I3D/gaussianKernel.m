function I = gaussianKernel( I , varargin )
%
%   K= gaussianKernel( -30:30 , 'std',s );
%   K= GaussianKernel( -3:3 , -3:3 , 'sigma',s );
%   K= GaussianKernel( -3:3 , -3:3 , -3:3 , 'sigma',s );
%

  I = cleanout( I ); I = remove_dereference( I );

  X = I.X - I.X( ceil(end/2) );
  Y = I.Y - I.Y( ceil(end/2) );
  Z = I.Z - I.Z( ceil(end/2) );
  
  I.T = 1;
  
  I.SpatialInterpolation = 'linear';
  I.BoundaryMode      = 'value';
  I.BoundarySize      = 0;
  I.OutsideValue      = NaN;
  I.TemporalInterpolation = 'constant';
  
  I.data = gaussianKernel( X , Y , Z , varargin{:} );
  I.ImageTransform = [ min(I.data(:))  0 ; max(I.data(:))  1 ];
  
end
