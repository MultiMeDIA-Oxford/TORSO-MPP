function M = skewmatrix( m  )

  if isvector( m )
    
    P = length(m);

    N = ( sqrt( P*8 + 1 ) + 1 )/2;

    if mod(N,1), error('numel(m) incorrect'); end

    M = zeros(N,N);
    if isa( m , 'sym' ), M = sym(M); end
    M( ~~tril( ones(N,N) , -1 ) ) = m(end:-1:1);
    
    M(1:2:end,:) = -M(1:2:end,:);
    M(:,1:2:end) = -M(:,1:2:end);
    
    M = M.' - M;
    
  else
    
    if ndims( m ) ~= 2 || size(m,1) ~= size(m,2)
      error('incorrect matrix');
    end
    
    if ~isa( m ,'sym' ) && maxnorm( m + m.' ) > 1e-8, warning('the matrix does not skew!!!'); end
    m = ( m.' - m )/2;

    N = size(m,1);
    M = tril( ones(N,N) , -1 );
    where = ~~M;
    
    m(1:2:end,:) = -m(1:2:end,:);
    m(:,1:2:end) = -m(:,1:2:end);
    
    M = m( where );
    
    M = flipdim( M(:) , 1 );
    
  end
  
end
