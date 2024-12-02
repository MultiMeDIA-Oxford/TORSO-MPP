function a_ = maxnorm( a , b )

  if nargin > 1, a = a - b; end

  a= max( abs( a(:) ) );
  
  try, if issparse(a), a = full(a); end; end
  
  if nargout > 0
    a_ = a;
  else
    fprintf('%.15g\n',a);
  end

end
