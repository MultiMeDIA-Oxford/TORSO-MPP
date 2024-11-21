function M = skewmatrix( m  )

  if ~isvector( m )
    error('only valid to pertub the generating vector');
  end
  
  P = length( m );
  N = ( sqrt( P*8 + 1 ) + 1 )/2;

  if mod(N,1), error('length(m) incorrect'); end

  M = dual;
  M.v = zeros(N,N);

  M.v( ~~tril( ones(N,N) , -1 ) ) = m.v(end:-1:1);

  M.v(1:2:end,:) = -M.v(1:2:end,:);
  M.v(:,1:2:end) = -M.v(:,1:2:end);

  M.v = M.v.' - M.v;

end
