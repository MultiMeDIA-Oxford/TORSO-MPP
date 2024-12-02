function [ S_ , err_coeff ] = generateStencil( X , order , method , sorted )

if 0
%%  
X = randn(1,30);
order = 1;
F = @(x)log(abs(x)); %F=@(x)x;
plot( X , F( generateStencil( X , order , 'vander'   , 1  ) ), '.b' ,...
      X , F( generateStencil( X , order , 'vander'   , 0  ) ), 'sr' ,...
      X , F( generateStencil( X , order , 'fornberg' , 1  ) ), 'ob' ,...
      X , F( generateStencil( X , order , 'fornberg' , 0  ) ), 'xr' ,...
      X , F( generateStencil( X , order  ,'sym'      , 1  ) ), '+b' ,...
      X , F( generateStencil( X , order  ,'sym'      , 0  ) ), 'dr' );
%%
end

  if nargin < 2 || isempty(order),  order  = 1;          end
  if nargin < 3 || isempty(method), method = 'fornberg'; end
  if nargin < 4, sorted = false; end
  N = numel(X);
  X = X(:).';

  if sorted, [X,ids] = sort( X ); end
  
  switch lower(method)
    case 'vander'
      g = vec( 0:N-1 );
      M = bsxfun(@power   , X , g );
      g(1)=1; g = cumprod(g);
      M = bsxfun(@rdivide , M , g );

      d = zeros(N,1); d(order+1) = 1;

      setWarning( 'off' , 'MATLAB:nearlySingularMatrix' );
      S = M \ d;
    %   S = pinv( M ) * d;
      restoreWarning( 'MATLAB:nearlySingularMatrix' );
    case 'sym'
      X = sym(X);
    
      M = sym( ones(N,N) );
      f = sym( 1 );
      for g = 1:N-1
        f = f*g;
        M(g+1,:) = X.^g/f;
      end

      d = sym(zeros(N,1)); d(order+1) = 1;

      S = M \ d;
      S = double( S );
    
    case 'fornberg'
      %Fornberg, B. "Calculation of weights in finite difference formulas." SIAM review 40.3 (1998): 685-691.
      S = Fornberg( X , order );
  end
  if sorted, S(ids) = S; end
  

  if nargout ~= 1
    g = vec( 0:(N+3) );
    M = bsxfun(@power   , X , g );
    g(1)=1; g = cumprod(g);
    M = bsxfun(@rdivide , M , g );

    err_coeff = M*S;
    err_coeff( order+1 ) = err_coeff(order+1)-1;
    err_coeff( abs(err_coeff) < 1e-10 ) = 0;
  end

  if nargout == 0

    fprintf(' (%d)|\n' , order );
    fprintf('y   |    =   ');
    for p = 1:N
      if abs(S(p)) < 1e-10, continue; end
      if S(p) > 0  &&  p > 1
        fprintf(' +');
      elseif S(p) < 0
        fprintf(' -');
      end
      fprintf(' %s*y[%g]', strtrim( rats(abs(S(p))) ) , X(p) );
    end
    
    for p = 1:numel(err_coeff)
      if abs( err_coeff(p) ) < 1e-8, continue; end
      fprintf(' + %g*f0^(%d)', abs(err_coeff(p)) , p-1 );
    end
    fprintf('\n');
    fprintf('    |(0)\n');
    
  else
    
    S_         = S.';
    
  end
	  

  function S = Fornberg( X , order )
    %from: http://faculty.washington.edu/rjl/fdmbook/matlab/fdcoeffF.m
    c1 = 1;
    c4 = X(1);
    C  = zeros( N-1 , order+1 );
    C(1,1) = 1;
    for i = 1:(N-1)
      i1 = i+1;
      mn = min( i , order );
      c2 = 1;
      c5 = c4;
      c4 = X(i1);
      for j = 0:i-1
        j1 = j+1;
        c3 = X(i1) - X(j1);
        c2 = c2*c3;
        if j == i-1
          for s = mn:-1:1
            s1 = s+1;
            C(i1,s1) = c1*(s*C(i1-1,s1-1) - c5*C(i1-1,s1))/c2;
          end
          C(i1,1) = -c1*c5*C(i1-1,1)/c2;
        end
        for s = mn:-1:1
          s1 = s+1;
          C(j1,s1) = (c4*C(j1,s1) - s*C(j1,s1-1))/c3;
        end
        C(j1,1) = c4*C(j1,1)/c3;
      end
      c1 = c2;
    end

    S = C(:,end);            % last column of c gives desired row vector
  end

end
