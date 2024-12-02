function A = intersect( A , varargin )

  for v = 1:numel(varargin)
    A.XY = polygon_mx( A.XY , varargin{v}.XY , 'intersection' );
  end
    
end
