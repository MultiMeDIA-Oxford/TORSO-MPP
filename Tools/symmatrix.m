function M = symmatrix( m , k )

  if nargin < 2, k = 1; end
  if k < 0, error('incorrect k'); end

  if isvector( m )
  
    P = numel(m);

    N = ( sqrt( P*8+1 ) + 2*k - 1 )/2;

    if mod(N,1), error('numel(m) incorrect'); end

    M = tril( ones(N,N) , -k );
    M( ~~M ) = m(:);

    M = M + M.';

    M( ~~eye(N) ) = M( ~~eye(N) )/2;
    
  else
    
    if ndims( m ) ~= 2 || size(m,1) ~= size(m,2)
      error('incorrect matrix');
    end
    
    if maxnorm( m - m.' ) > 1e-12, warning('the matrix does not symmetric!!!'); end
    m = ( m + m.' )/2;

    N = size(m,1);
    M = tril( ones(N,N) , -k );
    
    M = m( ~~M );
    
  end
    

end
