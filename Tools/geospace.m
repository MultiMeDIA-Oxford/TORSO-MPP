function x = geospace( a , b , n )


  if nargin < 2
    n = 100;
  end
  
  if numel(a) ~= 1, error('a scalar is expected.'); end
  if numel(b) ~= 1, error('a scalar is expected.'); end
  if numel(n) ~= 1, error('a scalar is expected.'); end
  
  if n <= 1
    error('n has to be greater than 1');
  end
  if a*b < 0
    error('a  and  b have to be on the same side of the real line');
  end
  
  d = realpow( b/a , 1/(n-1) );
  %d = exp(  ( log(b)-log(a) )/(n-1) );
  
  x = [ a*(  d.^(0:n-2) ) , b ];
  
end

