function x = shuffle( x , fast )

  try, shuffle( 1 ); end

  if nargout < 2
    fast = false;
  end

  n = numel(x);
  if n == 1,
    n = prod(size(x));
  end
  
  if fast

    x(:) = x( randperm( n ) );
    
  else
  
    s_old = randseed;

    x(:) = x( randperm( n ) );

    try, rand( s_old{:} ); end
  end

end
