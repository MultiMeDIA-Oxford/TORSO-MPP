function x = prevnum( x , s )
  
  if nargin < 2
    s = 100;
  end

  x = x - abs(s).*eps(x);

end
