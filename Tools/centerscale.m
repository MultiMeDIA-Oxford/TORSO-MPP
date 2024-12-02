function x = centerscale( x , s , anchor )

  if nargin < 2, s = 1.1;       end
  if nargin < 3, anchor = 'c';  end
  
  if ischar( anchor )
    switch lower(anchor)
      case {'c','center'}
        anchor = mean(x,2);
      case {'0','1'}
        anchor = x(:,1);
      case {'2','end'}
        anchor = x(:,2);
      case {'min'}
        anchor = min(x,[],2);
      case {'max'}
        anchor = max(x,[],2);
    end
  end
  
  x = bsxfun( @plus , bsxfun( @minus , x , anchor )*s , anchor );

end
