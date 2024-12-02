function C = contourc( I , varargin )

  if numel(I.data)/prod(size(I,1:3)) ~= 1
    error('Data must be scalar');
  end

  if sum( size(I,1:3) == 1 ) ~= 1
    error('The input have to be only a slice.');
  end
  
  I = rot90( I , rot90( cleanout(cleanout(I,'data')) , @(I)size(I,3) ) );
  if size( I.data , 3 ) ~= 1
    error('The input have to be only a slice.');
  end

  C = contourc( I.X , I.Y , double( I.data.' ) , varargin{:} );

  C(3,:) = I.Z;

  p = 1;
  while p < size(C,2)
    C(3,p) = NaN;
    p = p + C(2,p) + 1;
  end
  
  T = I.SpatialTransform;
  C = bsxfun( @plus , T(1:3,1:3) * C , T(1:3,4) );
  C = C.';

end

