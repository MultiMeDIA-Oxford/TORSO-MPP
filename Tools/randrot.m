function R = randrot( nsd )
%{

  N = 1e+6;
  Q = rodrigues( randn(3,1) );
  A = NaN(N,1); B = NaN(N,1);
  for t = 1:N
    R = randrot(3);
    A(t) = acos( ( R(1) + R(5) + R(9) - 1 )/2 );
    
    R = Q*R;
    B(t) = acos( ( R(1) + R(5) + R(9) - 1 )/2 );
  end
  subplot(211); histn( A , 100 ); hplot( X , (1-cos(X))/pi , '.-r' );
  subplot(212); histn( B , 100 ); hplot( X , (1-cos(X))/pi , '.-r' );



%}

  persistent X Y
  if isempty(X)
    X = linspace(0,pi,101).';
    Y = ( X - sin(X) )/pi;
  end
  

  if     nsd == 0

  elseif nsd == 3

    z = rand(1)*2 - 1;
    t = ( rand(1)*2 - 1 )*pi;

    u = sqrt(1-z*z);
    u = [ cos(t)*u , sin(t)*u , z ];
    
    a = Interp1D(X,Y,rand(1));

    R = rodrigues( u , a );

  else

    nSteps = 1e3;

    R = eye(nsd);
    n = nsd*(nsd-1)/2;
    for s = 1:nSteps
      r = randn( n , 1 );
  %     r = r / sqrt( r(:).' * r(:) );
  %     r = r / 1000;
      r = skewmatrix( r );
      r = expm( r );
      R = r * R;
    end
    
  end

end
