function A = union( A , varargin )

  for v = 1:numel(varargin)
    A.XY = polygon_mx( A.XY , varargin{v}.XY , 'union' );
  end
    
end
