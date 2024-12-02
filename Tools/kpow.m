function xd = kpow( x , n )
  
  if ~isscalar(n)
    error('exponent must be a scalar positive integer');
  elseif mod(n,1)
    error('exponent must be a scalar positive integer');
  elseif n < 1
    error('exponent must be a scalar positive integer');
  elseif n == 1
    xd = x;
  elseif n == 2
    xd = kron( x , x );
  elseif n == 3
    xd = kron( x  , x );
    xd = kron( xd , x );
  elseif n == 4
    xd = kron( x  , x );
    xd = kron( xd , xd );
  elseif ~mod(n,2)
    xd = kpow( x  , n/2 );
    xd = kron( xd , xd  );
  else
    xd = kpow( x , (n-1)/2 );
    xd = kron( xd , xd , x );
  end

  
%   xd = x;
%   for i = 2:n, xd = kron( xd , x ); end
  
end
