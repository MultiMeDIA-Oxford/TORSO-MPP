function x = gsmooth( x , s , varargin )

  g = gaussianKernel( -20*ceil(s):20*ceil(s) ,'s',s);
  g = g / sum(g(:));
  g = g(:);

  x = double( x );
  for d = 1:ndims(x)
    if size(x,d) <= 1, continue; end
    x = imfilter( x , vec(g,d) ,'same','symmetric',varargin{:});
  end

end
